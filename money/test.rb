require 'pg'
require 'minitest/autorun'
require 'json'

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
	def test_one
		res = DB.exec("SELECT row_to_json(r) AS js FROM (SELECT * FROM transactions WHERE id = 1) r")
		j = JSON.parse(res[0]['js'], symbolize_names: true)
		r = {:id=>1, :money=>{:currency=>'USD', :amount=>12.34}}
		assert_equal(r, j)
	end
end

