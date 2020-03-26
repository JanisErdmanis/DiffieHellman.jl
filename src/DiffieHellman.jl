module DiffieHellman

using CryptoGroups

struct DH
    wrap::Function
    unwrap::Function
    G::AbstractGroup
    hash::Function
    rngint::Function
end

### It is actually possible for your own socket to define stack and unstack method in the externa libraries. For that however I need a common dependency. Stackers.jl?

function stack(io::IO,msg::Vector{UInt8})
    frontbytes = reinterpret(UInt8,Int16[length(msg)])
    item = UInt8[frontbytes...,msg...]
    write(io,item)
end

function unstack(io::IO)
    sizebytes = [read(io,UInt8),read(io,UInt8)]
    size = reinterpret(Int16,sizebytes)[1]
    
    msg = UInt8[]
    for i in 1:size
        push!(msg,read(io,UInt8))
    end
    return msg
end


function diffiehellman(io::IO,wrap::Function,unwrap::Function,G::AbstractGroup,hash::Function,a::Integer)
    Avalue = value(G^a)
    envelopeA = wrap(Avalue)
    stack(io,envelopeA)

    envelopeB = unstack(io)
    Bvalue,id = unwrap(envelopeB)
    
    B = typeof(G)(Bvalue,G) ### I could also have used a type parameter
    @assert B!=G "Trivial group elements are not allowed."
    key = value(B^a)

    cmsgA = hash(envelopeA,envelopeB,key)
    stack(io,cmsgA)
    
    cmsgB = unstack(io)
    @assert cmsgB==hash(envelopeB,envelopeA,key) "The key exchange failed."

    return key,id 
end

diffiehellman(io::IO,dh::DH) = diffiehellman(io,dh.wrap,dh.unwrap,dh.G,dh.hash,dh.rngint())

export diffiehellman, DH

end # module
