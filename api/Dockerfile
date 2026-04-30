FROM node:20-alpine

# curl para healthcheck de Coolify
RUN apk add --no-cache curl

WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .

EXPOSE 3000
CMD ["node", "src/index.js"]
