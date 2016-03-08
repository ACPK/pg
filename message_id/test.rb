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
	def test_create
		res = DB.exec("INSERT INTO emails(outgoing, person_id, subject) VALUES (true, 9876, 'hi') RETURNING *")
		assert_match /\A[0-9]{17}\.9876@sivers.org\Z/, res[0]['message_id']
		# full format: Time.now.strftime('%Y%m%d%H%M%S%L')
		assert_equal res[0]['message_id'][0,12], Time.now.strftime('%Y%m%d%H%M')
	end
end

