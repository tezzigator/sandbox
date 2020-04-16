FROM alpine:3.11.5 AS builder

ARG ENV=test
ARG OPAM_VER=2.0.6
ARG BRANCH=mainnet
ARG RELEASE=v1.0.0

RUN apk update && apk add \
    rsync \
    git \
    m4 \
    build-base \
    patch \
    unzip \
    pkgconfig \
    gmp-dev \
    libev-dev \
    hidapi \
    opam

RUN opam init --bare --disable-sandbox --shell-setup && \
    mkdir /root/bin && \
    cd /root && \
    git clone -b $BRANCH https://gitlab.com/tezos/tezos.git && \
    if [ "$ENV" = "test" ] ; then sed -i 's/edpkvVCdQtDJHPnkmfRZuuHWKzFetH9N9nGP8F7zkwM2BJpjbvAU1N/edpkuSLWfVU1Vq7Jg9FucPyKmma6otcMHac9zG4oU1KMHSTBpJuGQ2/g' ./tezos/src/proto_000_Ps9mPmXa/lib_protocol/data.ml ; fi

RUN cd /root/tezos && \
    make build-deps && \
    eval $(opam env) && \
    make && \
    cp tezos-* /root/bin/ && \
    cd /root/ && \
    rm -rf /root/tezos
#

FROM alpine:3.11.5 

EXPOSE 9732/tcp
EXPOSE 8732/tcp

ARG POWLEVEL=5
ARG PROTOCOL=PsCARTHAGazKbHtnKfLzQg3kms52kSRpgnDY982a9oYsSXRLQEb
ARG ENV=test
ENV TEZOS_CLIENT_UNSAFE_DISABLE_DISCLAIMER=Y
ENV ACT1="tezos-node identity generate $POWLEVEL"
ENV ACT2="tezos-node run --no-bootstrap-peers --bootstrap-threshold=0 --connections=0 --net-addr=0.0.0.0:9732 --rpc-addr=0.0.0.0:8732 --data-dir=/root/.tezos-node --history-mode=experimental-rolling"
ENV ACT3="tezos-client -b genesis -A 127.0.0.1 activate protocol $PROTOCOL with fitness $POWLEVEL and key dictator and parameters /root/sandbox-parameters.json"

WORKDIR /root

COPY --from=builder /root/bin /usr/local/bin/
COPY sandbox-parameters.json .

RUN apk update && \
    apk add \
    gmp-dev \
    libev-dev \
    hidapi \
    curl && \
    if [ "$ENV" = "test" ] ; then /usr/local/bin/tezos-client import secret key dictator unencrypted:edsk31vznjHSSpGExDMHYASz45VZqXN4DPxvsa4hAyY8dHM28cZzp6 ; fi

ENTRYPOINT ["sh"]
