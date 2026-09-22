# Server Build Step

FROM golang:1.25-bookworm AS server-builder

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    libc6-dev

COPY fider/go.mod fider/go.sum ./

RUN  go mod download

COPY fider/ ./

RUN CGO_ENABLED=1 make build-server \
    LDFLAGS='-linkmode external -extldflags "-static"'

# UI Build Step

FROM node:22-bookworm AS ui-builder

WORKDIR /app

COPY fider/package.json fider/package-lock.json ./

RUN npm ci

COPY fider/ ./

RUN make build-ssr
RUN make build-ui

# Runtime Step

FROM scratch

WORKDIR /app

COPY --from=server-builder /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/certs/ca-certificates.crt

COPY --from=server-builder /app/migrations /app/migrations
COPY --from=server-builder /app/views /app/views
COPY --from=server-builder /app/locale /app/locale
COPY --from=server-builder /app/LICENSE /app/
COPY --from=server-builder /app/fider /app/fider
COPY --from=server-builder /app/static /app/static

COPY --from=ui-builder /app/favicon.png /app/
COPY --from=ui-builder /app/dist /app/dist
COPY --from=ui-builder /app/robots.txt /app/
COPY --from=ui-builder /app/ssr.js /app/

USER 10001

EXPOSE 3000

HEALTHCHECK --timeout=5s CMD ["/app/fider", "ping"]

CMD ["/app/fider"]
