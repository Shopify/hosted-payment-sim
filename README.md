Shopify Offsite Gateway Simulator
===========================

This is a common API that simplifies the onboarding of new payment providers, specifically Offsite Gateways / Hosted Payment Pages, that are looking to be used on [Shopify](http://www.shopify.com). By supporting a common API for redirect, cancel, complete, and callback phases of a payment flow, we are giving gateway implementers a way to integrate with Shopify at any time, without requiring a large amount of customization or validation work or bottlenecks by the Shopify integration team.

### Getting Started

Follow these simple steps to get started.

1. Review the rest of this document
2. Sign up for a free trial of Shopify at http://www.shopify.com/. You will use this shop to place test orders against your offsite gateway.
3. Send an email to to payment-integrations@shopify.com with **Universal Offsite Dev Kit** in the subject. Be sure to include:
  + Your Shopify store URL
  + Name, URL & description of the payment provider you wish to integrate 
  + Markets served by this integration
  + List of major supported payment methods, including all credit card brands offered
  + Your most recent Certificate of PCI Compliance (if you'll be accepting credit cards)

Once we enable developer mode, which normally happens within 48 hours, you'll be ready to proceed with integration testing.

1. [Sign in](http://www.shopify.com/login) to your Shopify store.
2. Go to [Products](http://www.shopify.com/admin/products) and [add a dummy product](http://docs.shopify.com/manual/your-store/products/create-product).
2. Go to [Settings/Payments](http://www.shopify.com/admin/settings/payments), and select the **Universal Offsite Dev Kit** in the gateway dropdown.
3. Complete the 3 fields,
  + ``x_account_id`` - this is an identifier for a test merchant on your system
  + ``HMAC key`` - this is a key your gateway will use to verify requests and sign responses
  + ``POST URL`` - this is URL on your system that will properly handle [Request Values](#request-values) and is then able to provide proper [Response Values](#response-values) to various return URLs at Shopify
4. Now you're ready to test! From your admin, click the 'view your website' link, and add a product to your cart. On the cart page, click the "Check out" button, enter in some dummy info, and complete the checkout using your gateway.

> We are providing this simple implementation of an Offsite Gateway Sim as a way to demonstrate basics of this new API. If you want to see it in action, leave ``POST URL`` on your **Universal Offsite Dev Kit** empty, or set it to ``https://offsite-gateway-sim.herokuapp.com/``, then try placing another order in your test shop.

> Note: The **Universal Offsite Dev Kit** will not support a separate ``POST URL`` for each merchant. However, you can get around this by using some field identifier (eg/ common prefix of the ``x_account_id`` field) as a basis to redirect from the POST URL to an appropriate hosted payment page based on that identifier.   

### Payment Flow

+ Customer initiates checkout on the Shopify storefront
+ Browser is redirected to gateway's URL using a POST request along with [Request Values](#request-values) (mandatory + whatever else may be available)
+ Gateway verifies ``x_signature`` value and presents their own payment flow to the customer (see [Signing Mechanism](#signing-mechanism))
+ Customers who exit the payment flow before successfully completing it should be redirected back to ``x_url_cancel``
+ Customers who complete the payment flow should be redirected back to ``x_url_complete`` with all required [Response Values](#response-values) as query parameters, including ``x_signature`` (see [Signing Mechanism](#signing-mechanism))
+ We strongly recommend that gateway also POSTs a callback asynchronously to ``x_url_callback`` with the same [Response Values](#response-values). This ensures that order can be completed even in cases where customer's connection to Shopify is terminated prematurely
 + HTTP 200 indicates successful receipt of a callback by Shopify. Otherwise up to 5 retries with an interval of at least 60 seconds are recommended
 + Duplicate notifications for the same ``x_reference`` are ignored by Shopify

### Signing Mechanism

All requests and responses must be signed/verified using ``HMAC-SHA256`` ([HMAC](http://en.wikipedia.org/wiki/Hash-based_message_authentication_code)) where,

+ ``key`` is a value known to both Shopify (``HMAC key`` field in gateway settings) and the gateway itself
+ ``message`` is a string of all key-value pairs that start with ``x_`` prefix, sorted alphabetically, and concatenated without any separators
  + Resulting codes must be hex-encoded and passed as value of ``x_signature``
  + Make sure to use case-insensitive comparison when verifying provided ``x_signature`` values

For example, (assuming your ``HMAC key`` is "iU44RWxeik"):

```ruby
fields = {x_account_id: Z9s7Yt0Txsqbbx, x_amount: 89.99, x_currency: 'USD', x_gateway_reference: '123', x_reference: "19783", x_result: "completed", x_test: "true",  x_timestamp: '2014-03-24T12:15:41Z'}
=> {:x_account_id=>Z9s7Yt0Txsqbbx, :x_amount=>89.99, :x_currency=>"USD", :x_gateway_reference=>"123", :x_reference=>"19783", :x_result=>"completed", :x_test=>"true", :x_timestamp=>"2014-03-24T12:15:41Z"}
message = fields.sort.join
=> "x_account_id123x_currencyUSDx_gateway_reference123x_reference19783x_resultcompletedx_testtruex_timestamp2014-03-24T12:15:41Z"
OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), 'iU44RWxeik', message)
=> "06880fd563ff6ce535d06a80ce8f2c2b79f34925d57de750ac392bc2d23c74e56"

"x_signature=06880fd563ff6ce535d06a80ce8f2c2b79f34925d57de750ac392bc2d23c74e56"
```

> You may use the provided [Signature Calculator](http://offsite-gateway-sim.herokuapp.com/calculator) to confirm that your signature generation function is working appropritately.

### Going Live

As soon as you are confident that your implementation is complete, please send another email to payment-integrations@shopify.com with the following details:

  + A link to a live (non-test) order processed with the Universal DevKit. eg/ ``http://shopname.myshopify.com/orders/123123123``
  + Names for any fields that your gateway will require shops to input when setting it up within Shopify.
    + Your gateway name
    + Label for the ``x_account_id`` field, needs to match your existing terminology, e.g. ``Merchant ID`` or ``Account #``
    + Label for the ``HMAC key`` field, needs to match your existing terminology, e.g. ``Key`` or ``Shared Secret``
  + URL of a POST handler for [Request Values](#request-values) that presents a payment flow to the customer, likely the same one you used to configure *Universal Offsite Dev Kit* gateway during integration testing
  + Test credentials for the integration
  + Your gateway's home page URL
  + Provider logo (minimum resolution 500 x 500 pixels) in vector format (SVG) or raster format (PNG), with a transparent background
  + Image to display to customers during checkout process that identifies your gateway's supported payment options (PNG, height: 20px, max width: 340px). 
  + Finally, please indicate whether or not your gateway supports ``x_test`` mode

### Request Values

| Key                                | Type                                                          | Mandatory | Example                                  | Comment                                                                          |
| ---------------------------------  |:-------------------------------------------------------------:|:---------:|:----------------------------------------:|----------------------------------------------------------------------------------|
| ``x_account_id``                   | unicode string                                                | ✓         | Z9s7Yt0Txsqbbx                           | This is an account identifier assigned to the merchant by the payment processor. |
| ``x_currency``                     | [iso-4217](http://en.wikipedia.org/wiki/ISO_4217)             | ✓         | USD                                      |                                                                                  |
| ``x_amount``                       | decimal                                                       | ✓         | 89.99                                    |                                                                                  |
| ``x_amount_shipping``              | decimal                                                       |           | 8.99                                     |                                                                                  |
| ``x_amount_tax``                   | decimal                                                       |           | 11.70                                    |                                                                                  |
| ``x_reference``                    | ascii string                                                  | ✓         | 19783                                    | Unique reference of an order assigned by the merchant.                           |
| ``x_shop_country``                 | [iso-3166-1 alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1) | ✓         | US                                       |                                                                                  |
| ``x_shop_name``                    | unicode string                                                | ✓         | Widgets Inc                              |                                                                                  |
| ``x_transaction_type``             | ascii string                                                  |           | sale                                     |                                                                                  |
| ``x_description``                  | unicode string                                                |           | Order #123                               |                                                                                  |
| ``x_invoice``                      | unicode string                                                |           | #123                                     |                                                                                  |
| ``x_test``                         | true/false                                                    | ✓         | true                                     | Indicates whether or not this request should be processed in test mode (if supported). |
| ``x_customer_first_name``          | unicode string                                                |           | Boris                                    |                                                                                  |
| ``x_customer_last_name``           | unicode string                                                |           | Slobodin                                 |                                                                                  |
| ``x_customer_email``               | unicode string                                                |           | boris.slobodin@example.com               |                                                                                  |
| ``x_customer_phone``               | unicode string                                                |           | +1-613-987-6543                          |                                                                                  |
| ``x_customer_shipping_city``       | unicode string                                                |           | Toronto                                  |                                                                                  |
| ``x_customer_shipping_company``    | unicode string                                                |           | Shopify Toronto                          |                                                                                  |
| ``x_customer_shipping_address1``   | unicode string                                                |           | 241 Spadina Ave                          |                                                                                  |
| ``x_customer_shipping_address2``   | unicode string                                                |           |                                          |                                                                                  |
| ``x_customer_shipping_state``      | unicode string                                                |           | ON                                       |                                                                                  |
| ``x_customer_shipping_zip``        | unicode string                                                |           | M5T 3A8                                  |                                                                                  |
| ``x_customer_shipping_country``    | [iso-3166-1 alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1) |           | CA                                       |                                                                                  |
| ``x_customer_shipping_phone``      | unicode string                                                |           | +1-416-123-4567                          |                                                                                  |
| ``x_url_callback``                 | url                                                           | ✓         | https://myshopify.io/ping/1              | URL to which a callback notification should be sent asynchronously.              |
| ``x_url_cancel``                   | url                                                           | ✓         | https://myshopify.io                     | URL to which customer must be redirected when they wish to quit payment flow and return to the merchant's site. |
| ``x_url_complete``                 | url                                                           | ✓         | https://myshopify.io/orders/1/done       | URL to which customer must be redirected upon successfully completing payment flow. |
| ``x_timestamp``                    | [iso-8601](http://en.wikipedia.org/wiki/ISO_8601) in UTC      | ✓         | 2014-03-24T12:13:12Z                     |                                                                                  |
| ``x_signature``                    | hex string, case-insensitive                                  | ✓         | 3a59e201a9b8692702b8c41dcba476d4a46e5f5c | See [Signing Mechanism](#signing-mechanism).                                     |

### Response Values

| Key                     | Type                                                     | Mandatory | Example                                  | Comment                                                                 |
| ------------------------|:--------------------------------------------------------:|:---------:|------------------------------------------|-------------------------------------------------------------------------|
| ``x_account_id``        | unicode string                                           | ✓         | Z9s7Yt0Txsqbbx                           | Echo request's ``x_account_id``                                         |
| ``x_reference``         | ascii string                                             | ✓         | 19783                                    | Echo request's ``x_reference``                                          |
| ``x_currency``          | [iso-4217](http://en.wikipedia.org/wiki/ISO_4217)        | ✓         | USD                                      | Echo request's ``x_currency``                                           |
| ``x_test``              | true/false                                               | ✓         | true                                     | Echo request's ``x_test``                                               |
| ``x_amount``            | decimal                                                  | ✓         | 89.99                                    | Echo request's ``x_amount``                                             |
| ``x_gateway_reference`` | unicode string                                           | ✓         | 123                                      | Unique reference for the authorization issued by the payment processor. |
| ``x_timestamp``         | [iso-8601](http://en.wikipedia.org/wiki/ISO_8601) in UTC | ✓         | 2014-03-24T12:15:41Z                     | Time of transaction completion.<br>UTC Time: YYYY-MM-DDTHH:MM:SSZ                                                                        |
| ``x_result``            | fixed choice                                             | ✓         | completed                                | One of: completed, failed, pending                                      |
| ``x_signature``         | hex string, case-insensitive                             | ✓         | 49d3166063b4d881b50af0b4648c1244bfa9890a53ed6bce6d2386404b610777 | See [Signing Mechanism](#signing-mechanism).                            |
