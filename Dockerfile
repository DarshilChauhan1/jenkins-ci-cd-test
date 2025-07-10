FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./

RUN npm install

# Copy source code
COPY . .

CMD [ "bash" ]