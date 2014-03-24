Shopify Offsite Simulator
===========================

This is a work-in-progress implementation of a generic offsite simulator for Shopify.

### Request Values

| Key                        | Type                                                          | Mandatory | Example                                  | Comment                                                                          |
| -------------------------- |:-------------------------------------------------------------:|:---------:|:----------------------------------------:|----------------------------------------------------------------------------------|
| ``x-account-id``           | string                                                        | ✓         | Z9s7Yt0Txsqbbx                           | This is an account identifier assigned to the merchant by the payment processor. |
| ``x-currency``             | [iso-4217](http://en.wikipedia.org/wiki/ISO_4217)             | ✓         | USD                                      |                                                                                  |
| ``x-amount``               | decimal                                                       | ✓         | 89.99                                    |                                                                                  |
| ``x-amount-shipping``      | decimal                                                       |           | 8.99                                     |                                                                                  |
| ``x-amount-tax``           | decimal                                                       |           | 11.70                                    |                                                                                  |
| ``x-shop-country``         | [iso-3166-1 alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1) | ✓         | US                                       |                                                                                  |
| ``x-shop-name``            | string                                                        | ✓         | Widgets Inc                              |                                                                                  |
| ``x-transaction-type``     | string                                                        |           |                                          |                                                                                  |
| ``x-description``          | string                                                        |           | Order #123                               |                                                                                  |
| ``x-invoice``              | string                                                        |           | #123                                     |                                                                                  |
| ``x-test``                 | true/false                                                    | ✓         | true                                     |                                                                                  |
| ``x-reference``            | string                                                        | ✓         | 19783                                    | Unique reference of an order assigned by the merchant.                           |
| ``x-customer-first-name``  | string                                                        |           | Boris                                    |                                                                                  |
| ``x-customer-last-name``   | string                                                        |           | Slobodin                                 |                                                                                  |
| ``x-customer-email``       | string                                                        |           | boris.slobodin@example.com               |                                                                                  |
| ``x-customer-city``        | string                                                        |           | Ottawa                                   |                                                                                  |
| ``x-customer-company``     | string                                                        |           | Shopify Inc                              |                                                                                  |
| ``x-customer-address1``    | string                                                        |           | 126 York St                              |                                                                                  |
| ``x-customer-address2``    | string                                                        |           | Second Floor                             |                                                                                  |
| ``x-customer-state``       | string                                                        |           | ON                                       |                                                                                  |
| ``x-customer-zip``         | string                                                        |           | K1N 5T5                                  |                                                                                  |
| ``x-customer-country``     | [iso-3166-1 alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1) |           | CA                                       |                                                                                  |
| ``x-customer-phone``       | string                                                        |           | +1 888-329-0139                          |                                                                                  |
| ``x-url-callback``         | url                                                           | ✓         | https://myshopify.io/ping/1              | URL to which a callback notification should be sent asynchronously.              |
| ``x-url-cancel``           | url                                                           | ✓         | https://myshopify.io                     | URL to which customer must be redirected when they wish to quit payment flow and return to the merchant's site. |
| ``x-url-complete``         | url                                                           | ✓         | https://myshopify.io/orders/1/done       | URL to which customer must be redirected upon completing payment flow regardless of outcome. |
| ``x-timestamp``            | [iso-8601](http://en.wikipedia.org/wiki/ISO_8601)             | ✓         | 2014-03-24T12:13:12Z                     |                                                                                  |
| ``x-signature``            | string                                                        | ✓         | 3a59e201a9b8692702b8c41dcba476d4a46e5f5c |                                                                                  |

### Response Values

| Key                     | Type                                              | Mandatory | Example              | Comment                                                                 |
| ------------------------|:-------------------------------------------------:|:---------:|----------------------|-------------------------------------------------------------------------|
| ``x-id``                | string                                            | ✓         | Z9s7Yt0Txsqbbx       | Echo request's ``x-id``                                                 |
| ``x-reference``         | string                                            | ✓         | 19783                | Echo request's ``x-reference``                                          |
| ``x-currency``          | [iso-4217](http://en.wikipedia.org/wiki/ISO_4217) | ✓         | USD                  | Echo request's ``x-currency``                                           |
| ``x-test``              | true/false                                        | ✓         | true                 | Echo request's ``x-test``                                               |
| ``x-amount``            | decimal                                           | ✓         | 89.99                | Echo request's ``x-amount``                                             |
| ``x-gateway-reference`` | string                                            | ✓         | 123                  | Unique reference for the authorization issued by the payment processor. |
| ``x-timestamp``         | [iso-8601](http://en.wikipedia.org/wiki/ISO_8601) | ✓         | 2014-03-24T12:15:41Z |                                                                         |
| ``x-result``            | choice                                            | ✓         | 123                  | One of: success, pending, failure                                       |
