# ASMREPL

This is a REPL for assembly language.

## Usage

Install the gem:

```
$ gem install asmrepl
```

Then start the repl like this:

```
$ asmrepl
```

If you're on macOS, you'll need to start the repl with `sudo`.

When the REPL starts, it will display all register values and flags:

```
================== CPU STATE ===================
rax  000000000000000000  r8   0x00007f89d0f04640
rbx  000000000000000000  r9   0x0000000000000004
rcx  0x00007f89d0f04a50  r10  000000000000000000
rdx  0x..fc611d3f0aa2900d4  r11  0x00000001033a4000
rdi  0x00007ff7bd126148  r12  000000000000000000
rsi  000000000000000000  r13  0x00007ff7bd125dc0
rbp  0x00007ff7bd125c40  r14  000000000000000000
rsp  0x00007ff7bd125c38  r15  000000000000000000

rip     0x00000001033a4001
rflags  0x0000000000000246
cs      0x000000000000002b
fs      000000000000000000
gs      000000000000000000

FLAGS: ["PF", "ZF", "IF"]

(rip 0x00000001033a4001)>
```

Then you can issue commands and inspect register values.  Let's write to the
`rax` register and inspect its value:

```
(rip 0x00000001033a4001)> mov rax, 5
=============== REGISTER CHANGES ===============
rax     000000000000000000 => 0x0000000000000005

(rip 0x00000001033a4009)> rax
0x0000000000000005
(rip 0x00000001033a4009)>
```

Now let's write to the `rbx` register and add the two values:

```
(rip 0x00000001033a4009)> mov rbx, 3
=============== REGISTER CHANGES ===============
rbx     000000000000000000 => 0x0000000000000003

(rip 0x00000001033a4011)> add rax, rbx
=============== REGISTER CHANGES ===============
rax     0x0000000000000005 => 0x0000000000000008
rflags  0x0000000000000246 => 0x0000000000000202

FLAGS: ["IF"]

(rip 0x00000001033a4015)> rax
0x0000000000000008
(rip 0x00000001033a4015)> rbx
0x0000000000000003
(rip 0x00000001033a4015)>
```

Finally, lets check all values in the CPU:

```
(rip 0x00000001033a4015)> cpu
================== CPU STATE ===================
rax  0x0000000000000008  r8   0x00007f89d0f04640
rbx  0x0000000000000003  r9   0x0000000000000004
rcx  0x00007f89d0f04a50  r10  000000000000000000
rdx  0x..fc611d3f0aa2900d4  r11  0x00000001033a4000
rdi  0x00007ff7bd126148  r12  000000000000000000
rsi  000000000000000000  r13  0x00007ff7bd125dc0
rbp  0x00007ff7bd125c40  r14  000000000000000000
rsp  0x00007ff7bd125c38  r15  000000000000000000

rip     0x00000001033a4015
rflags  0x0000000000000202
cs      0x000000000000002b
fs      000000000000000000
gs      000000000000000000

FLAGS: ["IF"]

(rip 0x00000001033a4015)>
```
