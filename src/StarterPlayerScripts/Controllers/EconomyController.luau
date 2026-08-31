local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local EconomyNet = require(RS.Network.EconomyNet)

local EconomyController = {}

-- REFERENCIAS GUI --
local localPlayer = Players.LocalPlayer
local GUI = localPlayer:WaitForChild("PlayerGui")
local EconomyVisuals = GUI:WaitForChild("EconomyVisuals")
local FramePrincipal = EconomyVisuals:WaitForChild("FramePrincipal")
local OroCantidad = FramePrincipal:WaitForChild("OroData"):WaitForChild("Cantidad")
local GemasCantidad = FramePrincipal:WaitForChild("GemasData"):WaitForChild("Cantidad")

function EconomyController.Init()
    EconomyNet.SyncEconomia:Client():On(function(datosDelServidor) --Recibe los datos de la economía desde el servidor
        print("[EconomyController] Sincronizando datos del inventario")
        local oroActual =  datosDelServidor.Oro --Recibe la cantidad de oro actual del jugador
        local gemasActual = datosDelServidor.Gemas --Recibe la cantidad de gemas actual del jugador
        EconomyController.ActualizarTextos(oroActual, gemasActual) --Actualiza los textos de oro y gemas con los datos del servidor
    end)
end

function EconomyController.ActualizarTextos(oro : number, gemas : number)
    OroCantidad.Text = tostring(oro) --Actualiza el texto de oro con la cantidad actual
    GemasCantidad.Text = tostring(gemas) --Actualiza el texto de gemas con la cantidad actual
end
return EconomyController