require "helper"

class ParserTest < ASMREPL::Test
  def setup
    super
    @parser    = ASMREPL::Parser.new
    @assembler = ASMREPL::Assembler.new
  end

  def test_int3
    assert_round_trip "int3 "
  end

  def test_and
    assert_round_trip "and r9, 0xffff"
  end

  def test_negative
    assert_round_trip "test qword ptr [r15], -9"
  end

  def test_mem_lhs
    asm = disasm_for "mov [r15], r9"
    assert_equal "mov qword ptr [r15], r9", asm
    assert_round_trip "mov qword ptr [r15], r9"
  end

  def test_inc
    assert_round_trip "inc r10"
    assert_round_trip "inc qword ptr [r10]"
    assert_round_trip "inc qword ptr [r10 + 8]"
  end

  def test_movabs
    assert_round_trip "movabs r10, 0x6000014b1ae0"
  end

  def test_ret
    assert_round_trip "ret "
  end

  def test_lea_rip
    assert_round_trip "lea rax, [rip]"
    assert_round_trip "lea rax, [rip + 9]"
  end

  def test_push_reg
    assert_round_trip "push r13"
  end

  def test_int_4
    assert_round_trip "int 4"
  end

  def test_shl_1
    assert_round_trip "shl rax, 1"
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
