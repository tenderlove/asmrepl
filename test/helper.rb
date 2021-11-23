require "asmrepl"
require "minitest"
require "minitest/autorun"
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
  class Test < Minitest::Test
  end
end
