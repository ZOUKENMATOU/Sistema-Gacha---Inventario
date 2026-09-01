local RNG_System = {}
local HttpService = game:GetService("HttpService")

function RNG_System.MakeRNG() --Genera un numero pseudoaleatorio
    local Time = os.time()
    local Clock = os.clock()
    local GUID = HttpService:GenerateGUID(false)
    local Number = math.random()

    local Combinar = tostring(Time)..tostring(Clock)..GUID..tostring(Number)

    local Hash = 2166136261
    for i = 1, #Combinar do 
        Hash = bit32.bxor(Hash, string.byte(Combinar, i))
        Hash = bit32.band(Hash * 16777619, 0xFFFFFFFF)
    end
    return Random.new(Hash)
end

local generadorSeguro = RNG_System.MakeRNG()

function RNG_System.GenerarRNG(pesoTotal :number) : number --Genera un numero pseudoaleatorio entre 1 y el peso total
    return generadorSeguro:NextInteger(1, pesoTotal)
end
return RNG_System