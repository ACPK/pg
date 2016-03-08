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
	def test_it
		res = DB.exec("SELECT array_intersect(array['a', 'b', 'c', 'd', 'e'], array['a', 'e', 'i']) AS nu")
		assert_equal '{a,e}', res[0]['nu']
	end
end

