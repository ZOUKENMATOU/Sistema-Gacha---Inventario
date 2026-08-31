local RS = game:GetService("ReplicatedStorage")

local Red = require(RS.Packages.Red)
local Guard = require(RS.Packages.Guard)


local function validarDatos(player: unknown, cantidad: unknown)
    local jugadorValido = Guard.String(player)
    local cantidadValida = Guard.Number(cantidad)
    return jugadorValido, cantidadValida
end


local EconomySync = {
    SyncEconomia = Red.Event("SyncEconomia", validarDatos)
}
return EconomySync