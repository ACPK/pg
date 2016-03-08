SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TYPE currency AS ENUM ('USD', 'EUR', 'NZD');
CREATE TYPE currency_amount AS (currency currency, amount numeric);

CREATE TABLE customers (
	id serial primary key,
	currency currency not null default 'USD',
	balance currency_amount not null default('USD',0)
);

CREATE TABLE transactions (
	id serial primary key,
	money currency_amount not null
);

INSERT INTO transactions (money) VALUES (('USD', 12.34));

COMMIT;

