{
  open Parser
  exception Error of string
}

let digit = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z' '_']
let ident = alpha (alpha | digit)*

rule token = parse
  | [' ' '\t' '\n']+ { token lexbuf }
  | "//" [^'\n']* '\n' { token lexbuf }
  | "/*" { comment lexbuf }
  | "pub" { PUB }
  | "fn" { FN }
  | "let" { LET }
  | "mut" { MUT }
  | "const" { CONST }
  | "if" { IF }
  | "else" { ELSE }
  | "match" { MATCH }
  | "for" { FOR }
  | "while" { WHILE }
  | "return" { RETURN }
  | "true" { TRUE }
  | "false" { FALSE }
  | "nil" { NIL }
  | "i8" { I8 }
  | "i16" { I16 }
  | "i32" { I32 }
  | "i64" { I64 }
  | "u8" { U8 }
  | "u16" { U16 }
  | "u32" { U32 }
  | "u64" { U64 }
  | "f32" { F32 }
  | "f64" { F64 }
  | "str" { STR }
  | "char" { CHAR }
  | "bool" { BOOL }
  | "unit" { UNIT }
  | "enum" { ENUM }
  | "type" { TYPE }
  | "struct" { STRUCT }
  | "Map" { MAP }
  | "ext" { EXT }
  | "in" { IN }
  | "throw" { THROW }
  | "||" { OR }
  | "&&" { AND }
  | "==" { EQ }
  | "!=" { NEQ }
  | "<=" { LE }
  | ">=" { GE }
  | "<" { LT }
  | ">" { GT }
  | "+" { PLUS }
  | "-" { MINUS }
  | "*" { STAR }
  | "/" { SLASH }
  | "%" { PERCENT }
  | "!" { BANG }
  | "=" { ASSIGN }
  | ".." { DOTDOT }
  | "." { DOT }
  | "," { COMMA }
  | ":" { COLON }
  | "::" { DOUBLECOLON }
  | ";" { SEMI }
  | "(" { LPAREN }
  | ")" { RPAREN }
  | "{" { LBRACE }
  | "}" { RBRACE }
  | "[" { LBRACK }
  | "]" { RBRACK }
  | "|" { PIPE }
  | "_" { UNDERSCORE }
  | "?" { QUESTION }
  | "\"" { string_literal lexbuf }
  | "'" { char_literal lexbuf }
  | digit+ as i { INT (int_of_string i) }
  | digit+ "." digit+ as f { FLOAT (float_of_string f) }
  | ident as id { IDENT id }
  | eof { EOF }
  | _ { raise (Error ("Unexpected character: " ^ Lexing.lexeme lexbuf)) }

and comment = parse
  | "*/" { token lexbuf }
  | _ { comment lexbuf }

and string_literal = parse
  | "\"" { STRING (Lexing.lexeme lexbuf) }  (* TODO: proper string *)
  | _ { string_literal lexbuf }

and char_literal = parse
  | _ "'" { CHAR_LIT (Lexing.lexeme_char lexbuf 0) }  (* simple *)
  | _ { char_literal lexbuf }