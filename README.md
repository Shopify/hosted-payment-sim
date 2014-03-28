Shopify Offsite Simulator
===========================

This is an idea we are exploring to simplify onboarding of new offsite gateways. By implementing a common offsite API for redirect/cancel/complete/callback phases, we can avoid having to touch Active Merchant code altogether. Instead, payment processor who implements this API must simply provide the following items to Shopify,

+ ``label:`` Label for the offsite gateway that shop owners will see when configuring it in Admin/Settings/Checkout
+ ``credential1:`` Label for the ``x_account_id`` parameter, which will be visible to the merchant under Admin/Settings/Checkout
+ ``credential2:`` Label for the HMAC secret key, which will be visible to the merchant Admin/Settings/Checkout
+ ``offsite_url:`` URL of a POST handler for **Request Values** listed below that presents a payment flow to the customer
+ ``test_mode:`` Indicator of whether or not ``x_test`` mode is supported
+ ``url:`` URL of a payment processor's home page, ideally with an affiliate identifier for revenue sharing, if available
+ ``/public/images/admin/icons/payment/{gateway_name}_cards.png``: image to display to customers during checkout process (PNG, height: 20px, max width: 350px)

#### Example entry in payment_providers.yml
```yml
-
  id: 103
  category: credit_card
  name: universal
  label: Comrade Yuri's Payments Emporium
  test_mode: true
  credential1: Account ID
  credential2: Account Secret
  credential3:
  credential4:
  sensitive_credentials: [ credential2 ]
  option1:
  offsite_url: https://pay.slobodin.ca/go
  attachment:
  type: offsite
  url: https://pay.slobodin.ca/?affiliate_id=y387s
  group: other
  order_management: false
  multiple_capture: false
  requires_phone: false
  beta: false
  express_name:
  countries:
    - CA
    - US
  void: false
  refund: false
  supported_card_brands:
   - master
   - visa
   - american_express
```

### Shop Configuration Flow

+ Shop admin selects ``Comrade Yuri's Payments Emporium`` in Admin/Settings/Checkout
+ They obtain values for ``Account ID`` and ``Account Secret`` from the gateway and enter them into respective fields

### Payment Flow

+ Customer initiates checkout on the Shopify storefront
+ Browser is redirected to ``offsite_url:`` URL using a POST request along with [Request Values](#request-values) (mandatory + whatever else is available)
+ Processor verifies ``x_signature`` value and presents their own payment flow to the customer (see [Signing Mechanism](#signing-mechanism))
+ Customers who exit the payment flow without successfully completing it, should be redirected back to ``x_url_cancel``
+ Customers who complete the payment flow, should be redirected back to ``x_url_complete`` with all required [Response Values](#response-values) as query parameters, including ``x_signature`` (see [Signing Mechanism](#signing-mechanism))
+ Processor is also required to POST a callback asynchronously to ``x_url_callback`` with the same [Response Values](#response-values), this ensures that order can be completed even in cases where customer closes the browser prematurely
 + HTTP 200 indicates successful receipt of a callback by Shopify, otherwise up to 5 retries with an interval of at least 60 seconds are recommended
 + Duplicate notifications for the same ``x_reference`` are ignored by Shopify

### Signing Mechanism

All requests and responses must be signed/verified using ``HMAC-SHA256`` ([HMAC](http://en.wikipedia.org/wiki/Hash-based_message_authentication_code)) where ``key`` is a value of ``credential2`` and ``message`` is a string of all key-value pairs that start with ``x_`` prefix, sorted alphabetically, and concatenated without any separators. Resulting codes must be hex-encoded and passed as value of ``x_signature``. Make sure to use case-insensitive comparison when verifying provided ``x_signature`` values.

```ruby
digest = OpenSSL::Digest.new('sha256')
OpenSSL::HMAC.hexdigest(digest, 'secret key', 'x_a=1x_b=2')

"x_signature=4c1c3fff26e479fbb6fba4148f98cc257936b57e89877b43b1306e7591a0c534"
```

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
| ``x_customer_billing_city``        | unicode string                                                |           | Ottawa                                   |                                                                                  |
| ``x_customer_billing_company``     | unicode string                                                |           | Shopify Ottawa                           |                                                                                  |
| ``x_customer_billing_address1``    | unicode string                                                |           | 126 York St                              |                                                                                  |
| ``x_customer_billing_address2``    | unicode string                                                |           | Second Floor                             |                                                                                  |
| ``x_customer_billing_state``       | unicode string                                                |           | ON                                       |                                                                                  |
| ``x_customer_billing_zip``         | unicode string                                                |           | K1N 5T5                                  |                                                                                  |
| ``x_customer_billing_country``     | [iso-3166-1 alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1) |           | CA                                       |                                                                                  |
| ``x_customer_billing_phone``       | unicode string                                                |           | +1-613-987-6543                          |                                                                                  |
| ``x_customer_shipping_first_name`` | unicode string                                                |           | Cody                                     |                                                                                  |
| ``x_customer_shipping_last_name``  | unicode string                                                |           | Fauser                                   |                                                                                  |
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
| ``x_signature``                    | hex string                                                    | ✓         | 3a59e201a9b8692702b8c41dcba476d4a46e5f5c | See [Signing Mechanism](#signing-mechanism).                                     |

### Response Values

| Key                     | Type                                                     | Mandatory | Example                                  | Comment                                                                 |
| ------------------------|:--------------------------------------------------------:|:---------:|------------------------------------------|-------------------------------------------------------------------------|
| ``x_account_id``        | unicode string                                           | ✓         | Z9s7Yt0Txsqbbx                           | Echo request's ``x_account_id``                                         |
| ``x_reference``         | ascii string                                             | ✓         | 19783                                    | Echo request's ``x_reference``                                          |
| ``x_currency``          | [iso-4217](http://en.wikipedia.org/wiki/ISO_4217)        | ✓         | USD                                      | Echo request's ``x_currency``                                           |
| ``x_test``              | true/false                                               | ✓         | true                                     | Echo request's ``x_test``                                               |
| ``x_amount``            | decimal                                                  | ✓         | 89.99                                    | Echo request's ``x_amount``                                             |
| ``x_gateway_reference`` | unicode string                                           | ✓         | 123                                      | Unique reference for the authorization issued by the payment processor. |
| ``x_timestamp``         | [iso-8601](http://en.wikipedia.org/wiki/ISO_8601) in UTC | ✓         | 2014-03-24T12:15:41Z                     |                                                                         |
| ``x_result``            | fixed choice                                             | ✓         | 123                                      | One of: success, pending, failure                                       |
| ``x_signature``         | hex string                                               | ✓         | 3a59e201a9b8692702b8c41dcba476d4a46e5f5c | See [Signing Mechanism](#signing-mechanism).                            |

### Outstanding Questions

+ Should we add some fields? Should we remove some fields? Should we clarify some of the fields' types?
+ Do we need to timestamp all requests/responses? It's quite common, but I'm not convinced it provides any value.
+ How should we express things like line items, shipping lines, discount lines etcetera in our [Request Values](#request-values)?