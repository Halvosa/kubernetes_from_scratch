# What is a Certificate Authority?
In many programs, it is important that clients and servers are able to authenticate eachother and communicate privately. This is often achieved with the application layer protocol TLS (Transport Layer Security). TLS is highly configurable, but the goals is ultimately for the client and the server to first trust eachother (usually through digital certificates), and then agree upon a secret symmetric session key to encrypt their messages with. A symmetric key is used because it is faster than asymmetric encryption. Sometimes TLS is configured such that only the client cares to authenticate the server, while the authenticity of the client is unimportant to the server. With bidirectional authentication, however, both the client and the server exchange certificates.

## The Handshake

The process of establishing a TLS connection between a server and a client goes roughly as follows:
1. The server has a pair of public and private keys.
2. The client ask the server to establish a TLS connection.
3. The server replies and provides its digital certificate. The certficate is a file that contains the server's public key and various other information like .... The certificate is digitally signed by a Certificate Authority, so as long as the client trusts the CA, it should be able to trust the certificate. (More on how the client can trust the CA and the signed certificate later.)
4. When the The next step is for the client and the server to agree on a symmetric session key in a secure manner. There are several algorithms for this. A simple one is that the client encrypts a random number with the server's public key and then sends it over to the server. The server should be the only one that can read the random number, because it should be the only entity that has the private key associated with the public key in the server's certificate. Next, both the server and the client use the same random number to generate the same symmetric key. A much more secure exchange algorithm is used today and is based on the Diffie-Hellman key exchange scheme, where both the server and the client has a public and private key pair.

## 

# Setting up a CA

We will be setting up a CA on the k8s-master VM, where the entire control plane resides. In a large scale production environment, it might be best to use a separate server for the CA only, and keep it mostly offline 

Easy-RSA is a utility for managing X.509 PKI, or Public Key Infrastructure. Crypto-related tasks use openssl as the functional backend.

```
Easy-RSA's main program is a script, supported by a couple of config files. As such, there is no formal "installation" required. Preparing to use Easy-RSA is as simple as downloading the compressed package (.tar.gz for Linux/Unix or .zip for Windows) and extract it to a location of your choosing. 

You should install and run Easy-RSA as a non-root (non-Administrator) account as root access is not required.

Easy-RSA 3 no longer needs any configuration file prior to operation, unlike earlier versions. 
```
We will just go with the default configuration. However, a list of available settings can be found in Easy-RSA's advanced documentation: https://easy-rsa.readthedocs.io/en/latest/advanced/. We could for example specify certificate details such as email, city, state, country, and issued cert expiration date, as well as more technical crypto-related setting. Settings can be set through CLI flags, environment variables, or through a config file.

First, we download the latest Easy-RSA release from the offical github repo and extract it to ~/easy-rsa. This folder will contain everything related to the CA. (The tar archive can techically be extracted anywhere you see fit, but somewhere in the home directory of the user responsible for the CA is a natural choice.) Only the user that controls the CA should have access to the CA, and therefore we set the permissions on the directory to 700.

```console
[vagrant@k8s-master ~]$ wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz
[vagrant@k8s-master ~]$ tar -xf EasyRSA-3.0.8.tgz
[vagrant@k8s-master ~]$ mv EasyRSA-3.0.8 easy-rsa
[vagrant@k8s-master ~]$ chmod 700 easy-rsa/
```

Next, we initialize a new PKI (Public Key Infrastructure). All it does is creating a directory called pki containing some default directories and files.

```console
[vagrant@k8s-master ~]$ cd easy-rsa
[vagrant@k8s-master easy-rsa]$ ./easyrsa init-pki

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /home/vagrant/easy-rsa/pki
[vagrant@k8s-master easy-rsa]$ ll pki/
total 16
-rw-------. 1 vagrant vagrant 4616 Dec 15 20:42 openssl-easyrsa.cnf
drwx------. 2 vagrant vagrant    6 Dec 15 20:42 private
drwx------. 2 vagrant vagrant    6 Dec 15 20:42 reqs
-rw-------. 1 vagrant vagrant 4650 Dec 15 20:42 safessl-easyrsa.cnf
```
The directory `private` contains private keys generated locally. The `reqs` directory contains locally created and imported CSR's. (When some external host needs a certificate, they send a Certificate Signing Request to the CA, which then must be imported to the reqs folder such that Easy-RSA knows about it. The request file must be a standard CSR in PKCS#10 format.) The `.cnf` files are configuration files for the underlying cryptography tools that Easy-RSA is built around.

The next command builds the CA according to the configured settings. This simply means that a private key `ca.key` and a certificate `ca.crt` are created. The directories issued, renewed and revoked are also created, as well as a few other files. (WHAT ARE THESE FILES?)

* Password?
* Common name?

```console
[vagrant@k8s-master easy-rsa]$ ./easyrsa build-ca
Using SSL: openssl OpenSSL 1.1.1g FIPS  21 Apr 2020

Enter New CA Key Passphrase: 
Re-Enter New CA Key Passphrase: 
Generating RSA private key, 2048 bit long modulus (2 primes)
.............+++++
.......................................................+++++
e is 65537 (0x010001)
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:kubernetes-ca

CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/home/vagrant/easy-rsa/pki/ca.crt
```

```console
[vagrant@k8s-master easy-rsa]$ ./easyrsa show-ca
```

Ansible for å dele ut nøkler?

```console
halvor@halvor-NUC:~/lab/Vagrant$ vagrant ssh node-1
[vagrant@node-1 ~]$ sudo vi /etc/ssh/sshd_config 
_...Set "PasswordAuthentication yes"..._
[vagrant@node-1 ~]$ sudo systemctl reload sshd
[vagrant@node-1 ~]$ sudo mkdir /usr/local/share/ca-certificates
```

Now copy ca.crt from k8s-master to node-1 using scp.

```console
[vagrant@k8s-master easy-rsa]$ sudo scp pki/ca.crt 192.168.50.11:/etc/pki/ca-trust/source/anchors/kubernetes.crt
[vagrant@node-1 ~]$ sudo update-ca-trust extract
```

```console
[vagrant@k8s-master easy-rsa]$ ./easyrsa help options
[vagrant@k8s-master easy-rsa]$ ./easyrsa help altname
```

```console
[vagrant@k8s-master easy-rsa]$ ./easyrsa --subject-alt-name="IP:192.168.50.10,"\
"DNS:kubernetes,"\
"DNS:kubernetes.default,"\
"DNS:kubernetes.default.svc,"\
"DNS:kubernetes.default.svc.cluster,"\
"DNS:kubernetes.default.svc.cluster.local" \
--days=10000 \
build-server-full server nopass
```
Hvorfor alle disse DNS-greiene???

--client-ca-file=/home/vagrant/easy-rsa/pki/ca.crt
--tls-cert-file=/yourdirectory/server.crt
--tls-private-key-file=/yourdirectory/server.key



# Links
Easy-RSA
* https://easy-rsa.readthedocs.io/en/latest/
* https://easy-rsa.readthedocs.io/en/latest/advanced/   (Configuration)

* https://kubernetes.io/docs/tasks/administer-cluster/certificates/
* https://kubernetes.io/docs/setup/best-practices/certificates/

