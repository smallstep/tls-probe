# TLS spec suite

This is a test suite written with the goal of understanding undocumented TLS implementation details of various open source services.

## Scope

Questions thses tests should test on common TLS-supporting services & clients:
* Server certificate types supported:
  * ECDSA chains?
  * RSA chains?
* Specific server cert format requirements * eg. special OIDs or subject DNs
* Client TLS support:
  * Are server certificates validated, or are invalid server certs silently accepted (encryption only)?
  * Is OCSP supported?
  * Does the client trust CAs in the system trust store?
  * Can an invalid server cert be (insecurely) accepted?
* Rotation process for servers:
  * Test the reload command, if any
  * If hot reloading an expired cert requires connecting to the server, can the client allow expired certs to connect?
* Root distribution:
  * Does the server trust CAs in the system trust store?
* Is a server rekey supported? (in some servers it creates a race condition)

To set it up:

- Install `npm`
- Install `docker`
- Install `step`
- Run the following:

  ```
  npm install -g bats
  npm install
  bash ./makecerts.sh
  bash ./docker_build.sh
  ```

- Start the fileserver:

  ```
  step fileserver --address 127.0.0.1:8443 \
                  --cert certs-ecdsa/server.crt \
	              --key certs-ecdsa/server.key \
	              --address 0.0.0.0:8443 fileserver
  ```

  In another window, run the tests:

  ```
  bats test
  ```

- Cleanup:

  ```
  docker rmi -f $(docker image ls -f tag=tlsprobe)
  ```

