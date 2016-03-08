# JSON Errors

Remember the ultimate goal of this work is to have a dumb webserver make a REST API by calling functions that always start with **SELECT mime, JS FROM**, like this:

```
SELECT mime, js FROM get_person(123);
SELECT mime, js FROM update_person(123, '{"name":"Dude"}');
SELECT mime, js FROM client_delete_project(7, 95);
```

The webserver knows it will **always** get back a MIME type and JSON hash, so it can just pass those directly into its HTTP response.  No special intelligence needed by the webserver.

So instead of PostgreSQL raising exceptions, I want to **catch all exceptions**, and return [application/api-problem+json](https://tools.ietf.org/html/draft-nottingham-http-problem-06), [like this](https://www.mnot.net/blog/2013/05/15/http_problem).

## status: works, now improve it

**The ideal:** no matter what error, whether foreign key fail, check constraint, raised error, or anything else, that there's a way to return a unique string that can be translated into English and other languages.

Errors are sent to a function that looks up a translation of the error.  Yes this could get complex, but it's in one place.  Imagine each time I add a constraint or foreign key to a table, just take a minute to log the unique error string in the database so it can be quickly found.

Example: Error is country code needs to be [A-Z]{2}. code: **country2char** English: "Country code needs to be 2 A-Z (uppercase) letters, valid ISO-3316."

