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
	def test_repl
		@js = '{"text": "abcde",
			"repls": [{"old": "a", "new": "YY"}, {"old": "d", "new": "ZZZ"}]}'
		res = DB.exec_params("SELECT nu FROM repl($1)", [@js])
		assert_equal 'YYbcZZZe', res[0]['nu']
	end
end

