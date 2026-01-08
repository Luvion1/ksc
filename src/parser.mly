%{
  open Ast
%}

%token <int> INT
%token <float> FLOAT
%token <string> STRING IDENT
%token <char> CHAR_LIT
%token PUB FN LET MUT CONST IF ELSE MATCH FOR WHILE RETURN TRUE FALSE NIL IN UNIT
%token I8 I16 I32 I64 U8 U16 U32 U64 F32 F64 STR CHAR BOOL ENUM TYPE STRUCT EXT
%token OR AND EQ NEQ LE GE LT GT PLUS MINUS STAR SLASH PERCENT BANG ASSIGN DOTDOT DOT COMMA COLON DOUBLECOLON SEMI LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK PIPE UNDERSCORE EOF

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
  PUB? FN name = IDENT LPAREN params = separated_list(COMMA, param) RPAREN COLON ret_ty = ty LBRACE body = list(stmt) RBRACE
    { { name; params; ret_ty; body } }

param:
  name = IDENT COLON ty = ty { (name, ty) }

ty:
  | I8 { I8 } | I16 { I16 } | I32 { I32 } | I64 { I64 }
  | U8 { U8 } | U16 { U16 } | U32 { U32 } | U64 { U64 }
  | F32 { F32 } | F64 { F64 } | STR { Str } | CHAR { Char } | BOOL { BoolTy } | UNIT { Unit }

stmt:
  | LET MUT? name = IDENT COLON ty = ty ASSIGN expr = expr SEMI { Let (Option.is_some $2, name, Some ty, expr) }
  | LET MUT? name = IDENT ASSIGN expr = expr SEMI { Let (Option.is_some $2, name, None, expr) }
  | name = IDENT ASSIGN expr = expr SEMI { Assign (name, expr) }
  | WHILE expr = expr LBRACE stmts = list(stmt) RBRACE { While (expr, stmts) }
  | FOR name = IDENT IN expr = expr LBRACE stmts = list(stmt) RBRACE { For (name, expr, stmts) }
  | expr = expr SEMI { ExprStmt expr }

expr:
  | literal = literal { Literal literal }
  | id = IDENT { Var id }
  | LPAREN expr = expr RPAREN { expr }
  | expr1 = expr binop = binop expr2 = expr { BinOp (expr1, binop, expr2) }
  | unop = unop expr = expr { UnOp (unop, expr) }
  | id = IDENT LPAREN args = separated_list(COMMA, expr) RPAREN { Call (Var id, args) }
  | IF cond = expr LBRACE then_ = list(stmt) RBRACE ELSE LBRACE else_ = list(stmt) RBRACE { If (cond, then_, Some else_) }
  | IF cond = expr LBRACE then_ = list(stmt) RBRACE { If (cond, then_, None) }
  | MATCH expr = expr LBRACE cases = separated_list(COMMA, case) RBRACE { Match (expr, cases) }
  | LBRACE stmts = list(stmt) expr = option(expr) RBRACE { Block (stmts, expr) }

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