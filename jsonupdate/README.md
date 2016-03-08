# JSON update

A generic function with three parameters:

1. table name
2. primary key
3. JSON hash where keys are table column names, values are new values

The function turns it into an UPDATE statement on that table and executes it.

If any errors, update is not performed.

## status:  working but ugly

Right now instead of constructing multi-column UPDATE statement string, it just loops through JSON key/value pairs, and creates multiple UPDATE statements.

If this is the best solution, so be it.  But looking for improvement suggestions.

As for the values, how to deal with NULL, NOW(), and non-string types?  Obviously, many people have tackled this problem before, so I don't need to reinvent the wheel.

## TODO:

Return updated record.  (What's the best way to do that?)

