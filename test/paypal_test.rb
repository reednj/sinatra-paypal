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

	def standard_payment_data
		{			
			:tax=>"0.00", 
			:receiver_email=>"accounts@reddit-stream.com", 
			:payment_gross=>"1.49", 
			:transaction_subject=>"rs-test", 
			:receiver_id=>"TDCZRKH9NXETE", 
			:quantity=>"1", 
			:business=>"accounts@reddit-stream.com", 
			:mc_currency=>"USD", 
			:payment_fee=>"0.44", 
			:notify_version=>"3.7", 
			:shipping=>"0.00", 
			:verify_sign=>"AVQ7PVd2w7LAwpsg5Yh7hFxe9SywAuiBQIp9fScf77n48fA8WF21KG2i", 
			:cmd=>"_notify-validate", 
			:test_ipn=>"1", 
			:txn_type=>"web_accept", 
			:charset=>"UTF-8", 
			:payer_id=>"649KQR22GAU4W", 
			:payer_status=>"verified", 
			:ipn_track_id=>"d1992aaea45a",
			:handling_amount=>"0.00", 
			:residence_country=>"US", 
			:payer_email=>"user1@reddit-stream.com", 
			:payment_date=>"09:26:13 Sep 23, 2013 PDT", 
			:protection_eligibility=>"Ineligible", 
			:payment_type=>"instant",

			:first_name=>"Nathan",
			:last_name=>"Reed",
			:custom=>"rs-test",
			
			:txn_id=>random_string(),
			:payment_status=>"Completed",
			:item_number=>"RS1",
			:item_name=>"reddit-stream.com Unlimited Account",
			:mc_gross=>"1.49",
			:mc_fee=>"0.44"		
		}
	end

	def random_string(len = 5)
		space = ['a', 'b', 'c', 'd', 'e','f', '1', '2', '3', '4', '5', '6', '7', '8', '9']
		return (0..5).map {|a| space.rand }.join
	end
	
	def page_error(desc)
		"#{desc} (HTTP #{last_response.status})\n" + 
		"#{last_response.body.truncate 256}"
	end

	#
	# Now we start the testing of the payment processing
	#
	def test_payment_rejects_double_processing
		data = standard_payment_data

		post '/payment/validate', data
		assert last_response.ok?, page_error("Payment rejected")
		assert !last_response.body.include?('already processed')

		post '/payment/validate', data
		assert last_response.ok?
		assert last_response.body.include?('already processed'), "duplicate payment accepted!"
	end

	def test_payment_thread_id
		data = standard_payment_data
		data[:custom] = {
			:username => 'njr123',
			:thread_id => '2hqk1o'
		}.to_json

		header 'Accept', 'text/plain'
		post '/payment/validate', data
		assert last_response.ok?, page_error("Payment not accepted")
	end

	def test_payment_thread_id_only
		data = standard_payment_data
		data[:custom] = {
			:thread_id => '2hqk1o'
		}.to_json

		post '/payment/validate', data
		assert_equal last_response.status, 400
	end

	def test_payment_accepted_json_custom_data
		data = standard_payment_data
		data[:custom] = {:username => data[:custom]}.to_json

		post '/payment/validate', data
		assert last_response.ok?, page_error("Payment not accepted")
	end

	def test_payment_accepted
		data = standard_payment_data
		username = data[:custom]

		post '/payment/validate', data
		assert last_response.ok?, page_error("Payment not accepted")
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
