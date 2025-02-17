openssl genrsa -out vpsadmin-cert.key 2048
openssl req -new -key vpsadmin-cert.key -out vpsadmin-cert.csr -subj "/CN=webui.aitherdev.int.vpsfree.cz"
openssl x509 -req -in vpsadmin-cert.csr \
  -CA vpsadmin-ca.crt -CAkey vpsadmin-ca.key -CAcreateserial \
  -out vpsadmin-cert.crt -days 3650 -sha256 \
  -extfile vpsadmin-cert.ext
