open Ast

module StringMap = Map.Make(String)

type env = ty StringMap.t

let rec infer_expr env expr =
  match expr with
  | Literal (Int _) -> I32
  | Literal (Float _) -> F64
  | Literal (Bool _) -> BoolTy
  | Literal (String _) -> Str
  | Literal (Char _) -> Char
  | Var name ->
      begin try StringMap.find name env
      with Not_found -> failwith ("Undefined variable: " ^ name)
      end
  | BinOp (e1, _, e2) ->
      let t1 = infer_expr env e1 in
      let t2 = infer_expr env e2 in
      if t1 <> t2 then failwith "Type mismatch in binop";
      t1
  | UnOp (_, e) -> infer_expr env e
  | If (cond, then_, else_) ->
      let t_cond = infer_expr env cond in
      if t_cond <> BoolTy then failwith "If condition must be bool";
      let t_then = infer_block env then_ in
      begin match else_ with
      | Some else_ ->
          let t_else = infer_block env else_ in
          if t_then <> t_else then failwith "If branches must have same type";
          t_then
      | None -> Unit
      end
  | Call (_, _) -> Unit
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
      StringMap.add name t_expr env
  | Assign (name, expr) ->
      let t_var = try StringMap.find name env with Not_found -> failwith ("Undefined variable: " ^ name) in
      let t_expr = infer_expr env expr in
      if t_var <> t_expr then failwith ("Type mismatch in assign: " ^ name);
      env
  | ExprStmt expr ->
      let _ = infer_expr env expr in
      env
  | While (cond, stmts) ->
      let t_cond = infer_expr env cond in
      if t_cond <> BoolTy then failwith "While condition must be bool";
      let _ = check_stmts env stmts in
      env
  | For (name, expr, stmts) ->
      let t_expr = infer_expr env expr in
      (* Assume collection type, add name as element type *)
      let env' = StringMap.add name t_expr env in  (* simple *)
      let _ = check_stmts env' stmts in
      env

and infer_block env stmts =
  let _ = check_stmts env stmts in
  Unit  (* blocks return unit for now *)

let check_func env func =
  let param_env = List.fold_left (fun env (name, ty) -> StringMap.add name ty env) env func.params in
  let _ = check_stmts param_env func.body in
  ()

let check_program program =
  let global_env = StringMap.empty in
  List.iter (check_func global_env) program