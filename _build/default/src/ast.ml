type ty =
  | I8 | I16 | I32 | I64
  | U8 | U16 | U32 | U64
  | F32 | F64
  | Str | Char | BoolTy
  | Unit

type binop =
  | Add | Sub | Mul | Div | Mod
  | Eq | Neq | Lt | Le | Gt | Ge
  | And | Or

type unop =
  | Not | Neg

type literal =
  | Int of int
  | Float of float
  | String of string
  | Char of char
  | Bool of bool

type expr =
  | Literal of literal
  | Var of string
  | BinOp of expr * binop * expr
  | UnOp of unop * expr
  | Call of expr * expr list
  | If of expr * stmt list * stmt list option
  | Match of expr * (pattern * expr) list
  | Block of stmt list * expr option

and pattern =
  | PVar of string
  | PLiteral of literal
  | PWild

and stmt =
  | Let of bool * string * ty option * expr  (* mut, name, ty, expr *)
  | Assign of string * expr
  | ExprStmt of expr
  | While of expr * stmt list
  | For of string * expr * stmt list

type func =
  { name : string
  ; params : (string * ty) list
  ; ret_ty : ty
  ; body : stmt list
  }

type program = func list