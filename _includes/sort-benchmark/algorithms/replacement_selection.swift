let REPLACEMENT_SELECTION_HEAP_SIZE = 32

func replacement_selection_sift_down(_ heap: inout [Int], _ i: Int) {
    var i = i
    let n = heap.count
    while true {
        let left = 2 * i + 1
        let right = left + 1
        var smallest = i
        if left < n && heap[left] < heap[smallest] {
            smallest = left
        }
        if right < n && heap[right] < heap[smallest] {
            smallest = right
        }
        if smallest == i {
            break
        }
        heap.swapAt(i, smallest)
        i = smallest
    }
}

func replacement_selection_sift_up(_ heap: inout [Int], _ i: Int) {
    var i = i
    while i > 0 {
        let parent = (i - 1) / 2
        if heap[i] >= heap[parent] {
            break
        }
        heap.swapAt(i, parent)
        i = parent
    }
}

func replacement_selection_heapify_min(_ heap: inout [Int]) {
    if heap.count <= 1 {
        return
    }
    for i in (0..<(heap.count / 2)).reversed() {
        replacement_selection_sift_down(&heap, i)
    }
}

func replacement_selection_heap_push(_ heap: inout [Int], _ value: Int) {
    heap.append(value)
    let i = heap.count - 1
    replacement_selection_sift_up(&heap, i)
}

func replacement_selection_heap_pop_min(_ heap: inout [Int]) -> Int {
    let n = heap.count
    precondition(n > 0)
    let min = heap[0]
    let last = heap.removeLast()
    if !heap.isEmpty {
        heap[0] = last
        replacement_selection_sift_down(&heap, 0)
    }
    return min
}

func replacement_selection_generate_runs(_ input: UnsafeBufferPointer<Int>, _ mem: Int) -> [[Int]] {
    let n = input.count
    var runs = [[Int]]()
    if n == 0 {
        return runs
    }

    let m = max(min(mem, n), 1)
    var i = 0
    var heap = [Int]()
    heap.reserveCapacity(m)
    while i < n && heap.count < m {
        heap.append(input[i])
        i += 1
    }
    replacement_selection_heapify_min(&heap)

    var frozen = [Int]()
    frozen.reserveCapacity(m)
    var run = [Int]()

    while true {
        if heap.isEmpty {
            if !run.isEmpty {
                runs.append(run)
                run = []
            }
            if frozen.isEmpty && i >= n {
                break
            }
            heap = frozen
            frozen = []
            while i < n && heap.count < m {
                heap.append(input[i])
                i += 1
            }
            if heap.isEmpty {
                break
            }
            replacement_selection_heapify_min(&heap)
            continue
        }

        let out = replacement_selection_heap_pop_min(&heap)
        run.append(out)

        if i < n {
            let next = input[i]
            i += 1
            if next >= out {
                replacement_selection_heap_push(&heap, next)
            } else {
                frozen.append(next)
            }
        }
    }

    return runs
}

func replacement_selection_merge_all_runs(_ runs: [[Int]]) -> [Int] {
    if runs.isEmpty {
        return []
    }
    var queue = runs
    while queue.count > 1 {
        var next = [[Int]]()
        next.reserveCapacity((queue.count + 1) / 2)
        var idx = 0
        while idx + 1 < queue.count {
            next.append(merge_values(queue[idx], queue[idx + 1]))
            idx += 2
        }
        if idx < queue.count {
            next.append(queue[idx])
        }
        queue = next
    }
    return queue.popLast() ?? []
}

func replacement_selection_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { replacement_selection_sort($0) }
}

func replacement_selection_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    let runs = replacement_selection_generate_runs(
        UnsafeBufferPointer(a),
        REPLACEMENT_SELECTION_HEAP_SIZE
    )
    let sorted = replacement_selection_merge_all_runs(runs)
    for i in 0..<n {
        a[i] = sorted[i]
    }
}
