# Build Stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o main main.go

# Run Stage
FROM alpine:3.19
WORKDIR /app
COPY --from=builder /app/main .
ENV PORT=8080
EXPOSE 8080
CMD ["./main"]
