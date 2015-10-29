ENV['RACK_ENV'] = 'development'

require 'rubygems'
require 'minitest/autorun'
require 'rack/test'
require 'test/unit'

require_relative './app'

class RedditStreamTest < Test::Unit::TestCase
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end
	
	def page_error(desc)
		"#{desc} (HTTP #{last_response.status})\n" + 
		"#{last_response.body.truncate 256}"
	end

	def test_form_helper_no_email
		app.paypal.email = nil

		begin
			get '/payment/form/empty'
			assert false, 'no email payment form didn\'t raise an exception'
		rescue => e
			raise if !e.message.include? 'email'
		end
	end

	def test_form_helper_no_item_code
		app.paypal.email = 'reednj@gmail.com'

		get '/payment/form'
		assert !last_response.ok?, 'form created without item code'
		assert last_response.body.include?('item.code'), 'no error about missing item.code'
	end

	def test_form_helper_invalid_price
		app.paypal.email = 'reednj@gmail.com'

		get '/payment/form', { :item_code => 'ITEM-0', :item_price => 'xxx'}
		assert !last_response.ok?, 'form created with invalid price'
		assert last_response.body.include?('item.price'), 'no error about invalid price'
	end

	def test_empty_form_helper
		app.paypal.email = 'reednj@gmail.com'
		
		get '/payment/form/empty'
		assert last_response.ok?, page_error('could not generate payment form')
		assert last_response.body.include?(app.paypal.email), 'account email not found in form'
		assert !last_response.body.include?('"username":'), 'should not include username custom_data by default'
	end

	def test_form_helper_with_item
		app.paypal.email = 'reednj@gmail.com'
		
		code = 'ITEM-0'
		get '/payment/form', { :item_code => code, :item_price => '5.00'}
		assert last_response.ok?, page_error('could not generate payment form')
		assert last_response.body.include?(app.paypal.email), 'account email not found in form'
		assert last_response.body.include?(code), 'item_code not found in form'
	end

	def test_form_helper_with_item_description
		app.paypal.email = 'reednj@gmail.com'
		
		code = 'ITEM-0'
		desc = 'item description'
		get '/payment/form', { :item_code => code, :item_price => '5.00', :item_name => desc }
		assert last_response.ok?, page_error('could not generate payment form')
		assert last_response.body.include?(app.paypal.email), 'account email not found in form'
		assert last_response.body.include?(code), 'item_code not found in form'
		assert last_response.body.include?(desc), 'item_name not found in form'
	end

end

class Array
	def rand
		self[Object.send(:rand, self.length)]
	end
end

class String
	def truncate(max_len = 32)
		append = '...'
		return self if self.length < max_len
		return self[0...(max_len - append.length)] + append
	end
end
