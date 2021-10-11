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

@test "[busybox:stable] ca-certificates is not installed" {
	 run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			busybox:stable \
			ls /etc/ssl
	assert_output --partial 'ls: /etc/ssl: No such file or directory'
}

@test "[busybox:stable-uclibc] ca-certificates is not installed" {
	run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			busybox:stable-uclibc \
			ls /etc/ssl
	assert_output --partial 'ls: /etc/ssl: No such file or directory'
}

@test "[busybox:stable-glibc] ca-certificates is not installed" {
	run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			busybox:stable-glibc \
			ls /etc/ssl
	assert_output --partial 'ls: /etc/ssl: No such file or directory'
}

@test "[busybox:stable-musl] ca-certificates is not installed" {
	run $DOCKER 2>/dev/null run --rm --label tlsprobe=true --name "${CONTAINER_NAME}" \
			busybox:stable-musl \
			ls /etc/ssl
	assert_output --partial 'ls: /etc/ssl: No such file or directory'
}

