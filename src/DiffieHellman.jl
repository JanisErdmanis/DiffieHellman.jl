module DiffieHellman

using CryptoGroups

function diffie(send::Function,get::Function,wrap::Function,unwrap::Function,G::AbstractGroup,hash::Function,a::Integer)
    envelopeB = get()
    Bvalue = unwrap(envelopeB)

    Avalue = value(G^a)

    envelopeA = wrap(Avalue)
    send(envelopeA)
    
    B = typeof(G)(Bvalue,G)
    @assert B!=G "Trivial group elements are not allowed."
    key = value(B^a)
    

    cmsgA = hash(envelopeA,envelopeB,key)
    send(cmsgA)

    cmsgB = get()
    @assert cmsgB==hash(envelopeB,envelopeA,key) "The key exchange failed."

    return key
end

"""
This one returns a secret connection between two fixed parties. The signature function sign returns signature and the group with respect to which the signature was signed.
"""
function hellman(send::Function,get::Function,wrap::Function,unwrap::Function,G::AbstractGroup,hash::Function,b::Integer)
    Bvalue = value(G^b)
    envelopeB = wrap(Bvalue)
    send(envelopeB)

    envelopeA = get()
    Avalue = unwrap(envelopeA)

    A = typeof(G)(Avalue,G)
    @assert A!=G "Trivial group elements are not allowed."
    key = value(A^b)
    
    cmsgB = hash(envelopeB,envelopeA,key)
    send(cmsgB)

    cmsgA = get()
    @assert cmsgA==hash(envelopeA,envelopeB,key) "The key exchange failed."
    
    return key
end

export diffie, hellman

end # module
