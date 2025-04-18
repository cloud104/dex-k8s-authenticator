ARG ARCH
FROM ${ARCH}golang:1.21.4-alpine3.18 AS build

RUN apk --no-cache add \
    alpine-sdk=~"1.0" \
    bash=~"5.2.15"

ENV GO111MODULE=on

WORKDIR /app

COPY go.mod .
COPY go.sum .

RUN go mod download

COPY . .

RUN make build

FROM ${ARCH}alpine:3.18.4

# Dex connectors, such as GitHub and Google logins require root certificates.
# Proper installations should manage those certificates, but it's a bad user
# experience when this doesn't work out of the box.
#
# OpenSSL is required so wget can query HTTPS endpoints for health checking.
RUN apk --no-cache add \
    ca-certificates=~"20230506" \
    openssl=~"3.1.4" \
    curl=~"8.4.0" \
    tini=~"0.19.0"

RUN mkdir -p /app/bin
COPY --from=build /app/bin/dex-k8s-authenticator /app/bin/
COPY --from=build /app/html /app/html
COPY --from=build /app/templates /app/templates

# Add any required certs/key by mounting a volume on /certs
# The entrypoint will copy them and run update-ca-certificates at startup
RUN mkdir -p /certs

WORKDIR /app

COPY entrypoint.sh /
RUN chmod a+x /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]

CMD ["--help"]
