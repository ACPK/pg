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
	def test_reply
		res = DB.exec_params("SELECT * FROM reply_to($1, $2)", [1, 'Right on!'])
		assert_equal '2', res[0]['id']
		assert_equal 're: hi', res[0]['subject']
		assert_match /\ARight on!\n\n/, res[0]['body']
		assert_match /^> You made sense.$/, res[0]['body']
		assert_match /^> Me, me@me.me\Z/, res[0]['body']
	end
end

