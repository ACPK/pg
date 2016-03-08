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
	def setup
		super
		@name = 'Dude'
		@email = 'dude@dude.com'
		@js = '{"id" : 1, "name" : "Dude", "email" : "dude@dude.com"}'
	end

	def test_positional
		res = DB.exec_params("SELECT js FROM create_person($1, $2)", [@name, @email])
		assert_equal @js, res[0]['js']
	end

	def test_named1
		res = DB.exec_params("SELECT js FROM create_person(name := $1, email := $2)", [@name, @email])
		assert_equal @js, res[0]['js']
	end

	# Very little benefit because exec_params needs params to be positional anyway
	def test_named2
		res = DB.exec_params("SELECT js FROM create_person(email := $1, name := $2)", [@email, @name])
		assert_equal @js, res[0]['js']
	end
end

