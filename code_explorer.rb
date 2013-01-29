require 'rubygems'
require 'sinatra'
require 'mongo'
require 'json'
require 'yaml'
require 'mongo_mapper'


include Mongo

require './helpers'


configure do
	MongoMapper.database = 'code_explorer'
end

no_codes_error = ' { "error" : "No codes found." }'


get '/' do
	erb :new_explorer
end


get '/admin' do
	if active_id = params[:_id]
		@code = Code.first({ "_id" => BSON::ObjectId(active_id) })
	end
	@count = Code.all.count
 	erb :index
end

post '/new' do # post a string of yaml
	if params[:code] && code = YAML.load(params[:code]) 
		if code["code"] != ''	
			p "Code received : #{code["code"]}"	
			if old_version = Code.first(code: code["code"])
				p "Merging with #{old_version.code}"
				old_version.attributes = old_version.attributes.merge!(code)
				p "Saving: #{old_version.attributes.inspect}"
				old_version.save
				redirect back
			else
				p "Creating a new code"
				Code.new(code).save
			end
		end
		redirect back
	else 
		"no data saved. PARAMS: #{params.inspect}"
	end			
end

get '/delete/:id' do
	Code.first({ "_id" => BSON::ObjectId(params[:id]) }).delete()
	redirect back
end

# Respond to both kinds of requests
get '/code/:code' do
	return_code_or_message(params[:code])
end
post '/code' do # post code
	return_code_or_message(params[:code])
end
def return_code_or_message(code_string)
	if code_string =~ /[0-9\.]+/ && @code = Code.first({code: code_string})
		@code.to_json
	else
		no_codes_error
	end
end


get '/query' do
	if params[:parent] || params[:code]
		return query_response_or_message(params)
	else
		no_codes_error
	end
end

post '/query' do
	if params
		return query_response_or_message(params)
	else 
		no_codes_error
	end
end
def query_response_or_message(params)
	params.each do |k,v|
		if v=='nil'
			params[k] = nil
		end

	end
	if codes = Code.where(params).all.to_json
		codes
	else
		no_codes_error
	end
end

