module DiffieHellman

using Signatures
using Mods

using Paillier

rngprime(N) = Paillier.nbit_prime_of_size(N)
rngint(N) = Paillier.n_bit_random_number(N)

### Stuff to be implemented
# https://math.stackexchange.com/questions/124408/finding-a-primitive-root-of-a-prime-number
getprimitiveroot(p) = 51

const N = 10

# Probably before user descides to contact the server he asks for the certificate of the public key and checks if that is valid. 
function diffie(io,istrusted::Function,sign::Function)
    s = Serializer(io)
    Serialization.writeheader(s)

    p = rngprime(N)
    g = getprimitiveroot(p)
    
    G = Mod(g,p)
    serialize(s,G)

    B,Bsign = deserialize(s)
    if verify(B,Bsign) && istrusted(id(Bsign))

        a = rngint(N-1)
        A = G^a
        serialize(s,(A,sign(A)))

        key = mod(B^a,p)
        return key
    else
        return Error("Key exchange failed.")
    end
end

"""
This one returns a secret connection between two fixed parties.
"""
function hellman(io,istrusted::Function,sign::Function)
    s = Serializer(io)
    s = Serialization.writeheader(s)

    G = deserialize(s)

    b = rngint(N-1) # A random int here
    
    B = G^b
    serialize(s,(B,sign(B)))

    A,Asign = deserialize(s)

    if verify(A,Asign) && istrusted(id(Asign))
        key = mod(A^b,p)
        return key
    else
        return Error("Key exchange failed.")
    end
end

end # module
