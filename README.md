# PostgreSQL experiments

I'm learning and testing PostgreSQL features.

Instead of always tying them into my big [d50b](https://gitlab.com/sivers/db-api/) database, it seemed better to keep experiments isolated with minimum context or baggage.


# Context

Very inspired by Rich Hickey's “[Simple Made Easy](https://www.youtube.com/watch?v=rI8tNMsozo0&t=45s)” talk. Especially these points:

* Don't braid things together
* Intertwined things must be considered together
* Simple doesn't mean programmer ease and familiarity
* gem/bower install "hairball" is not simplicity
* Simple might mean making more things, not fewer
* Simple might mean more learning curve (slower start) for later reward
* ORM is unnecessary complication. Work with SQL directly.
* Classes and Models (OOP) are unnecessary complication. Work with values directly (hash/map/table).
* Especially if JSON API is the eventual interface. It's just data.
* Information is simple. Don't hide it behind micro-language.

I have had the same database since 1998 (17 years!), but the required code around it has changed from Perl to PHP to Ruby to JavaScript and sometimes back again.  How many hundreds of hours have I spent re-writing that necessary logic around the database?

Though the norm in this industry is to treat the database as dumb storage, I have always wanted a smarter, stricter database that would not allow anything but a well-formed email address into the email field, or would not allow a started project to be deleted.

One step further, using PL/pgSQL, now *all* the “business logic” that classes and ORM models were doing could be done in the database directly!  No more depending on that ever-changing PHP, Ruby, JavaScript stuff around it.

One step further, now that PostgreSQL has JSON functions, even the job of a REST API webserver to convert table/row values into JSON documents could be done in the database.

Less intertwining.  Less complecting.  Less dependencies.  Double-down on the database.

PL/pgSQL is not as beautiful as Ruby, but by having all this inside the database, I can easily switch to whatever language/tech around it is best at the time.

Right now [OpenResty](http://openresty.org/) and [Plug](https://github.com/elixir-lang/plug) both look appealing, but I'm open to whatever.  The API webserver doesn't have to do anything but map HTTP methods and URLs to PostgreSQL function calls, then directly pass the database response as an HTTP response.


# Goal

As of now, I'm daydreaming of the dumbest possible webserver, and the smartest possible database, to make a great JSON REST API.

Every database call would be the same format:

`pg_query("SELECT mime, js FROM some_function_name($1, $2)", [params[:id], params[:json]])`

The webserver would just send the MIME type and JSON back as the response, even for errors.

I haven't tried this yet, but that's what these PostgreSQL experiments are leading towards.


# For these tests:

`createuser -s sivers ; createdb -E UTF8 -O sivers sivers`

