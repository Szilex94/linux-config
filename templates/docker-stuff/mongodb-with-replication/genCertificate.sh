#!/bin/bash
if [ "$1" = "" ]; then
echo 'Please enter your hostname (CN):'
exit 1
fi
HOST_NAME="$1"
SUBJECT="/C=RO/ST=Cluj/L=Cluj/O=Self/OU=Self/CN=$HOST_NAME"
openssl req -new -nodes -newkey rsa:4096 -subj "$SUBJECT" -keyout $HOST_NAME.key -out $HOST_NAME.csr
openssl x509 -CA mongoCA.crt -CAkey mongoCA.key -CAcreateserial -req -in $HOST_NAME.csr -out $HOST_NAME.crt
rm $HOST_NAME.csr
cat $HOST_NAME.key $HOST_NAME.crt > $HOST_NAME.pem
rm $HOST_NAME.key
rm $HOST_NAME.crt