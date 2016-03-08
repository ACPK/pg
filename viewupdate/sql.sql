SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE people (
	id serial primary key,
	name varchar(32),
	email varchar(32) unique
);

CREATE TABLE customers (
	id serial primary key,
	person_id integer not null unique references people(id),
	currency char(3)
);

CREATE TABLE writers (
	id serial primary key,
	person_id integer not null unique references people(id),
	bio text
);

INSERT INTO people (name, email) VALUES ('Mark Twain', 'mark@twa.in');
INSERT INTO writers (person_id, bio) VALUES (1, 'curmudgeon');
INSERT INTO people (name, email) VALUES ('Steve King', 's@ki.ng');
INSERT INTO writers (person_id, bio) VALUES (2, 'horror dude');
INSERT INTO customers (person_id, currency) VALUES (2, 'USD');

CREATE VIEW customer_person AS SELECT x.*, p.name, p.email
	FROM customers x
	JOIN people p ON x.person_id=p.id;

CREATE VIEW writer_person AS SELECT x.*, p.name, p.email
	FROM writers x
	JOIN people p ON x.person_id=p.id;

-- This solves how to update name & email...
CREATE FUNCTION up2person() RETURNS TRIGGER AS $$
BEGIN
	UPDATE people SET name=NEW.name, email=NEW.email WHERE id=OLD.person_id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER customer_up2person INSTEAD OF UPDATE ON customer_person FOR EACH ROW EXECUTE PROCEDURE up2person();
CREATE TRIGGER writer_up2person INSTEAD OF UPDATE ON writer_person FOR EACH ROW EXECUTE PROCEDURE up2person();
-- ... but what about updating name, email, and (bio or currency) in one query?

-- TODO: after UPDATE solution, use it for INSERT, too

COMMIT;

