require "fiddle"
require "fisk/helpers"
require "crabstone"
require "reline"

class Crabstone::Binding::Instruction
  class << self
    alias :old_release :release
  end

  # Squelch error in crabstone
  def self.release obj
    nil
  end
end

module ASMREPL
  class REPL
    include Fiddle

    module MacOS
      include Fiddle

      def self.make_function name, args, ret
        ptr = Handle::DEFAULT[name]
        func = Function.new ptr, args, ret, name: name
        define_singleton_method name, &func.to_proc
      end

      make_function "ptrace", [TYPE_INT, TYPE_INT, TYPE_VOIDP, TYPE_INT], TYPE_INT
      make_function "memset", [TYPE_VOIDP, TYPE_INT, TYPE_SIZE_T], TYPE_VOID
      make_function "strerror", [TYPE_INT], TYPE_CONST_STRING
      make_function "mach_task_self", [], TYPE_VOIDP
      make_function "task_threads", [TYPE_VOIDP, TYPE_VOIDP, TYPE_VOIDP], TYPE_VOIDP
      make_function "task_for_pid", [TYPE_VOIDP, TYPE_INT, TYPE_VOIDP], TYPE_INT
      make_function "task_threads", [TYPE_VOIDP, TYPE_VOIDP, TYPE_VOIDP], TYPE_INT
      make_function "thread_get_state", [TYPE_VOIDP, TYPE_INT, TYPE_VOIDP, TYPE_VOIDP], TYPE_INT
      class ThreadState
        fields = (<<-eostruct).scan(/uint64_t ([^;]*);/).flatten
struct x86_thread_state64_t {
  uint64_t rax;
  uint64_t rbx;
  uint64_t rcx;
  uint64_t rdx;
  uint64_t rdi;
  uint64_t rsi;
  uint64_t rbp;
  uint64_t rsp;
  uint64_t r8;
  uint64_t r9;
  uint64_t r10;
  uint64_t r11;
  uint64_t r12;
  uint64_t r13;
  uint64_t r14;
  uint64_t r15;
  uint64_t rip;
  uint64_t rflags;
  uint64_t cs;
  uint64_t fs;
  uint64_t gs;
}
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
            buf << "#{reg.ljust(6)}  #{sprintf("%#018x", send(reg))}\n"
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
          flags = rflags
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

      PT_TRACE_ME    = 0
      PT_CONTINUE    = 7

      class Tracer
        def initialize pid
          @pid = pid
          @target = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)

          raise unless MacOS.task_for_pid(MacOS.mach_task_self, pid, @target.ref).zero?

          @thread_list = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
          thread_count = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)

          raise unless MacOS.task_threads(@target, @thread_list.ref, thread_count).zero?

          @thread = Fiddle::Pointer.new(@thread_list[0, Fiddle::SIZEOF_VOIDP].unpack1("l!"))
        end

        def wait
          Process.waitpid @pid
        end

        def state
          # Probably should use this for something
          # count = thread_count[0]

          # I can't remember what header I found this in, but it's from a macOS header
          # :sweat-smile:
          x86_THREAD_STATE64_COUNT = ThreadState.sizeof / Fiddle::SIZEOF_INT

          # Same here
          x86_THREAD_STATE64 = 4

          state_count = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT64_T)
          state_count[0, Fiddle::SIZEOF_INT64_T] = [x86_THREAD_STATE64_COUNT].pack("l!")

          state = ThreadState.malloc
          raise unless MacOS.thread_get_state(@thread, x86_THREAD_STATE64, state, state_count).zero?

          state
        end

        def continue
          unless CFuncs.ptrace(CFuncs::PT_CONTINUE, @pid, 1, 0).zero?
            raise
          end
        end
      end
    end

    CFuncs = MacOS

    def initialize
      size = 1024 * 16 # 16k is enough for anyone!
      @buffer = Fisk::Helpers.jitbuffer(size)
      CFuncs.memset(@buffer.memory, 0xCC, size)
      @parser    = ASMREPL::Parser.new
      @assembler = ASMREPL::Assembler.new
    end

    def start
      pid = fork {
        raise unless CFuncs.ptrace(CFuncs::PT_TRACE_ME, 0, 0, 0).zero?
        @buffer.to_function([], TYPE_INT).call
      }

      tracer = CFuncs::Tracer.new pid
      while tracer.wait
        state = tracer.state
        puts " CPU STATE ".center(48, "=")
        puts state
        puts
        puts "FLAGS: #{state.flags.inspect}"
        puts
        pos = (state.rip - @buffer.memory.to_i)
        @buffer.seek pos
        cs = Crabstone::Disassembler.new(Crabstone::ARCH_X86, Crabstone::MODE_64)
        puts " INSTRUCTION HISTORY ".center(48, "=")
        cs.disasm(@buffer.memory[0, pos], @buffer.memory.to_i).each {|i|
          printf("0x%x:\t%s\t\t%s\n",i.address, i.mnemonic, i.op_str)
        }
        puts
        use_history = true
        loop do
          cmd = nil
          text = Reline.readmultiline(">> ", use_history) do |multiline_input|
            if multiline_input =~ /\A\s*(\w+)\s*\Z/
              register = $1
              cmd = [:read, register]
            else
              cmd = :run
            end
            true
          end

          case cmd
          in :run
            binary = @assembler.assemble @parser.parse text.chomp
            binary.bytes.each { |byte| @buffer.putc byte }
            break
          in [:read, reg]
            puts sprintf("%#018x", state[reg])
          else
          end
        end
        tracer.continue
      end
    end
  end
end

ASMREPL::REPL.new.start
