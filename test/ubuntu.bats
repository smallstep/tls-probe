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

@test "[ubuntu:xenial] ca-certificates is not installed" {
	run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			ubuntu:xenial \
			dpkg-query -f '${status}' -W ca-certificates
	assert_output --partial 'dpkg-query: no packages found matching ca-certificates'
}

@test "[ubuntu:bionic] ca-certificates is not installed" {
	run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			ubuntu:bionic \
			dpkg-query -f '${status}' -W ca-certificates
	assert_output --partial 'not-installed'
}

@test "[ubuntu:focal] ca-certificates is not installed" {
	run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			ubuntu:focal \
			dpkg-query -f '${status}' -W ca-certificates
	assert_output --partial 'not-installed'
}

@test "[ubuntu:hirsute] ca-certificates is not installed" {
	run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			ubuntu:hirsute \
			dpkg-query -f '${status}' -W ca-certificates
	assert_output --partial 'not-installed'
}

@test "[ubuntu:impish] ca-certificates is not installed" {
	run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			ubuntu:hirsute \
			dpkg-query -f '${status}' -W ca-certificates
	assert_output --partial 'not-installed'
}
