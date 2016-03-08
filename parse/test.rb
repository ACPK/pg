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
	def test_parse
		res = DB.exec("SELECT * FROM parse_formletter(1, 1)")
		assert_equal 'Hi Willy Wonka at willy@wonka.com, age 50', res.getvalue(0,0)
	end
end

