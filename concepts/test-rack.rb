require 'minitest/autorun'
require 'rack/test'
require 'json'
require_relative 'routes.rb'

# directly accessing DB (defined in routes.rb) to rebuild fixtures for each test
SQL = File.read('sql.sql')
class Minitest::Test
	def setup
		DB.exec(SQL)
	end
end
Minitest.after_run do
	DB.exec(SQL)
end

class ConceptsAPITest < Minitest::Test
  include Rack::Test::Methods
	def app
		ConceptsAPI.new
	end

	def test_get_concept
		get '/concepts/1'
		js = JSON.parse(last_response.body)
		assert_equal 'application/json', last_response.content_type
		assert_equal %w(id created_at concept tags), js.keys
		assert_equal 'roses are red', js['concept']
		assert_equal %w(color flower), js['tags'].sort
	end

	def test_get_concept_404
		get '/concepts/999'
		js = JSON.parse(last_response.body)
		assert_equal 'application/problem+json', last_response.content_type
		assert_equal 'about:blank', js['type']
		assert_equal 'Not Found', js['title']
		assert_equal 404, js['status']
	end

	def test_create_concept
		post '/concepts', {concept: ' River running '}
		assert_equal 'application/json', last_response.content_type
		js = JSON.parse(last_response.body)
		assert_equal 4, js['id']
		assert_equal 'River running', js['concept']
		assert_equal [], js['tags']
	end

	def test_update_concept
		put '/concepts/3', {concept: 'sugar is sticky '}
		assert_equal 'application/json', last_response.content_type
		js = JSON.parse(last_response.body)
		assert_equal 3, js['id']
		assert_equal 'sugar is sticky', js['concept']
		assert_equal %w(flavor), js['tags']
		put '/concepts/999', {concept: 'should return 404'}
		assert_equal 404, last_response.status
		assert_equal 'application/problem+json', last_response.content_type
		js = JSON.parse(last_response.body)
		assert_equal 'Not Found', js['title']
	end

	def test_delete_concept
		delete '/concepts/1'
		assert_equal 'application/json', last_response.content_type
		js = JSON.parse(last_response.body)
		assert_equal 'roses are red', js['concept']
		delete '/concepts/1'
		assert_equal 'application/problem+json', last_response.content_type
		js = JSON.parse(last_response.body)
		assert_equal 'Not Found', js['title']
	end

	def test_update_err
		put '/concepts/1', {concept: ''}
		assert_equal 'application/problem+json', last_response.content_type
		js = JSON.parse(last_response.body)
		assert_match /23514$/, js['type']
		assert_match /not_empty/, js['title']
		assert_match /^Failing row/, js['detail']
		put '/concepts/1'
		js = JSON.parse(last_response.body)
		assert_match /23502$/, js['type']
		assert_match /not-null/, js['title']
		assert_match /^Failing row/, js['detail']
	end

	def test_create_err
		post '/concepts', {concept: 'roses are red'}
		js = JSON.parse(last_response.body)
		assert_match /23505$/, js['type']
		assert_match /unique constraint/, js['title']
		post '/concepts'
		js = JSON.parse(last_response.body)
		assert_match /23502$/, js['type']
		assert_match /not-null/, js['title']
		assert_match /^Failing row/, js['detail']
	end

	def test_tag_concept
		post '/concepts/3/tag', {tag: ' JUICY '}
		js = JSON.parse(last_response.body)
		assert_equal 'sugar is sweet', js['concept']
		assert_equal %w(flavor juicy), js['tags'].sort
	end

	def test_concepts_tagged
		get '/concepts/tag?tag=flower'
		js = JSON.parse(last_response.body)
		assert_instance_of Array, js
		assert_equal 2, js.size
		assert_equal 1, js[0]['id']
		assert_equal 2, js[1]['id']
		assert_equal %w{color flower}, js[0]['tags'].sort
		assert_equal %w{color flower}, js[1]['tags'].sort
	end

	def test_get_pairing
		get '/pairings/1'
		assert_equal 'application/json', last_response.content_type
		js = JSON.parse(last_response.body)
		assert_equal 1, js['id']
		assert_match /201[0-9]-[0-9]{2}-[0-9]{2}/, js['created_at']
		assert_equal 'describing flowers', js['thoughts']
		assert_instance_of Array, js['concepts']
		assert_equal 2, js['concepts'].size
		c = js['concepts'][0]
		assert_equal 1, c['id']
		assert_equal 'roses are red', c['concept']
		assert_equal %w(color flower), c['tags'].sort
		c = js['concepts'][1]
		assert_equal 2, c['id']
		assert_equal 'violets are blue', c['concept']
		assert_equal %w(color flower), c['tags'].sort
	end

	def test_create_pairing
		post '/pairings'
		js = JSON.parse(last_response.body)
		assert_equal 2, js['id']
		assert_match /201[0-9]-[0-9]{2}-[0-9]{2}/, js['created_at']
		assert_nil js['thoughts']
		assert_instance_of Array, js['concepts']
		assert_equal 2, js['concepts'].size
	end

	def test_update_pairing
		put '/pairings/1', {thoughts: 'new thoughts'}
		js = JSON.parse(last_response.body)
		assert_equal 'new thoughts', js['thoughts']
	end

	def test_delete_pairing
		delete '/pairings/1'
		js = JSON.parse(last_response.body)
		assert_equal 'describing flowers', js['thoughts']
		delete '/pairings/1'
		assert_equal 'application/problem+json', last_response.content_type
		js = JSON.parse(last_response.body)
		assert_equal 'Not Found', js['title']
	end

	def test_tag_pairing
		post '/pairings/1/tag', {tag: 'newtag'}
		js = JSON.parse(last_response.body)
		assert_equal %w{color flower newtag}, js['concepts'][0]['tags'].sort
		assert_equal %w{color flower newtag}, js['concepts'][1]['tags'].sort
	end

end

