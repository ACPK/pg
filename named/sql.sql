SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE people (
	id serial primary key,
	name varchar(32),
	email varchar(32)
);

CREATE FUNCTION create_person(name text, email text, OUT js json) AS $$
BEGIN
	INSERT INTO people(name, email) VALUES ($1, $2)
		RETURNING json_build_object(
			'id', id,
			'name', people.name,
			'email', people.email) INTO js;
END;
$$ LANGUAGE plpgsql;

COMMIT;

