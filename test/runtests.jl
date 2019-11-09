#using Tests
# Lets run DiffieHellman over network

using DiffieHellman
using CryptoGroups
using CryptoSignatures

using Sockets

server = listen(2000)

@sync begin
    @async global serversocket = accept(server)
    global slavesocket = connect(2000)
end

# For Simplicity let's choose the same group and the same kind of signatures for both sides. Generally it could be different and even user could choose the generator himself.
G = CryptoGroups.MODP160Group()

# master
server = Signer(G)
serversign(data) = DSASignature(hash(data),server)

# slave
slave = Signer(G)
slavesign(data) = DSASignature(hash(data),slave)

### Let's say that we want slave to connect only to a true master. Thus he owns a certificate and from master had obtained a valid master id.

serverid = hash(server.pubkey)

@sync begin
    @async global keyserver = diffie(serversocket,serversign,(d,s)->verify(d,s,G),G)
    @async global keyslave = hellman(slavesocket,slavesign,(d,s)->verify(d,s,G) && hash(s.pubkey)==serverid) # x==serverid
end

@show keyslave==keyserver
