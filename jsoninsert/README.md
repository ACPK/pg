# JSON insert

A generic function with two parameters:

1. table name
2. JSON hash where keys are table column names, values are new values

The function turns it into an INSERT statement on that table and executes it.

Then it returns updated record.

If any errors, insert is not performed.

## status: works!

Like **jsonupdate3** directory here in this repository, I think the best approach is table-specific by upper-level API, using jsoninsert to handle some mundanes.

