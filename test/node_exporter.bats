setup() {
	load '../node_modules/bats-support/load'
	load '../node_modules/bats-assert/load'
	load '../common'
	DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
	CONTAINER_NAME="tlsprobe_${BATS_SUITE_TEST_NUMBER}"
	PORT=9100
}

teardown() {
	docker_stop
}

@test "[node_exporter] without a cert, TLS is disabled" {
	docker run --rm -d -p $PORT:$PORT --label tlsprobe=true --name "${CONTAINER_NAME}" \
			quay.io/prometheus/node-exporter:latest 
	wait_for_socket
	run docker logs	$(docker ps --filter "name=${CONTAINER_NAME}" -q)
	assert_output --partial 'TLS is disabled.'
}

@test "[node_exporter] with an EC cert chain, TLS is enabled" {
	docker run --rm -d --label tlsprobe=true \
			--name "${CONTAINER_NAME}" \
			-p $PORT:$PORT \
			-v $DIR/node_exporter:/run/config \
			-v $DIR/../certs-ecdsa:/run/secrets \
			quay.io/prometheus/node-exporter:latest \
				--web.config="/run/config/web-config.yml"
	wait_for_socket
	run docker logs	$(docker ps --filter "name=${CONTAINER_NAME}" -q)
	assert_output --partial 'TLS is enabled.'
	step certificate verify https://localhost:$PORT --roots $DIR/../certs-ecdsa/root-ca.crt
}

@test "[node_exporter] with an RSA cert chain, TLS is enabled" {
	docker run --rm -d --label tlsprobe=true \
		--name "${CONTAINER_NAME}" \
		-p $PORT:$PORT \
		-v $DIR/node_exporter:/run/config \
		-v $DIR/../certs-rsa:/run/secrets \
		quay.io/prometheus/node-exporter:latest \
			--web.config="/run/config/web-config.yml"
	wait_for_socket
	run docker logs	$(docker ps --filter "name=${CONTAINER_NAME}" -q)
	assert_output --partial 'TLS is enabled.'
	step certificate verify https://localhost:$PORT --roots $DIR/../certs-rsa/root-ca.crt
}

@test "[node_exporter] cert files are evaluated with each new request" {
	# World readability is needed here so the container can read the certs
	chmod 775 $BATS_TEST_TMPDIR

	cp $DIR/../certs-rsa/server.crt $DIR/../certs-rsa/server.key $BATS_TEST_TMPDIR
	docker run --rm -d --label tlsprobe=true \
		--name "${CONTAINER_NAME}" \
		-p $PORT:$PORT \
		-v $DIR/node_exporter:/run/config \
		-v $BATS_TEST_TMPDIR:/run/secrets \
		quay.io/prometheus/node-exporter:latest \
			--web.config="/run/config/web-config.yml"
	wait_for_socket

	# see the RSA issuer
	step certificate verify https://localhost:$PORT --roots $DIR/../certs-rsa/root-ca.crt

	# replace the cert in the mount volume
	cp $DIR/../certs-ecdsa/server.crt $DIR/../certs-ecdsa/server.key $BATS_TEST_TMPDIR

	# see the ECDSA issuer
	step certificate verify https://localhost:$PORT --roots $DIR/../certs-ecdsa/root-ca.crt
}

