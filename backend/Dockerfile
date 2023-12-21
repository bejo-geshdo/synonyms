#TODO more spcific version of node and alpine
FROM node:18-alpine as deps

WORKDIR /app

# Copies the file required to install deps
COPY package.json package-lock.json ./
# Installs the dependencies
RUN npm ci

FROM node:18-alpine as build

WORKDIR /app

COPY --from=deps /app .
COPY . .
# Transpiles typescript to javascript
RUN npm run build
# Removes dev dependencies
RUN npm prune --production

FROM node:18-alpine as run

WORKDIR /app
# Installs dumb init, this makes sures that node can be shutdown corectly
RUN apk add dumb-init

# Copies files from previus step and makes user "node" the owner
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/package.json /app/package-lock.json ./
COPY --from=build --chown=node:node /app/dist ./dist

# Tells node and express js that it's in production, improving performance
ENV NODE_ENV production

EXPOSE 8080
# Change user to code to improve security
USER node
ENTRYPOINT ["dumb-init", "node", "dist/src/index.js"]
