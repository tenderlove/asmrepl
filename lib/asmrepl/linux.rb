require "fisk/helpers"

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

    def self.traceme
      raise unless ptrace(PTRACE_TRACEME, 0, 0, 0).zero?
    end

    class ThreadState
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
      fields.each_with_index do |field, i|
        define_method(field) do
          to_ptr[Fiddle::SIZEOF_INT64_T * i, Fiddle::SIZEOF_INT64_T].unpack1("l!")
        end
      end

      define_singleton_method(:sizeof) do
        fields.length * Fiddle::SIZEOF_INT64_T
      end

      def [] name
        idx = fields.index(name)
        return unless idx
        to_ptr[Fiddle::SIZEOF_INT64_T * idx, Fiddle::SIZEOF_INT64_T].unpack1("l!")
      end

      def self.malloc
        new Fiddle::Pointer.malloc sizeof
      end

      attr_reader :to_ptr

      def initialize buffer
        @to_ptr = buffer
      end

      define_method(:fields) do
        fields
      end

      def to_s
        buf = ""
        fields.first(8).zip(fields.drop(8).first(8)).each do |l, r|
          buf << "#{l.ljust(3)}  #{sprintf("%#018x", send(l))}"
          buf << "  "
          buf << "#{r.ljust(3)}  #{sprintf("%#018x", send(r))}\n"
        end

        buf << "\n"

        fields.drop(16).each do |reg|
          buf << "#{reg.ljust(8)}  #{sprintf("%#018x", send(reg))}\n"
        end
        buf
      end

      FLAGS = [
        ['CF', 'Carry Flag'],
        [nil, 'Reserved'],
        ['PF', 'Parity Flag'],
        [nil, 'Reserved'],
        ['AF', 'Adjust Flag'],
        [nil, 'Reserved'],
        ['ZF', 'Zero Flag'],
        ['SF', 'Sign Flag'],
        ['TF', 'Trap Flag'],
        ['IF', 'Interrupt Enable Flag'],
        ['DF', 'Direction Flag'],
        ['OF', 'Overflow Flag'],
        ['IOPL_H', 'I/O privilege level High bit'],
        ['IOPL_L', 'I/O privilege level Low bit'],
        ['NT', 'Nested Task Flag'],
        [nil, 'Reserved'],
      ]

      def flags
        flags = eflags
        f = []
        FLAGS.each do |abbrv, _|
          if abbrv && flags & 1 == 1
            f << abbrv
          end
          flags >>= 1
        end
        f
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

      def continue
        unless Linux.ptrace(Linux::PTRACE_CONT, @pid, 1, 0).zero?
          raise
        end
      end
    end
  end
end
