# Sinatra::Paypal

This gem makes it easy to validation and process Paypal IPN payments.

It automatically adds a route at `/payment/validate` to use as the IPN endpoint, and then adds a number of new methods to the sinatra DSL allow payment events to be captured and processed

## Usage

Install the gem and then add it to your project with:

	require 'sinatra-paypal'

Then set the email of the paypal account where you want the payments to be sent:

	configure do
		settings.paypal.email = AppConfig.paypal.email
	end

There are other configuration options you could use, but only setting the destination email is required.

Add the following to your app. It will get called only when the payment is complete:
	
	# if this gets called, then you can be sure that the payment has passed validation
	# with paypal, but you will still have to do your own validation
	#
	# all the payment 'routes' get called with the payment object containing all
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

## Contributing

1. Fork it ( https://github.com/reednj/sinatra-paypal/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
