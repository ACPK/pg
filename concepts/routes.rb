require 'sinatra/base'
require 'pg'
DB = PG::Connection.new(dbname: 'sivers', user: 'sivers')

class ConceptsAPI < Sinatra::Base

	def qry(sql, params=[])
		@res = DB.exec_params('select mime, js from ' + sql, params)
	end

	after do
		content_type @res[0]['mime']
		body @res[0]['js']
		if @res[0]['mime'].include? 'problem'
			if @res[0]['js'].include? '"status": 404'
				status 404
			else
				status 400
			end
		end
	end

	get %r{\A/concepts/([0-9]+)\Z} do |id|
		qry('get_concept($1)', [id])
	end
	
	post '/concepts' do
		qry('create_concept($1)', [params[:concept]])
	end
	
	put %r{\A/concepts/([0-9]+)\Z} do |id|
		qry('update_concept($1, $2)', [id, params[:concept]])
	end
	
	delete %r{\A/concepts/([0-9]+)\Z} do |id|
		qry('delete_concept($1)', [id])
	end

	post %r{\A/concepts/([0-9]+)/tag\Z} do |id|
		qry('tag_concept($1, $2)', [id, params[:tag]])
	end
	
	get '/concepts/tag' do
		qry('concepts_tagged($1)', [params[:tag]])
	end
	
	get %r{\A/pairings/([0-9]+)\Z} do |id|
		qry('get_pairing($1)', [id])
	end
	
	post '/pairings' do
		qry('create_pairing()')
	end
	
	put %r{\A/pairings/([0-9]+)\Z} do |id|
		qry('update_pairing($1, $2)', [id, params[:thoughts]])
	end
	
	delete %r{\A/pairings/([0-9]+)\Z} do |id|
		qry('delete_pairing($1)', [id])
	end

	post %r{\A/pairings/([0-9]+)/tag\Z} do |id|
		qry('tag_pairing($1, $2)', [id, params[:tag]])
	end
	
end

