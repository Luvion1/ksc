let () =
  if Array.length Sys.argv <> 2 then
    (print_endline "Usage: ksharp <file.ks>";
     exit 1)
  else
    try
      let _ = Ksharp.Compiler.compile Sys.argv.(1) in
      print_endline "Parsed and type checked successfully";
    with Failure msg ->
      print_endline ("Error: " ^ msg);
      exit 1