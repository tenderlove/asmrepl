# ASMREPL

This is a REPL for assembly language.

Currently it only works on macOS, but I'll make it work on Linux too.

## Usage

I haven't made a gem yet, so use it like this:

```
$ bundle install
$ sudo ruby -I lib:test bin/asmrepl
```

When the REPL starts, it will display all register values and flags:

```
================== CPU STATE ===================
rax  000000000000000000  r8   0x0000600001782be0
rbx  000000000000000000  r9   0x00007fbf9b0068c0
rcx  0x0000000109dae951  r10  000000000000000000
rdx  0x000000000000000c  r11  0x000000010999c000
rdi  0x00007ff7b6b2bbf0  r12  000000000000000000
rsi  0x00000001096315fd  r13  0x00007ff7b6b2bdc0
rbp  0x00007ff7b6b2bc40  r14  000000000000000000
rsp  0x00007ff7b6b2bc38  r15  000000000000000000

rip     0x000000010999c001
rflags  0x0000000000000246
cs      0x000000000000002b
fs      000000000000000000
gs      000000000000000000

FLAGS: ["PF", "ZF", "IF"]

>> 
```

Then you can issue commands and inspect register values.  Let's write to the
`rax` register and inspect its value:

```
>> mov rax, 5
>> rax
0x0000000000000005
>> 
```

Now let's write to the `rbx` register and add the two values:

```
>> mov rbx, 3
>> add rax, rbx
>> rax
0x0000000000000008
>> rbx
0x0000000000000003
>> 
```

Finally, lets check all values in the CPU:

```
>> cpu
================== CPU STATE ===================
rax  0x0000000000000008  r8   0x0000600001d848a0
rbx  0x0000000000000003  r9   0x00007fced316f850
rcx  0x00000001017da951  r10  000000000000000000
rdx  0x000000000000000c  r11  0x00000001013cc000
rdi  0x00007ff7bf0fdbf0  r12  000000000000000000
rsi  0x000000010105f5fd  r13  0x00007ff7bf0fddc0
rbp  0x00007ff7bf0fdc40  r14  000000000000000000
rsp  0x00007ff7bf0fdc38  r15  000000000000000000

rip     0x00000001013cc029
rflags  0x0000000000000202
cs      0x000000000000002b
fs      000000000000000000
gs      000000000000000000

FLAGS: ["IF"]

>> 
```
