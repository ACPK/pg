SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE FUNCTION repl(jsonb, OUT nu text) AS $$
DECLARE
	o record;
BEGIN
	nu := $1->>'text';
	FOR o IN SELECT * FROM jsonb_array_elements($1->'repls') LOOP
		nu := replace(nu, o.value->>'old', o.value->>'new');
	END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMIT;

