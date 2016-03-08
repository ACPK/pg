require 'pg'
require 'minitest/autorun'
require 'json'

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

	# use log_update function to make the update and log it
	# PRO: one function call, has detailed before-and-after text saved
	# CON: every update to every table needs to run through this one function
	def test_update_1
		nu = {title: 'Nu B', price: 99}
		DB.exec_params("SELECT log_update($1, $2, $3, $4)",
			['sivers.books', 2, nu.to_json, 1])
		res = DB.exec("SELECT * FROM sivers.books WHERE id = 2")
		assert_equal nu[:title], res[0]['title']
		assert_equal nu[:price], res[0]['price'].to_i
		res = DB.exec("SELECT * FROM sivers.changes ORDER BY id")
		assert_equal 2, res.ntuples
		x = res[0]
		assert_equal '1', x['id']
		assert_equal '1', x['person_id']
		assert_equal 'sivers.books', x['table_name']
		assert_equal '2', x['table_id']
		assert_equal 'title', x['field_name']
		assert_equal 'Book B', x['before']
		assert_equal 'Nu B', x['after']
		x = res[1]
		assert_equal '2', x['id']
		assert_equal '1', x['person_id']
		assert_equal 'sivers.books', x['table_name']
		assert_equal '2', x['table_id']
		assert_equal 'price', x['field_name']
		assert_equal '24', x['before']
		assert_equal '99', x['after']
	end

	# use two calls: one to update/insert/whatever, next to log it
	# PRO: keep using whatever API functions I would anyway, no functions needed.
	# CON: two calls, no details! just id of what's changed
	def test_update_2
		DB.exec("UPDATE sivers.books SET title='Nu B', price=99 WHERE id=2")
		DB.exec("INSERT INTO changes(person_id, table_name, table_id)
			VALUES(1, 'sivers.books', 2)")
		res = DB.exec("SELECT * FROM sivers.changes")
		assert_equal 1, res.ntuples
		x = res[0]
		assert_equal '1', x['id']
		assert_equal '1', x['person_id']
		assert_equal 'sivers.books', x['table_name']
		assert_equal '2', x['table_id']
		assert_equal nil, x['field_name']
		assert_equal nil, x['before']
		assert_equal nil, x['after']
	end

	def test_insert_2
		res = DB.exec("INSERT INTO sivers.books (title, price)
			VALUES ('C', 10) RETURNING id")
		DB.exec("INSERT INTO changes(person_id, table_name, table_id)
			VALUES(1, 'sivers.books', %d)" % res[0]['id'])
		res = DB.exec("SELECT * FROM sivers.changes")
		assert_equal 1, res.ntuples
		x = res[0]
		assert_equal '1', x['id']
		assert_equal '1', x['person_id']
		assert_equal 'sivers.books', x['table_name']
		assert_equal '3', x['table_id']
		assert_equal nil, x['field_name']
		assert_equal nil, x['before']
		assert_equal nil, x['after']
	end
end

