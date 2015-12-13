(*
open Async.Std;;

*)
open Core.Std;;
open Sexplib.Conv;;
open Sexplib.Sexp;;
open Sexplib.Std;;
open Sexplib;;
open Magic_mime;;
open Core_kernel.Std;;
open ExtLib;;

type file = { selector : string ; label : string ; path : string } with sexp

type entry_type =
  | Text
  | Directory
  | CSO
  | Error
  | BinHex
  | Archive
  | UUEncoded
  | Search
  | Telnet
  | Binary
  | GIF
  | HTML
  | Information
  | Image
  | Audio
  | TN3270
     with sexp
let render_entry_type (e : entry_type) =
  match e with
  | Text -> "0"
  | Directory -> "1"
  | CSO -> "2"
  | Error -> "3"
  | BinHex -> "4"
  | Archive -> "5"
  | UUEncoded -> "6"
  | Search -> "7"
  | Telnet -> "8"
  | Binary -> "9"
  | GIF -> "g"
  | HTML -> "h"
  | Information -> "i"
  | Image -> "g"
  | Audio -> "s"
  | TN3270 -> "T"

type directory_entry =
  { entry_type : entry_type ; label : string; selector : string option ; host : string option ; port : int option }
type reference =
  { selector : string }
with sexp
type link =
  { entry_type : entry_type ; label : string; selector : string ; host : string        ; port : int }
with sexp
type listing =
  | Reference of reference
  | Label of string
  | Link of link
with sexp
type server = { host : string ; port : int } with sexp
type cache = { entry_type : entry_type ; label : string }
type state = { server : server ; lookup : (string,cache) Hashtbl.t }
type menu = { selector : string ; label : string ; listings : listing list} with sexp
type resource =
  | File of file
  | Menu of menu
with sexp

type catalog = { server : server ; resources : resource list } with sexp
type content = { selector : string ; content : string } with sexp

let render_entry ({ entry_type = entry_type ; label = label ; selector = selector ; host = host ; port = port } : directory_entry) =
  sprintf "%s%s\t%s\t%s\t%d\n"
    (render_entry_type entry_type)
    label
    (match selector with | Some selector -> selector | None -> "Error")
    (match host with | Some host -> host | None -> "(null)")
    (match port with | Some port -> port | None -> 0 )

let listing_entry ({ server = { host = host ; port = port } ; lookup = lookup } : state) (l : listing) : directory_entry =
  match l with
  | Reference { selector = selector } ->
     let { entry_type = entry_type ; label = label } = Hashtbl.find lookup selector in
     { entry_type = entry_type  ; label = label;  selector = Some selector ; host = Some host ; port = Some port }
  | Label label ->
     { entry_type = Information ; label = label;  selector = None          ; host = None      ; port = None }
  | Link
     { entry_type = entry_type  ; label = label;  selector = selector      ; host = host      ; port = port }
    ->
     { entry_type = entry_type  ; label = label;  selector = Some selector ; host = Some host ; port = Some port }

let rec render_menu (s : state) (l : listing list) =
  match l with
    h::t -> (render_entry (listing_entry s h)) ^ (render_menu s t)
  | [] -> ".\n"

let render_resource ({ server = server ; lookup = lookup } : state) (r : resource) =
  match r with
  |  File { selector = selector ; label = label ; path = path } ->
     let mime = Magic_mime.lookup path in
     let entry_type = match mime with
       | _ when String.exists mime "uuencode"   -> UUEncoded
       | _ when String.exists mime "html"       -> HTML
       | _ when String.exists mime "gif"        -> GIF
       | _ when String.exists mime "image"      -> Image
       | _ when String.exists mime "audio"      -> Audio
       | _ when String.exists mime "binary"     -> Binary
       | _ when String.exists mime "binhex"     -> BinHex
       | _ when String.exists mime "text"       -> Text
       | _ -> raise (Failure (sprintf "unexpected mime type '%s'" mime))
     in
     Hashtbl.replace lookup selector { entry_type = entry_type ; label = label };
     { selector = selector ; content = In_channel.read_all path }
  |  Menu { selector = selector ; label = label ; listings = listings } ->
     Hashtbl.replace lookup selector { entry_type = Directory ; label = label };
     { selector = selector ; content = render_menu { server = server ; lookup = lookup } listings }
;;

let load_scm (scm_path : string) (dbm_path : string) =
  let db = Dbm.opendbm dbm_path [Dbm.Dbm_rdwr; Dbm.Dbm_create] 0o666 in
  let { server = server ; resources = resources } = (catalog_of_sexp (Sexp.load_sexp scm_path)) in
  let state : state = { server = server ; lookup = Hashtbl.create (List.length resources) } in
  let persist { selector = selector ; content = content } : unit = Dbm.replace db selector content in
  let persist_resource (r : resource) : unit = persist (render_resource state r) in
  List.iter persist_resource resources;
  Dbm.close db
;;
let check_load (dbm_path : string) =
  let db = Dbm.opendbm dbm_path [Dbm.Dbm_rdwr; Dbm.Dbm_create] 0o666 in
  Dbm.iter (fun key value -> print_string (sprintf "'%s'\n%s" key value)) db

let sample : catalog = { server = { host = "host0" ; port = 70 }
                       ; resources = [File { selector = "selector1" ; label = "label1" ; path ="path0" }
                                     ;Menu { selector = "selector1" ; label = "label1" ;
                                             listings = [ Reference { selector = "url3" }
                                                        ; Label "label1"
                                                        ; Link { entry_type = Image ; label = "label2" ; selector = "url6" ; host = "host1" ; port = 71 }
                                                        ]
                                           } ] };;
let () =
  let default_scm = "site/index.scm" in
  let default_dbm = "gopher.db" in
  Command.basic
    ~summary:"Start an gopher server"
    Command.Spec.(empty
                  +> flag "-scm" (optional_with_default default_scm string)
                    ~doc:(sprintf " scm site description to load (default '%s')" default_scm)
                  +> flag "-db" (optional_with_default default_dbm string)
                    ~doc:(sprintf " DB path (default '%s')" default_dbm))
    (fun scm dbm () ->
      load_scm scm dbm;
      check_load dbm)
  |> Command.run
