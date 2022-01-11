openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out tls.crt \
    -keyout tls.key

kubectl create secret tls scrutiny-tls \
    --key tls.key \
    --cert tls.crt