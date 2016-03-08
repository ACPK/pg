SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

-- example table for testing setting boolean, NULL, and NOW()

CREATE TABLE legends (
	id serial primary key,
	name varchar(32),
	birth_date date,
	alive boolean
);

INSERT INTO legends (name, birth_date, alive) VALUES ('Aesop', NULL, false);

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

CREATE FUNCTION update_legends(integer, json) RETURNS SETOF legends AS $$
BEGIN
	PERFORM jsonupdate('sivers.legends', $1, $2,
		cols2update('sivers', 'legends', ARRAY['id']));
	RETURN QUERY SELECT * FROM legends WHERE id = $1;
END;
$$ LANGUAGE plpgsql;

COMMIT;
