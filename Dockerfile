FROM node:22

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./

RUN npm install

# Copy source code
COPY . .

CMD [ "bash" ]