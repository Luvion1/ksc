(* open Llvm *)
open Ast

module StringMap = Map.Make(String)

(* let context = global_context ()
let the_module = create_module context "ksharp"
let builder = builder context *)

let ty_to_llvm = function
  | I32 -> failwith "LLVM not available"
  | I64 -> failwith "LLVM not available"
  | F32 -> failwith "LLVM not available"
  | F64 -> failwith "LLVM not available"
  | BoolTy -> failwith "LLVM not available"
  | Str -> failwith "LLVM not available"
  | Unit -> failwith "LLVM not available"
  | _ -> failwith "Unsupported type in codegen"

let emit_expr _env _expr =
  failwith "Codegen not implemented for expr"

let rec emit_stmt _ll_func _env _stmt =
  failwith "Codegen not implemented for stmt"

and emit_stmts ll_func env stmts =
  List.fold_left (emit_stmt ll_func) env stmts

let emit_func _func =
  failwith "Codegen not implemented for func"

let emit_program _program =
  failwith "Codegen not implemented"