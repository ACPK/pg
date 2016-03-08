SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE errors (
	incode varchar(64) primary key,
	outcode varchar(64)
);

CREATE TABLE countries (
	id serial primary key,
	code char(2) not null unique CONSTRAINT charcode CHECK (code ~ '[A-Z][A-Z]'),
	name varchar(64) not null unique,
	sqkm integer
);

CREATE TABLE cities (
	id serial primary key,
	country_id integer REFERENCES countries(id),
	name text
);

INSERT INTO countries (code, name, sqkm) VALUES ('TH', 'Thailand', 513120);
INSERT INTO cities (country_id, name) VALUES (1, 'Chiang Mai');
INSERT INTO errors (incode, outcode) VALUES ('23514', 'check_violation');
INSERT INTO errors (incode, outcode) VALUES ('23503', 'foreign_key_violation');
INSERT INTO errors (incode, outcode) VALUES ('22P02', 'invalid_text_representation');
INSERT INTO errors (incode, outcode) VALUES ('charcode', 'countries_code_2AZ');
INSERT INTO errors (incode, outcode) VALUES ('cities_country_id_fkey', 'cities_country_id_not_found');

CREATE FUNCTION err2json(code text, col text, cnstrnt text, datatype text, msg text, tbl text, detail text, hint text, context text) RETURNS json AS $$
DECLARE
	ret text;
BEGIN
	IF cnstrnt != '' THEN
		SELECT outcode INTO ret FROM errors WHERE incode = cnstrnt;
	ELSIF code != '' THEN
		SELECT outcode INTO ret FROM errors WHERE incode = code;
	END IF;
	RETURN json_build_object('code', code, 'col', col, 'cnstrnt', cnstrnt, 'datatype', datatype, 'msg', msg, 'tbl', tbl, 'detail', detail, 'hint', hint, 'context', context, 'outcode', ret);
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_country(integer, OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	SELECT row_to_json(co) INTO js FROM
		(SELECT id, code, name, sqkm, (SELECT json_agg(ci) FROM
			(SELECT id, name FROM cities WHERE country_id = $1) ci) AS cities
		FROM countries WHERE id = $1) co;
_NOTFOUND
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_city(integer, OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	SELECT row_to_json(ci) INTO js FROM
		(SELECT id, country_id, name FROM cities WHERE id = $1) ci;
_NOTFOUND
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_country(integer, json, OUT mime text, OUT js json) AS $$
DECLARE
	keyval record;
	tempval text;
_ERRVARS
BEGIN
	FOR keyval IN SELECT key, value FROM json_each($2) LOOP
		tempval := btrim(keyval.value::text, '"');
		EXECUTE 'UPDATE countries SET ' || quote_ident(keyval.key)
		|| ' = ' || quote_literal(tempval) || ' WHERE id=' || $1;
	END LOOP;
	SELECT x.mime, x.js INTO mime, js FROM get_country($1) x;
_ERRCATCH
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_city(integer, json, OUT mime text, OUT js json) AS $$
DECLARE
	keyval record;
	tempval text;
_ERRVARS
BEGIN
	FOR keyval IN SELECT key, value FROM json_each($2) LOOP
		tempval := btrim(keyval.value::text, '"');
		EXECUTE 'UPDATE cities SET ' || quote_ident(keyval.key)
		|| ' = ' || quote_literal(tempval) || ' WHERE id=' || $1;
	END LOOP;
	SELECT x.mime, x.js INTO mime, js FROM get_city($1) x;
_ERRCATCH
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION delete_country(integer, OUT mime text, OUT js json) AS $$
DECLARE
_ERRVARS
BEGIN
	SELECT x.mime, x.js INTO mime, js FROM get_country($1) x;
	DELETE FROM countries WHERE id=$1;
_ERRCATCH
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION delete_city(integer, OUT mime text, OUT js json) AS $$
DECLARE
_ERRVARS
BEGIN
	SELECT x.mime, x.js INTO mime, js FROM get_city($1) x;
	DELETE FROM cities WHERE id=$1;
_ERRCATCH
END;
$$ LANGUAGE plpgsql;

COMMIT;
