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

	IF js IS NULL THEN
		mime := 'application/problem+json';
		js := '{"type": "about:blank", "title": "Not Found", "status": 404}';
	END IF;

END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_city(integer, OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	SELECT row_to_json(ci) INTO js FROM
		(SELECT id, country_id, name FROM cities WHERE id = $1) ci;

	IF js IS NULL THEN
		mime := 'application/problem+json';
		js := '{"type": "about:blank", "title": "Not Found", "status": 404}';
	END IF;

END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_country(integer, json, OUT mime text, OUT js json) AS $$
DECLARE
	keyval record;
	tempval text;

	err_code text;
	err_col text;
	err_cnstrnt text;
	err_datatype text;
	err_msg text;
	err_tbl text;
	err_detail text;
	err_hint text;
	err_context text;

BEGIN
	FOR keyval IN SELECT key, value FROM json_each($2) LOOP
		tempval := btrim(keyval.value::text, '"');
		EXECUTE 'UPDATE countries SET ' || quote_ident(keyval.key)
		|| ' = ' || quote_literal(tempval) || ' WHERE id=' || $1;
	END LOOP;
	SELECT x.mime, x.js INTO mime, js FROM get_country($1) x;

EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS
	err_code = RETURNED_SQLSTATE,
	err_col = COLUMN_NAME,
	err_cnstrnt = CONSTRAINT_NAME,
	err_datatype = PG_DATATYPE_NAME,
	err_msg = MESSAGE_TEXT,
	err_tbl = TABLE_NAME,
	err_detail = PG_EXCEPTION_DETAIL,
	err_hint = PG_EXCEPTION_HINT,
	err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := err2json(code := err_code,
		col := err_col,
		cnstrnt := err_cnstrnt,
		datatype := err_datatype,
		msg := err_msg,
		tbl := err_tbl,
		detail := err_detail,
		hint := err_hint,
		context := err_context);

END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_city(integer, json, OUT mime text, OUT js json) AS $$
DECLARE
	keyval record;
	tempval text;

	err_code text;
	err_col text;
	err_cnstrnt text;
	err_datatype text;
	err_msg text;
	err_tbl text;
	err_detail text;
	err_hint text;
	err_context text;

BEGIN
	FOR keyval IN SELECT key, value FROM json_each($2) LOOP
		tempval := btrim(keyval.value::text, '"');
		EXECUTE 'UPDATE cities SET ' || quote_ident(keyval.key)
		|| ' = ' || quote_literal(tempval) || ' WHERE id=' || $1;
	END LOOP;
	SELECT x.mime, x.js INTO mime, js FROM get_city($1) x;

EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS
	err_code = RETURNED_SQLSTATE,
	err_col = COLUMN_NAME,
	err_cnstrnt = CONSTRAINT_NAME,
	err_datatype = PG_DATATYPE_NAME,
	err_msg = MESSAGE_TEXT,
	err_tbl = TABLE_NAME,
	err_detail = PG_EXCEPTION_DETAIL,
	err_hint = PG_EXCEPTION_HINT,
	err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := err2json(code := err_code,
		col := err_col,
		cnstrnt := err_cnstrnt,
		datatype := err_datatype,
		msg := err_msg,
		tbl := err_tbl,
		detail := err_detail,
		hint := err_hint,
		context := err_context);

END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION delete_country(integer, OUT mime text, OUT js json) AS $$
DECLARE

	err_code text;
	err_col text;
	err_cnstrnt text;
	err_datatype text;
	err_msg text;
	err_tbl text;
	err_detail text;
	err_hint text;
	err_context text;

BEGIN
	SELECT x.mime, x.js INTO mime, js FROM get_country($1) x;
	DELETE FROM countries WHERE id=$1;

EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS
	err_code = RETURNED_SQLSTATE,
	err_col = COLUMN_NAME,
	err_cnstrnt = CONSTRAINT_NAME,
	err_datatype = PG_DATATYPE_NAME,
	err_msg = MESSAGE_TEXT,
	err_tbl = TABLE_NAME,
	err_detail = PG_EXCEPTION_DETAIL,
	err_hint = PG_EXCEPTION_HINT,
	err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := err2json(code := err_code,
		col := err_col,
		cnstrnt := err_cnstrnt,
		datatype := err_datatype,
		msg := err_msg,
		tbl := err_tbl,
		detail := err_detail,
		hint := err_hint,
		context := err_context);

END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION delete_city(integer, OUT mime text, OUT js json) AS $$
DECLARE

	err_code text;
	err_col text;
	err_cnstrnt text;
	err_datatype text;
	err_msg text;
	err_tbl text;
	err_detail text;
	err_hint text;
	err_context text;

BEGIN
	SELECT x.mime, x.js INTO mime, js FROM get_city($1) x;
	DELETE FROM cities WHERE id=$1;

EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS
	err_code = RETURNED_SQLSTATE,
	err_col = COLUMN_NAME,
	err_cnstrnt = CONSTRAINT_NAME,
	err_datatype = PG_DATATYPE_NAME,
	err_msg = MESSAGE_TEXT,
	err_tbl = TABLE_NAME,
	err_detail = PG_EXCEPTION_DETAIL,
	err_hint = PG_EXCEPTION_HINT,
	err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := err2json(code := err_code,
		col := err_col,
		cnstrnt := err_cnstrnt,
		datatype := err_datatype,
		msg := err_msg,
		tbl := err_tbl,
		detail := err_detail,
		hint := err_hint,
		context := err_context);

END;
$$ LANGUAGE plpgsql;

COMMIT;
