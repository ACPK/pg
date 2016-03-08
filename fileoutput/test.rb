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
	def test_insert
		DB.exec_params("INSERT INTO comments (uri, name, html) VALUES ($1, $2, $3)", ['blog1', 'Dude', 'Right on!'])
		js = JSON.parse(File.read('/tmp/blog1.json'))
		assert_equal 3, js.size
		assert_equal 'Bob', js[0]['name']
		assert_equal 'Bill', js[1]['name']
		assert_equal 'Dude', js[2]['name']
		assert_equal 'Right on!', js[2]['html']
	end

	def test_update
		DB.exec("UPDATE comments SET name='Robert' WHERE id=1")
		js = JSON.parse(File.read('/tmp/blog1.json'))
		assert_equal 2, js.size
		assert_equal 'Robert', js[0]['name']
	end

	def test_delete
		DB.exec("DELETE FROM comments WHERE id=3")
		js = JSON.parse(File.read('/tmp/blog2.json'))
		assert_equal 1, js.size
		assert_equal 'Árið', js[0]['html']
	end

	def test_clean
		DB.exec_params("UPDATE comments SET html=$1, uri=$2 WHERE id=3", ['cleaned first', ' "BLoG2€'])
		js = JSON.parse(File.read('/tmp/blog2.json'))
		assert_equal 2, js.size
		assert_equal 'cleaned first', js[0]['html']
	end
end

