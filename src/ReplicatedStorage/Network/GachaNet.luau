-- SERVICIOS
local RS = game:GetService("ReplicatedStorage")

-- DEPENDENCIAS
local Red = require(RS.Packages.Red)
local Guard = require(RS.Packages.Guard)

-- DEFINICION DEL EVENTO
local GachaNet = {
    AbrirCaja = Red.Function("AbrirCaja", Guard.String, Guard.String)
}

return GachaNet