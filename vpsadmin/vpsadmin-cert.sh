openssl req \
  -x509 \
  -nodes \
  -days 3650 \
  -newkey rsa:2048 \
  -keyout vpsadmin-cert.key \
  -out vpsadmin-cert.crt \
  -config vpsadmin-cert.cnf \
  -extensions req_ext