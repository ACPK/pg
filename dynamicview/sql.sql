SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE exclamations (
	id serial primary key,
	en varchar(16),
	es varchar(16),
	zh varchar(16)
);

CREATE FUNCTION exview(char(2), integer) RETURNS text AS $$
	SELECT FORMAT ('SELECT id, %I AS exclamation FROM exclamations WHERE id=%L', $1, $2);
$$ LANGUAGE SQL;

CREATE FUNCTION ex(char(2), integer, OUT js json) AS $$
BEGIN
	EXECUTE 'SELECT row_to_json(r) FROM (' || exview($1, $2) || ') r' INTO js;
END;
$$ LANGUAGE plpgsql;

INSERT INTO exclamations (en, es, zh) VALUES ('wow', 'guau', '哇');
INSERT INTO exclamations (en, es, zh) VALUES ('incredible', 'increíble', '惊人');
COMMIT;

