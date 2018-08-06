#all: ogopher_server ogopher_loader
all: build
install: 
build: ogopher_server.native 

# the debug flag is left on as this is usually for development
# this is statically linked so it is easier to root jail

ogopher_server.native: server/ogopher.ml server/ogopher_server.ml
	ocamlbuild -use-ocamlfind -syntax camlp4o -package deriving-yojson.syntax,deriving-yojson,core,async,deriving ogopher_server.native

# the loading is done out side the jail so we don't have to be
# to careful with the loader
ogopher_loader: loader/ogopher_loader.ml
	ocamlfind ocamlopt -ccopt -static -thread -package dbm,core,async -linkpkg -o ogopher_loader ogopher_loader.ml
clean:
	rm -f *.byte *.native *.db.* *.cmi *.cmx *.cmo *.o *~ ogopher_server ogopher_loader ; rm -rf _build
 
