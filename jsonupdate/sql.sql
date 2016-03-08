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

-- yes, primary_key will always be integer
CREATE FUNCTION jsonupdate(table_name text, primary_key integer, new_values json) RETURNS void AS $$
DECLARE
	key record;
	tempval text;
BEGIN
	FOR key IN SELECT k FROM json_object_keys(new_values) AS k LOOP
		tempval := new_values->>key.k;
		IF tempval != 'NULL' THEN -- better way to handle NULL?
			tempval := quote_literal(tempval);
		END IF;
		-- benefits to making multi-column UPDATE statement, instead of many separate ones?
		EXECUTE 'UPDATE ' || quote_ident(table_name)
		|| ' SET ' || quote_ident(key.k) || ' = ' || tempval
		|| ' WHERE id=' || primary_key;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

-- another approach
-- TODO: quoting is broken. The whole qry building thing seems smelly.
-- TODO: get json_populate_record into var first instead of building into qry
-- Actually everything is broken, now.  Leaving here for future fixing.
CREATE FUNCTION jupdate(tablename text, primary_key integer, new_values json) RETURNS void AS $$
DECLARE
	qry text;
	colname text;
	pairs text[];
	jsrec legends;
BEGIN
	SELECT * INTO jsrec FROM json_populate_record(null::legends, new_values);
	-- goal is to make string like "col1 = nu.col1, col2 = nu.col2"
	-- but to do it with proper comma in middle, make array of pairs, then join with comma
	FOREACH colname IN ARRAY array_remove(array(SELECT * FROM json_object_keys(new_values)), 'id') LOOP
		pairs := pairs || (colname || ' = nu.' || colname);
	END LOOP;
	qry := 'UPDATE ' || quote_ident(tablename) || ' SET '
	|| array_to_string(pairs, ', ')
	|| ' FROM (' || jsrec || ') nu WHERE ' || tablename || '.id=' || primary_key;
	--|| ' FROM (SELECT * FROM json_populate_record(null::' || tablename
	-- || ', ''' || new_values || ''')) nu WHERE '
	EXECUTE qry;
END;
$$ LANGUAGE plpgsql;
COMMIT;

