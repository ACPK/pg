SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE comments (
	id serial primary key,
	uri varchar(16),
	name varchar(16),
	comment text
);

INSERT INTO comments (uri, name, comment) VALUES ('trust', 'name one', 'comment "one"');
INSERT INTO comments (uri, name, comment) VALUES ('trust', 'name²', 'comment twø');

CREATE FUNCTION comments_changed() RETURNS TRIGGER AS $$
DECLARE
	u text;
BEGIN
	IF TG_OP = 'DELETE' THEN
		u := OLD.uri;
	ELSE
		u := NEW.uri;
	END IF;
	PERFORM pg_notify('comments_changed', u);
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER comments_changed AFTER INSERT OR UPDATE OR DELETE ON comments FOR EACH ROW EXECUTE PROCEDURE comments_changed();

COMMIT;

