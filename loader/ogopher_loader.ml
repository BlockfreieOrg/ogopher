open Core.Std
open Async.Std
open Core.Std;;
open Sexplib.Conv;;
open Sexplib.Sexp;;
open Sexplib.Std;;
open Sexplib;;
open Magic_mime;;
open Core_kernel.Std;;
open ExtLib;;

type server = { host : string ;
                port : int }
                deriving (Yojson)

type catalog = { server : server ;
                 resources : unit }
                deriving (Yojson)

let load_json
      (json_path : string)
      (dbm_path : string) : unit =
  let db = Dbm.opendbm
             dbm_path
             [Dbm.Dbm_rdwr; Dbm.Dbm_create]
             0o666
  in
  Dbm.close db
;;

let check_load (dbm_path : string) : unit =
  let db = Dbm.opendbm
             dbm_path
             [Dbm.Dbm_rdwr; Dbm.Dbm_create]
             0o666
  in
  Dbm.iter
    (fun key value -> print_string
                        (sprintf "'%s'\n%s" key value))
    db

let json_error f = sprintf "json site description to load (default '%s')" f
let dbm_error f = sprintf " DB path (default '%s')" f

let () =
  let default_json = "site/index.json" in
  let default_dbm = "gopher.db" in
  let json_error f = sprintf "json site description to load (default '%s')" f in
  let dbm_error f = sprintf " DB path (default '%s')" f in
  Command.basic
    ~summary:"load a gopher index from a json file"
    Command.Spec.(empty
                  +> flag
                       "-json"
                       (optional_with_default default_json string)
                       ~doc:(json_error default_json)
                  +> flag
                       "-db"
                       (optional_with_default default_dbm string)
                       ~doc:(dbm_error default_dbm))
    (fun json dbm () ->
      load_json json dbm;
      check_load dbm)
  |> Command.run
