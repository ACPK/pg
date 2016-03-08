SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TYPE currency AS ENUM ('USD', 'EUR', 'NZD');
CREATE TYPE currency_amount AS (currency currency, amount numeric);

CREATE TABLE transactions (
	id serial primary key,
	money currency_amount
);

INSERT INTO transactions (money) VALUES (('USD', 12.34));

COMMIT;

