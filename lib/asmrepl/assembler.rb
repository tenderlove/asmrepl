module ASMREPL
  class Assembler
    def assemble ast
      fisk = Fisk.new

      case ast
      in [:command, [:instruction, insn], [:register, r], [:int, n]]
        fisk.gen_with_insn insn, [r, fisk.imm(n)]
      in [:command, [:instruction, insn], [:register, r], [:register, r2]]
        fisk.gen_with_insn insn, [r, r2]
      in [:command, [:instruction, insn], [:register, r], [:memory, mem]]
        fisk.gen_with_insn insn, [r, mem]
      else
      end

      fisk.to_binary
    end
  end
end
