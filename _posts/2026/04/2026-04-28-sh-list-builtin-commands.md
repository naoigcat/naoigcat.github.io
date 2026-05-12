---
title:     シェルの組み込みコマンドを一覧表示する
date:      2026-04-28 05:13:54 +0900
tags:      bash
---

## 組み込みコマンドを一覧表示する

Bashの組み込みコマンドは `help` コマンドで一覧表示できる。

```sh
$ bash --noprofile --norc -lc 'help'
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)
These shell commands are defined internally.  Type `help' to see this list.
Type `help name' to find out more about the function `name'.
Use `info bash' to find out more about the shell in general.
Use `man -k' or `info' to find out more about commands not in this list.

A star (*) next to a name means that the command is disabled.

 JOB_SPEC [&]                       (( expression ))
 . filename [arguments]             :
 [ arg... ]                         [[ expression ]]
 alias [-p] [name[=value] ... ]     bg [job_spec ...]
 bind [-lpvsPVS] [-m keymap] [-f fi break [n]
 builtin [shell-builtin [arg ...]]  caller [EXPR]
 case WORD in [PATTERN [| PATTERN]. cd [-L|-P] [dir]
 command [-pVv] command [arg ...]   compgen [-abcdefgjksuv] [-o option
 complete [-abcdefgjksuv] [-pr] [-o continue [n]
 declare [-afFirtx] [-p] [name[=val dirs [-clpv] [+N] [-N]
 disown [-h] [-ar] [jobspec ...]    echo [-neE] [arg ...]
 enable [-pnds] [-a] [-f filename]  eval [arg ...]
 exec [-cl] [-a name] file [redirec exit [n]
 export [-nf] [name[=value] ...] or false
 fc [-e ename] [-nlr] [first] [last fg [job_spec]
 for NAME [in WORDS ... ;] do COMMA for (( exp1; exp2; exp3 )); do COM
 function NAME { COMMANDS ; } or NA getopts optstring name [arg]
 hash [-lr] [-p pathname] [-dt] [na help [-s] [pattern ...]
 history [-c] [-d offset] [n] or hi if COMMANDS; then COMMANDS; [ elif
 jobs [-lnprs] [jobspec ...] or job kill [-s sigspec | -n signum | -si
 let arg [arg ...]                  local name[=value] ...
 logout                             popd [+N | -N] [-n]
 printf [-v var] format [arguments] pushd [dir | +N | -N] [-n]
 pwd [-LP]                          read [-ers] [-u fd] [-t timeout] [
 readonly [-af] [name[=value] ...]  return [n]
 select NAME [in WORDS ... ;] do CO set [--abefhkmnptuvxBCHP] [-o opti
 shift [n]                          shopt [-pqsu] [-o long-option] opt
 source filename [arguments]        suspend [-f]
 test [expr]                        time [-p] PIPELINE
 times                              trap [-lp] [arg signal_spec ...]
 true                               type [-afptP] name [name ...]
 typeset [-afFirtx] [-p] name[=valu ulimit [-SHacdfilmnpqstuvx] [limit
 umask [-p] [-S] [mode]             unalias [-a] name [name ...]
 unset [-f] [-v] [name ...]         until COMMANDS; do COMMANDS; done
 variables - Some variable names an wait [n]
 while COMMANDS; do COMMANDS; done  { COMMANDS ; }
```

Zshでは `whence` コマンドを使用して組み込みコマンドを一覧表示できる。

```sh
$ zsh -flc 'whence -wm "*" | grep "builtin$"'
-: builtin
.: builtin
:: builtin
[: builtin
alias: builtin
autoload: builtin
bg: builtin
bindkey: builtin
break: builtin
builtin: builtin
bye: builtin
cd: builtin
chdir: builtin
command: builtin
compadd: builtin
comparguments: builtin
compcall: builtin
compctl: builtin
compdescribe: builtin
compfiles: builtin
compgroups: builtin
compquote: builtin
compset: builtin
comptags: builtin
comptry: builtin
compvalues: builtin
continue: builtin
declare: builtin
dirs: builtin
disable: builtin
disown: builtin
echo: builtin
echotc: builtin
echoti: builtin
emulate: builtin
enable: builtin
eval: builtin
exec: builtin
exit: builtin
export: builtin
false: builtin
fc: builtin
fg: builtin
float: builtin
functions: builtin
getln: builtin
getopts: builtin
hash: builtin
history: builtin
integer: builtin
jobs: builtin
kill: builtin
let: builtin
limit: builtin
local: builtin
log: builtin
logout: builtin
noglob: builtin
popd: builtin
print: builtin
printf: builtin
private: builtin
pushd: builtin
pushln: builtin
pwd: builtin
r: builtin
read: builtin
readonly: builtin
rehash: builtin
return: builtin
sched: builtin
set: builtin
setopt: builtin
shift: builtin
source: builtin
suspend: builtin
test: builtin
times: builtin
trap: builtin
true: builtin
ttyctl: builtin
type: builtin
typeset: builtin
ulimit: builtin
umask: builtin
unalias: builtin
unfunction: builtin
unhash: builtin
unlimit: builtin
unset: builtin
unsetopt: builtin
vared: builtin
wait: builtin
whence: builtin
where: builtin
which: builtin
zcompile: builtin
zformat: builtin
zle: builtin
zmodload: builtin
zparseopts: builtin
zregexparse: builtin
zstyle: builtin
```
