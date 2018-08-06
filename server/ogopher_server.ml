open Core.Std
open Async.Std
open Async.Std.Unix
open Ogopher

let () =
  Command.async_basic
    ~summary:"Start an gopher server"
    Command.Spec.(empty
                  +> flag "-port" (optional_with_default 70 int)
                    ~doc:" Port to listen on (default 70)"
                  +> flag "-db-path" (optional_with_default "gopher.db" string)
                    ~doc:" DB path (default 'gopher.db')")
    (fun port dbm_path () -> let ogopher = new Ogopher.ogopher port dbm_path
                            in ogopher#run)
  |> Command.run
