# Generating X509 cerificates

**Not this method failed after some time further research required!**

Create Conf File
```
[req]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C  = RO
ST = Cluj
L  = Cluj
O  = Self
CN = Szilex94

[req_ext]
subjectAltName = @alt_names

[v3_req]
basicConstraints     = CA:FALSE
subjectKeyIdentifier = hash
keyUsage             = digitalSignature, keyEncipherment
extendedKeyUsage     = clientAuth, serverAuth
subjectAltName       = @alt_names

[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints = CA:true
subjectAltName       = @alt_names

[alt_names]
DNS.1 = mongoMaster
DNS.2 = mongoSlave1
DNS.3 = mongoSlave2
DNS.4 = localhost
IP.1 = 127.0.0.1
```

Use the following command to generate the key (a.k.a. issuer key)

```shell
openssl genrsa -out mongoCA.key -aes256 8192
```

create signed certificate
```shell
openssl req -x509 -new -extensions v3_ca -key mongoCA.key -out mongoCA.crt -config openssl.conf
```

veryfy contents with

```shell
openssl x509 -in mongoCA.crt -text -noout
```

Generate Certificate for each node using following script  
This needs to be performed for each node and always update the CN in the openssl.config as such it matches the host name ex `CN = mongoMaster`
```shell
#!/bin/bash
if [ "$1" = "" ]; then
echo 'Please enter your hostname (CN):'
exit 1
fi
HOST_NAME="$1"
SUBJECT="/C=RO/ST=Cluj/L=Cluj/O=Self/OU=Self/CN=$HOST_NAME"

#openssl req -nodes -newkey rsa:4096 -sha256 -subj "$SUBJECT" -keyout $HOST_NAME.key -out $HOST_NAME.csr
#openssl x509 -CA mongoCA.crt -CAkey mongoCA.key -CAcreateserial -req -in $HOST_NAME.csr -out $HOST_NAME.crt

openssl genrsa -out $HOST_NAME.key 2048

openssl req \
  -new -key $HOST_NAME.key \
  -out $HOST_NAME.csr \
  -config openssl.conf

openssl x509 -req \
	-in $HOST_NAME.csr \
	-CA mongoCA.crt \
	-CAkey mongoCA.key \
	-CAcreateserial \
	-out $HOST_NAME.crt \
    -days 500 \
	-sha256 \
	-extensions v3_req \
	-extfile openssl.conf


cat $HOST_NAME.key $HOST_NAME.crt > $HOST_NAME.pem

rm $HOST_NAME.csr
rm $HOST_NAME.key
rm $HOST_NAME.crt

openssl x509 -in $HOST_NAME.pem -noout -text
```

## Docker

to unfuck fuced situation
```shell
docker compose -f "docker-compose.yml" down
docker system prune --force
```

```docker
docker compose up -d
```

Connect to master node
```docker
docker exec -it mongodb-with-replication-mongoMaster-1 /bin/bash
```

# Setup Replica
Start mongosh
```shell
mongosh --tls \
  --tlsCAFile /data/ssl/mongoCA.crt \
  --tlsCertificateKeyFile /data/ssl/mongoMaster.pem
```

```javascript
rs.initiate({_id:"mongo-rs-set",members:[{_id:0,host:"mongoMaster"},{_id:1,host:"mongoSlave1"},{_id:2,host:"mongoSlave2"}]});
```


```javascript
db.createUser({user:"root",pwd:"whatever",roles:["root"]});
```
