# WITH x AS y SELECT * FROM view

Many times, I perform an action, like an insert/update/delete, but then want to select the results of it into a view, returning just the view.

Ideally, I'd like to save the results of the table return, and pass that row-variable into a view, like this pseudo-code:

```sql
CREATE VIEW emails_view AS SELECT id, subject FROM emails;
CREATE FUNCTION new_email(text, text) RETURNS SETOF emails_view AS $$
DECLARE
	r emails;
BEGIN
	INSERT INTO emails(subject, body) VALUES ($1, $2) RETURNING * INTO r;
	WITH emails AS r SELECT * FROM emails_view;
END;
```

## status:   any ideas?

