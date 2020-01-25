using Test

using DiffieHellman
using Sockets
using Serialization
using CryptoGroups
using CryptoSignatures
using Random

function rngint(len::Integer)
    max_n = ( BigInt(1) << len ) - 1
    if len > 2
        min_n = BigInt(1) << (len - 1)
        return rand(min_n:max_n)
    end
    return rand(1:max_n)
end

G = CryptoGroups.MODP160Group()

id(s) = hash("$(s.pubkey)")
chash(envelope1,envelope2,key) = hash("$envelope1 $envelope2 $key")

# master
server = Signer(G)
serversign(data) = DSASignature(hash(data),server)
serverid = id(server)

# slave
slave = Signer(G)
slavesign(data) = DSASignature(hash(data),slave)
slaveid = id(slave)

wrap(sign::Function) = data->(data,sign(data))

function unwrap(envelope)
    data, signature = envelope
    @assert verify(data,signature,G)
    return data, id(signature)
end

### Let's assume that maintainer had contacted the server

@sync begin
    server = listen(2000)
    @async global serversocket = accept(server)
    global slavesocket = connect(2000)
end

### Let's say that we want slave to connect only to a true master. Thus he owns a certificate and from master had obtained a valid master id.
keyserver = @async diffiehellman(x->serialize(serversocket,x),()->deserialize(serversocket),wrap(serversign),unwrap,G,chash,rngint(100))
keyslave = @async diffiehellman(x->serialize(slavesocket,x),()->deserialize(slavesocket),wrap(slavesign),unwrap,G,chash,rngint(100)) # x==serverid

keyserv,idserv = fetch(keyserver)
keyslav,idslav = fetch(keyslave)

@test idserv==slaveid
@test idslav==serverid
@test keyserv==keyslav

### Let's now test diffie and hellman methods

# keyserver = @async diffie(x->serialize(serversocket,x),()->deserialize(serversocket),wrap(serversign),unwrap,G,chash,rngint(100))
# keyslave = @async hellman(x->serialize(slavesocket,x),()->deserialize(slavesocket),wrap(slavesign),unwrap,G,chash,rngint(100)) # x==serverid

# keyserv,idserv = fetch(keyserver)
# keyslav,idslav = fetch(keyslave)

# @test idserv==slaveid
# @test idslav==serverid
# @test keyserv==keyslav








