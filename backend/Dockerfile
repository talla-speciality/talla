FROM node:20-alpine

WORKDIR /app

COPY backend/package.json ./package.json
COPY backend/config.js ./config.js
COPY backend/server.js ./server.js
COPY backend/data ./data
COPY WalletPass ./WalletPass

ENV HOST=0.0.0.0
ENV PORT=8787

EXPOSE 8787

CMD ["npm", "start"]
