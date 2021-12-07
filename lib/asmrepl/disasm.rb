require "crabstone"

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
  module Disasm
    def self.disasm buffer
      binary = buffer.memory[0, buffer.pos]
      cs = Crabstone::Disassembler.new(Crabstone::ARCH_X86, Crabstone::MODE_64)
      cs.disasm(binary, buffer.memory.to_i).each {|i|
        puts "%s %s" % [i.mnemonic, i.op_str]
      }
    end
  end
end
