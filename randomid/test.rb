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
		res = DB.exec("INSERT INTO things (name) VALUES ('one') RETURNING *")
		assert_match /[a-zA-Z0-9]{4}/, res[0]['id']
		res = DB.exec("INSERT INTO things (name) VALUES ('two') RETURNING *")
		assert_match /[a-zA-Z0-9]{4}/, res[0]['id']
	end
end

