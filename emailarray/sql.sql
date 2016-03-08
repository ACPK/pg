SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE people (
	id serial primary key,
	emails text[]
);

INSERT INTO people (emails) VALUES ('{"derek@sivers.org", "derek@hotmail.com"}');
INSERT INTO people (emails) VALUES ('{"willy@wonka.com"}');
INSERT INTO people (emails) VALUES ('{"veruca@salt.com", "veruca@hotmail.com", "vsalt@gmail.com"}');

COMMIT;
