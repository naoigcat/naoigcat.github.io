#!/usr/bin/env swift
import Foundation

// `mise run serve` used to be an inline zsh program.  Keeping the orchestration
// in Swift makes the task independent of the user's login shell while leaving
// Docker and Jekyll as the actual site runtime.

struct CommandResult {
    let status: Int32
    let stdout: String
    let stderr: String
}

struct ScriptError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

/// Runs one executable without passing the command through a shell.
///
/// Using an argument array is important here: paths and container ids remain
/// individual arguments even when they contain characters meaningful to a
/// shell.  This is the Swift equivalent of the old quoted zsh invocations.
func runCommand(
    _ executable: String,
    _ arguments: [String],
    currentDirectory: URL? = nil,
    inheritIO: Bool = false
) throws -> CommandResult {
    let process = Process()
    if executable.hasPrefix("/") {
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
    } else {
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments
    }
    process.currentDirectoryURL = currentDirectory

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    if inheritIO {
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
    } else {
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
    }

    do {
        try process.run()
    } catch {
        throw ScriptError("Could not start \(executable): \(error)")
    }
    process.waitUntilExit()

    guard !inheritIO else {
        return CommandResult(status: process.terminationStatus, stdout: "", stderr: "")
    }

    let stdout = String(
        data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
    ) ?? ""
    let stderr = String(
        data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
    ) ?? ""
    return CommandResult(status: process.terminationStatus, stdout: stdout, stderr: stderr)
}

/// Fails with the command's stderr, which is usually more useful than a bare
/// non-zero status when Docker cannot start or Jekyll exits early.
@discardableResult
func requireCommand(
    _ executable: String,
    _ arguments: [String],
    currentDirectory: URL? = nil,
    inheritIO: Bool = false
) throws -> CommandResult {
    let result = try runCommand(
        executable,
        arguments,
        currentDirectory: currentDirectory,
        inheritIO: inheritIO
    )
    guard result.status == 0 else {
        let detail = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        if detail.isEmpty {
            throw ScriptError("Command failed (\(result.status)): \(executable) \(arguments.joined(separator: " "))")
        }
        throw ScriptError(detail)
    }
    return result
}

/// Reads one value from the shared Swift configuration.
///
/// Standalone Swift scripts cannot import another script as a module, so the
/// configuration file exposes a deliberately tiny command-line interface.
func projectConfigValue(_ key: String, root: URL) throws -> String {
    let config = root.appendingPathComponent("scripts/config.swift")
    let result = try requireCommand(
        "swift",
        [config.path, key],
        currentDirectory: root
    )
    let value = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else {
        throw ScriptError("config.swift returned an empty value for \(key)")
    }
    return value
}

let serveContainerName = "learnings-serve"

/// Stops the named serve container.  Used from defer and from signal handlers
/// because defer does not run when the process is killed by SIGINT/SIGTERM.
func stopServeContainer(root: URL) {
    _ = try? runCommand(
        "docker",
        ["stop", serveContainerName],
        currentDirectory: root
    )
}

let root = URL(fileURLWithPath: #filePath)
    .standardizedFileURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()

do {
    let image = try projectConfigValue("github-pages-image", root: root)

    // A fixed name caps leftovers at one container and lets the next serve
    // (or a signal handler) address it without remembering a random id.
    _ = try? runCommand(
        "docker",
        ["rm", "-f", serveContainerName],
        currentDirectory: root
    )

    // Detached mode lets this process poll the container until Jekyll is ready;
    // the old task used the same pattern so the browser opens only after the
    // development server has announced "Server running".
    let started = try runCommand(
        "docker",
        [
            "run", "--rm", "--init", "-d",
            "--name", serveContainerName,
            "-v", "\(root.path):/src/site",
            "-p", "127.0.0.1::4000",
            image,
            "jekyll", "serve", "--future", "-w", "--force_polling",
            "-H", "0.0.0.0", "-P", "4000",
        ],
        currentDirectory: root
    )
    guard started.status == 0 else {
        let detail = started.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        throw ScriptError(detail.isEmpty ? "Failed to start container" : detail)
    }

    let containerID = started.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !containerID.isEmpty else {
        throw ScriptError("Failed to get container ID")
    }

    // `defer` covers normal errors, including a timeout or a missing port.  It
    // is deliberately harmless when Docker has already removed the container.
    defer { stopServeContainer(root: root) }

    // Ctrl-C during `docker attach` is the usual exit path; ignore the default
    // disposition so DispatchSource can stop the container first.
    signal(SIGINT, SIG_IGN)
    signal(SIGTERM, SIG_IGN)
    let signalQueue = DispatchQueue(label: "learnings.serve.signals")
    let signalSources: [DispatchSourceSignal] = [SIGINT, SIGTERM].map { sig in
        let source = DispatchSource.makeSignalSource(signal: sig, queue: signalQueue)
        source.setEventHandler {
            stopServeContainer(root: root)
            Darwin.exit(128 + sig)
        }
        source.resume()
        return source
    }
    // Keep sources retained until attach returns or the process exits.
    defer { _ = signalSources }

    let timeoutSeconds = 300
    var elapsed = 0
    while true {
        let logs = try runCommand(
            "docker",
            ["logs", containerID],
            currentDirectory: root
        )
        let combinedLogs = logs.stdout + logs.stderr

        if combinedLogs.contains("Error response from daemon") {
            fputs(combinedLogs, stderr)
            throw ScriptError("Docker daemon error while waiting for server")
        }
        if combinedLogs.contains("Server running") {
            break
        }

        if elapsed >= timeoutSeconds {
            fputs(combinedLogs, stderr)
            throw ScriptError("Timeout waiting for server")
        }

        // A one-second poll keeps the task responsive without busy-spinning.
        Thread.sleep(forTimeInterval: 1)
        elapsed += 1
    }

    let portResult = try requireCommand(
        "docker",
        ["port", containerID, "4000/tcp"],
        currentDirectory: root
    )
    let firstPortLine = portResult.stdout.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
    guard let colon = firstPortLine.lastIndex(of: ":") else {
        throw ScriptError("Failed to resolve host port")
    }
    let port = String(firstPortLine[firstPortLine.index(after: colon)...])
    guard !port.isEmpty else {
        throw ScriptError("Failed to resolve host port")
    }

    // `open` is the macOS command used by the original task.  On Linux, which
    // is useful for a local container host as well, use the conventional
    // `xdg-open` fallback.  Opening the browser is best-effort; the terminal
    // remains usable even on a headless machine.
    #if os(macOS)
    let browser = "open"
    #else
    let browser = "xdg-open"
    #endif
    _ = try? runCommand(
        browser,
        ["http://localhost:\(port)"],
        currentDirectory: root,
        inheritIO: true
    )

    // Attach after readiness so the command stays interactive and shows the
    // same Jekyll log stream as `docker attach` in the former zsh task.
    _ = try? runCommand(
        "docker",
        ["attach", containerID],
        currentDirectory: root,
        inheritIO: true
    )
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
