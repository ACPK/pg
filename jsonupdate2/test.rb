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
		res = DB.exec_params("SELECT * FROM update_legends($1, $2)",
			[1, '{"name": "Dude", "alive": true, "birth_date": "1920-01-01"}'])
		assert_equal 'Dude', res[0]['name']
		assert_equal 't', res[0]['alive']
		assert_equal '1920-01-01', res[0]['birth_date']
	end

	def test_utf8
		res = DB.exec_params("SELECT * FROM update_legends($1, $2)", [1, '{"name": "þí¥維"}'])
		assert_equal 'þí¥維', res[0]['name']
	end

	def test_injection
		res = DB.exec_params("SELECT * FROM update_legends($1, $2)", [1, %q({"name": "d'a"})])
		assert_equal "d'a", res[0]['name']
		res = DB.exec_params("SELECT * FROM update_legends($1, $2)", [1, %q({"name": "the \"dog\""})])
		assert_equal 'the "dog"', res[0]['name']
	end

	# null has to be lowercase unquoted in JSON!
	def test_null
		err = assert_raises PG::InvalidTextRepresentation do
			DB.exec_params("SELECT * FROM update_legends($1, $2)", [1, '{"alive": "NULL"}'])
		end
		err = assert_raises PG::InvalidTextRepresentation do
			DB.exec_params("SELECT * FROM update_legends($1, $2)", [1, '{"alive": NULL}'])
		end
		res = DB.exec_params("SELECT * FROM update_legends($1, $2)", [1, '{"alive": null}'])
		assert_nil res[0]['alive']
	end

	def test_now
		res = DB.exec_params("SELECT * FROM update_legends($1, $2)", [1, '{"birth_date": "NOW()"}'])
		assert_equal Time.now.to_s[0,10], res[0]['birth_date']
	end

	# note JSON boolean works as unquoted true/false, or quoted "true"/"false", or quoted "t"/"f"
	def test_boolean
		res = DB.exec_params("SELECT * FROM update_legends($1, $2)", [1, '{"alive": true}'])
		# Ruby 'pg' library doesn't convert result into boolean. leaves as 't'/'f' string.
		assert_equal 't', res[0]['alive']
		res = DB.exec_params("SELECT * FROM update_legends($1, $2)", [1, '{"alive": "false"}'])
		assert_equal 'f', res[0]['alive']
		res = DB.exec_params("SELECT * FROM update_legends($1, $2)", [1, '{"alive": "t"}'])
		assert_equal 't', res[0]['alive']
	end

	# now I can throw any garbage at it, and it only uses the good stuff
	def test_garbage
		res = DB.exec_params("SELECT * FROM update_legends($1, $2)", [1, '{"name": "bob", "dog": "fido", "alive": true, "age": 99}'])
		assert_equal 'bob', res[0]['name']
		assert_equal 't', res[0]['alive']
	end
end
