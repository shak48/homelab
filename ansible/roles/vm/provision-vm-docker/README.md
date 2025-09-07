# NPM
# Self-Cert
  openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
  -keyout ~/npm-certs/selfsigned.key \
  -out    ~/npm-certs/selfsigned.crt \
  -subj "/CN=dummy.local"

  ~/npm-certs/selfsigned.key   # private key
  ~/npm-certs/selfsigned.crt   # public cert

