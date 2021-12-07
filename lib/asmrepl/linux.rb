require "fisk/helpers"
require "asmrepl/thread_state"

module ASMREPL
  module Linux
    include Fiddle

    def self.make_function name, args, ret
      ptr = Handle::DEFAULT[name]
      func = Function.new ptr, args, ret, name: name
      define_singleton_method name, &func.to_proc
    end

    # from sys/mman.h on macOS
    PROT_READ   = 0x01
    PROT_WRITE  = 0x02
    PROT_EXEC   = 0x04
    MAP_PRIVATE = 0x0002
    MAP_SHARED  = 0x0001
    MAP_ANON    = 0x20

    make_function "ptrace", [TYPE_INT, TYPE_INT, TYPE_VOIDP, TYPE_VOIDP], TYPE_INT
    make_function "memset", [TYPE_VOIDP, TYPE_INT, TYPE_SIZE_T], TYPE_VOID

    make_function "mmap", [TYPE_VOIDP,
                           TYPE_SIZE_T,
                           TYPE_INT,
                           TYPE_INT,
                           TYPE_INT,
                           TYPE_INT], TYPE_VOIDP

    def self.mmap_jit size
      ptr = mmap 0, size, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_SHARED | MAP_ANON, -1, 0
      ptr.size = size
      ptr
    end

    def self.jitbuffer size
      Fisk::Helpers::JITBuffer.new mmap_jit(size), size
    end

    PTRACE_TRACEME = 0

    PTRACE_CONT = 7

    # x86_64-linux-gnu/sys/ptrace.h
    PTRACE_GETREGS = 12
    PTRACE_SETREGS = 13

    def self.traceme
      raise unless ptrace(PTRACE_TRACEME, 0, 0, 0).zero?
    end

    fields = (<<-eostruct).scan(/int ([^;]*);/).flatten
struct user_regs_struct
{
  __extension__ unsigned long long int r15;
  __extension__ unsigned long long int r14;
  __extension__ unsigned long long int r13;
  __extension__ unsigned long long int r12;
  __extension__ unsigned long long int rbp;
  __extension__ unsigned long long int rbx;
  __extension__ unsigned long long int r11;
  __extension__ unsigned long long int r10;
  __extension__ unsigned long long int r9;
  __extension__ unsigned long long int r8;
  __extension__ unsigned long long int rax;
  __extension__ unsigned long long int rcx;
  __extension__ unsigned long long int rdx;
  __extension__ unsigned long long int rsi;
  __extension__ unsigned long long int rdi;
  __extension__ unsigned long long int orig_rax;
  __extension__ unsigned long long int rip;
  __extension__ unsigned long long int cs;
  __extension__ unsigned long long int eflags;
  __extension__ unsigned long long int rsp;
  __extension__ unsigned long long int ss;
  __extension__ unsigned long long int fs_base;
  __extension__ unsigned long long int gs_base;
  __extension__ unsigned long long int ds;
  __extension__ unsigned long long int es;
  __extension__ unsigned long long int fs;
  __extension__ unsigned long long int gs;
};
    eostruct

    class ThreadState < ASMREPL::ThreadState.build(fields)
      private

      def read_flags; eflags; end

      def other_registers
        super - ["orig_rax"]
      end
    end

    class Tracer
      def initialize pid
        @pid = pid
      end

      def wait
        Process.waitpid @pid
      end

      def state
        state = ThreadState.malloc
        raise unless Linux.ptrace(PTRACE_GETREGS, @pid, 0, state).zero?

        state
      end

      def state= state
        raise unless Linux.ptrace(PTRACE_SETREGS, @pid, 0, state).zero?

        state
      end

      def continue
        unless Linux.ptrace(Linux::PTRACE_CONT, @pid, 1, 0).zero?
          raise
        end
      end
    end
  end
end
