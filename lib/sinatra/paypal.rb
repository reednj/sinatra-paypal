
require 'sinatra/base'
require 'sinatra/paypal/version'
require 'sinatra/paypal/paypal-helper'
require 'sinatra/paypal/paypal-request'

PAYPAL_BLOCKS = {}

module PayPal

	module Helpers
		def paypal_block(name)
			return Proc.new{} if !PAYPAL_BLOCKS.key? name
			PAYPAL_BLOCKS[name]
		end

		def paypal_form_url
			PaypalHelper.form_url(settings.paypal.sandbox?)
		end

		def html_payment_form(offer_data, data = nil)
			data ||= {}
			data[:username] = session[:reddit_user] if !data.nil? && data[:username].nil?
			data[:offer_code] = offer_data.code if !offer_data.nil?

			raise 'cannot generate a payment form without settings.paypal.email' if settings.paypal.email.nil?

			erb :_payment, :views => File.join(File.dirname(__FILE__), '/paypal'), :locals => {
				:custom_data => data,
				:offer_data => offer_data
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
			paypal_helper = PaypalHelper.new(AppConfig.paypal.use_sandbox)
			paypal_request = PaypalRequest.new(params)
			
			# first we check the request against paypal to make sure it is ok
			if settings.production?
				halt 400, 'request could not be validated' if !paypal_helper.ipn_valid? params
			end

			halt 400, 'no username provided' if paypal_request.username.nil?
			
			# check transaction log to make sure this not a replay attack
			if instance_exec(paypal_request, &paypal_block(:repeated?))
				# we want to log this, so we know about it, but we also want to return 200, because
				# if it is paypal sending this, it will send it again and again until it gets a 200
				# back
				log_error 'already processed' 
				halt 200, 'already processed' 
			else
				instance_exec(paypal_request, &paypal_block(:save))
			end

			instance_exec(paypal_request, &paypal_block(:validate!))
			
			# check that the payment is complete. we still return 200 if not, but
			# we don't need to do anymore processing (except for marking it as accountable, if it is)
			if paypal_request.complete?
				instance_exec(paypal_request, &paypal_block(:complete))
			end

			instance_exec(paypal_request, &paypal_block(:finish))

			return 200
		end
	end

	def payment(name, &block)
		PAYPAL_BLOCKS[name] = block
	end
end


module Sinatra
	register PayPal
end