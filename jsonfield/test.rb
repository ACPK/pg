require 'pg'
require 'minitest/autorun'

DB = PG::Connection.new(dbname: 'sivers', user: 'sivers')
SQL = File.read('sql.sql')

class Minitest::Test
	def setup
		DB.exec(SQL)
	end
end
Minitest.after_run do
	DB.exec(SQL)
end

class SqlTest < Minitest::Test
	def test_count_none_found
		res = DB.exec_params("SELECT * FROM count_x($1)", ['{"a": "b", "x": ["y","q"]}'])
		assert_equal nil, res[0]['found_id']
		assert_equal '2', res[0]['counter']
	end

	def test_count_found
		res = DB.exec_params("SELECT * FROM count_x($1)", ['{"a": "b", "x": ["y","z"]}'])
		assert_equal '3', res[0]['found_id']
		assert_equal '2', res[0]['counter']
	end

	def test_empty
		res = DB.exec_params("SELECT * FROM count_x($1)", ['{"a": "b", "x": []}'])
		assert_equal nil, res[0]['found_id']
		assert_equal '0', res[0]['counter']
	end

	def test_missing   # no errors thrown! nice!
		res = DB.exec_params("SELECT * FROM count_x($1)", ['{"a": "b", "o": []}'])
		assert_equal nil, res[0]['found_id']
		assert_equal nil, res[0]['counter']
	end
end

