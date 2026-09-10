-- SERVICIOS
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

-- DEPENDENCIAS
local CasesIndex = require(RS.Config.Cases.CasesIndex)
local SPP = require(RS.Utils.SelectorPorPeso)
local RNG = require(RS.Utils.RNG)
local GachaNet = require(RS.Network.GachaNet)
local DataManager = require(SSS.Data.DataManager)

-- CONSTANTES
local COBRADORES_MONEDA: { [string]: (Player, number) -> boolean } = {
	Oro = DataManager.GastarOro,
	Gemas = DataManager.GastarGemas,
}

-- MÓDULO PÚBLICO
local GachaHandler = {}

-- FUNCIONES AUXILIARES PRIVADAS

-- Valida fondos y realiza el débito correspondiente de la moneda de la caja
local function cobrarPrecioCaja(player: Player, caja: any): boolean
	if caja.Moneda == "Robux" then
		error("[GachaService] Las cajas de Robux deben comprarse mediante la pasarela de pago.")
	end

	local cobrar = COBRADORES_MONEDA[caja.Moneda]
	if not cobrar or not cobrar(player, caja.Precio) then
		error(`[GachaService] Fondos insuficientes de {caja.Moneda}.`)
	end

	return true
end

-- Determina la rareza y el ítem resultante según las probabilidades y el contenido de la caja
local function seleccionarItemAleatorio(caja: any): (string?, string?)
	local pesos = caja.Probabilidades
	local pesoTotal = SPP.ObtenerTotal(pesos)
	local rng = RNG.GenerarRNG(pesoTotal)

	local rarezaGanadora = SPP.SeleccionarRareza(pesos, rng)
	if not rarezaGanadora then
		return nil, nil
	end

	local tablaItemsRareza = caja.Contenido[rarezaGanadora]
	if not tablaItemsRareza or #tablaItemsRareza == 0 then
		return nil, rarezaGanadora
	end

	local indiceAleatorio = math.random(#tablaItemsRareza)
	local itemGanadorId = tablaItemsRareza[indiceAleatorio]

	return itemGanadorId, rarezaGanadora
end

-- FUNCIONES PÚBLICAS

-- Inicializa los listeners y callbacks del sistema de Gacha
function GachaHandler.Init()
	GachaNet.AbrirCaja:SetCallback(function(player: Player, nombreCaja: string)
		local cajaRequerida = CasesIndex[nombreCaja]
		if not cajaRequerida then
			warn(`[GachaHandler] Caja inválida. No existe la caja con el ID: {nombreCaja}`)
			return
		end

		-- Cobro del costo de apertura
		cobrarPrecioCaja(player, cajaRequerida)

		-- Selección de recompensa
		local itemGanadorId, rarezaGanadora = seleccionarItemAleatorio(cajaRequerida)
		if not itemGanadorId or not rarezaGanadora then
			warn(`[GachaHandler] No se pudo obtener un ítem válido para la caja: {nombreCaja}`)
			return
		end

		-- Entrega del ítem o compensación
		DataManager.AgregarItemPorTipo(player, cajaRequerida.Tipo, itemGanadorId, rarezaGanadora)

		return itemGanadorId
	end)
end

return GachaHandler