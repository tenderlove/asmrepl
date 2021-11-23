require "racc/parser"
require "ripper"
require "fisk"
require "set"

module ASMREPL

  class Parser < Racc::Parser
    def initialize
      @registers = Set.new Fisk::Registers.constants.map(&:to_s)
      @instructions = Set.new Fisk::Instructions.constants.map(&:to_s)
    end

    def parse input
      @tokens = Ripper.lex input
      do_parse
    end

    def register_or_insn str
      if @instructions.include? str.upcase
        [:instruction, str]
      else
        [:register, str]
      end
    end

    def new_command mnemonic, arg1, arg2
      [:command, mnemonic, arg1, arg2]
    end

    def next_token
      while tok = @tokens.shift
        next if tok[1] == :on_sp
        m = tok && [tok[1], tok[2]]
        return m
      end
    end
  end
end

require "asmrepl/parser.tab"
