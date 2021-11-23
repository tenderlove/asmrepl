class ASMREPL::Parser
  token on_lbracket on_rbracket on_int on_comma qword ptr word dword byte
  token plus minus on_instruction on_register on_rip

rule

  command: instruction register on_comma int { result = new_command(val[0], val[1], val[3]) }
         | instruction register on_comma register { result = new_command(val[0], val[1], val[3]) }
         | instruction register on_comma memory { result = new_command(val[0], val[1], val[3]) }
         | instruction memory on_comma register { result = new_command(val[0], val[1], val[3]) }
         | instruction memory on_comma int { result = new_command(val[0], val[1], val[3]) }
         | instruction register { result = new_tuple(val[0], val[1]) }
         | instruction memory { result = new_tuple(val[0], val[1]) }
         | instruction int { result = new_tuple(val[0], val[1]) }
         | instruction { result = new_single(val[0]) }
         ;

  instruction: on_instruction { result = [:instruction, val[0]] }
             ;

  register: on_register { result = [:register, val[0]] }
          ;

  int: on_int     { result = [:int, Integer(val[0])] }
     | plus on_int { result = [:int, Integer(val[1])] }
     | minus on_int { result = [:int, -Integer(val[1])] }
     ;

  memory: on_lbracket register on_rbracket { result = [:memory, Fisk::M64.new(val[1].last, 0)] }
        | on_lbracket on_rip on_rbracket { result = [:memory, Fisk::Registers::Rip.new(0)] }
        | on_lbracket on_rip int on_rbracket { result = [:memory, Fisk::Registers::Rip.new(val[2].last)] }
        | on_lbracket register int on_rbracket { result = [:memory, Fisk::M64.new(val[1].last, val[2].last)] }
        | memsize on_lbracket register on_rbracket { result = [:memory, val[0].new(val[2].last, 0)] }
        | memsize on_lbracket register int on_rbracket { result = [:memory, val[0].new(val[2].last, val[3].last)] }
        ;

  memsize: qword ptr { result = Fisk::M64 }
         | dword ptr { result = Fisk::M32 }
         | word ptr { result = Fisk::M16 }
         | byte ptr { result = Fisk::M8 }
         ;
end
