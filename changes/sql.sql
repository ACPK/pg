SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;
SET search_path = sivers;

CREATE TABLE people (
	id serial primary key,
	name varchar(32),
	email varchar(32)
);

CREATE TABLE books (
	id serial primary key,
	title varchar(32),
	price integer
);

CREATE TABLE changes (
	id serial primary key,
	person_id integer not null REFERENCES people(id),
	approved boolean default false,
	table_name varchar(32),
	table_id integer,
	field_name varchar(16),
	before text,
	after text
);

INSERT INTO people (name, email) VALUES ('Willy Wonka', 'willy@wonka.com');
INSERT INTO books (title, price) VALUES ('Book A', 12);
INSERT INTO books (title, price) VALUES ('Book B', 24);

-- copied initially from db-api/core/functions.sql
-- PARAMS: table name, id, json, person_id
CREATE OR REPLACE FUNCTION log_update(text, integer, json, integer) RETURNS VOID AS $$
DECLARE
	col record;
	be4 text;
	aft text;
BEGIN
	FOR col IN SELECT name FROM json_object_keys($3) AS name LOOP
		-- before:
		EXECUTE format ('SELECT %I::text FROM %s WHERE id = %L',
			col.name, $1, $2) INTO be4;
		-- after:
		EXECUTE format ('SELECT %I::text FROM json_populate_record(null::%s, $1)',
			col.name, $1) USING $3 INTO aft;
		-- update:
		EXECUTE format ('UPDATE %s SET %I =
			(SELECT %I FROM json_populate_record(null::%s, $1)) WHERE id = %L',
			$1, col.name, col.name, $1, $2) USING $3;
		-- log:
		INSERT INTO changes(person_id, table_name, table_id, field_name, before, after)
			VALUES ($4, $1, $2, col.name, be4, aft);
	END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ULTRA SIMPLE: just a log of what's been changed
-- PARAMS: person_id, table name, id
-- Probably don't need this to be a function. Just do an insert.
CREATE OR REPLACE FUNCTION log_change(integer, text, integer) RETURNS integer AS $$
DECLARE
	change_id integer;
BEGIN
	INSERT INTO changes(person_id, table_name, table_id)
		VALUES ($1, $2, $3) RETURNING id INTO change_id;
	RETURN change_id;
END;
$$ LANGUAGE plpgsql;

