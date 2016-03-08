# Email array?

For a long time I've been wondering how to deal with people who use multiple email addresses.

Here I'm going to try storing them as an array.

Usage:

* outgoing emails (send to) : use 1st value
* authentication : can use either
* add/remove emails
* update emails : (a combination remove+add)
* make primary: move one to start of array
* LIKE search for '%@company%'
* validate values inside array match regexp '\A\S+@\S+\.\S+\Z'

Also important to make sure that this doesn't add a lot of complexity, since 99.99% of people have use just one email address with me.

## WARNING against:

PostgreSQL documentation says, “Tip: Arrays are not sets; searching for specific array elements can be a sign of database misdesign. Consider using a separate table with a row for each item that would be an array element. This will be easier to search, and is likely to scale better for a large number of elements.”

## status: started


