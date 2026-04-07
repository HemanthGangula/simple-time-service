# Stage 1: Build
FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-w -s" -o timeservice .


# Stage 2: Final image
FROM alpine:3.19

# Create a non-root user manually (required by the assessment)
RUN adduser -D -u 1001 appuser

COPY --from=builder /build/timeservice /timeservice

EXPOSE 8080

USER appuser

ENTRYPOINT ["/timeservice"]
