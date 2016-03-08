SET client_min_messages TO ERROR;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;
SET search_path = sivers;

CREATE TABLE stuff (
	id serial primary key,
	letter char(1) unique
);
INSERT INTO stuff (letter) VALUES ('m');
INSERT INTO stuff (letter) VALUES ('t');
INSERT INTO stuff (letter) VALUES ('z');

-- give json with key "x" that has array
CREATE FUNCTION count_x(json, OUT found_id integer, OUT counter integer) AS $$
BEGIN
	-- count array
	counter := json_array_length($1 -> 'x');
	-- check array size:
	IF counter > 0 THEN
		-- find stuff in array
		SELECT id INTO found_id FROM stuff WHERE letter IN
			(SELECT * FROM json_array_elements_text($1 -> 'x'));
	END IF;
END;
$$ LANGUAGE plpgsql;

