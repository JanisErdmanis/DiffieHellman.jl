using Test

using DiffieHellman
using CryptoGroups
using CryptoSignatures

using Sockets

# For Simplicity let's choose the same group and the same kind of signatures for both sides. Generally it could be different and even user could choose the generator himself.
G = CryptoGroups.MODP160Group()

# master
server = Signer(G)
serversign(data) = DSASignature(hash(data),server)
serverid = hash(server.pubkey)

# slave
slave = Signer(G)
slavesign(data) = DSASignature(hash(data),slave)

### Let's assume that maintainer had contacted the servre

@sync begin
    server = listen(2000)
    @async global serversocket = accept(server)
    global slavesocket = connect(2000)
end

### Let's say that we want slave to connect only to a true master. Thus he owns a certificate and from master had obtained a valid master id.
@async global keyserver = diffie(serversocket,serversign,(d,s)->verify(d,s,G),G)
keyslave = hellman(slavesocket,slavesign,(d,s)->verify(d,s,G) && hash(s.pubkey)==serverid) # x==serverid

@test keyslave==keyserver
