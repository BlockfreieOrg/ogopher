open Core.Std
open Async.Std
open Async.Std.Unix
open Dbm
open Printf

class ['a] ogopher ~port ~dbm_path =
  let db = Dbm.opendbm dbm_path [Dbm.Dbm_rdonly] 0o660 in
object (self)
  method default s = sprintf "Not found '%s'" s
  method handler s = try Dbm.find db s
                     with Not_found -> self#default s
  method handle_request r w =
    Reader.read_line r
    >>= function
    | `Eof -> return ()
    | `Ok line ->
       prerr_string (sprintf "'%s'\n" line);
       Writer.write w (self#handler line); return ()
  method run : 'a Async.Std.Deferred.t =
    let host_and_port = Tcp.Server.create
      ~on_handler_error:`Raise
      (Tcp.on_port port)
      (fun addr r w -> self#handle_request r w)
    in ignore (host_and_port : (Socket.Address.Inet.t, int) Tcp.Server.t Deferred.t);
       Deferred.never ()
end;;

class ['a] ogopher_hello_world ~port ~dbm_path =
object(self)
  inherit ['a] ogopher port dbm_path as super
  method default s = match s with
                     | _ -> "iHello World\terror.host\t1\n.\n"
end

class ['a] ogopher_services ~port ~dbm_path =
object(self)
  inherit ['a] ogopher port dbm_path as super
  method rand_bool () = string_of_bool (Random.bool ())
  method date () =
    let t = Unix.localtime (Unix.time ()) in
    let (day, month, year) = (t.tm_mday, t.tm_mon, t.tm_year) in
    sprintf "%04d-%02d-%02d" (1900 + year) (month + 1) day
  method default s = match s with
                     | "/rand_bool" -> self#rand_bool ()
                     | "/date"      -> self#date ()
                     | _            -> super#default s
end;;

let dbm_path = "gopher.db" in
    Dbm.close (Dbm.opendbm dbm_path [Dbm.Dbm_rdwr; Dbm.Dbm_create] 0o666);
    (new ogopher_hello_world 70 dbm_path)#run
