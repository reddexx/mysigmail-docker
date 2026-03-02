FROM node:20-bullseye-slim AS builder

WORKDIR /app

# Build can be skipped if SKIP_BUILD=1 is passed (dist is already present in context)
ARG SKIP_BUILD=0

# Copy package manifests first for better caching
COPY package.json package-lock.json* pnpm-lock.yaml* bun.lock* ./

# Copy rest of the sources (including dist if already built on runner)
COPY . .

# Ensure local binaries are available in PATH
ENV PATH=/app/node_modules/.bin:$PATH

# If SKIP_BUILD=1 and dist exists, skip install/build. Otherwise install and build.
RUN corepack enable || true
RUN if [ "$SKIP_BUILD" = "1" ] && [ -d /app/dist ]; then \
			echo "Dist present and SKIP_BUILD=1 — skipping install & build"; \
		else \
			if [ -f pnpm-lock.yaml ]; then \
				corepack prepare pnpm@latest --activate && pnpm install --frozen-lockfile; \
			else \
				npm install --legacy-peer-deps --no-audit --no-fund; \
			fi; \
			npm run build || (echo "Build failed" && exit 2); \
		fi

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
