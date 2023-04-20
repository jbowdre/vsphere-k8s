Install pinniped CLI:
```shell
curl -Lso pinniped https://get.pinniped.dev/v0.23.0/pinniped-cli-linux-amd64 \
  && chmod +x pinniped \
  && sudo mv pinniped /usr/local/bin/pinniped
```

Install pinniped supervisor:
```shell
kubectl apply -f https://get.pinniped.dev/v0.23.0/install-pinniped-supervisor.yaml
```

