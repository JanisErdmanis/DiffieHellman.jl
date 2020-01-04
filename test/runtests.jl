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

id(s) = hash(s.pubkey)
chash(envelope1,envelope2,key) = hash("$envelope1 $envelope2 $key")

# master
server = Signer(G)
serversign(data) = DSASignature(hash(data),server)
serverid = id(server)

# slave
slave = Signer(G)
slavesign(data) = DSASignature(hash(data),slave)
slaveid = id(slave)

verifysignature(data,signature) = verify(data,signature,G)

wrap(sign::Function) = data->(data,sign(data))

function unwrap(verify::Function,validate::Function)
    envelope -> begin
        data, signature = envelope
        @assert verify(data,signature) && validate(id(signature))
        return data
    end
end

### Let's assume that maintainer had contacted the server

@sync begin
    server = listen(2000)
    @async global serversocket = accept(server)
    global slavesocket = connect(2000)
end

### Let's say that we want slave to connect only to a true master. Thus he owns a certificate and from master had obtained a valid master id.
@async global keyserver = diffie(x->serialize(serversocket,x),()->deserialize(serversocket),wrap(serversign),unwrap(verifysignature,id->true),G,chash,rngint(100))
keyslave = hellman(x->serialize(slavesocket,x),()->deserialize(slavesocket),wrap(slavesign),unwrap(verifysignature,id->id==serverid),G,chash,rngint(100)) # x==serverid

@test keyslave==keyserver











