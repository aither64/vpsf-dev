vpsAdmin development certificates
================================

This directory holds a simple local CA and a single leaf certificate for the vpsAdmin development domains.

Files
-----
- `vpsadmin-ca.crt` / `vpsadmin-ca.key`: local CA (key is encrypted; you need its passphrase to sign).
- `vpsadmin-cert.key`: leaf private key.
- `vpsadmin-cert.ext`: OpenSSL extensions (subject, SANs).
- `vpsadmin-cert.csr`: CSR generated from the leaf key.
- `vpsadmin-cert.crt`: leaf certificate signed by the CA.
- `gen-ca.sh` / `gen-cert.sh`: helper scripts to initialize the CA and leaf.

Add or remove domains
---------------------
1) Edit `vpsadmin-cert.ext` and update the `[alt_names]` list. Keep the `DNS.n` numbering contiguous (increment the highest index).
2) If you want a different Common Name, update `CN = ...` under `[ req_distinguished_name ]` and match it in the `-subj` used below.
3) Reissue the CSR with the existing key (this keeps TLS keys stable):
   ```
   cd certs
   openssl req -new -key vpsadmin-cert.key -out vpsadmin-cert.csr -subj "/CN=webui.aitherdev.int.vpsfree.cz"
   ```
4) Sign a new 10-year certificate (3650 days) with the local CA and the updated SANs:
   ```
   cd certs
   openssl x509 -req -in vpsadmin-cert.csr \
     -CA vpsadmin-ca.crt -CAkey vpsadmin-ca.key -CAcreateserial \
     -out vpsadmin-cert.crt -days 3650 -sha256 -extfile vpsadmin-cert.ext
   ```
   You will be prompted for the CA key passphrase.
5) Verify the result:
   ```
   openssl x509 -in certs/vpsadmin-cert.crt -noout -text | rg -A1 "Subject Alternative Name"
   openssl verify -CAfile certs/vpsadmin-ca.crt certs/vpsadmin-cert.crt
   ```
6) Restart any local services that load this certificate so they pick up the new SAN list.

Notes
-----
- Keep the CA serial file (`vpsadmin-ca.srl`) with the CA key; `-CAcreateserial` will create it if missing. Avoid deleting it so serials stay unique across reissues.
- If you need a fresh leaf key, regenerate it before step 3 with `openssl genrsa -out vpsadmin-cert.key 2048`, then continue with the same steps.
