# ---- Build stage ----
FROM node:20-alpine AS build
LABEL maintainer="qzee-dev"
WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm install --legacy-peer-deps

# Copy app source
COPY . .

# ---- Production stage ----
FROM node:20-alpine AS production

WORKDIR /app

# Copy only necessary files from build stage
COPY --from=build /app /app

# Security: use non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose API port
EXPOSE 1004

# Start the server
CMD ["node", "server.js"]