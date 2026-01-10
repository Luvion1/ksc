open Ast

module StringMap = Map.Make(String)

type env = {
  vars: ty StringMap.t;
   funcs: (ty list * ty) StringMap.t;
  structs: (string * ty) list StringMap.t;  (* struct name -> fields *)
  enums: (string * ty list) list StringMap.t;  (* enum name -> variants *)
  scopes: (string * ty) list;  (* current scope for variable shadowing *)
}

(* Fungsi tambahan untuk manajemen scope *)
let push_scope env =
  { env with scopes = [] }

let pop_scope env =
  { env with scopes = [] }

let add_var_to_current_scope env name ty =
  { env with
    vars = StringMap.add name ty env.vars;
    scopes = (name, ty) :: env.scopes
  }

let remove_scope_vars env =
  let vars' = List.fold_left (fun vars (name, _) -> StringMap.remove name vars) env.vars env.scopes in
  { env with vars = vars'; scopes = [] }

let rec infer_expr env expr =
  match expr with
  | Literal (Int _) -> I32
  | Literal (Float _) -> F64
  | Literal (Bool _) -> BoolTy
  | Literal (String _) -> Str
  | Literal (Char _) -> Char
  | Var name ->
      begin try StringMap.find name env.vars
      with Not_found -> failwith ("Undefined variable: " ^ name)
      end
  | BinOp (e1, op, e2) ->
      let t1 = infer_expr env e1 in
      let t2 = infer_expr env e2 in
      begin match op with
      | Ast.And | Ast.Or ->
          if t1 <> BoolTy || t2 <> BoolTy then failwith "Logical operators require bool operands";
          BoolTy
      | Ast.Eq | Ast.Neq | Ast.Lt | Ast.Le | Ast.Gt | Ast.Ge ->
          if t1 <> t2 then failwith "Type mismatch in comparison";
          BoolTy
      | _ ->
          if t1 <> t2 then failwith "Type mismatch in binop";
          t1
      end
  | UnOp (_, e) -> infer_expr env e
  | Call (Var name, args) ->
       let (param_tys, ret_ty) = try StringMap.find name env.funcs with Not_found -> failwith ("Undefined function: " ^ name) in
       let arg_tys = List.map (infer_expr env) args in
       if List.length param_tys <> List.length arg_tys then failwith "Wrong number of arguments";
       List.iter2 (fun p a -> if p <> a then failwith "Type mismatch in call") param_tys arg_tys;
       ret_ty
   | Call _ -> failwith "Only direct calls supported"
  | Match (e, cases) ->
      let _ = infer_expr env e in
      List.iter (fun (_, expr) -> let _ = infer_expr env expr in ()) cases;
      (* Assume same type *)
      Unit
  | Block (stmts, expr_opt) ->
      let env' = check_stmts env stmts in
      begin match expr_opt with
      | Some e -> infer_expr env' e
      | None -> Unit
      end
  | Cast (expr, ty) ->
      let _ = infer_expr env expr in
      ty
  | Throw expr ->
      let _ = infer_expr env expr in
      Unit
  | FieldAccess (expr, field) ->
      let t = infer_expr env expr in
      begin match t with
      | StructType fields ->
          begin try List.assoc field fields
          with Not_found -> failwith ("Field not found: " ^ field)
          end
      | _ -> failwith "Field access on non-struct type"
      end

and check_stmts env stmts =
  List.fold_left check_stmt env stmts

and check_stmt env stmt =
  match stmt with
  | Let (_, name, ty_opt, expr) ->
      let t_expr = infer_expr env expr in
      begin match ty_opt with
      | Some ty when ty <> t_expr -> failwith ("Type mismatch in let: " ^ name)
      | _ -> ()
      end;
      { env with vars = StringMap.add name t_expr env.vars }
  | Assign (name, expr) ->
      let t_var = try StringMap.find name env.vars with Not_found -> failwith ("Undefined variable: " ^ name) in
      let t_expr = infer_expr env expr in
      if t_var <> t_expr then failwith ("Type mismatch in assign: " ^ name);
      env
  | ExprStmt expr ->
      let _ = infer_expr env expr in
      env
  | If (cond, then_, else_) ->
       let t_cond = infer_expr env cond in
       if t_cond <> BoolTy then failwith "If condition must be bool";
       let _ = check_stmts env then_ in
       begin match else_ with
       | Some else_ -> let _ = check_stmts env else_ in ()
       | None -> ()
       end;
       env
  | While (cond, stmts) ->
      let t_cond = infer_expr env cond in
      if t_cond <> BoolTy then failwith "While condition must be bool";
      let _ = check_stmts env stmts in
      env
  | For (name, expr, stmts) ->
      let t_expr = infer_expr env expr in
      (* Assume collection type, add name as element type *)
      let env' = { env with vars = StringMap.add name t_expr env.vars } in
      let _ = check_stmts env' stmts in
      env
  | Const (name, ty, expr) ->
      let t_expr = infer_expr env expr in
      if t_expr <> ty then failwith ("Type mismatch in const: " ^ name);
      { env with vars = StringMap.add name ty env.vars }
  | StructDef (name, fields) ->
      { env with structs = StringMap.add name fields env.structs }
  | EnumDef (name, variants) ->
      { env with enums = StringMap.add name variants env.enums }
  | Return expr_opt ->
       begin match expr_opt with
       | Some e -> let _ = infer_expr env e in ()
       | None -> ()
       end;
       env

and infer_block env stmts =
  let _ = check_stmts env stmts in
  Unit  (* blocks return unit for now *)

let check_func env func =
  let param_vars = List.fold_left (fun vars (name, ty) -> StringMap.add name ty vars) env.vars func.params in
  let param_env = { env with vars = param_vars } in
  let _ = check_stmts param_env func.body in
  ()

let collect_defs stmts env =
  List.fold_left (fun env stmt ->
    match stmt with
    | StructDef (name, fields) ->
        { env with structs = StringMap.add name fields env.structs }
    | EnumDef (name, variants) ->
        { env with enums = StringMap.add name variants env.enums }
    | _ -> env
  ) env stmts

let check_program program =
  let empty_env = { vars = StringMap.empty; funcs = StringMap.empty; structs = StringMap.empty; enums = StringMap.empty; scopes = [] } in
  let global_env = List.fold_left (fun env func ->
    collect_defs func.body env
  ) empty_env program in
  List.iter (check_func global_env) program