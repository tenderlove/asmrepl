require "fiddle"
require "fisk/helpers"
require "reline"

if RUBY_PLATFORM =~ /darwin/
  require "asmrepl/macos"
else
  require "asmrepl/linux"
end

module ASMREPL
  class REPL
    include Fiddle

    if RUBY_PLATFORM =~ /darwin/
      CFuncs = MacOS
    else
      CFuncs = Linux
    end

    def initialize
      size = 1024 * 16 # 16k is enough for anyone!
      @buffer = CFuncs.jitbuffer(size)
      CFuncs.memset(@buffer.memory, 0xCC, size)
      @parser    = ASMREPL::Parser.new
      @assembler = ASMREPL::Assembler.new
    end

    def display_state state
      puts " CPU STATE ".center(48, "=")
      puts state
      puts
      puts "FLAGS: #{state.flags.inspect}"
      puts
    end

    def start
      pid = fork {
        CFuncs.traceme
        @buffer.to_function([], TYPE_INT).call
      }

      tracer = CFuncs::Tracer.new pid
      should_cpu = true
      while tracer.wait
        state = tracer.state

        # Show CPU state once on boot
        if should_cpu
          display_state state
          should_cpu = false
        end

        # Move the JIT buffer to the current instruction pointer
        pos = (state.rip - @buffer.memory.to_i)
        @buffer.seek pos
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
            break if text.chomp.empty?
            binary = @assembler.assemble @parser.parse text.chomp
            binary.bytes.each { |byte| @buffer.putc byte }
            break
          in [:read, "cpu"]
            display_state state
          in [:read, reg]
            val = state[reg]
            if val
              puts sprintf("%#018x", state[reg])
            else
              puts "Unknown command: "
              puts "  " + text
            end
          else
          end
        end
        tracer.continue
      end
    end
  end
end
