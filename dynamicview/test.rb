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
	def test_ex
		res = DB.exec("SELECT js FROM ex('en', 1)")
		assert_equal '{"id":1,"exclamation":"wow"}', res[0]['js']
		res = DB.exec("SELECT js FROM ex('zh', 1)")
		assert_equal '{"id":1,"exclamation":"哇"}', res[0]['js']
		res = DB.exec("SELECT js FROM ex('es', 2)")
		assert_equal '{"id":2,"exclamation":"increíble"}', res[0]['js']
	end
end

