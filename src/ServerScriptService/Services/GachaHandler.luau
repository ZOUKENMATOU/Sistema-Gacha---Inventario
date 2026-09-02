local GachaHandler = {}

--SERVICIOS
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

--DEPENDENCIAS
local CasesIndex = require(RS.Config.Cases.CasesIndex)
local SPP = require(RS.Utils.SelectorPorPeso)
local RNG = require(RS.Utils.RNG)
local GachaNet = require(RS.Network.GachaNet)

local DataManager = require(SSS.Data.DataManager)


local CobradoresMoneda : {[string]: (Player, number) -> boolean} = {
    Oro = DataManager.GastarOro,
    Gemas = DataManager.GastarGemas,
}
function GachaHandler.Init()
    GachaNet.AbrirCaja:SetCallback(function(player: Player, nombreCaja: string)
        local CajaRequerida = CasesIndex[nombreCaja]

        if not CajaRequerida then
            warn("[GachaHandler] Caja inválida. No existe la caja con el ID: " .. nombreCaja)
            return
        end

        if CajaRequerida.Moneda == "Robux" then
            error("[GachaService] Las cajas de Robux deben comprarse mediante la pasarela de pago.")
        end

        local cobrar = CobradoresMoneda[CajaRequerida.Moneda] --Función para cobrar la moneda correspondiente al jugador
        if not cobrar or not cobrar(player, CajaRequerida.Precio) then --Cobrar la moneda correspondiente al jugador si no se puede cobrar, se devuelve un error
            error(`[GachaService] Fondos insuficientes de {CajaRequerida.Moneda}.`)
        end
        
        --Seleccionar una rareza ganadora basada en las probabilidades definidas en la caja
        local pesos = CajaRequerida.Probabilidades --Tabla de probabilidades de los items en la caja
        local pesoTotal = SPP.ObtenerTotal(pesos) --Suma de todos los pesos de los items en la caja
        local rng = RNG.GenerarRNG(pesoTotal) --Genera un número aleatorio entre 1 y el peso total

        local rarezaGanadora = SPP.SeleccionarRareza(pesos, rng) --Selecciona la rareza del item ganador basado en el RNG generado
        if not rarezaGanadora then
            warn("[GachaHandler] No se pudo seleccionar una rareza ganadora para la caja: " .. nombreCaja)
            return
        end

        --Seleccionar un item ganador basado en la rareza seleccionada
        local tablaRareza = CasesIndex[nombreCaja].Contenido[rarezaGanadora] --Indice de items de la rareza seleccionada
        if not tablaRareza or #tablaRareza == 0 then
            warn("[GachaHandler] No hay items disponibles para la rareza seleccionada: " .. rarezaGanadora)
            return
        end
        local numRandom = math.random(#tablaRareza) --Genera un número aleatorio entre 1 y la cantidad de items de la rareza seleccionada
        local itemGanadorId = tablaRareza[numRandom] --Selecciona el item ganador basado en el número aleatorio generado
        
        DataManager.AgregarItemPorTipo(player, CajaRequerida.Tipo, itemGanadorId, rarezaGanadora)
        return itemGanadorId
    end)
end
return GachaHandler