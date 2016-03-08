require 'pg'
require 'minitest/autorun'

DB ||= PG::Connection.new(dbname: 'sivers', user: 'sivers')
SQL = File.read('sql.sql')

class Minitest::Test
	def setup
		DB.exec(SQL)
	end
end
#Minitest.after_run do
#	DB.exec(SQL)
#end

class SqlTest < Minitest::Test
	def setup
		@raw = "<h1>\r\n\tThis is a title\r\n</h1><p>\r\n\tAnd this?\r\n\tThis is a sentence.\r\n</p>"
		@lines = ['This is a title', 'And this?', 'This is a sentence.']
		@fr = ['Ceci est un titre', 'Et ça?', 'Ceci est une phrase.']
		super
	end

	def test_code
		res = DB.exec("INSERT INTO sentences (en) VALUES ('hello') RETURNING code")
		hellocode = res[0]['code']
		assert_match /[A-Za-z0-9]{8}/, hellocode
		res = DB.exec("INSERT INTO sentences (en) VALUES ('hi') RETURNING code")
		hicode = res[0]['code']
		assert_match /[A-Za-z0-9]{8}/, hicode
		res = DB.exec("SELECT en FROM sentences WHERE code = '%s'" % hellocode)
		assert_equal 'hello', res[0]['en']
		res = DB.exec("SELECT en FROM sentences WHERE code = '%s'" % hicode)
		assert_equal 'hi', res[0]['en']
	end

	def test_parse_file
		DB.exec_params("INSERT INTO files(filename, raw) VALUES ($1, $2)", ['this.txt', @raw])
		DB.exec("SELECT * FROM parse_file(1)")
		res = DB.exec("SELECT * FROM sentences WHERE file_id = 1")
		assert_match /[A-Za-z0-9]{8}/, res[0]['code']
		assert_equal '1', res[0]['sortid']
		assert_equal @lines[0], res[0]['en']
		assert_match /[A-Za-z0-9]{8}/, res[1]['code']
		assert_equal '2', res[1]['sortid']
		assert_equal @lines[1], res[1]['en']
		assert_match /[A-Za-z0-9]{8}/, res[2]['code']
		assert_equal '3', res[2]['sortid']
		assert_equal @lines[2], res[2]['en']
		res = DB.exec("SELECT template FROM files WHERE id = 1")
		assert_match /<h1>\n\{[A-Za-z0-9]{8}\}\n<\/h1><p>\n\{[A-Za-z0-9]{8}\}\n\{[A-Za-z0-9]{8}\}\n<\/p>/, res[0]['template']
	end

	def test_text_for_translator
		DB.exec_params("INSERT INTO files(filename, raw) VALUES ($1, $2)", ['this.txt', @raw])
		DB.exec("SELECT * FROM parse_file(1)")
		res = DB.exec("SELECT * FROM text_for_translator(1)")
		assert_equal @lines.join("\r\n"), res[0]['text']
	end

	def test_txn_compare
		DB.exec_params("INSERT INTO files(filename, raw) VALUES ($1, $2)", ['this.txt', @raw])
		DB.exec("SELECT * FROM parse_file(1)")
		res = DB.exec_params("SELECT * FROM txn_compare(1, $1)", [@fr.join("\r\n")])
		assert_match /[A-Za-z0-9]{8}/, res[0]['code']
		assert_equal @lines[0], res[0]['en']
		assert_equal @fr[0], res[0]['theirs']
		assert_match /[A-Za-z0-9]{8}/, res[1]['code']
		assert_equal @lines[1], res[1]['en']
		assert_equal @fr[1], res[1]['theirs']
		assert_match /[A-Za-z0-9]{8}/, res[2]['code']
		assert_equal @lines[2], res[2]['en']
		assert_equal @fr[2], res[2]['theirs']
	end

	def test_txn_update
		DB.exec_params("INSERT INTO files(filename, raw) VALUES ($1, $2)", ['this.txt', @raw])
		DB.exec("SELECT * FROM parse_file(1)")
		DB.exec_params("SELECT * FROM txn_update(1, 'fr', $1)", [@fr.join("\r\n")])
		res = DB.exec("SELECT * FROM sentences WHERE file_id=1 ORDER BY sortid")
		assert_match /[A-Za-z0-9]{8}/, res[0]['code']
		assert_equal @lines[0], res[0]['en']
		assert_equal @fr[0], res[0]['fr']
		assert_match /[A-Za-z0-9]{8}/, res[1]['code']
		assert_equal @lines[1], res[1]['en']
		assert_equal @fr[1], res[1]['fr']
		assert_match /[A-Za-z0-9]{8}/, res[2]['code']
		assert_equal @lines[2], res[2]['en']
		assert_equal @fr[2], res[2]['fr']
	end
end

