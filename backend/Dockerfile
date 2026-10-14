FROM node:22-bookworm

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-venv \
    && python3 -m venv /opt/coffee-ai-venv \
    && /opt/coffee-ai-venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/coffee-ai-venv/bin/pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch \
    && rm -rf /var/lib/apt/lists/*

COPY backend/package.json backend/package-lock.json ./
RUN npm ci --omit=dev

COPY backend/*.js ./
COPY backend/modules ./modules
COPY backend/admin ./admin
COPY backend/assets ./assets
COPY backend/data ./data
COPY backend/migrations ./migrations
COPY WalletPass ./WalletPass
COPY coffee_ai_from_scratch/serve.py /opt/coffee_ai/serve.py
COPY coffee_ai_from_scratch/model.py /opt/coffee_ai/model.py
COPY coffee_ai_from_scratch/tokenizer.py /opt/coffee_ai/tokenizer.py
COPY coffee_ai_from_scratch/data/tokenizer.json /opt/coffee_ai/data/tokenizer.json
COPY coffee_ai_from_scratch/coffee_ai.pt /opt/coffee_ai/coffee_ai.pt

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=8787
ENV COFFEE_AI_PATH=/opt/coffee_ai
ENV COFFEE_AI_PYTHON=/opt/coffee-ai-venv/bin/python

EXPOSE 8787

CMD ["npm", "start"]
