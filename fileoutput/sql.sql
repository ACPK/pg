SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE comments (
	id serial primary key,
	uri varchar(8),
	name varchar(32),
	created_at date not null default current_date,
	html text
);

INSERT INTO comments (uri, name, html) VALUES ('blog1', 'Bob', 'great stuff');
INSERT INTO comments (uri, name, html) VALUES ('blog1', 'Bill', 'I agree!');
INSERT INTO comments (uri, name, html) VALUES ('blog2', 'Penny', 'This isn''t "cool".');
INSERT INTO comments (uri, name, html) VALUES ('blog2', 'Đaviđ', 'Árið');

CREATE FUNCTION clean_uri() RETURNS TRIGGER AS $$
BEGIN
	NEW.uri = lower(regexp_replace(NEW.uri, '[^[:alnum:]-]', '', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER clean_uri BEFORE INSERT OR UPDATE OF uri ON comments FOR EACH ROW EXECUTE PROCEDURE clean_uri();

CREATE FUNCTION write2disk() RETURNS TRIGGER AS $$
DECLARE
	u text;
BEGIN
	IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
		u := NEW.uri;
	ELSE
		u := OLD.uri;
	END IF;
	-- Double-escaping of backslash creating invalid JSON.
	-- (JSON adds \ to escape ". COPY adds another \ to escape \)
	-- Solution: pipe to PROGRAM that removes double-escaped \
	EXECUTE format ('COPY (SELECT json_agg(row_to_json(x)) FROM '
	|| '(SELECT id, uri, name, created_at, html FROM comments'
	|| ' WHERE uri = %L ORDER BY id) x) TO PROGRAM ''/tmp/jparse.rb''', u);
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER write2disk AFTER INSERT OR UPDATE OR DELETE ON comments FOR EACH ROW EXECUTE PROCEDURE write2disk();

COMMIT;

