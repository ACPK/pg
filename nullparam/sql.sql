SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE people (
	id serial primary key,
	name varchar(32),
	rank integer
);

-- PARAMS: name, rank
CREATE FUNCTION new_person(text, integer) RETURNS SETOF people AS $$
BEGIN
	RETURN QUERY EXECUTE 'INSERT INTO people(name, rank) VALUES ($1, $2) RETURNING *' USING $1, $2;
END;
$$ LANGUAGE plpgsql;

-- What about a FOREACH over a possibly NULL array?
CREATE FUNCTION many_ranks(integer[]) RETURNS void AS $$
DECLARE
	arank integer;
BEGIN
	IF $1 IS NOT NULL THEN
		FOREACH arank IN ARRAY $1 LOOP
			INSERT INTO people(rank) VALUES (arank);
		END LOOP;
	END IF;
	RETURN;
END;
$$ LANGUAGE plpgsql;

COMMIT;

