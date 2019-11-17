module DiffieHellman

using Random
#using Serialization
using SecureIO

using CryptoGroups

const _default_rng = Ref{RandomDevice}()
function __init__()
    _default_rng[] = RandomDevice()
end

default_rng() = _default_rng[]

function rngint(rng::AbstractRNG, len::Integer)
    max_n = ( BigInt(1) << len ) - 1
    if len > 2
        min_n = BigInt(1) << (len - 1)
        return rand(rng, min_n:max_n)
    end
    return rand(rng, 1:max_n)
end

# Probably before user descides to contact the server he asks for the certificate of the public key and checks if that is valid. 
function diffie(s,sign::Function,verify::Function,G::AbstractGroup,rng::AbstractRNG)
    #@show "Diffie", typeof(s), hasmethod(serialize,(typeof(s),Any))
    serialize(s,G)
    
    B,Bsign = deserialize(s)

    #@show verify(B,Bsign)

    if verify(B,Bsign)

        t = security(G)
        a = rngint(rng,t)
        A = binary(G^a)

        serialize(s,(A,sign(A)))
        
        Bb = typeof(G)(B,G)
        key = value(Bb^a)
        return key
    else
        return Error("Key exchange failed.")
    end
end

diffie(io,sign::Function,verify::Function,G::AbstractGroup) = diffie(io,sign,verify,G,default_rng())

"""
This one returns a secret connection between two fixed parties. The signature function sign returns signature and the group with respect to which the signature was signed.
"""
function hellman(s,sign::Function,verify::Function,rng::AbstractRNG)
    #@show "Hellman"
    G = deserialize(s)

    t = security(G)
    b = rngint(rng,t) 
    
    B = binary(G^b)
    serialize(s,(B,sign(B)))
    
    A,Asign = deserialize(s)

    if verify(A,Asign)
        Aa = typeof(G)(A,G)
        key = value(Aa^b)
        return key
    else
        return Error("Key exchange failed.")
    end
end

hellman(io,sign::Function,verify::Function) = hellman(io,sign,verify,default_rng())

export diffie, hellman

end # module
