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
	def test_thing
		res = DB.exec("SELECT * FROM new_person('Dude', 1)")
		assert_equal '1', res[0]['rank']
		res = DB.exec("SELECT * FROM new_person('Dude', NULL)")
		assert_equal nil, res[0]['rank']
	end

	def test_array
		DB.exec("SELECT * FROM many_ranks(ARRAY[1,2,3])");
		# needs IF NOT NULL to not crash:
		DB.exec("SELECT * FROM many_ranks(NULL)");
	end
end


