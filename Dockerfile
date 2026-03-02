FROM node:20-bullseye-slim AS builder

WORKDIR /app

# Copy package manifests first for better caching
COPY package.json package-lock.json* pnpm-lock.yaml* bun.lock* ./

# Copy rest of the sources
COPY . .

# Ensure local binaries are available in PATH
ENV PATH=/app/node_modules/.bin:$PATH

# Use pnpm if lockfile present, else npm; install devDependencies reliably
RUN corepack enable || true
RUN if [ -f pnpm-lock.yaml ]; then \
			corepack prepare pnpm@latest --activate && pnpm install --frozen-lockfile; \
		else \
			npm install --legacy-peer-deps --no-audit --no-fund; \
		fi

# Build the app (fail loudly)
RUN npm run build || (echo "Build failed" && exit 2)

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
