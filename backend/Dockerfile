FROM node:20-bookworm-slim

WORKDIR /app

# Update OS security packages
RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# Upgrade npm compatible with Node 20
RUN npm install -g npm@10

COPY package*.json ./

RUN npm ci --omit=dev

COPY . .

EXPOSE 5000

CMD ["node", "index.js"]
