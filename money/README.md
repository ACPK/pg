# Money

Because anything having to do with money will always be stored with two attributes...

* currency char(3)
* amount numeric

... it seems wise to have those bundled up in a PostgreSQL type, so that money amounts with different currency codes can't be added/subtracted.

A separate table of currency codes with exchange rates would be kept for converting one amount to another.

## Example usage:

Client in Europe wants to be billed in EUR amounts.

For his project, there are a few people working on it in the U.S. and Japan. 

The U.S. worker charges 20 USD per hour.  After working for 30 minutes, his 10 USD fee is convered at today's rate of 1 USD = 0.842339 EUR, and the client gets a charge for 8.42 EUR.

The Japan worker charges 2500 JPY per hour.  After working for an hour, his 2500 JPY fee is converted at today's rate of 1 JPY = 0.00707985 EUR, and the client gets a charge for 17.70 EUR.

Client pays his bill in EUR.  The workers are paid in USD and JPY.

## Function needed?

I used to have a Ruby library to do this stuff, but looking back, it only did a few things:

* prevented amounts from being added or subtracted unless their currency codes matched
* exchanged amounts in one currency to the equivalent in another
* printed a formatted string (£10.23 British Pounds Sterling or €50 EUR)

The last one isn't necessary, since the client app can decide how to do that.  The only info needed is currency code and amount.

So really it's just four functions, each returning a new money amount:

* add_money(money, money)
* subtract_money(money, money)
* sum_money(rows_of_money)
* exchange_money(money, new_currency)

Since Bitcoin (BTC) deals in tiny (0.00000001) amounts, no need for rounding.

## Type needed?

The type name “money” is [taken](http://www.postgresql.org/docs/9.4/static/datatype-money.html), but maybe make a type like:

```
CREATE TYPE cash AS (currency char(3), amount numeric);
CREATE TABLE transactions (
	money cash,
);
```

... though I don't know the implications of that, getting values in and out of JSON hashes and such.  If too difficult then I'd rather just keep currency and amount as separate columns.

## thoughts?

No need to reinvent the wheel.  Any experience dealing with this?

## STATUS:  works!

