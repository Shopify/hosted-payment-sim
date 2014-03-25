Shopify Offsite Simulator
===========================

This is an idea we are exploring to simplify onboarding of new offsite gateways. By implementing a common offsite API for redirect/cancel/complete/callback phases, we can avoid having to touch Active Merchant code altogether. Instead, payment processor who implements this API must simply provide the following items to Shopify,

+ ``label:`` Label for the offsite gateway that shop owners will see when configuring it in Admin/Settings/Checkout
+ ``credential1:`` Label for the ``x-account-id`` parameter, which will be visible to the merchant under Admin/Settings/Checkout
+ ``credential2:`` Label for the HMAC secret key, which will be visible to the merchant Admin/Settings/Checkout
+ ``option1:`` URL of a POST handler for **Request Values** listed below that presents a payment flow to the customer
+ ``test_mode:`` Indicator of whether or not ``x-test`` mode is supported
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
  option1: https://pay.slobodin.ca/go
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

### Payment Flow

+ Customer initiates checkout on Shopify
+ Browser is redirected to ``option1:`` URL using a POST request along with [Request Values](#request-values) (mandatory + whatever else is available)
+ Processor verifies ``x-signature`` value and presents their own payment flow to the customer (see [Signing Mechanism](#signing-mechanism))
+ Customers who quit the payment flow without completing it, should be redirected back to ``x-url-cancel``
+ Customers who complete the payment flow, should be redirected back to ``x-url-complete`` with all required [Response Values](#response-values) as query parameters, including ``x-signature`` (see [Signing Mechanism](#signing-mechanism))
+ Processor is also encouraged (but not required) to POST a callback asynchronously to ``x-url-callback`` with the same [Response Values](#response-values), in case customer closes the browser prematurely
 + HTTP 200 indicates successful receipt of a callback by Shopify, otherwise up to 5 retries with an interval of at least 60 seconds are recommended
 + Duplicate notifications for the same ``x-reference`` are ignored by Shopify

### Signing Mechanism

All requests and responses must be signed/verified using ``HMAC-SHA256`` ([HMAC](http://en.wikipedia.org/wiki/Hash-based_message_authentication_code)) where ``key`` is a value of ``credential2`` and ``message`` is a string of all key-value pairs that start with ``x-`` prefix, sorted alphabetically, and concatenated without any separators. Resulting codes must be hex-encoded and passed as value of ``x-signature``.

```ruby
digest = OpenSSL::Digest.new('sha256')
OpenSSL::HMAC.hexdigest(digest, "secret key", "x-a=1x-b=2")

"x-signature=a7b44bbfdfb4b3b191bb0f3ff44d0e7e8f5cae5ed18d20e728b816fdaaf80319"
```

### Request Values

| Key                        | Type                                                          | Mandatory | Example                                  | Comment                                                                          |
| -------------------------- |:-------------------------------------------------------------:|:---------:|:----------------------------------------:|----------------------------------------------------------------------------------|
| ``x-account-id``           | unicode string                                                | ✓         | Z9s7Yt0Txsqbbx                           | This is an account identifier assigned to the merchant by the payment processor. |
| ``x-currency``             | [iso-4217](http://en.wikipedia.org/wiki/ISO_4217)             | ✓         | USD                                      |                                                                                  |
| ``x-amount``               | decimal                                                       | ✓         | 89.99                                    |                                                                                  |
| ``x-amount-shipping``      | decimal                                                       |           | 8.99                                     |                                                                                  |
| ``x-amount-tax``           | decimal                                                       |           | 11.70                                    |                                                                                  |
| ``x-shop-country``         | [iso-3166-1 alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1) | ✓         | US                                       |                                                                                  |
| ``x-shop-name``            | unicode string                                                | ✓         | Widgets Inc                              |                                                                                  |
| ``x-transaction-type``     | ascii string                                                  |           |                                          |                                                                                  |
| ``x-description``          | unicode string                                                |           | Order #123                               |                                                                                  |
| ``x-invoice``              | unicode string                                                |           | #123                                     |                                                                                  |
| ``x-test``                 | true/false                                                    | ✓         | true                                     | Indicates whether or not this request should be processed in test mode (if supported). |
| ``x-reference``            | ascii string                                                  | ✓         | 19783                                    | Unique reference of an order assigned by the merchant.                           |
| ``x-customer-first-name``  | unicode string                                                |           | Boris                                    |                                                                                  |
| ``x-customer-last-name``   | unicode string                                                |           | Slobodin                                 |                                                                                  |
| ``x-customer-email``       | unicode string                                                |           | boris.slobodin@example.com               |                                                                                  |
| ``x-customer-city``        | unicode string                                                |           | Ottawa                                   |                                                                                  |
| ``x-customer-company``     | unicode string                                                |           | Shopify Inc                              |                                                                                  |
| ``x-customer-address1``    | unicode string                                                |           | 126 York St                              |                                                                                  |
| ``x-customer-address2``    | unicode string                                                |           | Second Floor                             |                                                                                  |
| ``x-customer-state``       | unicode string                                                |           | ON                                       |                                                                                  |
| ``x-customer-zip``         | unicode string                                                |           | K1N 5T5                                  |                                                                                  |
| ``x-customer-country``     | [iso-3166-1 alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1) |           | CA                                       |                                                                                  |
| ``x-customer-phone``       | unicode string                                                |           | +1 888-329-0139                          |                                                                                  |
| ``x-url-callback``         | url                                                           | ✓         | https://myshopify.io/ping/1              | URL to which a callback notification should be sent asynchronously.              |
| ``x-url-cancel``           | url                                                           | ✓         | https://myshopify.io                     | URL to which customer must be redirected when they wish to quit payment flow and return to the merchant's site. |
| ``x-url-complete``         | url                                                           | ✓         | https://myshopify.io/orders/1/done       | URL to which customer must be redirected upon completing payment flow regardless of outcome. |
| ``x-timestamp``            | [iso-8601](http://en.wikipedia.org/wiki/ISO_8601)             | ✓         | 2014-03-24T12:13:12Z                     |                                                                                  |
| ``x-signature``            | hex string                                                    | ✓         | 3a59e201a9b8692702b8c41dcba476d4a46e5f5c | See [Signing Mechanism](#signing-mechanism).                                     |

### Response Values

| Key                     | Type                                              | Mandatory | Example                                  | Comment                                                                 |
| ------------------------|:-------------------------------------------------:|:---------:|------------------------------------------|-------------------------------------------------------------------------|
| ``x-account-id``        | unicode string                                    | ✓         | Z9s7Yt0Txsqbbx                           | Echo request's ``x-account-id``                                         |
| ``x-reference``         | ascii string                                      | ✓         | 19783                                    | Echo request's ``x-reference``                                          |
| ``x-currency``          | [iso-4217](http://en.wikipedia.org/wiki/ISO_4217) | ✓         | USD                                      | Echo request's ``x-currency``                                           |
| ``x-test``              | true/false                                        | ✓         | true                                     | Echo request's ``x-test``                                               |
| ``x-amount``            | decimal                                           | ✓         | 89.99                                    | Echo request's ``x-amount``                                             |
| ``x-gateway-reference`` | unicode string                                    | ✓         | 123                                      | Unique reference for the authorization issued by the payment processor. |
| ``x-timestamp``         | [iso-8601](http://en.wikipedia.org/wiki/ISO_8601) | ✓         | 2014-03-24T12:15:41Z                     |                                                                         |
| ``x-result``            | fixed choice                                      | ✓         | 123                                      | One of: success, pending, failure                                       |
| ``x-signature``         | hex string                                        | ✓         | 3a59e201a9b8692702b8c41dcba476d4a46e5f5c | See [Signing Mechanism](#signing-mechanism).                                     |

### Outstanding Questions

+ Do we need to timestamp all requests/responses? It's quite common, but I'm not convinced it provides any value.
+ Can we initiate an offsite using a GET, ideally a 302? One concern with that, is that contents of the request (including personally identifiable information) are likely to be logged by load balancers, web servers, web frameworks etcetera.
+ How should we express things like line items, shipping lines, discount lines etcetera in our [Request Values](#request-values)?