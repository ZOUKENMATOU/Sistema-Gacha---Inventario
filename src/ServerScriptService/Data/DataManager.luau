-- SERVICIOS
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- DEPENDENCIAS
local ProfileStore = require(SSS.ServerPackages.profilestore)
local PlayerTemplate = require(SSS.Data.PlayerTemplate)
local RarezasConfig = require(RS.Config.RarezasConfig) -- Importación de la configuración de rarezas
local InventoryNet = require(RS.Network.InventoryNet)
local EconomyNet = require(RS.Network.EconomyNet)

-- TIPOS DE DATOS
type NombreRareza = RarezasConfig.NombresRareza

export type RecompensasData = {
	Oro: number,
	Gemas: number,
}

-- CONSTANTES
--Datos separados entre Studio y datos Reales
local function obtenerClaveAlmacen(): string
	return RunService:IsStudio() and "Data_TestV1" or "Data_Live"
end

local COMPENSACION_RAREZAS: { [NombreRareza]: RecompensasData } = {
	Common = {
		Oro = 10,
		Gemas = 0,
	},
	Uncommon = {
		Oro = 25,
		Gemas = 0,
	},
	Rare = {
		Oro = 50,
		Gemas = 1,
	},
	Epic = {
		Oro = 80,
		Gemas = 3,
	},
	Legendary = {
		Oro = 150,
		Gemas = 5,
	},
	Mythic = {
		Oro = 200,
		Gemas = 10,
	},
	Divine = {
		Oro = 400,
		Gemas = 15,
	},
}

-- ESTADO LOCAL
local PlayerStore = ProfileStore.New(obtenerClaveAlmacen(), PlayerTemplate)
local Profiles = {} -- Perfiles de sesión activos

-- MÓDULO PÚBLICO
local DataManager = {}

-- FUNCIONES AUXILIARES PRIVADAS

-- Sincroniza el estado de la economía del jugador hacia el cliente correspondiente
local function sincronizarEconomia(player: Player, profile: any)
	local datosEconomia = {
		Oro = profile.Data.Economia.Oro,
		Gemas = profile.Data.Economia.Gemas,
	}
	EconomyNet.SyncEconomia:Server():Fire(player, datosEconomia)
end

-- Sincroniza el inventario completo del jugador hacia el cliente correspondiente
local function sincronizarInventario(player: Player, profile: any)
	local datosInventario = {
		Armas = profile.Data.Armas,
		Auras = profile.Data.Auras,
	}
	InventoryNet.SyncInventario:Server():Fire(player, datosInventario)
end

-- Otorga compensación económica por un ítem duplicado según su rareza
local function compensarDuplicado(player: Player, tipo: string, rareza: NombreRareza)
	local recompensas = COMPENSACION_RAREZAS[rareza]
	local oroExtra = (recompensas and recompensas.Oro) or 0
	local gemasExtra = (recompensas and recompensas.Gemas) or 0

	DataManager.AgregarOro(player, oroExtra)
	DataManager.AgregarGemas(player, gemasExtra)
	print(`[DataManager] Duplicado ({tipo}): +{oroExtra} Oro, +{gemasExtra} Gemas`)
end

-- FUNCIONES PÚBLICAS: SESIÓN Y CICLO DE VIDA

-- Carga la sesión del perfil del jugador conectado
function DataManager.CargarPerfil(player: Player)
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId)
	if profile == nil then
		player:Kick("Error al cargar tus datos. Vuelve a intentarlo")
		return
	end

	-- GDPR: Si un jugador solicita borrado de datos, Roblox conoce dónde están almacenados
	profile:AddUserId(player.UserId)
	profile:Reconcile() -- Si se agregan nuevos datos a la plantilla, se actualizan automáticamente

	-- Manejo de desconexión forzada de sesión (ej. carga simultánea en otro servidor)
	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick("Tus datos se cargaron en otro servidor.")
	end)

	-- Verificación de estado del perfil (activo o inactivo)
	if player:IsDescendantOf(Players) then
		if profile:IsActive() then
			print(`[DataManager] Cargando datos de {player.Name}`)
			Profiles[player] = profile

			-- Enviar datos iniciales de inventario y economía al cliente
			sincronizarInventario(player, profile)
			sincronizarEconomia(player, profile)
		else
			profile:EndSession()
		end
	else
		profile:EndSession()
	end
end

-- Guarda y libera la sesión del perfil al desconectarse el jugador
function DataManager.GuardarPerfil(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
		Profiles[player] = nil
		print(`[DataManager] Se han guardado los datos de {player.Name}.`)
	end
end

-- Devuelve el perfil activo del jugador actual
function DataManager.ObtenerPerfil(player: Player)
	return Profiles[player]
end

-- Inicializa las conexiones del ciclo de vida de jugadores
function DataManager.Init()
	Players.PlayerAdded:Connect(DataManager.CargarPerfil)
	Players.PlayerRemoving:Connect(DataManager.GuardarPerfil)

	-- Carga los perfiles de los jugadores presentes antes de la inicialización
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			DataManager.CargarPerfil(player)
		end)
	end
end

-- FUNCIONES PÚBLICAS: ECONOMÍA

-- Deduce una cantidad de Oro del perfil del jugador si posee fondos suficientes
function DataManager.GastarOro(player: Player, cantidad: number): boolean
	local profile = Profiles[player]
	if not profile then return false end

	if profile.Data.Economia.Oro >= cantidad then
		profile.Data.Economia.Oro -= cantidad
		print(`[DataManager] Se ha restado {cantidad} oro a {player.Name}`)
		sincronizarEconomia(player, profile)
		return true
	else
		warn(`[DataManager] Compra rechazada. Fondos insuficientes de Oro para {player.Name}`)
		return false
	end
end

-- Deduce una cantidad de Gemas del perfil del jugador si posee fondos suficientes
function DataManager.GastarGemas(player: Player, cantidad: number): boolean
	local profile = Profiles[player]
	if not profile then return false end

	if profile.Data.Economia.Gemas >= cantidad then
		profile.Data.Economia.Gemas -= cantidad
		print(`[DataManager] Se ha restado {cantidad} gemas a {player.Name}`)
		sincronizarEconomia(player, profile)
		return true
	else
		warn(`[DataManager] Compra rechazada. Fondos insuficientes de Gemas para {player.Name}`)
		return false
	end
end

-- Añade una cantidad de Oro al perfil del jugador y sincroniza con el cliente
function DataManager.AgregarOro(player: Player, cantidad: number)
	local profile = Profiles[player]
	if not profile then return end

	profile.Data.Economia.Oro += cantidad
	sincronizarEconomia(player, profile)
end

-- Añade una cantidad de Gemas al perfil del jugador y sincroniza con el cliente
function DataManager.AgregarGemas(player: Player, cantidad: number)
	local profile = Profiles[player]
	if not profile then return end

	profile.Data.Economia.Gemas += cantidad
	sincronizarEconomia(player, profile)
end

-- FUNCIONES PÚBLICAS: INVENTARIO

-- Agrega un ítem al inventario del jugador o compensa con divisas en caso de estar repetido
function DataManager.AgregarItemPorTipo(player: Player, tipo: string, itemId: string, rarezaGanadora: NombreRareza) : boolean
	local profile = Profiles[player]
	if not profile then return false end

	local inventarioCategoria = profile.Data[tipo]
	if not inventarioCategoria then
		warn(`[DataManager] La categoría '{tipo}' no existe en el perfil de {player.Name}`)
		return false
	end

	-- Manejo de duplicados: otorga compensación en lugar de agregar el ítem repetido
	if table.find(inventarioCategoria, itemId) then
		compensarDuplicado(player, tipo, rarezaGanadora)
		return false
	end

	-- Agregar ítem nuevo al inventario y sincronizar
	table.insert(inventarioCategoria, itemId)
	print(`[DataManager] Se agregó {itemId} a la categoría '{tipo}' de {player.Name}`)

	sincronizarInventario(player, profile)
	return true
end

return DataManager