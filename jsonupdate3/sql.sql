SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE people (
	id serial primary key,
	name varchar(32),
	email varchar(32)
);

CREATE TABLE clients (
	id serial primary key,
	person_id integer unique not null REFERENCES people(id),
	notes text
);

CREATE TABLE workers (
	id serial primary key,
	person_id integer unique not null REFERENCES people(id),
	salary integer
);

CREATE VIEW client_view AS
	SELECT clients.*, people.name, people.email
	FROM clients JOIN people ON clients.person_id=people.id;

CREATE VIEW worker_view AS
	SELECT workers.*, people.name, people.email
	FROM workers JOIN people ON workers.person_id=people.id;

INSERT INTO people (name, email) VALUES ('Willy Wonka', 'willy@wonka.com');
INSERT INTO clients (person_id, notes) VALUES (1, 'chocolate guy');
INSERT INTO people (name, email) VALUES ('Oompa Loompa', 'oompa@loompa.com');
INSERT INTO workers (person_id, salary) VALUES (2, 10000);

-- params: schema name, table name, array of column names that are NOT allowed to be updated
-- RETURNS: array of column names that ARE allowed to be updated
CREATE FUNCTION cols2update(text, text, text[]) RETURNS text[] AS $$
BEGIN
	RETURN array(SELECT column_name::text FROM information_schema.columns
		WHERE table_schema=$1 AND table_name=$2 AND column_name != ALL($3));
END;
$$ LANGUAGE plpgsql;

-- params: tablename, id, json-values, array of column names that are allowed to be updated
CREATE FUNCTION jsonupdate(text, integer, json, text[]) RETURNS VOID AS $$
DECLARE
	col record;
BEGIN
	FOR col IN SELECT name FROM json_object_keys($3) AS name LOOP
		CONTINUE WHEN col.name != ALL($4);
		EXECUTE format('UPDATE %s SET %I =
			(SELECT %I FROM json_populate_record(null::%s, $1)) WHERE id = %L',
			$1, col.name, col.name, $1, $2) USING $3;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_people(integer, json) RETURNS SETOF people AS $$
BEGIN
	PERFORM jsonupdate('sivers.people', $1, $2,
		cols2update('sivers', 'people', ARRAY['id']));
	RETURN QUERY SELECT * FROM people WHERE id = $1;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_clients(integer, json) RETURNS SETOF client_view AS $$
DECLARE
	pid integer;
BEGIN
	SELECT person_id INTO pid FROM sivers.clients WHERE id = $1;
	PERFORM jsonupdate('sivers.people', pid, $2,
		cols2update('sivers', 'people', ARRAY['id']));
	PERFORM jsonupdate('sivers.clients', $1, $2,
		cols2update('sivers', 'clients', ARRAY['id']));
	RETURN QUERY SELECT * FROM client_view WHERE id = $1;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_workers(integer, json) RETURNS SETOF worker_view AS $$
DECLARE
	pid integer;
BEGIN
	SELECT person_id INTO pid FROM sivers.workers WHERE id = $1;
	PERFORM jsonupdate('sivers.people', pid, $2,
		cols2update('sivers', 'people', ARRAY['id']));
	PERFORM jsonupdate('sivers.workers', $1, $2,
		cols2update('sivers', 'workers', ARRAY['id']));
	RETURN QUERY SELECT * FROM worker_view WHERE id = $1;
END;
$$ LANGUAGE plpgsql;

COMMIT;
