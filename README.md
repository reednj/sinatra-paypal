# Sinatra::Paypal

This gem makes it easy to validate and process Paypal IPN payments.

It automatically adds a route at `/payment/validate` to use as the IPN endpoint, and then adds a number of new methods to the sinatra DSL allow payment events to be captured and processed

## Usage

Install the gem and then add it to your project with:

	require 'sinatra-paypal'

Then set the email of the paypal account where you want the payments to be sent:

	configure do
		settings.paypal.email = 'my.company@gmail.com'
	end

There are other configuration options you could use, but only setting the destination email is required.

Add the following to your app. It will get called only when the payment is complete:
	
	# if this gets called, then you can be sure that the payment has passed validation
	# with paypal, but you will still have to do your own validation - users can fiddle
	# with the form fields before it gets sent to paypal - the only thing you can be sure
	# of it the $ amount - if the payment is complete then this is the amount in your 
	# account.
	#
	# all the payment 'routes' get called with the payment object ('p')s containing all
	# the data for the transaction
	payment :complete do |p|
		#
		# check that the price for the item matches ours - it's possible for users to
		# change the price to whatever they want, and there is no way for paypal to check
		# this
		#
		# You could also do this in the 'payment :validate' method
		#
		halt 500, 'invalid price' if p.amount != ITEM_PRICE

		# you can put a json string in the custom_data property of the payment
		# form, and it will be deserialized into the data object - this is very 
		# useful for tracking user names etc, but remember that the contents of this
		# field are not secure - a user could set it to whatever they want
		upgrade_account p.data[:user_id]
	end

Other routes that you can use for processing:

	# validate! is called for every transaction - not just complete ones
	#
	# if it fails validation, then 'halt' with the error message - the
	# return value is ignored
	payment :validate! do |p|
		# we need a 'user_id' field in the data, otherwise its not valid
		halt 500, 'user_id required' if p.data[:user_id].nil?
	end

	# finsh is called last after all other processing is complete. It is called for
	# every transaction type. It is useful for doing logging etc.
	payment :finish do |p|
		log_payment p.id, p.amount
	end

	# repeated should return true if this transaction has been seen before - we want
	# to make sure we don't process it more than once
	payment :repeated? do |p|
		return true if transaction_list.include? p.id
		
		transaction_list.push p.id
		return false
	end

## The Payment Object

Each payment route gets passed a payment object containing all the data from paypal for the transaction. It has several useful methods to make it easier to process the payment.

	p.id 				# unique sha1 for the payment notification
	p.transaction_id 	# paypal transaction_id
	p.item_number 		# the item number set in the payment form
	p.amount 			# payment amount
	p.payment_fee 		# paypal fee amount
	p.profit 			# payment amount minus any fees
	p.data 				# custom data sent through as JSON
	p.status 			# payment status - COMPLETE, PENDING, REFUNDED etc
	p.complete?			# true if the payment status is COMPLETE
	p.is_accountable?	# true if this notification has caused you paypal balance to change
	p.reason_code 		# if the transaction is a refund the reason code will appear here
	p.fields 			# object with the raw paypal notification data

## Contributing

1. Fork it ( https://github.com/reednj/sinatra-paypal/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
