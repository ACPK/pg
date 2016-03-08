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
	def test_spaces
		res = DB.exec("INSERT INTO urls(url) VALUES ('  \r \n \thttp://dude.com \r') RETURNING url")
		assert_equal 'http://dude.com', res[0]['url']
	end

	def test_https
		res = DB.exec("INSERT INTO urls(url) VALUES (' https://bank.com/') RETURNING url")
		assert_equal 'https://bank.com/', res[0]['url']
	end

	def test_add_http
		res = DB.exec("INSERT INTO urls(url) VALUES ('me.com') RETURNING url")
		assert_equal 'http://me.com', res[0]['url']
	end
end

