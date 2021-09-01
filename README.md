# TLS spec suite

To set it up:

- Install `npm`
- Install `docker`
- Install `step`
- Run the following:

  ```
  npm install -g bats
  npm install
  bash ./makecerts.sh
  ```

To run the tests:

```
bats test
```

