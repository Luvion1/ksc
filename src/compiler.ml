let compile filename =
  let ic = open_in filename in
  let lexbuf = Lexing.from_channel ic in
  try
    let ast = Parser.program Lexer.token lexbuf in
    close_in ic;
    Semantic.check_program ast;
    Codegen.emit_program ast;
    ast
  with
  | Lexer.Error msg ->
      close_in ic;
      failwith ("Lexer error: " ^ msg)
  | Parser.Error ->
      close_in ic;
      let pos = lexbuf.Lexing.lex_curr_p in
      failwith (Printf.sprintf "Parse error at line %d, column %d" pos.Lexing.pos_lnum pos.Lexing.pos_cnum)