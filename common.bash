wait_for_socket() {
    curl --retry 50 \
    --retry-max-time 60 \
    --retry-all-errors \
    localhost:$PORT
}

docker_stop() {
    docker ps --filter label=tlsspec -q | xargs docker stop 2>/dev/null
}

