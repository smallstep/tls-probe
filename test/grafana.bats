setup() {
	load '../node_modules/bats-support/load'
	load '../node_modules/bats-assert/load'
    load '../common'
	DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
	CONTAINER_NAME="tlsspec_${BATS_SUITE_TEST_NUMBER}"
    PORT=3000
}

teardown() {
	docker_stop
}

@test "[grafana] without a cert, TLS is disabled" {
    docker run --rm -d -p $PORT:$PORT --label tlsspec=true --name "${CONTAINER_NAME}" \
           -v grafana-storage:/var/lib/grafana \
           grafana/grafana
    wait_for_socket
    run docker logs $(docker ps --filter "name=${CONTAINER_NAME}" -q)
    assert_output --partial 'protocol=http '
}


@test "[grafana] with an EC cert chain, TLS is enabled" {
    docker run --rm -d --label tlsspec=true \
           --name "${CONTAINER_NAME}" \
           -e "GF_SERVER_PROTOCOL=https" \
           -e "GF_SERVER_CERT_FILE=/run/secrets/server.crt" \
           -e "GF_SERVER_CERT_KEY=/run/secrets/server.key" \
           -p $PORT:$PORT \
           -v $DIR/../certs-ecdsa:/run/secrets \
           -v grafana-storage:/var/lib/grafana \
           grafana/grafana
    wait_for_socket
    run docker logs $(docker ps --filter "name=${CONTAINER_NAME}" -q)
    assert_output --partial 'protocol=https '
    step certificate verify https://localhost:$PORT --roots $DIR/../certs-ecdsa/root-ca.crt
}

@test "[grafana] with an RSA cert chain, TLS is enabled" {
    docker run --rm -d --label tlsspec=true \
           --name "${CONTAINER_NAME}" \
           -e "GF_SERVER_PROTOCOL=https" \
           -e "GF_SERVER_CERT_FILE=/run/secrets/server.crt" \
           -e "GF_SERVER_CERT_KEY=/run/secrets/server.key" \
           -p $PORT:$PORT \
           -v $DIR/../certs-rsa:/run/secrets \
           -v grafana-storage:/var/lib/grafana \
           grafana/grafana
    wait_for_socket
    run docker logs $(docker ps --filter "name=${CONTAINER_NAME}" -q)
    assert_output --partial 'protocol=https '
    step certificate verify https://localhost:$PORT --roots $DIR/../certs-rsa/root-ca.crt
}
