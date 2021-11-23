require "helper"

class ParserTest < ASMREPL::Test
  def setup
    super
    @parser    = ASMREPL::Parser.new
    @assembler = ASMREPL::Assembler.new
  end

  def test_simple
    assert_round_trip "mov rax, 0xff"
    assert_round_trip "mov r8, 0xff"
  end

  def test_2_regs
    assert_round_trip "mov r8, rax"
  end

  def test_memory_offset
    assert_round_trip "mov r8, qword ptr [rax + 0x7b]"
    assert_round_trip "mov r8, qword ptr [rax - 0x7b]"
  end

  def test_memory_defaults_64_offset
    asm = disasm_for "mov rax, [rax + 0x7b]"
    assert_equal "mov rax, qword ptr [rax + 0x7b]", asm

    asm = disasm_for "mov rax, [rax - 0x7b]"
    assert_equal "mov rax, qword ptr [rax - 0x7b]", asm
  end

  def test_memory_defaults_64
    asm = disasm_for "mov rax, [rax]"
    assert_equal "mov rax, qword ptr [rax]", asm
  end

  def test_memory_specify_width
    assert_round_trip "mov r8, qword ptr [rax]"
    assert_round_trip "mov r8d, dword ptr [r8]"
    assert_round_trip "mov r8w, word ptr [r8]"
    assert_round_trip "mov r8b, byte ptr [r8]"
  end

  def assert_round_trip asm
    ast = @parser.parse asm
    binary = @assembler.assemble ast
    assert_equal asm, disasm(binary)
  end

  def disasm_for asm
    ast = @parser.parse asm
    binary = @assembler.assemble ast
    disasm(binary)
  end

  def disasm binary
    cs = Crabstone::Disassembler.new(Crabstone::ARCH_X86, Crabstone::MODE_64)
    cs.disasm(binary, 0x0000).each {|i|
      return "%s %s" % [i.mnemonic, i.op_str]
    }
  end
end
