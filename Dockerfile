# ------------------------------------------------------------------------------
# Stage 1: Rust Builder
# ------------------------------------------------------------------------------
FROM osgeo/gdal:ubuntu-small-3.4.1 as rust-builder

# Install system dependencies
RUN apt-get update && apt-get -y install \
    curl build-essential pkg-config libssl-dev libclang-dev cmake libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# 👇 CHANGED FROM 'nightly' TO 'stable' TO FIX BUILD CRASH
RUN rustup default stable

# Install wasm-pack
RUN curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh

WORKDIR /app

# Copy manifests first to cache dependencies
COPY ./Cargo.toml ./Cargo.lock ./
# We create dummy dirs to satisfy COPY, actual source comes later
COPY ./matico_spec ./matico_spec
COPY ./matico_spec_derive ./matico_spec_derive
COPY ./matico_server ./matico_server
COPY ./matico_common ./matico_common
# EXCLUDING COMPUTE FOR NOW to avoid Polars breakages
# COPY ./matico_compute ./matico_compute
COPY ./matico_types ./matico_types
COPY ./scripts ./scripts

# Update the broken dependency
RUN cargo update -p wasm-bindgen

# Build Server
RUN cargo build --release --bin matico_server

# Build WASM Spec
WORKDIR /app/matico_spec

# Create static directory structure
RUN mkdir -p /app/matico_server/static/compute/

# Return to root and build types
WORKDIR /app
RUN ./scripts/build_types.sh

# ------------------------------------------------------------------------------
# Stage 2: JavaScript Dependencies
# ------------------------------------------------------------------------------
FROM node:18-alpine as javascript_deps
ENV NODE_ENV production
# Skip Husky hooks in Docker
ENV HUSKY=0
# Install system deps for native builds
RUN apk --no-cache add shadow gcc musl-dev autoconf automake make libtool nasm tiff jpeg zlib zlib-dev file pkgconf libc6-compat git
WORKDIR /app

# Enable pnpm via Corepack
RUN corepack enable && corepack prepare pnpm@10.22.0 --activate

# Copy workspace configs
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY matico_components/package.json ./matico_components/package.json
COPY matico_admin/package.json ./matico_admin/package.json
COPY matico_charts/package.json ./matico_charts/package.json
# Copy built WASM/Types from Rust stage
COPY --from=rust-builder /app/matico_spec/pkg ./matico_spec/pkg
COPY --from=rust-builder /app/matico_spec/package.json ./matico_spec/package.json
COPY --from=rust-builder /app/matico_types ./matico_types

# Install dependencies (force installation of devDeps for building)
RUN pnpm install --frozen-lockfile --prod=false

# ------------------------------------------------------------------------------
# Stage 3: Frontend Builder
# ------------------------------------------------------------------------------
FROM node:18-alpine as frontend-builder
ENV NODE_ENV production
RUN corepack enable && corepack prepare pnpm@10.22.0 --activate

WORKDIR /app

# Copy node_modules from previous stage
COPY --from=javascript_deps /app ./

# Copy source code
COPY matico_components ./matico_components
COPY matico_admin ./matico_admin
COPY matico_charts ./matico_charts

# Build packages in order
RUN pnpm --filter @maticoapp/matico_charts run build-prod
RUN pnpm --filter @maticoapp/matico_components run build-prod
ENV NEXT_PUBLIC_SERVER_URL="/api"
RUN pnpm --filter matico_admin run build

# ------------------------------------------------------------------------------
# Stage 4: Runtime
# ------------------------------------------------------------------------------
FROM osgeo/gdal:ubuntu-small-3.4.1

ENV NODE_ENV production
ARG APP=/usr/src/app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates tzdata nginx curl gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Install PM2 globally
RUN npm install pm2 -g

# Create App User
ENV TZ=Etc/UTC \
    APP_USER=appuser
RUN groupadd $APP_USER \
    && useradd -g $APP_USER $APP_USER \
    && mkdir -p ${APP}

WORKDIR ${APP}

# Copy built artifacts
COPY --from=frontend-builder /app/matico_admin ${APP}/matico_admin
COPY --from=frontend-builder /app/node_modules ${APP}/node_modules
COPY --from=rust-builder /app/target/release/matico_server ${APP}/matico_server

# Copy scripts
COPY scripts/run_docker_prod.sh ./
COPY scripts/nginx.conf /etc/nginx/nginx.conf

# Fix permissions
RUN chmod +x run_docker_prod.sh

# Expose Ports
EXPOSE 8000 3000

CMD ["/bin/bash", "run_docker_prod.sh"]