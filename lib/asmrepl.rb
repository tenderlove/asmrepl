require "fiddle"

module Fiddle
  unless Fiddle.const_defined?(:SIZEOF_INT64_T)
    SIZEOF_INT64_T = Fiddle::SIZEOF_UINTPTR_T
  end
end

require "asmrepl/parser"
require "asmrepl/assembler"
require "asmrepl/repl"
