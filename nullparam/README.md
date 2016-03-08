# NULL argument

Just curious what happens in a function when I have an optional parameter than can be set to NULL.

If turned into a dynamic query, will it be NULL there?

## Answer: yes

What about doing FOREACH on an array that might be NULL?

Just put an IF $9 IS NOT NULL around the FOREACH thing.

