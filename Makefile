#all: ogopher_server ogopher_loader
all: build
install: 
build: ogopher_server.native ogopher_loader.native

# the debug flag is left on as this is usually for development
# this is statically linked so it is easier to root jail

ogopher_server.native: server/ogopher.ml server/ogopher_server.ml
	ocamlbuild -use-ocamlfind ogopher_server.native

# the loading is done out side the jail so we don't have to be
# to careful with the loader
ogopher_loader.native: loader/ogopher_loader.ml
	ocamlbuild -use-ocamlfind ogopher_loader.native

clean:
	rm -f *.byte *.native *.db.* *.cmi *.cmx *.cmo *.o *~ ogopher_server ogopher_loader ; rm -rf _build
 
