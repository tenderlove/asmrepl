module ASMREPL
  class Assembler
    def assemble ast
      fisk = Fisk.new

      case ast
      in [:command, [:instruction, m], [:register, r], [:int, n]]
        insn = Fisk::Instructions.const_get(m.upcase)
        reg = Fisk::Registers.const_get(r.upcase)
        fisk.gen_with_insn insn, [reg, fisk.imm(n)]
      else
      end

      fisk.to_binary
    end
  end
end
