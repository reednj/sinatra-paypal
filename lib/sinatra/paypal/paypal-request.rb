
class PaypalRequest
	def initialize(params)
		if params.is_a? String
			 params = JSON.parse(params, {:symbolize_names => true})
		end

		@fields = params
		@custom_data = nil
	end

	
	def id
		self.transaction_hash
	end

	# the same transaction id can come in mulitple times with different statuses
	# so we need to check both of them in order to see if the txn is unquie
	def transaction_hash
		"#{self.transaction_id}-#{@fields[:payment_status]}".sha1
	end

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

	# defined as the gross amount, minus transaction fees
	# could also subtract shipping and tax here as well, but we don't have to deal with
	# any of that yet
	def profit
		self.amount - self.payment_fee
	end

	def username
		self.custom_data[:username]
	end

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

	def data
		custom_data
	end

	def status
		@fields[:payment_status]
	end

	def complete?
		self.status == 'Completed'
	end

	# these are payment statues that actually result in the paypal balance changing, so we should set them as
	# accountable in the payment_log
	def is_accountable?
		(self.complete? || self.status == 'Refunded' || self.status == 'Reversed' || self.status == 'Canceled_Reversal')
	end

	def reason_code
		@fields[:reason_code] || @fields[:pending_reason]
	end

	def fields
		@fields
	end
end
