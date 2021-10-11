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

@test "[debian:9] ca-certificates is not installed" {
	 run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			debian:9 \
			dpkg-query -f '${status}' -W ca-certificates
	assert_output --partial 'dpkg-query: no packages found matching ca-certificates'
}

@test "[debian:10] ca-certificates is not installed" {
	run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			debian:10 \
			dpkg-query -f '${status}' -W ca-certificates
	assert_output --partial 'not-installed'
}

@test "[debian:11] ca-certificates is not installed" {
	run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			debian:11 \
			dpkg-query -f '${status}' -W ca-certificates
	assert_output --partial 'not-installed'
}

