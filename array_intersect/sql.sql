SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE FUNCTION array_intersect(anyarray, anyarray) RETURNS anyarray AS $$
	SELECT array(
		SELECT unnest($1) INTERSECT SELECT unnest($2)
	);
$$ LANGUAGE sql;

COMMIT;

