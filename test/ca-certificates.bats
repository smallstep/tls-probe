setup() {
	load '../node_modules/bats-support/load'
	load '../node_modules/bats-assert/load'
	load '../common'
	DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
	CONTAINER_NAME="tlsprobe_${BATS_SUITE_TEST_NUMBER}"
}

teardown() {
	docker_stop
}

@test "[debian:latest] volume mounting to /etc/ssl/certs/ca-certificates.crt replaces trust store" {
	run $DOCKER run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
        --volume $DIR/../certs-ecdsa/root-ca.crt:/etc/ssl/certs/ca-certificates.crt \
        --add-host host.docker.internal:host-gateway \
		debian_step \
		sh -c 'step certificate verify https://host.docker.internal:8443; echo -n $?'
    assert_line "0"
}

@test "[ubuntu:latest] volume mounting to /etc/ssl/certs/ca-certificates.crt replaces trust store" {
	run $DOCKER run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
        --volume $DIR/../certs-ecdsa/root-ca.crt:/etc/ssl/certs/ca-certificates.crt \
        --add-host host.docker.internal:host-gateway \
		ubuntu_step \
		sh -c 'step certificate verify https://host.docker.internal:8443; echo -n $?'
    assert_line "0"
}

@test "[busybox:latest] volume mounting to /etc/ssl/certs/ca-certificates.crt replaces trust store" {
	run $DOCKER run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
        --volume $DIR/../certs-ecdsa/root-ca.crt:/etc/ssl/certs/ca-certificates.crt \
        --add-host host.docker.internal:host-gateway \
		busybox_step \
		sh -c 'step certificate verify https://host.docker.internal:8443; echo -n $?'
    assert_line "0"
}

@test "[alpine:latest] volume mounting to /etc/ssl/certs/ca-certificates.crt replaces trust store" {
	run $DOCKER run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
        --volume $DIR/../certs-ecdsa/root-ca.crt:/etc/ssl/certs/ca-certificates.crt \
        --add-host host.docker.internal:host-gateway \
		alpine_step \
		sh -c 'step certificate verify https://host.docker.internal:8443; echo -n $?'
    assert_line "0"
}


