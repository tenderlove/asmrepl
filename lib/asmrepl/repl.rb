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
      puts bold(" CPU STATE ".center(48, "="))
      puts state
      puts
      puts "FLAGS: #{state.flags.inspect}"
      puts
    end

    def display_state_change last_state, state
      puts bold(" REGISTER CHANGES ".center(48, "="))
      show_flags = false

      state.fields.each do |field|
        next if field == "rip"

        if last_state[field] != state[field]
          print "#{field.ljust(6)}  "
          print sprintf("%#018x", last_state[field])
          print " => "
          puts bold(sprintf("%#018x", state[field]))
        end
      end

      if last_state.flags != state.flags
        puts
        puts "FLAGS: #{state.flags.inspect}"
      end

      puts
    end

    def bold string
      "\e[1m#{string}\e[0m"
    end

    def start
      pid = fork {
        CFuncs.traceme
        @buffer.to_function([], TYPE_INT).call
      }

      tracer = CFuncs::Tracer.new pid
      should_cpu = true
      last_state = nil

      while tracer.wait
        state = tracer.state

        # Show CPU state once on boot
        if last_state.nil?
          display_state state
          last_state = state
        else
          display_state_change last_state, state
          last_state = state
        end

        # Move the JIT buffer to the current instruction pointer
        pos = (state.rip - @buffer.memory.to_i)
        @buffer.seek pos
        use_history = true
        begin
          loop do
            cmd = nil
            prompt = sprintf("(rip %#018x)> ", state.rip)
            text = Reline.readmultiline(prompt, use_history) do |multiline_input|
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
              begin
                parser_result = @parser.parse text.chomp
              rescue
                puts "Invalid intruction"
                next
              end

              begin
                binary = @assembler.assemble parser_result
                binary.bytes.each { |byte| @buffer.putc byte }
              rescue Fisk::Errors::InvalidInstructionError => e
                # Print an error message when the instruction is invalid
                puts e.message
                next
              end
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
        rescue Interrupt
          puts ""
          exit 0
        end
        tracer.continue
      end
    end
  end
end
