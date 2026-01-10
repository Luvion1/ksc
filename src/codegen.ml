open Llvm
open Llvm_target
open Llvm_all_backends
open Ast

module StringMap = Map.Make(String)

let () = initialize ()

let context = global_context ()
let the_module = create_module context "ksharp"
let builder = builder context

let ty_to_llvm = function
  | I32 -> i32_type context
  | I64 -> i64_type context
  | F32 -> float_type context
  | F64 -> double_type context
  | BoolTy -> i1_type context
  | Str -> pointer_type (i8_type context)  (* simple string *)
  | Unit -> void_type context
  | StructType fields -> struct_type context (Array.of_list (List.map (fun (_, ty) -> ty_to_llvm ty) fields))
   | EnumType _ -> failwith "Enum type not implemented"
   | OptionalType ty -> pointer_type (ty_to_llvm ty)
   | ListType ty -> pointer_type (ty_to_llvm ty)
   | MapType _ -> failwith "Map type not implemented"
   | _ -> failwith "Unsupported type in codegen"

let rec emit_expr env expr =
  match expr with
  | Literal (Int i) -> const_int (i32_type context) i
  | Literal (Float f) -> const_float (double_type context) f
  | Literal (Bool b) -> const_int (i1_type context) (if b then 1 else 0)
  | Literal (String s) -> build_global_stringptr s "str" builder
  | Literal (Char c) -> const_int (i32_type context) (Char.code c)
  | Var name ->
      begin try StringMap.find name env
      with Not_found -> failwith ("Undefined variable: " ^ name)
      end
  | BinOp (e1, op, e2) ->
      let v1 = emit_expr env e1 in
      let v2 = emit_expr env e2 in
      let ty = type_of v1 in
      if ty = double_type context then
        begin match op with
        | Add -> build_fadd v1 v2 "faddtmp" builder
        | Sub -> build_fsub v1 v2 "fsubtmp" builder
        | Mul -> build_fmul v1 v2 "fmultmp" builder
        | Div -> build_fdiv v1 v2 "fdivtmp" builder
        | Eq -> build_fcmp Fcmp.Oeq v1 v2 "feqtmp" builder
        | Neq -> build_fcmp Fcmp.One v1 v2 "fneqtmp" builder
        | Lt -> build_fcmp Fcmp.Olt v1 v2 "flttmp" builder
        | Le -> build_fcmp Fcmp.Ole v1 v2 "fletmp" builder
        | Gt -> build_fcmp Fcmp.Ogt v1 v2 "fgttmp" builder
        | Ge -> build_fcmp Fcmp.Oge v1 v2 "fgetmp" builder
        | _ -> failwith "Unsupported float binop in codegen"
        end
      else
        begin match op with
        | Add -> build_add v1 v2 "addtmp" builder
        | Sub -> build_sub v1 v2 "subtmp" builder
        | Mul -> build_mul v1 v2 "multmp" builder
        | Div -> build_sdiv v1 v2 "divtmp" builder
        | Mod -> build_srem v1 v2 "modtmp" builder
        | Eq -> build_icmp Icmp.Eq v1 v2 "eqtmp" builder
        | Neq -> build_icmp Icmp.Ne v1 v2 "neqtmp" builder
        | Lt -> build_icmp Icmp.Slt v1 v2 "lttmp" builder
        | Le -> build_icmp Icmp.Sle v1 v2 "letmp" builder
        | Gt -> build_icmp Icmp.Sgt v1 v2 "gttmp" builder
        | Ge -> build_icmp Icmp.Sge v1 v2 "getmp" builder
        | And -> build_and v1 v2 "andtmp" builder
        | Or -> build_or v1 v2 "ortmp" builder
        | _ -> failwith "Unsupported int binop in codegen"
        end
  | UnOp (op, e) ->
      let v = emit_expr env e in
      begin match op with
      | Not -> build_not v "nottmp" builder
      | Neg -> build_neg v "negtmp" builder
      end
   | FieldAccess _ -> failwith "FieldAccess not implemented"
   | Throw _ -> failwith "Throw not implemented"
   | Match _ -> failwith "Match not implemented"
  | _ -> failwith "Unsupported expr in codegen"

and emit_stmts ll_func env stmts =
  List.fold_left (emit_stmt ll_func) env stmts

and emit_stmt ll_func env stmt =
  match stmt with
  | Let (_, name, _, expr) ->
      let v = emit_expr env expr in
      StringMap.add name v env
  | Assign (name, expr) ->
      let v = emit_expr env expr in
      let var = try StringMap.find name env with Not_found -> failwith ("Undefined variable: " ^ name) in
      let _ = build_store v var builder in
      env
  | ExprStmt expr ->
      let _ = emit_expr env expr in
      env
  | If (cond, then_, else_) ->
       let cond_v = emit_expr env cond in
       let start_bb = insertion_block builder in
       let the_function = block_parent start_bb in
       let then_bb = append_block context "then" the_function in
       let else_bb = append_block context "else" the_function in
       let merge_bb = append_block context "ifcont" the_function in
       let _ = build_cond_br cond_v then_bb else_bb builder in
       position_at_end then_bb builder;
       let _ = emit_stmts the_function env then_ in
       let _ = build_br merge_bb builder in
       position_at_end else_bb builder;
       begin match else_ with
       | Some stmts -> let _ = emit_stmts the_function env stmts in ()
       | None -> ()
       end;
       let _ = build_br merge_bb builder in
       position_at_end merge_bb builder;
       env
  | While (cond, stmts) ->
      let start_bb = insertion_block builder in
      let the_function = block_parent start_bb in
      let loop_bb = append_block context "loop" the_function in
      let after_bb = append_block context "afterloop" the_function in
      let _ = build_br loop_bb builder in
      position_at_end loop_bb builder;
      let cond_v = emit_expr env cond in
      let _ = build_cond_br cond_v loop_bb after_bb builder in
      let _ = emit_stmts the_function env stmts in
      let _ = build_br loop_bb builder in
      position_at_end after_bb builder;
      env
  | For (name, expr, stmts) ->
      let iter_v = emit_expr env expr in
      let env' = StringMap.add name iter_v env in
      let _ = emit_stmts ll_func env' stmts in
      env
  | Return expr_opt ->
       begin match expr_opt with
       | Some e -> let v = emit_expr env e in build_ret v builder
       | None -> build_ret_void builder
       end;
       env
  | StructDef _ -> env
  | EnumDef _ -> env
  | _ -> failwith "Unsupported stmt in codegen"

let emit_func func =
  let param_types = Array.of_list (List.map (fun (_, ty) -> ty_to_llvm ty) func.params) in
  let ret_type = ty_to_llvm func.ret_ty in
  let func_type = function_type ret_type param_types in
  let ll_func = declare_function func.name func_type the_module in
  let bb = append_block context "entry" ll_func in
  position_at_end bb builder;
  let env = StringMap.empty in
  let param_env = List.fold_left2 (fun env (name, _) param ->
    StringMap.add name param env
  ) env func.params (Array.to_list (Llvm.params ll_func)) in
  let _ = emit_stmts ll_func param_env func.body in
  ll_func

let emit_program program =
  List.iter emit_func program
  let triple = Target.default_triple ()
  set_target_triple triple the_module
  let target = Target.by_triple triple
  let machine = TargetMachine.create ~triple target
  TargetMachine.emit_to_file the_module CodeGenFileType.ObjectFile "output.o" machine;
  ignore (Sys.command "clang output.o -o output")