using Tests
# Lets run DiffieHellman over network

using Sockets

servesocket = 
clientsocket = 

# Now let's generate signers

using Signatures
import Paillier

# master
server = Signer(Paillier.generate_paillier_keypair(1024))
# slave

user = Signer(Paillier.generate_paillier_keypair(1024))
### Let's say that we want slave to connect only to a true master. Thus he owns a certificate and from master had obtained a valid master id.
serverid = id(server)

@sync begin
    @async keyuser = hellman(clientside,x->x==serverid,data->sign(data,SHA256,user))
    @async keyserver = diffie(clientside,x->true,data->sign(data,SHA256,server))
end

@test keyuser==keyserver
