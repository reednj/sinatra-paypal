require 'rest-client'

class PaypalHelper
	def initialize(use_sandbox)
		@use_sandbox = use_sandbox
	end

	# returns the url that the payment forms must be submitted to so they can be
	# processed by paypal. If the sandbox attribute is set, then it will return the
	# url for the sandbox
	#
	# 	form_url # => https://www.paypal.com/cgi-bin/webscr
	#
	def form_url
		@use_sandbox ? 'https://www.sandbox.paypal.com/cgi-bin/webscr' : 'https://www.paypal.com/cgi-bin/webscr'
	end

	def self.form_url(use_sandbox)
		new(use_sandbox).form_url
	end

	# validates the ipn request with paypal to make sure it is genuine. +params+ should contain
	# the exact params object that was sent as part of the IPN POST
	def ipn_valid?(params)
		return false if params.nil?

		params[:cmd] = '_notify-validate'
		return RestClient.post(self.form_url, params) == 'VERIFIED'
	end
end
