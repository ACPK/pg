# Update/Insert View that spans two tables

I have a table called **people** that is referenced by many other tables.  The reason is that a person might be a customer of one of my projects, a writer for a different project, and a manager of yet another project.  But since it's just one person, I didn't want to duplicate fields like **name** and **email** across many different tables.

But the JSON API doesn't need to know this database normalization impedance mismatch stuff.  That's why I make views that hide this, including some people.info along with stuff specific to that table.

In my tiny example here, I put just name and email columns in the people table, but really it includes about 10 more columns like address, city, country, and notes.

## Problem:

When updating or inserting into these views, I can use the whole “INSTEAD OF” trigger trick to send the update to the people table instead.

But then what about an update or insert that contains columns for both the people table and the customers or writers table?  If I want to update both people.email and writers.bio at once?

## status: started but broken

Currently only updates people table, without knowing how to handle local columns.

Also don't know how to do inserts.

See **jsonupdate3** directory in this repository, for a better approach.

