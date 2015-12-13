# ogopher
yet another gopher package for ocaml

A gopher server in < 40 lines of code.  It serves from a key
value store which guards against path based attacks as data
can only be read from the store.  The use of a key value
store also simplifies the deployment of the gopher site.

Adding url's which return executable contant is as simple
as inheritence.  Lets use this to create a simple hello world
app.

Lets check it out .

It is simple to add services on url as below.

A tool is provided that allows the key values store to be
loaded via a simple dsl in sexpressions.  The file command :
(file url path)
stores the file given by the path in the following url. The
index command :
(index url_i "text" url_1 ...)
Builds the index comprised of text and urls that the user will
view on a menu at at url_i.

This is all that is needed for a simple gopher site.
