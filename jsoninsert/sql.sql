SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE legends (
	id serial primary key,
	name varchar(32),
	birth_date date DEFAULT current_date,
	alive boolean
);

-- params: schema name, table name, array of column names that are NOT allowed to be updated
-- RETURNS: array of column names that ARE allowed to be updated
CREATE FUNCTION cols2update(text, text, text[]) RETURNS text[] AS $$
BEGIN
	RETURN array(SELECT column_name::text FROM information_schema.columns
		WHERE table_schema=$1 AND table_name=$2 AND column_name != ALL($3));
END;
$$ LANGUAGE plpgsql;

-- params: tablename, json-values, array of column names allowed to be used
-- Returns id (primary key) of new row
CREATE FUNCTION jsoninsert(text, json, text[], OUT id integer) AS $$
DECLARE
	cols text;
BEGIN
	SELECT array_to_string(array(SELECT unnest($3)
		INTERSECT SELECT json_object_keys($2)), ',') INTO cols;
	EXECUTE format('INSERT INTO %s(%s) SELECT %s FROM
		json_populate_record(null::%s, $1) RETURNING id',
		$1, cols, cols, $1) INTO id USING $2;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION insert_legends(json) RETURNS SETOF legends AS $$
DECLARE
	new_id integer;
BEGIN
	SELECT id INTO new_id FROM jsoninsert('sivers.legends', $1,
		cols2update('sivers', 'legends', ARRAY['id'])) x;
	RETURN QUERY SELECT * FROM legends WHERE id = new_id;
END;
$$ LANGUAGE plpgsql;

COMMIT;

