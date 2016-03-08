# Dynamic status column

In Ruby, I'd have a method called 'status' that would dynamically return a string based on the values of a few different columns in a table.

What I liked about it is that it was indistinguishable from a regular table column.  I could call project.name, project.status, not caring that one was a database field and the other was generated on the fly.

So - how to do that in PostgreSQL directly?  A field that is updated with triggers?


## status: maybe finished?

Please review.  Just added the update_status() and date_in_order() triggers, which seem to do the job well.  Any downsides to this approach?


