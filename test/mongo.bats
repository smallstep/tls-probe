setup() {
	load '../node_modules/bats-support/load'
	load '../node_modules/bats-assert/load'
	load '../common'
	DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
	CONTAINER_NAME="tlsprobe_${BATS_SUITE_TEST_NUMBER}"
	IMAGE_NAME="docker.io/mongo:latest"
	PORT=27017
}

teardown() {
	docker_stop
}

@test "[mongo] without a cert, TLS is disabled" {
	$DOCKER run --rm -d -p $PORT:$PORT --label tlsprobe=true --name "${CONTAINER_NAME}" \
			${IMAGE_NAME}
	wait_for_socket
	run $DOCKER logs $($DOCKER ps --filter "name=${CONTAINER_NAME}" -q)
	assert_output --partial '"ssl":"off"'
}

@test "[mongo] with an EC cert chain, TLS is enabled" {
	$DOCKER run --rm -d --label tlsprobe=true \
			--name "${CONTAINER_NAME}" \
			-p $PORT:$PORT \
			-v $DIR/../certs-ecdsa:/run/secrets \
			${IMAGE_NAME} \
				--tlsMode requireTLS \
				--tlsCAFile /run/secrets/root-ca.crt \
				--tlsCertificateKeyFile /run/secrets/server-merged.pem
	wait_for_socket
	run $DOCKER logs $($DOCKER ps --filter "name=${CONTAINER_NAME}" -q)
	assert_output --partial '"ssl":"on"'
	step certificate verify https://localhost:$PORT --roots $DIR/../certs-ecdsa/root-ca.crt
}

@test "[mongo] with an RSA cert chain, TLS is enabled" {
	$DOCKER run --rm -d --label tlsprobe=true \
		--name "${CONTAINER_NAME}" \
		-p $PORT:$PORT \
		-v $DIR/../certs-rsa:/run/secrets \
		${IMAGE_NAME} \
				--tlsMode requireTLS \
				--tlsCAFile /run/secrets/root-ca.crt \
				--tlsCertificateKeyFile /run/secrets/server-merged.pem
	wait_for_socket
	run $DOCKER logs $($DOCKER ps --filter "name=${CONTAINER_NAME}" -q)
	assert_output --partial '"ssl":"on"'
	step certificate verify https://localhost:$PORT --roots $DIR/../certs-rsa/root-ca.crt
}

@test "[mongo] when a CA is not specified, server auth TLS is enabled" {
	$DOCKER run --rm -d --label tlsprobe=true \
			--name "${CONTAINER_NAME}" \
			-p $PORT:$PORT \
			-v $DIR/../certs-ecdsa:/run/secrets \
			${IMAGE_NAME} \
				--tlsMode requireTLS \
				--tlsCertificateKeyFile /run/secrets/server-merged.pem
	wait_for_socket
	run $DOCKER logs $($DOCKER ps --filter "name=${CONTAINER_NAME}" -q)
	assert_output --partial '"ssl":"on"'
	step certificate verify https://localhost:$PORT --roots $DIR/../certs-ecdsa/root-ca.crt
}

@test "[mongo] cert files are evaluated when rotateCertificates is called" {
	# https://docs.mongodb.com/v5.0/reference/command/rotateCertificates/
	# { rotateCertificates: 1,
	#  message: "<optional log message>" }

	# World readability is needed here so the container can read the certs
	chmod 775 $BATS_TEST_TMPDIR

	cp $DIR/../certs-rsa/server-merged.pem $DIR/../certs-rsa/root-ca.crt $BATS_TEST_TMPDIR

	# make an extra copy so we can connect to rotate the cert
	cp $BATS_TEST_TMPDIR/server-merged.pem $BATS_TEST_TMPDIR/server-merged-rsa.pem
	cp $BATS_TEST_TMPDIR/root-ca.crt $BATS_TEST_TMPDIR/root-ca-rsa.crt

	$DOCKER run --rm -d --label tlsprobe=true \
		--name "${CONTAINER_NAME}" \
		-p $PORT:$PORT \
		-v $BATS_TEST_TMPDIR:/run/secrets \
		${IMAGE_NAME} \
			--tlsMode requireTLS \
			--tlsCAFile /run/secrets/root-ca.crt \
			--tlsCertificateKeyFile /run/secrets/server-merged.pem
	wait_for_socket

	# replace the cert in the mount volume
	cp $DIR/../certs-ecdsa/server-merged.pem $DIR/../certs-ecdsa/root-ca.crt $BATS_TEST_TMPDIR

	# see the old RSA issuer
	step certificate verify https://localhost:$PORT --roots $DIR/../certs-rsa/root-ca.crt
	
	# rotateCertificates
	$DOCKER exec -it "${CONTAINER_NAME}" \
		 bash -c 'mongosh "mongodb://localhost:27017?tls=true&tlsCAFile=/run/secrets/root-ca-rsa.crt&tlsCertificateKeyFile=/run/secrets/server-merged-rsa.pem" -f <(echo "db.adminCommand( { rotateCertificates: 1 } )")'

	# see the ECDSA issuer
	step certificate verify https://localhost:$PORT --roots $DIR/../certs-ecdsa/root-ca.crt
}

@test "[mongo] an expired cert can be rotated via --tlsAllowInvalidCertificates" {
	skip
	# It's difficult to test expired cert behavior in MongoDB because:
	# 1. the server won't start up if the cert is already expired, and
	# 2. there's no way to fiddle with time in a Docker container.
	# 
	# So this test would have to issue a short-lived cert and then wait for it to expire. :(
	# 

	step certificate create localhost $BATS_TEST_TMPDIR/server.crt $BATS_TEST_TMPDIR/server.key \
		--ca $DIR/../certs-ecdsa/intermediate-ca.crt --ca-key $DIR/../certs-ecdsa/intermediate-ca.key \
		--not-after=5m --bundle \
		--insecure --no-password --force

	cat $BATS_TEST_TMPDIR/server.crt $BATS_TEST_TMPDIR/server.key > $BATS_TEST_TMPDIR/server-merged.pem
	cp $DIR/../certs-ecdsa/root-ca.crt $BATS_TEST_TMPDIR

	$DOCKER run --rm -d --label tlsprobe=true \
			--name "${CONTAINER_NAME}" \
			-p $PORT:$PORT \
			-v $BATS_TEST_TMPDIR:/run/secrets \
			${IMAGE_NAME} \
				--tlsMode requireTLS \
				--tlsCAFile /run/secrets/root-ca.crt \
				--tlsCertificateKeyFile /run/secrets/server-merged.pem

	wait_for_socket
	# wait_for_cert_to_expire

	$DOCKER exec -it "${CONTAINER_NAME}" \
		 bash -c 'mongosh --tlsAllowInvalidCertificates "mongodb://localhost:27017?tls=true&tlsCAFile=/run/secrets/root-ca.crt&tlsCertificateKeyFile=/run/secrets/server-merged.pem" -f <(echo "db.adminCommand( { rotateCertificates: 1 } )")'
		
}

@test "[mongo] mongod trusts root CAs from the Web PKI when --tlsCAFile is not specified" {
    skip
	# One way to test this is to get a Let's Encrypt cert,
	# and try using it as a client certificate connecting to a MongoDB instance.
}

@test "[mongo] mongod does NOT trust root CAs from the Web PKI when --tlsCAFile is specified" {
    skip
}

