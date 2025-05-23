FROM --platform=$BUILDPLATFORM golang:1.24-alpine3.20 AS builder

WORKDIR /apps

RUN apk add --no-cache git

RUN git clone https://github.com/wy2919/docker-build-test.git .

RUN go mod init main && go mod tidy

ARG TARGETOS
ARG TARGETARCH

RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /apps/main /apps/main.go

FROM --platform=$TARGETPLATFORM alpine:3.20

WORKDIR /apps

COPY --from=builder /apps/main .

RUN apk update && apk add --no-cache docker-cli tzdata && chmod +x main

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

ARG TARGETPLATFORM

RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        echo "arm平台"; \
    fi

ENV KEY=""

#ENV SECOND=30 \
#    CODES="" \
#    WXKEY=""

#CMD ./main \
#  -second $SECOND \
#  -codes $CODES \
#  -wxkey $WXKEY

CMD ./main -k $KEY
