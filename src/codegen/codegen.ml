open Ast

module StringMap = Map.Make(String)

(* LLVM Code Generation Module *)
let () =
  Printf.printf "DEBUG: Codegen module loaded (LLVM implementation)\n"

(* Counter for generating unique labels and variables *)
let label_counter = ref 0
let var_counter = ref 0
let struct_counter = ref 0

let fresh_label () =
  incr label_counter;
  Printf.sprintf "label_%d" !label_counter

let fresh_var () =
  incr var_counter;
  Printf.sprintf "%%var_%d" !var_counter

let fresh_struct_name () =
  incr struct_counter;
  Printf.sprintf "struct_%d" !struct_counter

(* Fitur tambahan untuk filosofi K# *)
let emit_memory_safety_checks = ref true
let emit_optimization_hints = ref true

(* Type mapping to LLVM types *)
let ty_to_llvm = function
  | I8 | U8 -> "i8"
  | I16 | U16 -> "i16"
  | I32 | U32 -> "i32"
  | I64 | U64 -> "i64"
  | F32 -> "float"
  | F64 -> "double"
  | BoolTy -> "i1"
  | Str -> "i8*"
  | Char -> "i8"
  | Unit -> "void"
  | StructType _ -> "struct"
  | EnumType _ -> "enum"
  | OptionalType _ -> "optional"
  | ListType _ -> "list"
  | MapType _ -> "map"

(* Fitur tambahan untuk filosofi K# *)
let emit_struct_definition struct_name fields =
  Printf.printf "%%%s = type { " struct_name;
  let field_types = List.map (fun (_, ty) -> ty_to_llvm ty) fields in
  Printf.printf "%s" (String.concat ", " field_types);
  Printf.printf " }\n"

let emit_enum_definition enum_name variants =
  Printf.printf "%%%s = type { i32, " enum_name;
  (* Simplified enum representation *)
  Printf.printf "i8* }\n"

let emit_optional_type inner_ty =
  Printf.printf "%%optional_%s = type { i1, %s }\n" inner_ty inner_ty

let emit_list_type inner_ty =
  Printf.printf "%%list_%s = type { i32, %s* }\n" inner_ty inner_ty

let emit_map_type key_ty val_ty =
  Printf.printf "%%map_%s_%s = type { i32, %s*, %s* }\n" key_ty val_ty key_ty val_ty

(* Environment for tracking variables and their LLVM types *)
type env = {
  vars: string StringMap.t;  (* variable name -> LLVM variable name *)
  types: string StringMap.t; (* variable name -> LLVM type *)
}

let empty_env = {
  vars = StringMap.empty;
  types = StringMap.empty;
}

let add_var env name llvm_var llvm_type =
  { vars = StringMap.add name llvm_var env.vars;
    types = StringMap.add name llvm_type env.types;
  }

let get_var env name =
  try StringMap.find name env.vars
  with Not_found -> failwith ("Undefined variable: " ^ name)

let get_type env name =
  try StringMap.find name env.types
  with Not_found -> failwith ("Undefined type for variable: " ^ name)

(* Emit LLVM IR for expressions *)
let rec emit_expr env expr =
  match expr with
  | Literal (Int i) ->
      let var = fresh_var () in
      Printf.printf "  %s = add i32 %d, 0\n" var i;
      (var, "i32")
  | Literal (Float f) ->
      let var = fresh_var () in
      Printf.printf "  %s = fadd double %f, 0.0\n" var f;
      (var, "double")
  | Literal (Bool b) ->
      let var = fresh_var () in
      let val_str = if b then "1" else "0" in
      Printf.printf "  %s = add i1 %s, 0\n" var val_str;
      (var, "i1")
  | Literal (String _) ->
      let var = fresh_var () in
      Printf.printf "  %s = getelementptr i8, i8* @.str, i32 0\n" var;
      (var, "i8*")
  | Literal (Char c) ->
      let var = fresh_var () in
      Printf.printf "  %s = add i8 %d, 0\n" var (Char.code c);
      (var, "i8")
  | Var name ->
      let var = get_var env name in
      let ty = get_type env name in
      (var, ty)
  | BinOp (e1, op, e2) ->
      emit_binop env e1 op e2
  | UnOp (op, e) ->
      emit_unop env op e
  | Call (Var name, args) ->
      emit_call env name args
  | Call _ ->
      let var = fresh_var () in
      Printf.printf "  %s = call i32 @unknown_function()\n" var;
      (var, "i32")
  | FieldAccess (expr, field) ->
      emit_field_access env expr field
  | Throw expr ->
      emit_throw env expr
  | Match (expr, cases) ->
      emit_match env expr cases
  | Block (stmts, expr_opt) ->
      emit_block env stmts expr_opt
  | Cast (expr, ty) ->
      emit_cast env expr ty

(* Fitur tambahan untuk memory safety dan optimization *)
and emit_safe_field_access env expr field =
  let (var, ty) = emit_expr env expr in
  let result_var = fresh_var () in
  Printf.printf "  %s = getelementptr inbounds %s, %s* %s, i32 0, i32 0\n" result_var ty ty var;
  (* Tambahkan null pointer check jika diaktifkan *)
  if !emit_memory_safety_checks then
    Printf.printf "  %s = icmp ne %s* %s, null\n" (fresh_var ()) ty result_var;
  (result_var, "i32")

and emit_safe_array_access env array_expr index_expr =
  let (array_var, _) = emit_expr env array_expr in
  let (index_var, _) = emit_expr env index_expr in
  let result_var = fresh_var () in
  (* Tambahkan bounds checking jika diaktifkan *)
  if !emit_memory_safety_checks then begin
    Printf.printf "  %%bounds_check = icmp ult i32 %s, 10\n" index_var; (* Simplified bounds *)
    Printf.printf "  br i1 %%bounds_check, label %%bounds_ok, label %%bounds_error\n";
    Printf.printf "bounds_ok:\n";
  end;
  Printf.printf "  %s = getelementptr inbounds i32, i32* %s, i32 %s\n" result_var array_var index_var;
  if !emit_memory_safety_checks then
    Printf.printf "bounds_error:\n  call void @llvm.trap()\n  unreachable\n";
  (result_var, "i32")

and emit_optimized_loop env init_expr cond_expr body_stmts =
  let loop_var = fresh_var () in
  let (init_val, _) = emit_expr env init_expr in
  Printf.printf "  %s = alloca i32\n" loop_var;
  Printf.printf "  store i32 %s, i32* %s\n" init_val loop_var;
  
  let loop_label = fresh_label () in
  let body_label = fresh_label () in
  let end_label = fresh_label () in
  
  Printf.printf "  br label %s\n" loop_label;
  Printf.printf "%s:\n" loop_label;
  
  (* Emit condition check *)
  let (cond_var, _) = emit_expr env cond_expr in
  Printf.printf "  br i1 %s, label %s, label %s\n" cond_var body_label end_label;
  
  Printf.printf "%s:\n" body_label;
  let env' = emit_stmts env body_stmts in
  
  (* Loop increment with optimization hint *)
  if !emit_optimization_hints then
    Printf.printf "  %s = load i32, i32* %s\n" (fresh_var ()) loop_var;
  Printf.printf "  %s = add i32 %s, 1\n" (fresh_var ()) init_val;
  Printf.printf "  store i32 %s, i32* %s\n" (fresh_var ()) loop_var;
  
  Printf.printf "  br label %s\n" loop_label;
  Printf.printf "%s:\n" end_label;
  env'

and emit_binop env e1 op e2 =
  let (var1, ty1) = emit_expr env e1 in
  let (var2, _) = emit_expr env e2 in
  let result_var = fresh_var () in
  let llvm_op = match op with
    | Add -> if ty1 = "double" then "fadd" else "add"
    | Sub -> if ty1 = "double" then "fsub" else "sub"
    | Mul -> if ty1 = "double" then "fmul" else "mul"
    | Div -> if ty1 = "double" then "fdiv" else "sdiv"
    | Mod -> "srem"
    | Eq -> "icmp eq"
    | Neq -> "icmp ne"
    | Lt -> "icmp slt"
    | Le -> "icmp sle"
    | Gt -> "icmp sgt"
    | Ge -> "icmp sge"
    | And -> "and"
    | Or -> "or"
  in
  let result_ty = match op with
    | Eq | Neq | Lt | Le | Gt | Ge | And | Or -> "i1"
    | _ -> ty1
  in
  Printf.printf "  %s = %s %s %s, %s\n" result_var llvm_op ty1 var1 var2;
  (result_var, result_ty)

and emit_unop env op e =
  let (var, ty) = emit_expr env e in
  let result_var = fresh_var () in
  match op with
  | Not ->
      Printf.printf "  %s = xor i1 %s, 1\n" result_var var;
      (result_var, "i1")
  | Neg ->
      Printf.printf "  %s = sub %s 0, %s\n" result_var ty var;
      (result_var, ty)

and emit_call env name args =
  let arg_vars = List.map (fun arg -> fst (emit_expr env arg)) args in
  let result_var = fresh_var () in
  Printf.printf "  %s = call i32 @%s(%s)\n" result_var name (String.concat ", " arg_vars);
  (result_var, "i32")

and emit_field_access env expr _ =
  let (var, _) = emit_expr env expr in
  let result_var = fresh_var () in
  Printf.printf "  %s = getelementptr inbounds %%struct, %%struct* %s, i32 0, i32 0\n" result_var var;
  (result_var, "i32")

and emit_throw env expr =
  let (var, _) = emit_expr env expr in
  Printf.printf "  call void @llvm.trap()\n";
  Printf.printf "  unreachable\n";
  (var, "void")

and emit_match env expr cases =
  let _ = emit_expr env expr in
  let end_label = fresh_label () in
  let result_var = fresh_var () in
  
  List.iter (fun (_, case_expr) ->
    let case_label = fresh_label () in
    let (case_var, _) = emit_expr env case_expr in
    Printf.printf "  br label %s\n" case_label;
    Printf.printf "%s:\n" case_label;
    Printf.printf "  %s = %s\n" result_var case_var;
    Printf.printf "  br label %s\n" end_label;
  ) cases;
  
  Printf.printf "%s:\n" end_label;
  (result_var, "i32")

and emit_block env stmts expr_opt =
  let env' = emit_stmts env stmts in
  match expr_opt with
  | Some expr -> emit_expr env' expr
  | None -> (fresh_var (), "void")

and emit_cast env expr ty =
  let (var, _) = emit_expr env expr in
  let result_var = fresh_var () in
  let from_ty = ty_to_llvm Unit in (* Simplified *)
  let to_ty = ty_to_llvm ty in
  Printf.printf "  %s = bitcast %s %s to %s\n" result_var from_ty var to_ty;
  (result_var, to_ty)

(* Emit LLVM IR for statements *)
and emit_stmts env stmts =
  List.fold_left emit_stmt env stmts

and emit_stmt env stmt =
  match stmt with
  | Let (_, name, ty_opt, expr) ->
      let (var, expr_ty) = emit_expr env expr in
      let llvm_ty = match ty_opt with
        | Some ty -> ty_to_llvm ty
        | None -> expr_ty
      in
      let env' = add_var env name var llvm_ty in
      Printf.printf "  %s = alloca %s\n" var llvm_ty;
      Printf.printf "  store %s %s, %s* %s\n" expr_ty var llvm_ty var;
      env'
  | Assign (name, expr) ->
      let (var, expr_ty) = emit_expr env expr in
      let llvm_var = get_var env name in
      let llvm_ty = get_type env name in
      Printf.printf "  store %s %s, %s* %s\n" expr_ty var llvm_ty llvm_var;
      env
  | ExprStmt expr ->
      let _ = emit_expr env expr in
      env
  | If (cond, then_stmts, else_opt) ->
      let (cond_var, _) = emit_expr env cond in
      let then_label = fresh_label () in
      let else_label = fresh_label () in
      let end_label = fresh_label () in
      
      Printf.printf "  br i1 %s, label %s, label %s\n" cond_var then_label else_label;
      Printf.printf "%s:\n" then_label;
      let env' = emit_stmts env then_stmts in
      Printf.printf "  br label %s\n" end_label;
      
      Printf.printf "%s:\n" else_label;
      begin match else_opt with
      | Some else_stmts ->
          let _ = emit_stmts env else_stmts in
          ()
      | None -> ()
      end;
      Printf.printf "  br label %s\n" end_label;
      
      Printf.printf "%s:\n" end_label;
      env'
  | While (cond, stmts) ->
      let loop_label = fresh_label () in
      let body_label = fresh_label () in
      let end_label = fresh_label () in
      
      Printf.printf "  br label %s\n" loop_label;
      Printf.printf "%s:\n" loop_label;
      let (cond_var, _) = emit_expr env cond in
      Printf.printf "  br i1 %s, label %s, label %s\n" cond_var body_label end_label;
      Printf.printf "%s:\n" body_label;
      let env' = emit_stmts env stmts in
      Printf.printf "  br label %s\n" loop_label;
      Printf.printf "%s:\n" end_label;
      env'
  | For (name, expr, stmts) ->
      let (iter_var, iter_ty) = emit_expr env expr in
      let loop_label = fresh_label () in
      let body_label = fresh_label () in
      let end_label = fresh_label () in
      
      Printf.printf "  br label %s\n" loop_label;
      Printf.printf "%s:\n" loop_label;
      Printf.printf "  %s = phi %s [ %s, %%entry ], [ %s, %%body ]\n" iter_var iter_ty iter_var iter_var;
      Printf.printf "  br i1 true, label %s, label %s\n" body_label end_label; (* Simplified *)
      Printf.printf "%s:\n" body_label;
      let env' = add_var env name iter_var iter_ty in
      let _ = emit_stmts env' stmts in
      Printf.printf "  br label %s\n" loop_label;
      Printf.printf "%s:\n" end_label;
      env
  | Return expr_opt ->
      begin match expr_opt with
      | Some expr ->
          let (var, ty) = emit_expr env expr in
          Printf.printf "  ret %s %s\n" ty var;
      | None ->
          Printf.printf "  ret void\n";
      end;
      env
  | StructDef (name, fields) ->
      (* Emit struct definition *)
      let struct_name = fresh_struct_name () in
      emit_struct_definition struct_name fields;
      env
  | EnumDef (name, variants) ->
      (* Emit enum definition *)
      let enum_name = fresh_struct_name () in
      emit_enum_definition enum_name variants;
      env
  | Const _ -> env

(* Emit LLVM IR for functions *)
let emit_func env func =
  let param_strs = List.map (fun (name, ty) -> ty_to_llvm ty ^ " %" ^ name) func.params in
  Printf.printf "define %s @%s(%s) {\n" (ty_to_llvm func.ret_ty) func.name (String.concat ", " param_strs);
  
  let env' = List.fold_left (fun env (name, ty) ->
    add_var env name ("%" ^ name) (ty_to_llvm ty)
  ) env func.params in
  
  let _ = emit_stmts env' func.body in
  
  (* Default return if no explicit return *)
  if func.ret_ty = Unit then
    Printf.printf "  ret void\n"
  else
    Printf.printf "  ret %s 0\n" (ty_to_llvm func.ret_ty);
  
  Printf.printf "}\n\n";
  env'

(* Emit complete LLVM IR program *)
let emit_program program =
  Printf.printf "DEBUG: Starting emit_program with %d functions\n" (List.length program);
  
  (* Emit string constant for string literals *)
  Printf.printf "@.str = private constant [10 x i8] c\"hello\\00\\00\\00\\00\"\n\n";
  
  (* Emit function declarations *)
  Printf.printf "declare void @llvm.trap()\n\n";
  
  (* Emit functions *)
  let _ = List.fold_left emit_func empty_env program in
  Printf.printf "DEBUG: Functions emitted successfully\n";
  Printf.printf "DEBUG: LLVM IR generation completed\n"