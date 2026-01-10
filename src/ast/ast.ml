type ty =
  | I8 | I16 | I32 | I64
  | U8 | U16 | U32 | U64
  | F32 | F64
  | Str | Char | BoolTy
  | Unit
  | StructType of (string * ty) list  (* field name and type *)
  | EnumType of (string * ty list) list  (* variant name and parameter types *)
  | OptionalType of ty
  | ListType of ty
  | MapType of ty * ty  (* key type, value type *)

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

  | Match of expr * (pattern * expr) list
  | Block of stmt list * expr option
  | Cast of expr * ty
  | FieldAccess of expr * string
  | Throw of expr

and pattern =
  | PVar of string
  | PLiteral of literal
  | PWild

and stmt =
  | Let of bool * string * ty option * expr  (* mut, name, ty, expr *)
  | Assign of string * expr
  | ExprStmt of expr
  | If of expr * stmt list * stmt list option
  | While of expr * stmt list
  | For of string * expr * stmt list
  | Const of string * ty * expr
  | StructDef of string * (string * ty) list
  | EnumDef of string * (string * ty list) list
  | Return of expr option

type func =
  { name : string
  ; params : (string * ty) list
  ; ret_ty : ty
  ; body : stmt list
  }

type program = func list