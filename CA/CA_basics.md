# What is a Certificate Authority?
In many programs, it is important that clients and servers are able to authenticate eachother and communicate privately. This is often achieved with the application layer protocol TLS (Transport Layer Security). TLS is highly configurable, but the goals is ultimately for the client and the server to first trust eachother (usually through digital certificates), and then agree upon a secret symmetric session key to encrypt their messages with. A symmetric key is used because it is faster than asymmetric encryption. Sometimes TLS is configured such that only the client cares to authenticate the server, while the authenticity of the client is unimportant to the server. With bidirectional authentication, however, both the client and the server exchange certificates.

## The Handshake

The process of establishing a TLS connection between a server and a client goes roughly as follows:
1. The server has a pair of public and private keys.
2. The client ask the server to establish a TLS connection.
3. The server replies and provides its digital certificate. The certficate is a file that contains the server's public key and various other information like .... The certificate is digitally signed by a Certificate Authority, so as long as the client trusts the CA, it should be able to trust the certificate. (More on how the client can trust the CA and the signed certificate later.)
4. When the The next step is for the client and the server to agree on a symmetric session key in a secure manner. There are several algorithms for this. A simple one is that the client encrypts a random number with the server's public key and then sends it over to the server. The server should be the only one that can read the random number, because it should be the only entity that has the private key associated with the public key in the server's certificate. Next, both the server and the client use the same random number to generate the same symmetric key. A much more secure exchange algorithm is used today and is based on the Diffie-Hellman key exchange scheme, where both the server and the client has a public and private key pair.

## 
