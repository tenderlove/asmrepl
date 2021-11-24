require "racc/parser"
require "ripper"
require "fisk"
require "set"
require "strscan"

module ASMREPL
  class Lexer
    INTEGER = /(?:[-+]?0b[0-1_,]+               (?# base 2)
                 |[-+]?(?:0(?!x)|[1-9][0-9_,]*) (?# base 10)
                 |[-+]?0x[0-9a-fA-F_,]+         (?# base 16))/x

    def initialize input
      @input = input
      @scanner = StringScanner.new input
    end

    REGISTERS = Set.new Fisk::Registers.constants.map(&:to_s)
    INSTRUCTIONS = Set.new Fisk::Instructions.constants.map(&:to_s)

    def next_token
      return if @scanner.eos?

      if @scanner.scan(INTEGER)
        [:on_int, @scanner.matched]
      elsif @scanner.scan(/\[/)
        [:on_lbracket, @scanner.matched]
      elsif @scanner.scan(/\]/)
        [:on_rbracket, @scanner.matched]
      elsif @scanner.scan(/,/)
        [:on_comma, @scanner.matched]
      elsif @scanner.scan(/qword/)
        [:qword, @scanner.matched]
      elsif @scanner.scan(/dword/)
        [:dword, @scanner.matched]
      elsif @scanner.scan(/word/)
        [:word, @scanner.matched]
      elsif @scanner.scan(/byte/)
        [:byte, @scanner.matched]
      elsif @scanner.scan(/ptr/)
        [:ptr, @scanner.matched]
      elsif @scanner.scan(/rip/i)
        [:on_rip, @scanner.matched]
      elsif @scanner.scan(/movabs/i)
        [:on_instruction, Fisk::Instructions::MOV]
      elsif @scanner.scan(/\w+/)
        ident = @scanner.matched
        if INSTRUCTIONS.include?(ident.upcase)
          [:on_instruction, Fisk::Instructions.const_get(ident.upcase)]
        elsif REGISTERS.include?(ident.upcase)
          [:on_register, Fisk::Registers.const_get(ident.upcase)]
        else
          [:on_ident, @scanner.matched]
        end
      elsif @scanner.scan(/\s+/)
        [:on_sp, @scanner.matched]
      elsif @scanner.scan(/\+/)
        [:plus, @scanner.matched]
      elsif @scanner.scan(/-/)
        [:minus, @scanner.matched]
      else
        raise
      end
    end
  end

  class Parser < Racc::Parser
    def initialize
      @registers = Set.new Fisk::Registers.constants.map(&:to_s)
      @instructions = Set.new Fisk::Instructions.constants.map(&:to_s)
    end

    def parse input
      @lexer = Lexer.new input
      do_parse
    end

    def new_command mnemonic, arg1, arg2
      [:command, mnemonic, arg1, arg2]
    end

    def new_tuple mnemonic, arg1
      [:command, mnemonic, arg1]
    end

    def new_single mnemonic
      [:command, mnemonic]
    end

    def next_token
      while tok = @lexer.next_token
        next if tok.first == :on_sp
        return tok
      end
    end
  end
end

require "asmrepl/parser.tab"
