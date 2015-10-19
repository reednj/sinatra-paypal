require 'json'

class PaypalRequest
	def initialize(params)
		if params.is_a? String
			 params = JSON.parse(params, {:symbolize_names => true})
		end

		@fields = params
		@custom_data = nil
	end

	# a unique id for the transaction (event if the paypal transaction_id is the
	# same)
	#
	# 	payment.id # => 661295c9cbf9d6b2f6428414504a8deed3020641
	#
	def id
		self.transaction_hash
	end

	# alias for +id+
	def transaction_hash
		# the same transaction id can come in mulitple times with different statuses
		# so we need to check both of them in order to see if the txn is unquie
		"#{self.transaction_id}-#{@fields[:payment_status]}".sha1
	end

	# the paypal transaction_id
	#
	# 	payment.transaction_id # => 6FH51066BB6306017
	#
	def transaction_id
		@fields[:txn_id]
	end

	def item_valid?(item_list, offer_data = nil)
		if item_list[self.item_number] != nil
			if item_list[self.item_number][:amount] == self.amount
				# this is a regular purchase at the regular price
				return true
			elsif self.uses_offer?(offer_data)
				# the price comes from a special offer, its valid
				return true
			end
		end

		return false
	end

	def uses_offer?(offer_data)
		# to check if the offer is valid on this purchase we need to check the item code and the price matches
		return !offer_data.nil? && offer_data[:offer][:item_code] == self.item_number && offer_data[:offer][:amount]  == self.amount
	end

	def item_number
		@fields[:item_number]
	end

	def amount
		Float(@fields[:mc_gross] || 0)
	end

	def payment_fee
		Float(@fields[:mc_fee] || 0)
	end

	# The payment amount minus any fees, giving the net profit
	#
	# 	payment.profit # => 1.63
	#
	def profit
		# defined as the gross amount, minus transaction fees
		# could also subtract shipping and tax here as well, but we don't have to deal with
		# any of that yet
		self.amount - self.payment_fee
	end

	# One of the most common peices of data to send through with the payment is the
	# username that the payment applies to. This method will return the username from
	# the custom_data field, if it contains one
	#
	# 	payment.username # => reednj
	#
	def username
		self.custom_data[:username]
	end

	# Whatever is put in the custom_data field on the payment form will be sent back
	# in the payment notification. This is useful for tracking the username and other
	# information that is required to process the payment.
	#
	# The sinatra-paypal module expects this to be either a plain string containing 
	# the username or a json string that can be parse into a ruby object.
	#
	# Note that this field can be modified by the user before submitting the form, 
	# so you should verify the contents of it before using it.
	#
	# payment.custom_data # => { :username => 'dave' }
	#
	def custom_data
		if @custom_data.nil?
			if @fields[:custom].strip.start_with? '{'
				# we could get a json object through, in which case it needs to be parsed...
				@custom_data = JSON.parse(@fields[:custom], {:symbolize_names => true})
			else
				# ...or would just have a string (which we assume is the target username) in that
				# case we need to normalize it into an object
				@custom_data = {:username => @fields[:custom]}
			end
		end

		return @custom_data
	end

	# an alias for +custom_data+
	def data
		custom_data
	end

	# The payment status. The most common is Completed, but you might also see
	#
	#  - Refunded 
	#  - Pending
	#  - Reversed
	#  - Canceled_Reversal
	#  - Completed
	#
	# 	payment.status # => Pending
	#
	def status
		@fields[:payment_status]
	end

	# Returns true if +status+ is Completed
	def complete?
		self.status == 'Completed'
	end

	# Returns true if the transaction results in a change of the merchant account balance. This
	# doesn't apply to all IPN notifications - some (such as those with status Pending) are simply
	# notifications that do not actually result in money chaning hands
	def is_accountable?
		# these are payment statues that actually result in the paypal balance changing, so we should set them as
		# accountable in the payment_log
		(self.complete? || self.status == 'Refunded' || self.status == 'Reversed' || self.status == 'Canceled_Reversal')
	end

	# returns the reason code for noticiations that have one (usually Pending or Refunded transactions)
	# if a reason code is not applicable, this will return nil
	def reason_code
		@fields[:reason_code] || @fields[:pending_reason]
	end

	# A Hash with the raw data for the paypal transaction, this contains many less useful
	# fields not listed above
	#
	# Here is a list of the fields for a Completed transaction. These fields differ slightly
	# between the main transaction types.
	#
	# 	:business: you@yourcompany.com
	# 	:charset: UTF-8
	# 	:cmd: _notify-validate
	# 	:custom: ! '{"thread_id":"3f3fc5","username":"customer_user_name"}'
	# 	:first_name: Bill
	# 	:handling_amount: '0.00'
	# 	:ipn_track_id: a5d596fffd057
	# 	:item_name: Describe your item
	# 	:item_number: I01
	# 	:last_name: Davies
	# 	:mc_currency: USD
	# 	:mc_fee: '0.37'
	# 	:mc_gross: '2.00'
	# 	:notify_version: '3.8'
	# 	:payer_email: customer@gmail.com
	# 	:payer_id: 9AFYVBV9TTT5L
	# 	:payer_status: verified
	# 	:payment_date: 18:01:26 Jul 29, 2015 PDT
	# 	:payment_fee: '0.37'
	# 	:payment_gross: '2.00'
	# 	:payment_status: Completed
	# 	:payment_type: instant
	# 	:protection_eligibility: Ineligible
	# 	:quantity: '1'
	# 	:receiver_email: you@yourcompany.com
	# 	:receiver_id: 4SUZXXXXFMC28
	# 	:residence_country: US
	# 	:shipping: '0.00'
	# 	:tax: '0.00'
	# 	:transaction_subject: ! '{"thread_id":"3f3fc5","username":"customer_user_name"}'
	# 	:txn_id: 6FH51036BB6776017
	# 	:txn_type: web_accept
	# 	:verify_sign: AmydMwaMHzmxRimnFMnKy3o9n-ElAWWRtiJ9TEixE0iGouC6EaMS0mWI
	#
	# See https://developer.paypal.com/docs/classic/ipn/integration-guide/IPNandPDTVariables/ for
	# a full description of the notification fields
	#
	def fields
		@fields
	end
end

# extensions needed for the paypal request to work
class String
	def sha1
		Digest::SHA1.hexdigest self
	end
end

