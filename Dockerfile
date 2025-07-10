# Multi-stage build for production
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
COPY tsconfig*.json ./
COPY nest-cli.json ./

# Install dependencies
RUN npm install --only=production --silent

# Copy source code and build
COPY src/ ./src/
RUN npm run build

# Production stage
FROM node:22-alpine AS production

WORKDIR /app

# Copy package files and install only production dependencies
COPY package*.json ./
RUN npm ci --only=production --silent && npm cache clean --force

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001
USER nestjs

# Expose port
EXPOSE 3000

CMD [ "npm", "run", "start" ]

# FROM jenkins/jenkins:2.504.3-jdk21
# USER root
# RUN apt-get update && apt-get install -y lsb-release ca-certificates curl && \
#     install -m 0755 -d /etc/apt/keyrings && \
#     curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
#     chmod a+r /etc/apt/keyrings/docker.asc && \
#     echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
#     https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" \
#     | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
#     apt-get update && apt-get install -y docker-ce-cli && \
#     apt-get clean && rm -rf /var/lib/apt/lists/*
# USER jenkins
# RUN jenkins-plugin-cli --plugins "blueocean docker-workflow json-path-api"