require 'pg'
require 'minitest/autorun'

DB = PG::Connection.new(dbname: 'sivers', user: 'sivers')
SQL = File.read('sql.sql')

class Minitest::Test
	def setup
		DB.exec(SQL)
	end
end

class SqlTest < Minitest::Test
	def test_add
		DB.exec("INSERT INTO comments (uri, name, comment) VALUES ('trust', 'name³', 'þree')")
		DB.exec("INSERT INTO comments (uri, name, comment) VALUES ('newpost', 'Dude', 'wow')")
	end
end

