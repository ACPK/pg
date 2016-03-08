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

	def test_view_select
		res = DB.exec("SELECT * FROM writer_person ORDER BY id ASC")
		assert_equal 'Mark Twain', res[0]['name']
		assert_equal 'curmudgeon', res[0]['bio']
		assert_equal 'Steve King', res[1]['name']
		assert_equal 'horror dude', res[1]['bio']
		res = DB.exec("SELECT * FROM customer_person WHERE id=1")
		assert_equal 's@ki.ng', res[0]['email']
		assert_equal 'USD', res[0]['currency']
	end

	def test_update_person
		DB.exec("UPDATE writer_person SET email='s@king.com', name='Stephen King' WHERE id=2")
		res = DB.exec("SELECT * FROM writer_person WHERE id=2")
		assert_equal 's@king.com', res[0]['email']
		assert_equal 'Stephen King', res[0]['name']
		assert_equal 'horror dude', res[0]['bio'] # unchanged
	end

	def test_update_both
		DB.exec("UPDATE customer_person SET name='Herr King', currency='EUR' WHERE id=1")
		res = DB.exec("SELECT * FROM customer_person WHERE id=1")
		assert_equal 'Herr King', res[0]['name']
		assert_equal 'EUR', res[0]['currency'] # TEST FAILS
	end

	# TODO: make this work
	def test_insert
		DB.exec("INSERT INTO customer_person(name, email, currency) VALUES ('Dude', 'dude@du.de', 'EUR')")
		res = DB.exec("SELECT * FROM customer_person WHERE id=2")
		assert_equal '3', res[0]['person_id']
		assert_equal 'Dude', res[0]['name']
		assert_equal 'dude@du.de', res[0]['email']
		assert_equal 'EUR', res[0]['currency']
	end

end

