#!/bin/bash
set -e -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
mkdir -p $SCRIPT_DIR/certs-ecdsa
pushd $SCRIPT_DIR/certs-ecdsa

# ECDSA CAs
step certificate create root-ca root-ca.crt root-ca.key \
    --profile root-ca --not-after=100000h --insecure --no-password --force
step certificate create intermediate-ca intermediate-ca.crt intermediate-ca.key \
    --profile intermediate-ca --ca ./root-ca.crt --ca-key ./root-ca.key \
    --not-after=100000h --insecure --no-password --force
# Leaf cert
step certificate create localhost server.crt server.key \
    --ca ./intermediate-ca.crt --ca-key ./intermediate-ca.key \
    --not-after=100000h --bundle \
    --insecure --no-password --force
# Merged PEM
cat server.crt server.key > server-merged.pem

# Expired cert
step certificate create localhost server-expired.crt server-expired.key \
    --ca ./intermediate-ca.crt --ca-key ./intermediate-ca.key \
    --not-before=-24h --not-after=-1h --bundle \
    --insecure --no-password --force
# Merged PEM
cat server-expired.crt server-expired.key > server-expired-merged.pem
rm root-ca.key

chmod 664 *

popd
mkdir -p $SCRIPT_DIR/certs-rsa
pushd $SCRIPT_DIR/certs-rsa

# RSA CA
step certificate create root-ca root-ca.crt root-ca.key --profile root-ca \
    --profile root-ca --not-after=100000h --kty=RSA --insecure --no-password --force
step certificate create intermediate-ca intermediate-ca.crt intermediate-ca.key \
    --profile intermediate-ca --kty=RSA --ca ./root-ca.crt --ca-key ./root-ca.key \
    --not-after=100000h --insecure --no-password --force

# Leaf cert
step certificate create localhost server.crt server.key \
    --ca ./intermediate-ca.crt --ca-key ./intermediate-ca.key \
    --kty=RSA --not-after=100000h --bundle \
    --insecure --no-password --force

# Merged PEM
cat server.crt server.key > server-merged.pem

chmod 664 *

rm root-ca.key

popd
