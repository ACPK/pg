# JSON field

To be used in peeps.import_email:

I want to be able to pass in a JSON object, where one value is an array.

Get that array and use it as an array.

## status: works, altered

Changed the plan a bit.  Instead of needing it to be a PostgreSQL array, turn it into rows and use an IN query.

