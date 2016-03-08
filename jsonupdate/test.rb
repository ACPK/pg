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
	def test_regular_update
		DB.exec_params("SELECT jsonupdate($1, $2, $3)",
			['legends', 1, '{"name": "Dude", "alive": true, "birth_date": "1920-01-01"}'])
		res = DB.exec("SELECT * FROM legends WHERE id = 1")
		assert_equal 'Dude', res[0]['name']
		assert_equal 't', res[0]['alive']
		assert_equal '1920-01-01', res[0]['birth_date']
	end

	def test_utf8
		DB.exec_params("SELECT jsonupdate($1, $2, $3)", ['legends', 1, '{"name": "þí¥維"}'])
		res = DB.exec("SELECT * FROM legends WHERE id = 1")
		assert_equal 'þí¥維', res[0]['name']
	end

	def test_injection
		DB.exec_params("SELECT jsonupdate($1, $2, $3)", ['legends', 1, %q({"name": "d'a"})])
		res = DB.exec("SELECT * FROM legends WHERE id = 1")
		assert_equal "d'a", res[0]['name']
		# TODO: what's proper technique for JSON value with quotes?
	end

	def test_null
		DB.exec_params("SELECT jsonupdate($1, $2, $3)", ['legends', 1, '{"alive": "NULL"}'])
		res = DB.exec("SELECT * FROM legends WHERE id = 1")
		assert_nil res[0]['alive']
	end

	def test_now
		DB.exec_params("SELECT jsonupdate($1, $2, $3)", ['legends', 1, '{"birth_date": "NOW()"}'])
		res = DB.exec("SELECT * FROM legends WHERE id = 1")
		assert_equal Time.now.to_s[0,10], res[0]['birth_date']
	end

	# note JSON boolean works as unquoted true/false, or quoted "true"/"false", or quoted "t"/"f"
	def test_boolean
		DB.exec_params("SELECT jsonupdate($1, $2, $3)", ['legends', 1, '{"alive": true}'])
		res = DB.exec("SELECT * FROM legends WHERE id = 1")
		# Ruby 'pg' library doesn't convert result into boolean. leaves as 't'/'f' string.
		assert_equal 't', res[0]['alive']
		DB.exec_params("SELECT jsonupdate($1, $2, $3)", ['legends', 1, '{"alive": "false"}'])
		res = DB.exec("SELECT * FROM legends WHERE id = 1")
		assert_equal 'f', res[0]['alive']
		DB.exec_params("SELECT jsonupdate($1, $2, $3)", ['legends', 1, '{"alive": "t"}'])
		res = DB.exec("SELECT * FROM legends WHERE id = 1")
		assert_equal 't', res[0]['alive']
	end

end
