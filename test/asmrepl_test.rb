require "helper"

class ParserTest < ASMREPL::Test
  def setup
    super
    @parser    = ASMREPL::Parser.new
    @assembler = ASMREPL::Assembler.new
  end

  def test_simple
    assert_round_trip "mov rax, 0xff"
  end

  def assert_round_trip asm
    ast = @parser.parse asm
    binary = @assembler.assemble ast
    assert_equal asm, disasm(binary)
  end

  def disasm binary
    cs = Crabstone::Disassembler.new(Crabstone::ARCH_X86, Crabstone::MODE_64)
    cs.disasm(binary, 0x0000).each {|i|
      return "%s %s" % [i.mnemonic, i.op_str]
    }
  end
end
