SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE people (
	id serial primary key,
	name varchar(32),
	email varchar(32),
	age integer
);

CREATE TABLE formletters (
	id serial primary key,
	body text
);

INSERT INTO people(name, email, age) VALUES ('Willy Wonka', 'willy@wonka.com', 50);
INSERT INTO formletters(body) VALUES ('Hi {name} at {email}, age {age}');

-- PARAMS: people.id, formletters.id
CREATE FUNCTION parse_formletter(integer, integer) RETURNS text AS $$
DECLARE
	new_body text;
	thisvar text;
	thisval text;
BEGIN
	SELECT body INTO new_body FROM formletters WHERE id = $2;
	FOR thisvar IN SELECT regexp_matches(body, '{([^}]+)}', 'g') FROM formletters
		WHERE id = $2 LOOP
		EXECUTE format ('SELECT %s::text FROM people WHERE id=%L',
			btrim(thisvar, '{}'), $1) INTO thisval;
		new_body := regexp_replace(new_body, thisvar, thisval);
	END LOOP;
	RETURN new_body;
END;
$$ LANGUAGE plpgsql;


COMMIT;
