SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE urls (
	id serial primary key,
	url text
);

CREATE FUNCTION clean_url() RETURNS TRIGGER AS $$
BEGIN
	NEW.url := regexp_replace(NEW.url, '[\r\n\t\ ]', '', 'g');
	IF NEW.url !~ '\Ahttps?://' THEN
		NEW.url = CONCAT('http://', NEW.url);
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER clean_url BEFORE INSERT OR UPDATE ON urls FOR EACH ROW EXECUTE PROCEDURE clean_url();

COMMIT;

