SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE projects (
	id serial primary key,
	title varchar(32),
	started_at date
);

INSERT INTO projects (title, started_at) VALUES ('has started', NOW());
INSERT INTO projects (title, started_at) VALUES ('not started', NULL);

CREATE FUNCTION started_lock() RETURNS TRIGGER AS $$
BEGIN
	IF OLD.started_at IS NOT NULL THEN
		RAISE 'project_locked';
	ELSIF TG_OP = 'UPDATE' THEN
		RETURN NEW;
	ELSE
		RETURN OLD;
	END IF;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER started_lock BEFORE DELETE OR UPDATE OF title ON projects FOR EACH ROW EXECUTE PROCEDURE started_lock();

COMMIT;

