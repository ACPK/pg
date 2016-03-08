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

	def test_raw
		res = DB.exec("INSERT INTO transactions(money) VALUES (('EUR', 56.115)) RETURNING *")
		assert_equal '(EUR,56.115)', res[0]['money']
	end

	def test_bad_cur
		assert_raises PG::InvalidTextRepresentation do
			DB.exec("INSERT INTO transactions(money) VALUES (('EUX', 56.115)) RETURNING *")
		end
	end
end

