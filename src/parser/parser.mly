%{
  open Ast
%}

%token <int> INT
%token <float> FLOAT
%token <string> STRING IDENT
%token <char> CHAR_LIT
%token PUB FN LET MUT CONST IF ELSE MATCH FOR WHILE RETURN TRUE FALSE NIL IN UNIT THROW
%token I8 I16 I32 I64 U8 U16 U32 U64 F32 F64 STR CHAR BOOL ENUM TYPE STRUCT MAP EXT
%token OR AND EQ NEQ LE GE LT GT PLUS MINUS STAR SLASH PERCENT BANG ASSIGN DOTDOT DOT COMMA COLON DOUBLECOLON SEMI LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK PIPE UNDERSCORE QUESTION EOF

%nonassoc below_SEMI
%nonassoc SEMI
%right ASSIGN
%left OR
%left AND
%left EQ NEQ
%left LT LE GT GE
%left PLUS MINUS
%left STAR SLASH PERCENT
%right BANG
%left DOT

%start <Ast.program> program

%%

program:
  funcs = list(func) EOF { funcs }

func:
  PUB? FN name = IDENT LPAREN params = separated_list(COMMA, param) RPAREN ret_ty_opt = option(preceded(COLON, ty)) LBRACE body = list(stmt) RBRACE
    { let ret_ty = match ret_ty_opt with Some t -> t | None -> Unit in { name; params; ret_ty; body } }

param:
  name = IDENT COLON ty = ty { (name, ty) }

field:
  name = IDENT COLON ty = ty { (name, ty) }

variant:
  | name = IDENT { (name, []) }
  | name = IDENT LPAREN tys = separated_list(COMMA, ty) RPAREN { (name, tys) }

ty:
  | I8 { I8 } | I16 { I16 } | I32 { I32 } | I64 { I64 }
  | U8 { U8 } | U16 { U16 } | U32 { U32 } | U64 { U64 }
  | F32 { F32 } | F64 { F64 } | STR { Str } | CHAR { Char } | BOOL { BoolTy } | UNIT { Unit }
  | ty QUESTION { OptionalType $1 }
  | LBRACK ty RBRACK { ListType $2 }
  | MAP LPAREN ty COMMA ty RPAREN { MapType ($3, $5) }

stmt:
  | LET MUT? name = IDENT COLON ty = ty ASSIGN expr = expr SEMI { Let (Option.is_some $2, name, Some ty, expr) }
  | LET MUT? name = IDENT ASSIGN expr = expr SEMI { Let (Option.is_some $2, name, None, expr) }
  | name = IDENT ASSIGN expr = expr SEMI { Assign (name, expr) }
  | IF expr = expr LBRACE then_stmts = list(stmt) RBRACE else_opt = option(else_clause) { If (expr, then_stmts, else_opt) }
  | WHILE expr = expr LBRACE stmts = list(stmt) RBRACE { While (expr, stmts) }
  | FOR name = IDENT IN expr = expr LBRACE stmts = list(stmt) RBRACE { For (name, expr, stmts) }
  | CONST name = IDENT COLON ty = ty ASSIGN expr = expr SEMI { Const (name, ty, expr) }
  | TYPE name = IDENT STRUCT LBRACE fields = separated_list(SEMI, field) RBRACE { StructDef (name, fields) }
  | ENUM name = IDENT LBRACE variants = separated_list(SEMI, variant) RBRACE { EnumDef (name, variants) }
  | expr = expr SEMI { ExprStmt expr }
  | RETURN expr = option(expr) SEMI { Return expr }

expr:
  | literal = literal { Literal literal }
  | id = IDENT { Var id }
  | LPAREN expr = expr RPAREN { expr }
  | expr1 = expr binop = binop expr2 = expr { BinOp (expr1, binop, expr2) }
  | unop = unop expr = expr { UnOp (unop, expr) }
  | id = IDENT LPAREN args = separated_list(COMMA, expr) RPAREN { Call (Var id, args) }

  | MATCH expr = expr LBRACE cases = separated_list(COMMA, case) RBRACE { Match (expr, cases) }
  | LBRACE stmts = list(stmt) expr = option(expr) RBRACE { Block (stmts, expr) }
  | expr = expr DOT field = IDENT { FieldAccess (expr, field) }
  | expr = expr DOT ty = ty LPAREN RPAREN { Cast (expr, ty) }
  | THROW expr = expr { Throw expr }

case:
  pat = pattern PIPE expr = expr { (pat, expr) }

pattern:
  | UNDERSCORE { PWild }
  | literal = literal { PLiteral literal }
  | id = IDENT { PVar id }

binop:
  | PLUS { Add } | MINUS { Sub } | STAR { Mul } | SLASH { Div } | PERCENT { Mod }
  | EQ { Eq } | NEQ { Neq } | LT { Lt } | LE { Le } | GT { Gt } | GE { Ge }
  | AND { And } | OR { Or }

unop:
  | BANG { Not } | MINUS { Neg }

literal:
  | INT { Int $1 } | FLOAT { Float $1 } | STRING { String $1 } | CHAR_LIT { Char $1 } | TRUE { Bool true } | FALSE { Bool false }

else_clause:
  | ELSE LBRACE stmts = list(stmt) RBRACE { stmts }