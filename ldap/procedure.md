Install metallb manifest:
```shell
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml
```

Configure metallb:
```shell
cat << EOF > config-metallb.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.70-192.168.1.89
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
EOF
kubectl apply -f config-metallb.yaml
```

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

Create LoadBalancer:
```shell
cat << EOF > pinniped-supervisor-lb.yaml
apiVersion: v1
kind: Service
metadata:
  name: pinniped-supervisor-loadbalancer
  namespace: pinniped-supervisor
spec:
  type: LoadBalancer
  selector:
    app: pinniped-supervisor
  ports:
  - protocol: TCP
    port: 443
    targetPort: 8443 # 8443 is the TLS port.
EOF
kubectl apply -f pinniped-supervisor-lb.yaml
```

Get LoadBalancer IP:
```shell
kubectl get service pinniped-supervisor-loadbalancer \
  -o jsonpath='{.status.loadBalancer.ingress[*].ip}' \
  --namespace pinniped-supervisor
```

Install cert-manager:
```shell
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.yaml
```


Configure Vault as Intermediate CA:
```shell
vault secrets enable pki
vault secrets tune -max-lease-ttl=8760h pki
vault write pki/intermediate/generate/exported common_name=vault.lab.bowdre.net ttl=87600h alt_names="vault"
vault write pki/intermediate/set-signed certificate=@signed_cert.pem
vault write pki/config/urls issuing_certificates="https://vault.lab.bowdre.net/v1/pki/ca" crl_distribution_points="https://vault.lab.bowdre.net/v1/pki/crl"
vault write pki/roles/lab-bowdre-net allowed_domains=lab.bowdre.net allow_subdomains=true max_ttl=72h
vault write pki/issue/lab-bowdre-net common_name=coobernettees.lab.bowdre.net
```

Configure approle auth for cert-manager:
```shell
vault auth enable approle
cat << EOF | vault policy write cert-manager -
path "pki/sign/lab-bowdre-net" {
  capabilities = ["create", "update", "delete"]
}
EOF
vault write auth/approle/role/cert-manager secret_id_ttl=0 token_policies=["cert-manager"]
# get approle role-id (username)
vault read auth/approle/role/cert-manager/role-id
# get approle secret-id (token)
vault write -f auth/approle/role/cert-manager/secret-id
```

```shell
cat << EOF > pinniped-cert-manager.yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: cert-manager-vault-approle
  namespace: pinniped-supervisor
data:
  secretId: "${VAULT_CERTMAN_SECRETID_B64}"
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: pinniped-vault-issuer
  namespace: pinniped-supervisor
spec:
  vault:
    path: pki/sign/lab-bowdre-net
    server: https://vault.lab.bowdre.net/
    caBundle: |
      LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlEalRDQ0FuV2dBd0lCQWdJUVlVemtVbW5W
      SnJsSlBtUTk1SFZ0QkRBTkJna3Foa2lHOXcwQkFRc0ZBREJaDQpNUk13RVFZS0NaSW1pWlB5TEdR
      QkdSWURibVYwTVJZd0ZBWUtDWkltaVpQeUxHUUJHUllHWW05M1pISmxNUk13DQpFUVlLQ1pJbWla
      UHlMR1FCR1JZRGJHRmlNUlV3RXdZRFZRUURFd3hzWVdJdFYwbE9NREV0UTBFd0hoY05Nakl3DQpN
      akl6TVRrME5qUTJXaGNOTWpjd01qSXpNVGsxTmpRMldqQlpNUk13RVFZS0NaSW1pWlB5TEdRQkdS
      WURibVYwDQpNUll3RkFZS0NaSW1pWlB5TEdRQkdSWUdZbTkzWkhKbE1STXdFUVlLQ1pJbWlaUHlM
      R1FCR1JZRGJHRmlNUlV3DQpFd1lEVlFRREV3eHNZV0l0VjBsT01ERXRRMEV3Z2dFaU1BMEdDU3FH
      U0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLDQpBb0lCQVFESXp2dG9RRjNvT3VDRmNVc21OcWtHRjVH
      ZVdBUjNibDN6Y3BmMXJRRy8wMlJrTUhVNFFla1V1QzBwDQo3eFdhTFc1Wmg4aWhlL3BhaVcvMXJO
      UTB2UnZNcW96OFlTRkhJN3czYStFMjUxQ3BqKy93Z1NUV3JuZUsyYUJ0DQoyellpMTdmcFVIRTV1
      R25kYi9TNjVpQk9IdFJzNG5BZ1VPcUFsZ2hjZnlkZU9qd3dMdldJOTdqSFV4a3RhVzE0DQpWUzlh
      NTlBc0dGTk1rVFY0SzRMRmN1eExxd2lOUkFaTFNOejFuck1uMFlpcTBxenpVbFAvUXlJNVhCMmF2
      V2lSDQpveGRJaVZWYm5rRlRJaWxiSUVaNFVKWWNCZFdqQ01nNUZHcGU0SmdaU3dRSDNCMmR6aU01
      aVdHc3Z2eklwQUlNDQpyNnFKZTBVNG13V24vUjlGdTVBV0gyZUhrMXV0QWdNQkFBR2pVVEJQTUFz
      R0ExVWREd1FFQXdJQmhqQVBCZ05WDQpIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSd2VR
      SHVBRGJuVEFnV2NabnFDYnQwY1BwU2JUQVFCZ2tyDQpCZ0VFQVlJM0ZRRUVBd0lCQURBTkJna3Fo
      a2lHOXcwQkFRc0ZBQU9DQVFFQXg5dVcrK2ZWSEZ1c2sxc1VTeXRFDQpsWEpJVXdocGtGWE1Md2lm
      Y2VRQ3VwcjlJUjk4UzNzTFI4U2hucGltaVNpbGVXa052cXR5RWVsUHFIM2hEbE9BDQo5bHRzRGY5
      dWVWZTRaSVNxejlQMk14NXVGckxhQ1g5cm5vNlVXSjdYRGZyTk0zMHJVd2NwbDdsdG9aQmFoSm80
      DQpmWWtDeGx4a1dSQkVmNnlNMzVjQnREVVRHZ1dlNFQ3RG82aDBvRUNSRzlsNTE1b04xRkVRVnpH
      MEtGWTc5UmZ5DQp3S0xtL2FpVGxPNWp2Q3Q0V1Jjak1vWjhMbU15dStwY1ZyOWwySjhsK0tNUUFq
      b2UvV1RSOFRMa2duZ2dNNmpIDQo0bUNIWENOWVlxNGJJVVZKWDlVVzMxL1FhRnpZeXl5Smg4cHhI
      YVF1RkllZVFBUDY5aW1WRjM2QmViTlMwYkh2DQowdz09DQotLS0tLUVORCBDRVJUSUZJQ0FURS0t
      LS0tDQo=
    auth:
      appRole:
        path: approle
        roleId: "${VAULT_CERTMAN_ROLEID}"
        secretRef:
          name: cert-manager-vault-approle
          key: secretId
EOF
kubectl apply -f pinniped-cert-manager.yaml

k -n pinniped-supervisor get issuers pinniped-vault-issuer -o wide
NAME           READY   STATUS           AGE
vault-issuer   True    Vault verified   2m16s
```

Create cert request for pinniped-supervisor
```shell
cat <<EOF > pinniped-cert-request.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: supervisor-tls-cert-request
  namespace: pinniped-supervisor
spec:
  secretName: supervisor-tls-cert
  commonName: "pinniped-supervisor.lab.bowdre.net"
  issuerRef:
    name: pinniped-vault-issuer
  dnsNames:
  - "pinniped-supervisor.lab.bowdre.net"
EOF
kubectl apply -f pinniped-cert-request.yaml
```

Create FederationDomain:
```shell
cat <<EOF > pinniped-federationdomain.yaml
apiVersion: config.supervisor.pinniped.dev/v1alpha1
kind: FederationDomain
metadata:
  name: federation-domain
  namespace: pinniped-supervisor
spec:
  # You can choose an arbitrary path for the issuer URL.
  issuer: "https://pinniped-supervisor.lab.bowdre.net/issuer"
  tls:
    # The name of the secretName from the cert-manager Certificate
    # resource above.
    secretName: supervisor-tls-cert
EOF
kubectl apply -f pinniped-federationdomain.yaml
```

Create ActiveDirectoryIdentityProvider
```shell
cat << EOF > pinniped-ad-idp.yaml
apiVersion: v1
kind: Secret
metadata:
  name: active-directory-bind-account
  namespace: pinniped-supervisor
type: kubernetes.io/basic-auth
data:
  # The dn (distinguished name) of your Active Directory bind account.
  # Remember to b64 encode without newlines:
  # echo -n "string" | base64 -w 0
  username: "${LDAP_BIND_USERNAME_B64}"
  # The password of your Active Directory bind account.
  password: "${LDAP_BIND_PASSWORD_B64}"
---
apiVersion: idp.supervisor.pinniped.dev/v1alpha1
kind: ActiveDirectoryIdentityProvider
metadata:
  name: lab-bowdre-net-idp
  namespace: pinniped-supervisor
spec:
  # Specify the host of the Active Directory server.
  host: "win01.lab.bowdre.net:636"
  # Specify the name of the Kubernetes Secret that contains your Active
  # Directory bind account credentials. This service account will be
  # used by the Supervisor to perform LDAP user and group searches.
  bind:
    secretName: "active-directory-bind-account"
  tls:
    certificateAuthorityData: |+
      LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlEalRDQ0FuV2dBd0lCQWdJUVlVemtVbW5W
      SnJsSlBtUTk1SFZ0QkRBTkJna3Foa2lHOXcwQkFRc0ZBREJaDQpNUk13RVFZS0NaSW1pWlB5TEdR
      QkdSWURibVYwTVJZd0ZBWUtDWkltaVpQeUxHUUJHUllHWW05M1pISmxNUk13DQpFUVlLQ1pJbWla
      UHlMR1FCR1JZRGJHRmlNUlV3RXdZRFZRUURFd3hzWVdJdFYwbE9NREV0UTBFd0hoY05Nakl3DQpN
      akl6TVRrME5qUTJXaGNOTWpjd01qSXpNVGsxTmpRMldqQlpNUk13RVFZS0NaSW1pWlB5TEdRQkdS
      WURibVYwDQpNUll3RkFZS0NaSW1pWlB5TEdRQkdSWUdZbTkzWkhKbE1STXdFUVlLQ1pJbWlaUHlM
      R1FCR1JZRGJHRmlNUlV3DQpFd1lEVlFRREV3eHNZV0l0VjBsT01ERXRRMEV3Z2dFaU1BMEdDU3FH
      U0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLDQpBb0lCQVFESXp2dG9RRjNvT3VDRmNVc21OcWtHRjVH
      ZVdBUjNibDN6Y3BmMXJRRy8wMlJrTUhVNFFla1V1QzBwDQo3eFdhTFc1Wmg4aWhlL3BhaVcvMXJO
      UTB2UnZNcW96OFlTRkhJN3czYStFMjUxQ3BqKy93Z1NUV3JuZUsyYUJ0DQoyellpMTdmcFVIRTV1
      R25kYi9TNjVpQk9IdFJzNG5BZ1VPcUFsZ2hjZnlkZU9qd3dMdldJOTdqSFV4a3RhVzE0DQpWUzlh
      NTlBc0dGTk1rVFY0SzRMRmN1eExxd2lOUkFaTFNOejFuck1uMFlpcTBxenpVbFAvUXlJNVhCMmF2
      V2lSDQpveGRJaVZWYm5rRlRJaWxiSUVaNFVKWWNCZFdqQ01nNUZHcGU0SmdaU3dRSDNCMmR6aU01
      aVdHc3Z2eklwQUlNDQpyNnFKZTBVNG13V24vUjlGdTVBV0gyZUhrMXV0QWdNQkFBR2pVVEJQTUFz
      R0ExVWREd1FFQXdJQmhqQVBCZ05WDQpIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSd2VR
      SHVBRGJuVEFnV2NabnFDYnQwY1BwU2JUQVFCZ2tyDQpCZ0VFQVlJM0ZRRUVBd0lCQURBTkJna3Fo
      a2lHOXcwQkFRc0ZBQU9DQVFFQXg5dVcrK2ZWSEZ1c2sxc1VTeXRFDQpsWEpJVXdocGtGWE1Md2lm
      Y2VRQ3VwcjlJUjk4UzNzTFI4U2hucGltaVNpbGVXa052cXR5RWVsUHFIM2hEbE9BDQo5bHRzRGY5
      dWVWZTRaSVNxejlQMk14NXVGckxhQ1g5cm5vNlVXSjdYRGZyTk0zMHJVd2NwbDdsdG9aQmFoSm80
      DQpmWWtDeGx4a1dSQkVmNnlNMzVjQnREVVRHZ1dlNFQ3RG82aDBvRUNSRzlsNTE1b04xRkVRVnpH
      MEtGWTc5UmZ5DQp3S0xtL2FpVGxPNWp2Q3Q0V1Jjak1vWjhMbU15dStwY1ZyOWwySjhsK0tNUUFq
      b2UvV1RSOFRMa2duZ2dNNmpIDQo0bUNIWENOWVlxNGJJVVZKWDlVVzMxL1FhRnpZeXl5Smg4cHhI
      YVF1RkllZVFBUDY5aW1WRjM2QmViTlMwYkh2DQowdz09DQotLS0tLUVORCBDRVJUSUZJQ0FURS0t
      LS0tDQo=
EOF
kubectl apply -f pinniped-ad-idp.yaml
```

Install Concierge
```shell
kubectl apply -f https://get.pinniped.dev/v0.23.0/install-pinniped-concierge-crds.yaml
kubectl apply -f https://get.pinniped.dev/v0.23.0/install-pinniped-concierge-resources.yaml
```

Configure Concierge
```shell
cat << EOF > pinniped-concierge.yaml
apiVersion: authentication.concierge.pinniped.dev/v1alpha1
kind: JWTAuthenticator
metadata:
  name: my-supervisor-authenticator
spec:

  # The value of the issuer field should exactly match the issuer
  # field of your Supervisor's FederationDomain.
  issuer: https://pinniped-supervisor.lab.bowdre.net/issuer

  # You can use any audience identifier for your cluster, but it is
  # important that it is unique for security reasons.
  audience: kates-$(openssl rand -hex 8)

  # If the TLS certificate of your FederationDomain is not signed by
  # a standard CA trusted by the Concierge pods by default, then
  # specify its CA here as a base64-encoded PEM.
  tls:
    certificateAuthorityData: |+
      LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlEalRDQ0FuV2dBd0lCQWdJUVlVemtVbW5W
      SnJsSlBtUTk1SFZ0QkRBTkJna3Foa2lHOXcwQkFRc0ZBREJaDQpNUk13RVFZS0NaSW1pWlB5TEdR
      QkdSWURibVYwTVJZd0ZBWUtDWkltaVpQeUxHUUJHUllHWW05M1pISmxNUk13DQpFUVlLQ1pJbWla
      UHlMR1FCR1JZRGJHRmlNUlV3RXdZRFZRUURFd3hzWVdJdFYwbE9NREV0UTBFd0hoY05Nakl3DQpN
      akl6TVRrME5qUTJXaGNOTWpjd01qSXpNVGsxTmpRMldqQlpNUk13RVFZS0NaSW1pWlB5TEdRQkdS
      WURibVYwDQpNUll3RkFZS0NaSW1pWlB5TEdRQkdSWUdZbTkzWkhKbE1STXdFUVlLQ1pJbWlaUHlM
      R1FCR1JZRGJHRmlNUlV3DQpFd1lEVlFRREV3eHNZV0l0VjBsT01ERXRRMEV3Z2dFaU1BMEdDU3FH
      U0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLDQpBb0lCQVFESXp2dG9RRjNvT3VDRmNVc21OcWtHRjVH
      ZVdBUjNibDN6Y3BmMXJRRy8wMlJrTUhVNFFla1V1QzBwDQo3eFdhTFc1Wmg4aWhlL3BhaVcvMXJO
      UTB2UnZNcW96OFlTRkhJN3czYStFMjUxQ3BqKy93Z1NUV3JuZUsyYUJ0DQoyellpMTdmcFVIRTV1
      R25kYi9TNjVpQk9IdFJzNG5BZ1VPcUFsZ2hjZnlkZU9qd3dMdldJOTdqSFV4a3RhVzE0DQpWUzlh
      NTlBc0dGTk1rVFY0SzRMRmN1eExxd2lOUkFaTFNOejFuck1uMFlpcTBxenpVbFAvUXlJNVhCMmF2
      V2lSDQpveGRJaVZWYm5rRlRJaWxiSUVaNFVKWWNCZFdqQ01nNUZHcGU0SmdaU3dRSDNCMmR6aU01
      aVdHc3Z2eklwQUlNDQpyNnFKZTBVNG13V24vUjlGdTVBV0gyZUhrMXV0QWdNQkFBR2pVVEJQTUFz
      R0ExVWREd1FFQXdJQmhqQVBCZ05WDQpIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSd2VR
      SHVBRGJuVEFnV2NabnFDYnQwY1BwU2JUQVFCZ2tyDQpCZ0VFQVlJM0ZRRUVBd0lCQURBTkJna3Fo
      a2lHOXcwQkFRc0ZBQU9DQVFFQXg5dVcrK2ZWSEZ1c2sxc1VTeXRFDQpsWEpJVXdocGtGWE1Md2lm
      Y2VRQ3VwcjlJUjk4UzNzTFI4U2hucGltaVNpbGVXa052cXR5RWVsUHFIM2hEbE9BDQo5bHRzRGY5
      dWVWZTRaSVNxejlQMk14NXVGckxhQ1g5cm5vNlVXSjdYRGZyTk0zMHJVd2NwbDdsdG9aQmFoSm80
      DQpmWWtDeGx4a1dSQkVmNnlNMzVjQnREVVRHZ1dlNFQ3RG82aDBvRUNSRzlsNTE1b04xRkVRVnpH
      MEtGWTc5UmZ5DQp3S0xtL2FpVGxPNWp2Q3Q0V1Jjak1vWjhMbU15dStwY1ZyOWwySjhsK0tNUUFq
      b2UvV1RSOFRMa2duZ2dNNmpIDQo0bUNIWENOWVlxNGJJVVZKWDlVVzMxL1FhRnpZeXl5Smg4cHhI
      YVF1RkllZVFBUDY5aW1WRjM2QmViTlMwYkh2DQowdz09DQotLS0tLUVORCBDRVJUSUZJQ0FURS0t
      LS0tDQo=
EOF
kubectl apply -f pinniped-concierge.yaml
```