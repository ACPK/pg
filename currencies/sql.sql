SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE currencies (
	code char(3) primary key
);

CREATE TABLE currency_rates (
	code char(3) NOT NULL REFERENCES currencies(code),
	day date NOT NULL DEFAULT current_date,
	rate numeric,
	PRIMARY KEY (code, day)
);

INSERT INTO currencies (code) VALUES ('USD');
INSERT INTO currencies (code) VALUES ('EUR');
INSERT INTO currencies (code) VALUES ('JPY');
INSERT INTO currencies (code) VALUES ('BTC');

INSERT INTO currency_rates (code, day, rate) VALUES ('USD', '2015-09-12', 1);
INSERT INTO currency_rates (code, day, rate) VALUES ('EUR', '2015-09-12', 0.881602);
INSERT INTO currency_rates (code, day, rate) VALUES ('JPY', '2015-09-12', 120.6708);
INSERT INTO currency_rates (code, day, rate) VALUES ('BTC', '2015-09-12', 0.0043424245);

-- PARAMS: JSON of currency rates https://openexchangerates.org/documentation
CREATE OR REPLACE FUNCTION update_currency_rates(jsonb) RETURNS void AS $$
DECLARE
	rates jsonb;
	acurrency currencies;
	acode text;
	arate numeric;
BEGIN
	rates := jsonb_extract_path($1, 'rates');
	FOR acurrency IN SELECT * FROM currencies LOOP
		acode := acurrency.code;
		arate := CAST((rates ->> acode) AS numeric);
		INSERT INTO currency_rates (code, rate) VALUES (acode, arate);
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;

-- PARAMS: amount, from.code to.code
CREATE OR REPLACE FUNCTION currency_from_to(numeric, text, text, OUT amount numeric) AS $$
BEGIN
	IF $2 = 'USD' THEN
		SELECT ($1 * rate) INTO amount FROM currency_rates WHERE code = $3
			ORDER BY day DESC LIMIT 1;
	ELSIF $3 = 'USD' THEN
		SELECT ($1 / rate) INTO amount FROM currency_rates WHERE code = $2
			ORDER BY day DESC LIMIT 1;
	ELSE
		SELECT (
			(SELECT $1 / rate FROM currency_rates WHERE code = $2
				ORDER BY day DESC LIMIT 1) * rate) INTO amount
			FROM currency_rates WHERE code = $3 ORDER BY day DESC LIMIT 1;
	END IF;
END;
$$ LANGUAGE plpgsql;

COMMIT;

