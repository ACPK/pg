require 'pg'
DB = PG::Connection.new(dbname: 'sivers', user: 'sivers')
#DB2 = PG::Connection.new(dbname: 'sivers', user: 'sivers')

# http://deveiate.org/code/pg/PG/Connection.html#method-i-wait_for_notify

qry = "SELECT json_agg(row_to_json(x)) AS j FROM" +
	" (SELECT id, uri, name, comment FROM comments" +
	" WHERE uri='%s' ORDER BY id) x"

DB.async_exec('LISTEN comments_changed')

while true do
	DB.wait_for_notify do |event, pid, uri|
		outfile = '/tmp/%s.js' % uri
		res = DB.exec(qry % uri)
		File.open(outfile, 'w') do |f|
			f.puts res[0]['j']
		end
		puts outfile
	end
end

