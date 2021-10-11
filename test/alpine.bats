setup() {
	load '../node_modules/bats-support/load'
	load '../node_modules/bats-assert/load'
	load '../common'
	DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
	CONTAINER_NAME="tlsprobe_${BATS_SUITE_TEST_NUMBER}"
	PORT=27017
}

teardown() {
	docker_stop
}

@test "[alpine:3] ca-certificates is installed" {
	 run $DOCKER run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			alpine:3 \
			apk info -e ca-certificates-bundle
	assert_line 'ca-certificates-bundle'
}

@test "[alpine:edge] ca-certificates is installed" {
	run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			alpine:edge \
			apk info -e ca-certificates-bundle
	assert_line 'ca-certificates-bundle'
}

