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
	def test_copylong1
		res = DB.exec("SELECT * FROM copylong1(1, 2)")
		assert_equal 'New Person', res[0]['name']
		assert_equal 'Address 2', res[0]['address']
		assert_equal 'Singapore', res[0]['city']
		assert_equal 'SG', res[0]['state']
		assert_equal '02121', res[0]['postalcode']
		assert_equal '1-312-920-1566', res[0]['phone']
	end

	def test_copylong2
		res = DB.exec("SELECT * FROM copylong2(1, 2)")
		assert_equal 'New Person', res[0]['name']
		assert_equal 'Address 2', res[0]['address']
		assert_equal 'Singapore', res[0]['city']
		assert_equal 'SG', res[0]['state']
		assert_equal '02121', res[0]['postalcode']
		assert_equal '1-312-920-1566', res[0]['phone']
	end
end

