local RS = game:GetService("ReplicatedStorage")

local Red = require(RS.Packages.Red)
local Guard = require(RS.Packages.Guard)

local GachaNet = {
    AbrirCaja = Red.Function("AbrirCaja", Guard.String, Guard.String)
}
return GachaNet