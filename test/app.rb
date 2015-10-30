
require 'bundler'
Bundler.require

require 'sinatra'
require 'sinatra/paypal'
require 'fileutils'

# this allows us to handle errors in test without the default page
# getting generated (which isn't very useful inside unit-tests)
set :raise_errors, false
set :show_exceptions, false

# dump the error description - this will make it appear nicely in the 
# unit test description
error do
	e = request.env['sinatra.error']
	return "#{e.class}: #{e.message}" unless e.nil?
	return "unknown error"
end

payment :repeated? do |p|
	path = 'test.sinatra-payment.log'
	path = File.join '/tmp', path if !Gem.win_platform?
	FileUtils.touch path if !File.exist? path
	
	data = File.read path
	id = "#{p.id}\n"

	if data.include? id
		return true
	else
		File.append path, "#{p.id}\n"
		return false
	end
end

get '/payment/form/empty' do
	return html_payment_form nil
end

get '/payment/form' do
	item = {}
	item[:code] = params[:item_code]
	item[:price] = params[:item_price]
	item[:name] = params[:item_name]
	item = OpenStruct.new item

	return html_payment_form(item)
end

#
# Extensions to make the the test app simpler
# 
class File
	def self.append(path, data)
		File.open(path, 'a:UTF-8') do |file| 
			file.write data 
		end
	end
end
