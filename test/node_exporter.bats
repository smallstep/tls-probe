setup() {
	load '../node_modules/bats-support/load'
	load '../node_modules/bats-assert/load'
	DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
}

teardown() {
	docker ps --filter label=tlsspec -q | xargs docker stop
}

@test "when running node_exporter without a cert, TLS is disabled" {
	docker run --rm -d -p 9100:9100 --label tlsspec=true --name node_exporter \
           quay.io/prometheus/node-exporter:latest 
	$DIR/../wait-for-it.sh localhost:9100
        run docker logs	$(docker ps --filter name=node_exporter -q)
	assert_output --partial 'TLS is disabled.'
}

@test "when running node_exporter with an EC cert, TLS is enabled" {
	docker run --rm -d --label tlsspec=true \
           --name node_exporter \
	   -p 9100:9100 \
           -v $DIR/node_exporter:/run/config \
           -v $DIR/../certs-ecdsa:/run/secrets \
           quay.io/prometheus/node-exporter:latest \
           --web.config="/run/config/web-config.yml"
	$DIR/../wait-for-it.sh localhost:9100
        run docker logs	$(docker ps --filter name=node_exporter -q)
	assert_output --partial 'TLS is enabled.'
	step certificate verify https://localhost:9100 --roots $DIR/../certs-ecdsa/root-ca.crt
}

@test "when running node_exporter with an RSA cert, TLS is enabled" {
	docker run --rm -d --label tlsspec=true \
           --name node_exporter \
	   -p 9100:9100 \
           -v $DIR/node_exporter:/run/config \
           -v $DIR/../certs-rsa:/run/secrets \
           quay.io/prometheus/node-exporter:latest \
           --web.config="/run/config/web-config.yml"
	$DIR/../wait-for-it.sh localhost:9100
        run docker logs	$(docker ps --filter name=node_exporter -q)
	assert_output --partial 'TLS is enabled.'
	step certificate verify https://localhost:9100 --roots $DIR/../certs-rsa/root-ca.crt
}

