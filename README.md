Hosted Payment Simulator
===========================

This tool will allow you to simulate the redirects and callbacks needed to build an integration using the [Hosted Payment SDK](https://docs.shopify.com/hosted-payment-sdk). It also serves as a [calculator](https://offsite-gateway-sim.shopifycloud.com/calculator) that can be used to verify your signature algorithm.

To use the simulator please familiarize yourself with the [Hosted Payment SDK](https://docs.shopify.com/hosted-payment-sdk) documentation and then:

1. Add a payment gateway with "Redirect URL" of `https://offsite-gateway-sim.shopifycloud.com/`.

2. Add your gateway to a shop (see "[Creating a development store](https://help.shopify.com/api/sdks/hosted-payment-sdk/getting-started#create-a-development-store)" if you don't have one) and activate it using these credentials:

  * **Login** - any non-empty value
  * **Password** - iU44RWxeik

3. Complete a test purchase on your shop (you may need to add a product first). At the end of checkout you will be redirected to the sceen below.

![Offsite Gateway](/offsite-gateway-sim-page.png)

The various buttons will allow you to simulate the callbacks and redirects required in your integration.

Please email payment-integrations@shopify.com if you have any questions.
