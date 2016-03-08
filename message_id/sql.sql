SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE emails (
	id serial primary key,
	person_id integer,
	outgoing boolean,
	message_id text,
	subject text
);

CREATE FUNCTION make_message_id() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.outgoing IS TRUE AND NEW.message_id IS NULL THEN
		NEW.message_id = CONCAT(
			to_char(current_timestamp, 'YYYYMMDDHH24MISSMS'),
			'.', NEW.person_id, '@sivers.org');
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER make_message_id BEFORE INSERT ON emails FOR EACH ROW EXECUTE PROCEDURE make_message_id();

COMMIT;
