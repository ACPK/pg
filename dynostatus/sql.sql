SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE projects (
	id serial primary key,
	title varchar(16),
	created_at date not null default current_date,
	quoted_at date,
	approved_at date,
	started_at date,
	finished_at date,
	status varchar(8) not null default 'created'
);

CREATE FUNCTION update_status() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.quoted_at IS NULL THEN
		NEW.status := 'created';
	ELSIF NEW.approved_at IS NULL THEN
		NEW.status := 'quoted';
	ELSIF NEW.started_at IS NULL THEN
		NEW.status := 'approved';
	ELSIF NEW.finished_at IS NULL THEN
		NEW.status := 'started';
	ELSE
		NEW.status := 'finished';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER update_status BEFORE INSERT OR UPDATE ON projects FOR EACH ROW EXECUTE PROCEDURE update_status();

-- Dates must always exist in this order:
-- created_at, quoted_at, approved_at, started_at, finished_at
CREATE FUNCTION dates_in_order() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.approved_at IS NOT NULL AND NEW.quoted_at IS NULL)
		OR (NEW.started_at IS NOT NULL AND NEW.approved_at IS NULL)
		OR (NEW.finished_at IS NOT NULL AND NEW.started_at IS NULL)
		OR (NEW.started_at IS NULL AND NEW.finished_at IS NOT NULL)
		OR (NEW.approved_at IS NULL AND NEW.started_at IS NOT NULL)
		OR (NEW.quoted_at IS NULL AND NEW.approved_at IS NOT NULL)
		THEN RAISE 'dates_out_of_order';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER dates_in_order BEFORE INSERT OR UPDATE ON projects FOR EACH ROW EXECUTE PROCEDURE dates_in_order();

INSERT INTO projects (title, created_at, quoted_at, approved_at, started_at, finished_at) VALUES ('1= created', '2015-01-01', null, null, null, null);
INSERT INTO projects (title, created_at, quoted_at, approved_at, started_at, finished_at) VALUES ('2= quoted', '2015-01-01', '2015-01-02', null, null, null);
INSERT INTO projects (title, created_at, quoted_at, approved_at, started_at, finished_at) VALUES ('3= approved', '2015-01-01', '2015-01-02', '2015-01-03', null, null);
INSERT INTO projects (title, created_at, quoted_at, approved_at, started_at, finished_at) VALUES ('4= started', '2015-01-01', '2015-01-02', '2015-01-03', '2015-01-04', null);
INSERT INTO projects (title, created_at, quoted_at, approved_at, started_at, finished_at) VALUES ('5= finished', '2015-01-01', '2015-01-02', '2015-01-03', '2015-01-04', '2015-01-05');
COMMIT;

