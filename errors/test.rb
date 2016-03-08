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
	def test_named_constraint
		res = DB.exec_params("SELECT mime, js FROM update_country($1, $2)", [1, '{"code": "tH"}'])
		assert_equal 'application/problem+json', res[0]['mime']
		js = JSON.parse(res[0]['js'])
		assert_equal js['outcode'], 'countries_code_2AZ'
		assert_equal js['code'], '23514' # check_violation
		assert_equal js['cnstrnt'], 'charcode'
		assert js['context'].include? 'update_country'
	end

	def test_foreign_key
		res = DB.exec_params("SELECT mime, js FROM update_city($1, $2)", [1, '{"country_id": 9}'])
		assert_equal 'application/problem+json', res[0]['mime']
		js = JSON.parse(res[0]['js'])
		assert_equal js['outcode'], 'cities_country_id_not_found'
		assert_equal js['code'], '23503' # foreign_key_violation
		assert_equal js['cnstrnt'], 'cities_country_id_fkey'
		assert js['detail'].include? 'not present in table'
	end

	def test_column_type
		res = DB.exec_params("SELECT mime, js FROM update_country($1, $2)", [1, '{"sqkm": "a"}'])
		assert_equal 'application/problem+json', res[0]['mime']
		js = JSON.parse(res[0]['js'])
		assert_equal js['outcode'], 'invalid_text_representation'
		assert_equal js['code'], '22P02' # invalid_text_representation
		assert js['msg'].include? 'syntax for integer'
		assert js['context'].include? 'update_country'
	end

	def test_404_get
		res = DB.exec("SELECT mime, js FROM get_country(99)")
		assert_equal 'application/problem+json', res[0]['mime']
		js = JSON.parse(res[0]['js'])
		assert_equal 'Not Found', js['title']
		assert_equal 404, js['status']
	end

	def test_404_update
		res = DB.exec_params("SELECT mime, js FROM update_country($1, $2)", [9, '{"name": "Belgium"}'])
		assert_equal 'application/problem+json', res[0]['mime']
		js = JSON.parse(res[0]['js'])
		assert_equal 'Not Found', js['title']
		assert_equal 404, js['status']
	end
end

