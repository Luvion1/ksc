
(* The type of tokens. *)

type token = 
  | WHILE
  | UNIT
  | UNDERSCORE
  | U8
  | U64
  | U32
  | U16
  | TYPE
  | TRUE
  | STRUCT
  | STRING of (string)
  | STR
  | STAR
  | SLASH
  | SEMI
  | RPAREN
  | RETURN
  | RBRACK
  | RBRACE
  | PUB
  | PLUS
  | PIPE
  | PERCENT
  | OR
  | NIL
  | NEQ
  | MUT
  | MINUS
  | MATCH
  | LT
  | LPAREN
  | LET
  | LE
  | LBRACK
  | LBRACE
  | INT of (int)
  | IN
  | IF
  | IDENT of (string)
  | I8
  | I64
  | I32
  | I16
  | GT
  | GE
  | FOR
  | FN
  | FLOAT of (float)
  | FALSE
  | F64
  | F32
  | EXT
  | EQ
  | EOF
  | ENUM
  | ELSE
  | DOUBLECOLON
  | DOTDOT
  | DOT
  | CONST
  | COMMA
  | COLON
  | CHAR_LIT of (char)
  | CHAR
  | BOOL
  | BANG
  | ASSIGN
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.program)
