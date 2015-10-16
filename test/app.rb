
require 'bundler'
Bundler.require

require 'sinatra'
require 'sinatra/paypal'

# this allows us to handle errors in test without the default page
# getting generated (which isn't very useful inside unit-tests)
set :raise_errors, false
set :show_exceptions, false

error do
	e = request.env['sinatra.error']
	return "#{e.class}: #{e.message}" unless e.nil?
	return "unknown error"
end

