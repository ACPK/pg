SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TYPE currency AS ENUM ('USD', 'EUR', 'JPY', 'BTC');
CREATE TYPE currency_amount AS (currency currency, amount numeric);

CREATE TABLE currency_rates (
	code currency NOT NULL,
	day date NOT NULL DEFAULT current_date,
	rate numeric,
	PRIMARY KEY (code, day)
);

INSERT INTO currency_rates (code, day, rate) VALUES ('USD', '2015-09-12', 1);
INSERT INTO currency_rates (code, day, rate) VALUES ('EUR', '2015-09-12', 0.881602);
INSERT INTO currency_rates (code, day, rate) VALUES ('JPY', '2015-09-12', 120.6708);
INSERT INTO currency_rates (code, day, rate) VALUES ('BTC', '2015-09-12', 0.0043424245);

-- PARAMS: JSON of currency rates https://openexchangerates.org/documentation
CREATE OR REPLACE FUNCTION update_currency_rates(jsonb) RETURNS void AS $$
DECLARE
	rates jsonb;
	acode currency;
	arate numeric;
BEGIN
	rates := jsonb_extract_path($1, 'rates');
	FOR acode IN SELECT code FROM currency_rates LOOP
		arate := CAST((rates ->> acode::text) AS numeric);
		INSERT INTO currency_rates (code, rate) VALUES (acode, arate);
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;

-- PARAMS: amount, from.code to.code
CREATE OR REPLACE FUNCTION currency_from_to(numeric, currency, currency, OUT amount numeric) AS $$
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

