module ASMREPL
  class Assembler
    def assemble ast
      fisk = Fisk.new

      case ast
      in [:command, [:instruction, insn], [:register, r], [:int, n]]
        possibles = insn.forms.find_all do |form|
          form.operands.first.type == r.type
        end
        l = if possibles.any? { |form| form.operands[1].type == n.to_s }
          fisk.lit(n)
        else
          fisk.imm(n)
        end
        fisk.gen_with_insn insn, [r, l]
      in [:command, [:instruction, insn], [:register, r], [:register, r2]]
        fisk.gen_with_insn insn, [r, r2]
      in [:command, [:instruction, insn], [:register, r], [:memory, mem]]
        fisk.gen_with_insn insn, [r, mem]
      in [:command, [:instruction, insn], [:int, n]]
        fisk.gen_with_insn insn, [fisk.imm(n)]
      else
      end

      fisk.to_binary
    end
  end
end
