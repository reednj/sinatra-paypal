
require 'sinatra/base'
require 'sinatra/paypal/version'
require 'sinatra/paypal/paypal-helper'
require 'sinatra/paypal/paypal-request'

PAYPAL_BLOCKS = {}

module PayPal

	module Helpers
		def _paypal_block(name)
			return Proc.new{} if !PAYPAL_BLOCKS.key? name
			PAYPAL_BLOCKS[name]
		end

		def paypal_form_url
			PaypalHelper.form_url(settings.paypal.sandbox?)
		end

		def html_payment_form(item, data = {})
			# it is valid to send a nil item through - we might be going to set the fields in
			# javascript - but if it isn't null then there are certain fields that need to be
			# set
			if !item.nil?
				raise 'item.code required' if !item.respond_to?(:code) || item.code.nil?
				raise 'item.price required' if !item.respond_to?(:price) || item.price.nil?
				raise 'item.price must be a number above zero' if item.price.to_f <= 0
			end

			raise 'cannot generate a payment form without settings.paypal.email' if settings.paypal.email.nil?

			erb :_payment, :views => File.join(File.dirname(__FILE__), '/paypal'), :locals => {
				:custom_data => data,
				:item => item
			}
		end
	end

	def self.registered(app)
		app.helpers PayPal::Helpers

		app.set :paypal, OpenStruct.new({
			:return_url => '/payment/complete',
			:notify_url => '/payment/validate',
			:sandbox? => app.settings.development?,
			:email => nil
		})

		app.post '/payment/validate' do
			paypal_helper = PaypalHelper.new(app.settings.paypal.sandbox?)
			paypal_request = PaypalRequest.new(params)
			
			# first we check the request against paypal to make sure it is ok
			if settings.production?
				halt 500, 'request could not be validated' if !paypal_helper.ipn_valid? params
			end
			
			# check transaction log to make sure this not a replay attack
			if instance_exec(paypal_request, &_paypal_block(:repeated?))
				# we also want to return 200, because if it is paypal sending this, it will send 
				# it again and again until it gets a 200 back
				halt 200, 'already processed'
			end

			instance_exec(paypal_request, &_paypal_block(:validate!))
			
			# check that the payment is complete. we still return 200 if not, but
			# we don't need to do anymore processing (except for marking it as accountable, if it is)
			if paypal_request.complete?
				instance_exec(paypal_request, &_paypal_block(:complete))
			end

			instance_exec(paypal_request, &_paypal_block(:finish))

			return 200
		end
	end

	# Register a payment callback. All callbacks are called
	# with a single argument of the type +PaypalRequest+ containing all the
	# data for the notification.
	#
	# 	payment :complete do |p|
	# 		# process the payment here
	# 		# don't forget to check that the price is correct!
	# 	end
	#
	def payment(name, &block)
		valid_names = [:complete, :finish, :validate!, :repeated?]
		raise "#{name.to_s} is not a valid payment callback" if !valid_names.include? name
		PAYPAL_BLOCKS[name] = block
	end
end


module Sinatra
	register PayPal
end
