FROM golang:1.27.1 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go install github.com/swaggo/swag/cmd/swag@v1.16.6

RUN /go/bin/swag init -g cmd/danfse/main.go -o ./api/swagger

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o danfse-service ./cmd/danfse

FROM alpine:latest

RUN apk update && apk add --no-cache \
    ca-certificates \
    tzdata

ENV TZ=America/Sao_Paulo \
    SERVER_PORT=8080

WORKDIR /app

COPY --from=builder /app/danfse-service .

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=15s --retries=5 \
    CMD wget -q -O - http://127.0.0.1:8080/health/live || exit 1

ENTRYPOINT ["./danfse-service"]
