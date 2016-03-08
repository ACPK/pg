SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE files (
	id serial primary key,
	filename varchar(64) not null unique,
	raw text,
	template text
);
-- INSERT INTO files (filename, raw) VALUES ('this.txt', E'<h1>\n\tThis is a title\n</h1><p>\n\tAnd this?\n\tThis is a sentence.\n</p>');

CREATE TABLE sentences (
	code char(8) primary key,
	file_id integer REFERENCES files(id),
	sortid integer,
	en text,
	fr text,
	es text,
	zh text
);

CREATE OR REPLACE FUNCTION parse_file(fileid integer) RETURNS text AS $$
DECLARE
	lines text[];
	line text;
	new_template text := '';
	sid integer := 0;
	one_code char(8);
BEGIN
	SELECT regexp_split_to_array(raw, E'\n') INTO lines FROM files WHERE id = $1;
	FOREACH line IN ARRAY lines LOOP
		IF E'\t' = substring(line from 1 for 1) THEN
			sid := sid + 1;
			INSERT INTO sentences(file_id, sortid, en)
				VALUES ($1, sid, btrim(line, E'\t')) RETURNING code INTO one_code;
			new_template := new_template || '{' || one_code || '}' || E'\n';
		ELSE
			new_template := new_template || line || E'\n';
		END IF;
	END LOOP;
	UPDATE files SET template = rtrim(new_template, E'\n') WHERE id = $1;
	RETURN rtrim(new_template, E'\n');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION text_for_translator(fileid integer, OUT text text) AS $$
BEGIN
	text := string_agg(en, E'\r\n') FROM
		(SELECT en FROM sentences WHERE file_id = $1 ORDER BY sortid) s;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION txn_compare(file_id integer, translation text)
RETURNS TABLE(code char(8), en text, theirs text) AS $$
BEGIN
	-- TODO: stop and notify if split array has more lines than database?
	RETURN QUERY
	WITH t2 AS (SELECT * FROM
		UNNEST(regexp_split_to_array(replace($2, E'\r', ''), E'\n'))
		WITH ORDINALITY AS theirs)
		SELECT t1.code, t1.en, t2.theirs FROM sentences t1
		INNER JOIN t2 ON t1.sortid=t2.ordinality
		WHERE t1.file_id=$1
		ORDER BY sortid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION txn_update(file_id integer, lang text, translation text) RETURNS boolean AS $$
DECLARE
	atxn RECORD;
BEGIN
	FOR atxn IN SELECT code, theirs FROM txn_compare($1, $3) LOOP
		EXECUTE 'UPDATE sentences SET ' || quote_ident(lang) || ' = $2 WHERE code = $1'
			USING atxn.code, atxn.theirs;
	END LOOP;
	RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION merge(file_id integer, lang text) RETURNS text AS $$
DECLARE
	merged text;
	a RECORD;
BEGIN
	SELECT files.template INTO merged FROM files WHERE id = $1;
	FOR a IN EXECUTE ('SELECT code, ' || quote_ident(lang) ||
		' AS tx FROM sentences WHERE file_id = ' || $1) LOOP
		merged := replace(merged, '{' || a.code || '}', a.tx);
	END LOOP;
	RETURN merged;
END;
$$ LANGUAGE plpgsql;

-- No Windows \r carriage return in raw:
CREATE OR REPLACE FUNCTION clean_raw() RETURNS TRIGGER AS $$
BEGIN
	NEW.raw = replace(NEW.raw, E'\r', '');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_raw ON files CASCADE;
CREATE TRIGGER clean_raw
	BEFORE INSERT OR UPDATE OF raw ON files
	FOR EACH ROW EXECUTE PROCEDURE clean_raw();


-- COPIED FROM /pg/randomid/ PROJECT HERE:

CREATE OR REPLACE FUNCTION random_string(length integer) RETURNS text AS $$
DECLARE
	chars text[] := '{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
	result text := '';
	i integer := 0;
BEGIN
	FOR i IN 1..length LOOP
		result := result || chars[1+random()*(array_length(chars, 1)-1)];
	END LOOP;
	RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION codegen() RETURNS TRIGGER AS $$
DECLARE
	new_code text := random_string(8);
BEGIN
	LOOP
		PERFORM 1 FROM sentences WHERE code=new_code;
		IF NOT FOUND THEN
			NEW.code := new_code;
			RETURN NEW;
		END IF;
		new_code := random_string(8);
	END LOOP;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER codegen
	BEFORE INSERT ON sentences
	FOR EACH ROW WHEN (NEW.code IS NULL)
	EXECUTE PROCEDURE codegen();

COMMIT;
