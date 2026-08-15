# Talla universal links

The iOS app accepts HTTPS links from `talla.me` and `www.talla.me` for products,
collections, loyalty, brewing guides, order history, search, and app shortcuts.

## Shopify storefront configuration

The Talla Speciality App's Storefront API integration is configured with:

- Apple App ID: `TAG9WXY85M.Talla-Speciality.Talla-Speciality`
- Use iOS universal links: enabled

Shopify generates and serves the association file at
`https://talla.me/.well-known/apple-app-site-association`. The copy in this
directory records the expected generated response for verification; Shopify is
the source of the live file.

## Supported links

- `https://talla.me/products/<shopify-product-handle>`
- `https://talla.me/collections/<shopify-collection-handle>`
- `https://talla.me/pages/loyalty-program`
- `https://talla.me/blogs/brewing-methods/<article-handle>`
- `https://talla.me/account/orders`
- `https://talla.me/search?q=<query>`
- `https://talla.me/app/shop`
- `https://talla.me/app/rewards`
- `https://talla.me/app/brewing`
- `https://talla.me/app/concierge?q=<query>`
- `https://talla.me/app/shelf`

After the association file is live, install a freshly signed app build on a
physical device before testing links from Messages, Mail, or Notes.
