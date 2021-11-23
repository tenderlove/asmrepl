class ASMREPL::Parser
  token on_ident on_lbracket on_rbracket on_int on_comma

rule

  command: ident ident on_comma int { result = new_command(val[0], val[1], val[3]) }

  ident: on_ident { result = register_or_insn(val[0]) }
  int: on_int     { result = [:int, Integer(val[0])] }
end
