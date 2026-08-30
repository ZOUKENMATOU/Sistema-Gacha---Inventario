local RS = game:GetService("ReplicatedStorage")

local Red = require(RS.Packages.Red)

local function validarDatos(jugador: unknown, cantidad: unknown)
    assert(type(jugador) == "string" and type(cantidad) == "number", "[EconomyNet] Los datos deben ser un string y un número")
    return jugador :: string, cantidad :: number
end

local EconomySync = {
    SyncEconomia = Red.Event("SyncEconomia", validarDatos)
}
return EconomySync