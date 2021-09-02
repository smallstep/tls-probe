wait_for_socket() {
	retries=0
	while :; do
		retries=$((retries + 1))
		run curl localhost:$PORT
		# status 52 is an empty reply; which is fine
		if [ $status -eq 0 ] || [ $status -eq 52 ]; then
			break
		fi
		if [ $retries -eq 10 ]; then
			break
		fi
		sleep 5
	done
}

docker_stop() {
    docker ps --filter label=tlsprobe -q | xargs docker stop 2>/dev/null
}

