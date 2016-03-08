SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE emails (
	id serial primary key,
	subject text,
	body text
);

INSERT INTO emails (subject, body) VALUES ('hi', E'Hi -\n\nYou made sense.\nI understand.  \n\n--\nMe, me@me.me');

CREATE FUNCTION reply_to(email_id integer, body text) RETURNS SETOF emails AS $$
DECLARE
	old_email emails;
BEGIN
	SELECT * INTO old_email FROM emails WHERE id = email_id;
	-- add old_email.body to the end of new body
	body := concat(body, E'\n\n',
		-- after adding '> ' to every newline
		regexp_replace(old_email.body, '^', '> ', 'ng'));
	RETURN QUERY EXECUTE 'INSERT INTO emails (subject, body) VALUES ($1, $2) RETURNING *'
		USING concat('re: ', old_email.subject), body;
END;
$$ LANGUAGE plpgsql;

COMMIT;

