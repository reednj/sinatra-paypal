
class PaypalHelper
	def initialize(use_sandbox)
		@use_sandbox = use_sandbox
	end

	def form_url
		@use_sandbox ? 'https://www.sandbox.paypal.com/cgi-bin/webscr' : 'https://www.paypal.com/cgi-bin/webscr'
	end

	def self.form_url(use_sandbox)
		new(use_sandbox).form_url
	end

	def ipn_valid?(params)
		return false if params.nil?

		params[:cmd] = '_notify-validate'
		return RestClient.post(self.form_url, params) == 'VERIFIED'
	end
end
