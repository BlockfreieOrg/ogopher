#all: ogopher ogopherloader
all: ogopher.cma
ogopher.cma: ogopher.ml
	ocamlfind ocamlc -c -g -thread -package dbm,core,async -linkpkg ogopher.ml
ogopher: ogopher.ml
	ocamlfind ocamlopt -ccopt -static -thread -package dbm,core,async -linkpkg -o ogopher ogopher.ml
loader.byte: loader.ml
	ocamlfind ocamlc  -g -thread -package extlib,dbm,core,async,sexplib.syntax,camlp4,magic-mime -pp "camlp4of -I `ocamlfind query type_conv` -I `ocamlfind query sexplib` pa_type_conv.cma pa_sexp_conv.cma" -linkpkg -o loader.byte loader.ml
clean:
	rm -f *.byte *.native *.db.* *.cmi *.cmx *.cmo  #echo.ml#  *~
 
