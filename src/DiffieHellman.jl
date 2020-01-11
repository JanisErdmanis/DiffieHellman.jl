module DiffieHellman

using CryptoGroups

struct DH
    wrap::Function
    unwrap::Function
    G::AbstractGroup
    hash::Function
    rngint::Function
end

function diffiehellman(send::Function,get::Function,wrap::Function,unwrap::Function,G::AbstractGroup,hash::Function,a::Integer)
    Avalue = value(G^a)
    envelopeA = wrap(Avalue)
    send(envelopeA)

    envelopeB = get()
    Bvalue,id = unwrap(envelopeB)
    
    B = typeof(G)(Bvalue,G)
    @assert B!=G "Trivial group elements are not allowed."
    key = value(B^a)

    #sleep(3)
    
    cmsgA = hash(envelopeA,envelopeB,key)
    send(cmsgA)
    
    cmsgB = get()
    @assert cmsgB==hash(envelopeB,envelopeA,key) "The key exchange failed."

    return key,id 
end

diffiehellman(send::Function,get::Function,dh::DH) = diffiehellman(send,get,dh.wrap,dh.unwrap,dh.G,dh.hash,dh.rngint())

"""
A helper function when IO gets messed with races. (bugs are hard)
"""
function diffie(send::Function,get::Function,wrap::Function,unwrap::Function,G::AbstractGroup,hash::Function,a::Integer)

    envelopeB = get()
    Bvalue,id = unwrap(envelopeB)

    Avalue = value(G^a)
    envelopeA = wrap(Avalue)
    send(envelopeA)
    
    B = typeof(G)(Bvalue,G)
    @assert B!=G "Trivial group elements are not allowed."
    key = value(B^a)

    cmsgB = get()
    @assert cmsgB==hash(envelopeB,envelopeA,key) "The key exchange failed."

    cmsgA = hash(envelopeA,envelopeB,key)
    send(cmsgA)

    return key,id 
end

diffie(send::Function,get::Function,dh::DH) = diffie(send,get,dh.wrap,dh.unwrap,dh.G,dh.hash,dh.rngint())

hellman = diffiehellman

export diffiehellman, diffie, hellman, DH

end # module
