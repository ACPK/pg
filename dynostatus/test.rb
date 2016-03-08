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
	def test_status_field
		DB.exec("UPDATE projects SET quoted_at=NOW() WHERE id=1")
		res = DB.exec("SELECT status FROM projects WHERE id=1")
		assert_equal 'quoted', res[0]['status']
		DB.exec("UPDATE projects SET approved_at=NOW() WHERE id=1")
		res = DB.exec("SELECT status FROM projects WHERE id=1")
		assert_equal 'approved', res[0]['status']
		DB.exec("UPDATE projects SET started_at=NOW() WHERE id=1")
		res = DB.exec("SELECT status FROM projects WHERE id=1")
		assert_equal 'started', res[0]['status']
		DB.exec("UPDATE projects SET finished_at=NOW() WHERE id=1")
		res = DB.exec("SELECT status FROM projects WHERE id=1")
		assert_equal 'finished', res[0]['status']
		# works backwards, too!
		DB.exec("UPDATE projects SET finished_at=NULL WHERE id=1")
		res = DB.exec("SELECT status FROM projects WHERE id=1")
		assert_equal 'started', res[0]['status']
		DB.exec("UPDATE projects SET started_at=NULL WHERE id=1")
		res = DB.exec("SELECT status FROM projects WHERE id=1")
		assert_equal 'approved', res[0]['status']
		DB.exec("UPDATE projects SET approved_at=NULL WHERE id=1")
		res = DB.exec("SELECT status FROM projects WHERE id=1")
		assert_equal 'quoted', res[0]['status']
		DB.exec("UPDATE projects SET quoted_at=NULL WHERE id=1")
		res = DB.exec("SELECT status FROM projects WHERE id=1")
		assert_equal 'created', res[0]['status']
	end

	def test_dates_in_order
		err = assert_raises PG::RaiseException do
			DB.exec("UPDATE projects SET finished_at=NOW() WHERE id=1")
		end
		assert err.message.include? 'dates_out_of_order'
	end
end

