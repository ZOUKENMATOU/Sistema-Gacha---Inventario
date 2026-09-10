-- SERVICIOS
local RS = game:GetService("ReplicatedStorage")

-- DEPENDENCIAS
local Red = require(RS.Packages.Red)
local Guard = require(RS.Packages.Guard)

--FUNCION DE VALIDACION
local function validarDatos(player: unknown, cantidad: unknown)
    local jugadorValido = Guard.String(player)
    local cantidadValida = Guard.Number(cantidad)
    return jugadorValido, cantidadValida
end

-- DEFINICION DEL EVENTO
local EconomySync = {
    SyncEconomia = Red.Event("SyncEconomia", validarDatos)
}

return EconomySync