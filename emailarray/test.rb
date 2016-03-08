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
	def test_simple_find
		res = DB.exec("SELECT * FROM people WHERE 'derek@sivers.org' = ANY(emails)")
		assert_equal '1', res[0]['id']
		res = DB.exec("SELECT * FROM people WHERE 'vsalt@gmail.com' = ANY(emails)")
		assert_equal '3', res[0]['id']
	end

	def test_primary
		res = DB.exec("SELECT emails[1] AS email FROM people ORDER BY id")
		assert_equal 'derek@sivers.org', res[0]['email']
		assert_equal 'willy@wonka.com', res[1]['email']
		assert_equal 'veruca@salt.com', res[2]['email']
	end

	def test_make_primary
		nu = 'vsalt@gmail.com'
		DB.exec_params("UPDATE people SET emails = array_prepend($1, array_remove(emails, $2)) WHERE id = $3", [nu, nu, 3])
		res = DB.exec("SELECT emails[1] AS email FROM people WHERE id = 3")
		assert_equal nu, res[0]['email']
		nu = 'willy@wonka.com'
		DB.exec_params("UPDATE people SET emails = array_prepend($1, array_remove(emails, $2)) WHERE id = $3", [nu, nu, 2])
		res = DB.exec("SELECT emails[1] AS email FROM people WHERE id = 2")
		assert_equal nu, res[0]['email']
	end
end

