class ASMREPL::Parser
  token on_ident on_lbracket on_rbracket on_int on_comma qword ptr word dword byte
  token plus minus

rule

  command: ident ident on_comma int { result = new_command(val[0], val[1], val[3]) }
         | ident ident on_comma ident { result = new_command(val[0], val[1], val[3]) }
         | ident ident on_comma memory { result = new_command(val[0], val[1], val[3]) }
         ;

  ident: on_ident { result = register_or_insn(val[0]) }
       ;
  int: on_int     { result = [:int, Integer(val[0])] }
     ;

  memory: on_lbracket ident on_rbracket { result = [:memory, Fisk::M64.new(val[1].last, 0)] }
        | on_lbracket ident plus on_int on_rbracket { result = [:memory, Fisk::M64.new(val[1].last, Integer(val[3]))] }
        | on_lbracket ident minus on_int on_rbracket { result = [:memory, Fisk::M64.new(val[1].last, -Integer(val[3]))] }
        | memsize on_lbracket ident on_rbracket { result = [:memory, val[0].new(val[2].last, 0)] }
        | memsize on_lbracket ident plus on_int on_rbracket { result = [:memory, val[0].new(val[2].last, Integer(val[4]))] }
        | memsize on_lbracket ident minus on_int on_rbracket { result = [:memory, val[0].new(val[2].last, -Integer(val[4]))] }
        ;

  memsize: qword ptr { result = Fisk::M64 }
         | dword ptr { result = Fisk::M32 }
         | word ptr { result = Fisk::M16 }
         | byte ptr { result = Fisk::M8 }
         ;
end
