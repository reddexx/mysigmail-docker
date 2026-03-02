FROM node:20-bullseye-slim AS builder

WORKDIR /app

# Copy package manifests first for better caching
COPY package.json package-lock.json* pnpm-lock.yaml* bun.lock* ./
COPY . .

# Use pnpm if lockfile present, else npm
RUN corepack enable || true
RUN if [ -f pnpm-lock.yaml ]; then corepack prepare pnpm@latest --activate && pnpm install --frozen-lockfile; elif [ -f package-lock.json ]; then npm ci; else npm install; fi

# Build the app
RUN npm run build || pnpm run build || (echo "Build failed" && exit 2)

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
