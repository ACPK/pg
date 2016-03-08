# changes needing approval

When I'm in control of my own data in my database, when it's only updated by me, I have no problem updating everything directly.  If I say someone has moved to Antarctica, then they have.  If I say their website is sex.xxx, then it is.

But when I'm letting users update their own info, I can't be sure of that.  They might want to fuck with it, or they might make mistakes.  When asked for their city, they could write, "Not sure yet, moving soon."  When asked for email they could (and do) write, "one@hotmail.com,another@gmail.com".

So I want some way of logging updates made by users.  Ideally showing before-and-after.

One option is adding a “deleted_at” column to every table, making updates into a delete-and-insert, and queries adding "WHERE deleted_at IS NULL"

But here I'm going to try another option.  A changes table that logs before-and-after.  Then a manager will sort through and look for trouble, marking them as approved if they look OK.  If not OK, it'll need human intervention anyway.

The downside is that the database could temporarily have some shit values.  But before generating static sites, it'll just be part of the workflow to first approve changes.

Let's see how to do this.

# status: 

