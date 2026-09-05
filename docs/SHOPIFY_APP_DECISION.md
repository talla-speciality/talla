# Shopify app decision

Decision: remove the nested `talla-speciality-app` starter from active development and from the release pipeline.

The directory is an untracked, separately initialized Shopify starter with no commits and no Talla-specific production behavior. Talla's supported Shopify integration already lives in `backend/server.js`: Storefront checkout, order webhooks, EazyPay reconciliation, product controls, and order export. Developing a second embedded Shopify application would duplicate authentication, deployment, data ownership, and operational responsibility without a defined merchant workflow.

Reconsider an embedded app only when a concrete Shopify Admin use case cannot be delivered safely through the existing backend/admin console. That proposal must name the merchant users, required scopes, data retention, webhook ownership, deployment environment, and acceptance tests before code is generated.

The local starter was removed from the active checkout and preserved at `/Users/ahmad/Documents/talla-speciality-app-starter-archive-2026-09-04`. The old repository path remains ignored by `.gitignore`, so the starter cannot silently re-enter a release artifact.
