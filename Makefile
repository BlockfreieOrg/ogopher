#all: ogopher_server ogopher_loader
all: ogopher.cma ogopher_server ogopher_loader
# the debug flag is left on as this is usually for development
ogopher.cma: ogopher.ml
	ocamlfind ocamlc -c -g -thread -package dbm,core,async -linkpkg ogopher.ml
# this is statically linked so it is easier to root jail
ogopher_server: ogopher.ml ogopher_server.ml
	ocamlfind ocamlopt -ccopt -static -thread -package dbm,core,async -linkpkg -o ogopher_server ogopher.ml ogopher_server.ml
# the loading is done out side the jail so we don't have to be
# to careful with the loader
ogopher_loader: ogopher_loader.ml
	ocamlfind ocamlc  -g -thread -package extlib,dbm,core,async,sexplib.syntax,camlp4,magic-mime -pp "camlp4of -I `ocamlfind query type_conv` -I `ocamlfind query sexplib` pa_type_conv.cma pa_sexp_conv.cma" -linkpkg -o ogopher_loader ogopher_loader.ml
clean:
	rm -f *.byte *.native *.db.* *.cmi *.cmx *.cmo *.o *~ ogopher_server ogopher_loader
 
