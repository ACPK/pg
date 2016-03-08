# Translation project

I almost made it a whole new repository, but instead I'll just experiment here.

Ruby + PostgreSQL project to parse a file, send it to Gengo, get it back, unparse it, turn into many languages.

## STATUS: Works!

Tried it in Ruby, but surprisingly, this PL/pgSQL version is just as nice.

1. INSERT INTO files(filename, raw) VALUES ('myfile.txt', 'the text of the file here')
2. SELECT * FROM parse_file(123)
3. SELECT text FROM text_for_translator(123)
4. Send that text file to Gengo. When I get it back....
5. SELECT * FROM txn_compare(123, 'their translated file text here')
6. Everything look OK?  Check last line in particular.  If so...
7. SELECT * FROM txn_update(123, 'zh', 'their translated file text here')
8. SELECT * FROM merge(123, 'zh')

