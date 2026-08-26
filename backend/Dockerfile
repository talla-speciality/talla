FROM node:20-alpine

WORKDIR /app

COPY backend/package.json backend/package-lock.json ./
RUN npm ci --omit=dev

COPY backend/*.js ./
COPY backend/admin ./admin
COPY backend/assets ./assets
COPY backend/data ./data
COPY backend/migrations ./migrations
COPY WalletPass ./WalletPass

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=8787

EXPOSE 8787

CMD ["npm", "start"]
