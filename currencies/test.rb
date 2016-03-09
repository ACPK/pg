require 'pg'
require 'minitest/autorun'
require 'json'
require 'zlib'

DB = PG::Connection.new(dbname: 'sivers', user: 'sivers')
SQL = File.read('sql.sql')

class Minitest::Test
	def setup
		DB.exec(SQL)
	end
end

# OPENEXCHANGERATES = 'yourAPIkeyHERE' # - from https://openexchangerates.org/
# require 'net/http'
# uri = URI('https://openexchangerates.org/api/latest.json?app_id=' + OPENEXCHANGERATES)
# JS = Net::HTTP.get(uri)

Zlib::GzipReader.open('openexchangerates.json.gz') do |f|
	JS = f.read
end
OE = JSON.parse(JS)

class SqlTest < Minitest::Test
	def test_update
		DB.exec_params("SELECT * FROM update_currency_rates($1)", [JS])
		res = DB.exec("SELECT rate FROM currency_rates WHERE code='EUR'")
		assert_equal OE['rates']['EUR'].to_s, res[0]['rate']
		res = DB.exec("SELECT rate FROM currency_rates WHERE code='BTC'")
		assert_equal OE['rates']['BTC'].to_s, res[0]['rate']
		assert_raises PG::InvalidTextRepresentation do
			DB.exec("SELECT rate FROM currency_rates WHERE code='SGD'")
		end
	end

	def test_money_to
		res = DB.exec("SELECT * FROM money_to(('USD', 1000), 'EUR')")
		assert (881..882).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM money_to(('EUR', 1000), 'USD')")
		assert (1134..1135).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM money_to(('JPY', 1000), 'EUR')")
		assert (7..8).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM money_to(('EUR', 1000), 'BTC')")
		assert (4..5).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM money_to(('BTC', 9), 'JPY')")
		assert (250099..250100).cover? res[0]['amount'].to_f 
	end

	def test_from_to
		res = DB.exec("SELECT * FROM currency_from_to(1000, 'USD', 'EUR')")
		assert (881..882).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM currency_from_to(1000, 'EUR', 'USD')")
		assert (1134..1135).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM currency_from_to(1000, 'JPY', 'EUR')")
		assert (7..8).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM currency_from_to(1000, 'EUR', 'BTC')")
		assert (4..5).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM currency_from_to(9, 'BTC', 'JPY')")
		assert (250099..250100).cover? res[0]['amount'].to_f 
	end
end

