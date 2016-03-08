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
	def test_junk_ignored
		res = DB.exec_params("SELECT * FROM update_people($1, $2)",
			[1, '{"name": "Bill Wonka", "ignore": "this", "extra": "junk"}'])
		assert_equal 'Bill Wonka', res[0]['name']
	end

	def test_regular_update
		res = DB.exec_params("SELECT * FROM update_clients($1, $2)",
			[1, '{"name": "Bill Wonka", "notes": "Gene, not Johnny"}'])
		assert_equal 'Bill Wonka', res[0]['name']
		assert_equal 'Gene, not Johnny', res[0]['notes']
	end

	def test_regular_update2
		res = DB.exec_params("SELECT * FROM update_workers($1, $2)",
			[1, '{"name": "Ümpa Lümpa", "email": "o@l.mm", "salary": 20000}'])
		assert_equal 'Ümpa Lümpa', res[0]['name']
		assert_equal 'o@l.mm', res[0]['email']
		assert_equal '20000', res[0]['salary']
	end

	# now I can throw any garbage at it, and it only uses the good stuff
	def test_garbage
		res = DB.exec_params("SELECT * FROM update_clients($1, $2)",
			[1, '{"email": "w@w.w", "dog": "fido", "notes": "foo", "age": 99}'])
		assert_equal 'w@w.w', res[0]['email']
		assert_equal 'foo', res[0]['notes']
	end

	# person_id can be changed
	def test_person_id
		res = DB.exec_params("SELECT * FROM update_workers($1, $2)",
			[1, '{"person_id": 1}'])
		assert_equal 'Willy Wonka', res[0]['name']
	end

	# id can't be changed
	def test_id
		res = DB.exec_params("SELECT * FROM update_clients($1, $2)",
			[1, '{"id": 9, "notes": "foo", "name": "WW"}'])
		assert_equal 'WW', res[0]['name']
		assert_equal 'foo', res[0]['notes']
		assert_equal '1', res[0]['id']
		assert_equal '1', res[0]['person_id']
	end

end
