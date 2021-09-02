setup() {
	load '../node_modules/bats-support/load'
	load '../node_modules/bats-assert/load'
	load '../common'
	DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
	CONTAINER_NAME="tlsprobe_${BATS_SUITE_TEST_NUMBER}"
	PORT=6379
}

teardown() {
	docker_stop
}

@test "[redis] with an EC cert chain, TLS is enabled" {
	docker run --rm -d --label tlsprobe=true \
			--name "${CONTAINER_NAME}" \
			-p $PORT:$PORT \
			-v $DIR/../certs-ecdsa:/run/secrets \
			redis \
				--tls-port $PORT --port 0 \
				--tls-cert-file /run/secrets/server.crt \
				--tls-key-file /run/secrets/server.key \
				--tls-ca-cert-file /run/secrets/root-ca.crt \
				--tls-auth-clients no
	wait_for_socket
	run docker exec -it \
			${CONTAINER_NAME} redis-cli --tls \
			--cacert /run/secrets/root-ca.crt ping
	[[ "${output}" =~ PONG ]]
}

@test "[redis] with an RSA cert chain, TLS is enabled" {
	docker run --rm -d --label tlsprobe=true \
			--name $CONTAINER_NAME \
			-p $PORT:$PORT \
			-v $DIR/../certs-rsa:/run/secrets \
			redis \
				--tls-port $PORT --port 0 \
				--tls-cert-file /run/secrets/server.crt \
				--tls-key-file /run/secrets/server.key \
				--tls-ca-cert-file /run/secrets/root-ca.crt \
				--tls-auth-clients no
	wait_for_socket
	run docker exec -it \
			${CONTAINER_NAME} redis-cli --tls \
			--cacert /run/secrets/root-ca.crt ping
	[[ "${output}" =~ PONG ]]
}

@test "[redis] cert files reloaded when the CONFIG SET command is provided" {
	# World readability is needed here so the container can read the certs
	chmod 775 $BATS_TEST_TMPDIR

	cp $DIR/../certs-rsa/server.crt $BATS_TEST_TMPDIR
	cp $DIR/../certs-rsa/server.key $BATS_TEST_TMPDIR
	cp $DIR/../certs-rsa/root-ca.crt $BATS_TEST_TMPDIR

	# Make an extra copy of the CA cert so we can connect after updating the certificate files
	# to run the restart command.
	cp $DIR/../certs-rsa/root-ca.crt $BATS_TEST_TMPDIR/root-ca-rsa.crt

	docker run --rm -d --label tlsprobe=true \
			--name $CONTAINER_NAME \
			-p $PORT:$PORT \
			-v $BATS_TEST_TMPDIR:/run/secrets \
			redis \
				--tls-port $PORT --port 0 \
				--tls-cert-file /run/secrets/server.crt \
				--tls-key-file /run/secrets/server.key \
				--tls-ca-cert-file /run/secrets/root-ca.crt \
				--tls-auth-clients no

	wait_for_socket

	# 0. test the old certs
	run docker exec -it \
			$CONTAINER_NAME redis-cli --tls \
			--cacert /run/secrets/root-ca-rsa.crt ping
	[[ "${output}" =~ PONG ]]

	# 1. put the new certs in place
	cp $DIR/../certs-ecdsa/server.crt $DIR/../certs-ecdsa/server.key $BATS_TEST_TMPDIR
	cp $DIR/../certs-ecdsa/root-ca.crt $BATS_TEST_TMPDIR

	# 2. notify Redis
	CERT_FILE=$(docker exec -it $CONTAINER_NAME redis-cli --tls --cacert /run/secrets/root-ca-rsa.crt --raw config get tls-cert-file | tail -n1)
	docker exec -it $CONTAINER_NAME redis-cli --tls --cacert /run/secrets/root-ca-rsa.crt config set tls-cert-file ${CERT_FILE//[$'\r\n']}

	# 3. test the new certs
	run docker exec -it \
			${CONTAINER_NAME} redis-cli \
				 --tls \
				--cacert /run/secrets/root-ca.crt ping
	[[ "${output}" =~ PONG ]]
}

@test "[redis] it's possible to connect to a server with an expired cert, if --insecure is used" {
	docker run --rm -d --label tlsprobe=true \
			--name $CONTAINER_NAME \
			-p $PORT:$PORT \
			-v $DIR/../certs-ecdsa:/run/secrets \
			redis \
				--tls-port $PORT --port 0 \
				--tls-cert-file /run/secrets/server-expired.crt \
				--tls-key-file /run/secrets/server-expired.key \
				--tls-ca-cert-file /run/secrets/root-ca.crt \
				--tls-auth-clients no
	wait_for_socket
	run docker exec -it \
			${CONTAINER_NAME} redis-cli --tls --insecure \
			--cacert /run/secrets/root-ca.crt ping
	[[ "${output}" =~ PONG ]]
}


