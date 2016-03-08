# JSON update IMPROVED

Instead of the approach taken in jsonupdate directory here, what if I give up on abstractions and try letting each API command just make its own typecast updates?

Now it's a hybrid with a specific calling a generic.

If I could do the type-casting of each column, and do RETURNS SETOF RECORD in jsonupdate, then I could go all-generic, but maybe this is enough abstraction.


# status: works great!

But still trying to improve it.

Check out the garbage test.  Now it can receive junk in JSON, without error.

