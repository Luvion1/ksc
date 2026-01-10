let test_simple () =
  let code = "fn main() { let x = 5; }" in
  try
    let lexbuf = Lexing.from_string code in
    let ast = Parser.program Lexer.token lexbuf in
    print_endline "Simple test passed"
  with _ -> print_endline "Simple test failed"

let test_if () =
  let code = "fn main() { if true { let x = 1; } else { let x = 2; } }" in
  try
    let lexbuf = Lexing.from_string code in
    let ast = Parser.program Lexer.token lexbuf in
    print_endline "If test passed"
  with _ -> print_endline "If test failed"

let () =
  test_simple ();
  test_if ()