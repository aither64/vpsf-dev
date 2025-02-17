openssl genrsa -aes256 -out vpsadmin-ca.key 2048
openssl req -x509 -new -nodes -key vpsadmin-ca.key -sha256 -days 3650 -out vpsadmin-ca.crt
