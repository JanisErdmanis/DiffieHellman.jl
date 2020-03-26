using Test

using DiffieHellman
using Sockets
using CryptoGroups
using CryptoSignatures
using Random
using Pkg.TOML


function rngint(len::Integer)
    max_n = ( BigInt(1) << len ) - 1
    if len > 2
        min_n = BigInt(1) << (len - 1)
        return rand(min_n:max_n)
    end
    return rand(1:max_n)
end

hash(x::AbstractString) = BigInt(Base.hash(x))

function chash(envelope1::Vector{UInt8},envelope2::Vector{UInt8},key::BigInt) 
    str = "$(String(copy(envelope1))) $(String(copy(envelope2))) $key"
    inthash = hash(str)
    strhash = string(inthash,base=16)
    return Vector{UInt8}(strhash)
end

id(s) = hash("$(s.pubkey)")

function wrap(value::BigInt,signer::Signer)
    signature = DSASignature(hash("$value"),signer)
    signaturedict = Dict(signature)
    dict = Dict("value"=>string(value,base=16),"signature"=>signaturedict)
    io = IOBuffer()
    TOML.print(io,dict)
    return take!(io)
end

function unwrap(envelope::Vector{UInt8})
    dict = TOML.parse(String(copy(envelope)))
    value = parse(BigInt,dict["value"],base=16)
    signature = DSASignature{BigInt}(dict["signature"])
    @assert verify(signature,G) && signature.hash==hash("$value")
    return value, id(signature)
end

G = CryptoGroups.Scep256k1Group()
#G = CryptoGroups.MODP160Group()

# master
server = Signer(G)
serversign(data) = DSASignature(hash(data),server)
serverid = id(server)

# slave
slave = Signer(G)
slavesign(data) = DSASignature(hash(data),slave)
slaveid = id(slave)


value = BigInt(234234324)
value2, signerid2 = unwrap(wrap(value,server))
@test value==value2
@test id(server)==signerid2

### Let's assume that maintainer had contacted the server

@sync begin
    server = listen(2000)
    @async global serversocket = accept(server)
    global slavesocket = connect(2000)
end

### Let's say that we want slave to connect only to a true master. Thus he owns a certificate and from master had obtained a valid master id.
keyserver = @async diffiehellman(serversocket,value->wrap(value,server),unwrap,G,chash,rngint(100))
keyslave = @async diffiehellman(slavesocket,value->wrap(value,slave),unwrap,G,chash,rngint(100)) # x==serverid

keyserv,idserv = fetch(keyserver)
keyslav,idslav = fetch(keyslave)

@test idserv==slaveid
@test idslav==serverid
@test keyserv==keyslav
