# File output

Trigger when changed, output all that blog post's comments as a JSON array, to a file in the filesystem.


## status: use notify instead, until plpython some day

Use **notify** approach instead, in sibling directory here.

See <https://wiki.postgresql.org/wiki/COPY#Caveats_with_import>.  Seems the backslash characters thing is unavoidable.  What a shame.

So now I've added a Ruby script to pipe all output to, which reads the PostgreSQL output, removes the double slashes, removes the uri from hash while at it, and re-saves it using the uri in the filename.

None of this would be needed if PostgreSQL could skip the escaping of the backslash.

Other alternative is to use plPython untrusted.

