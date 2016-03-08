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
	def test_yes_update
		res = DB.exec("UPDATE projects SET title='ok' WHERE id=2")
		assert_equal 1, res.cmd_tuples
		res = DB.exec("SELECT * FROM projects WHERE id=2")
		assert_equal 'ok', res[0]['title']
	end

	def test_yes_delete
		DB.exec("DELETE FROM projects WHERE id=2")
		res = DB.exec("SELECT * FROM projects WHERE id=2")
		assert_equal 0, res.ntuples
	end

	def test_no_update
		err = assert_raises PG::RaiseException do
			DB.exec("UPDATE projects SET title='ok' WHERE id=1")
		end
		assert err.message.include? 'project_locked'
	end

	def test_no_delete
		err = assert_raises PG::RaiseException do
			DB.exec("DELETE FROM projects WHERE id=1")
		end
		assert err.message.include? 'project_locked'
	end

	def test_update_date
		res = DB.exec("UPDATE projects SET started_at=NULL WHERE id=1")
		assert_equal 1, res.cmd_tuples
		res = DB.exec("UPDATE projects SET title='now ok' WHERE id=1")
		assert_equal 1, res.cmd_tuples
		res = DB.exec("SELECT title FROM projects WHERE id=1")
		assert_equal 'now ok', res[0]['title']
	end
end

