-- SERVICIOS
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")

-- DEPENDENCIAS
local InventoryNet = require(RS.Network.InventoryNet)
local DataManager = require(SSS.Data.DataManager)

-- TIPOS DE DATOS
type EquipHandler = (player: Player, character: Model, clon: Instance) -> ()

-- CONSTANTES
local TIEMPO_ESPERA_PERFIL_DEFAULT = 5

local EQUIP_HANDLERS: { [string]: EquipHandler } = {
	Armas = function(player: Player, _character: Model, clon: Instance)
		clon.Parent = player.Backpack
	end,

	Auras = function(_player: Player, character: Model, clon: Instance)
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if clon:IsA("Model") and clon.PrimaryPart and rootPart then
			clon:PivotTo(rootPart.CFrame)

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rootPart
			weld.Part1 = clon.PrimaryPart
			weld.Parent = clon
		end
		clon.Parent = character
	end,
}

-- ESTADO LOCAL
local _itemEquipado: { [Player]: { [string]: Instance } } = {} -- Memoria que almacena los items equipados por cada jugador

-- MÓDULO PÚBLICO
local InventoryHandler = {}

-- FUNCIONES AUXILIARES PRIVADAS

-- Espera de forma asíncrona hasta que el perfil de datos del jugador esté listo
local function obtenerPerfilConEspera(player: Player, timeout: number?): any
	local limite = timeout or TIEMPO_ESPERA_PERFIL_DEFAULT
	local inicio = os.clock()

	while not DataManager.ObtenerPerfil(player) do
		if not player:IsDescendantOf(Players) then
			return nil
		end

		if os.clock() - inicio > limite then
			warn(`[InventoryService] Tiempo de espera agotado cargando datos para {player.Name}`)
			return nil
		end
		task.wait(0.1)
	end

	return DataManager.ObtenerPerfil(player)
end

-- Desequipa el ítem activo de una categoría y destruye su modelo en el personaje
local function desequiparItem(player: Player, profile: any, categoria: string)
	_itemEquipado[player] = _itemEquipado[player] or {}
	local itemPrevio = _itemEquipado[player][categoria]
	if itemPrevio and itemPrevio.Parent then
		itemPrevio:Destroy()
	end
	_itemEquipado[player][categoria] = nil

	if profile and profile.Data and profile.Data.Equipados then
		profile.Data.Equipados[categoria] = nil
	end
end

-- Clona y equipa físicamente el ítem especificado en el personaje
local function equiparItem(player: Player, profile: any, character: Model, categoria: string, itemId: string)
	-- Validación de posesión del ítem
	if not profile.Data[categoria] or not table.find(profile.Data[categoria], itemId) then
		warn(`[InventoryService] Intento ilegal: {player.Name} no posee '{itemId}'`)
		return
	end

	local carpetaAssets = SS.Assets:FindFirstChild(categoria)
	local modeloOriginal = carpetaAssets and carpetaAssets:FindFirstChild(itemId)
	if not modeloOriginal then return end

	local handler = EQUIP_HANDLERS[categoria]
	if not handler then
		warn(`[InventoryHandler] No se ha definido un handler para la categoria '{categoria}'`)
		return
	end

	-- Limpieza previa en la categoría antes de equipar el nuevo
	desequiparItem(player, profile, categoria)

	-- Entrega física y registro en memoria y perfil
	local clon = modeloOriginal:Clone()
	handler(player, character, clon)
	_itemEquipado[player][categoria] = clon -- Guardar el clon activo en memoria

	if profile.Data and profile.Data.Equipados then
		profile.Data.Equipados[categoria] = itemId
	end
end

-- FUNCIONES PÚBLICAS

-- Procesa solicitudes de equipar o desequipar ítems
function InventoryHandler.ProcesarEquipamiento(player: Player, itemId: string?, categoria: string)
	local character = player.Character
	if not character then return end

	-- Validación del perfil del jugador
	local profile = DataManager.ObtenerPerfil(player)
	if not profile then return end

	-- DESEQUIPAR ITEM --
	if not itemId or itemId == "" then
		desequiparItem(player, profile, categoria)
		return
	end

	-- EQUIPAR ITEM --
	equiparItem(player, profile, character, categoria, itemId)
end

-- Restaura todos los ítems guardados como equipados en el perfil tras reaparecer
function InventoryHandler.RestaurarEquipamiento(player: Player, character: Model)
	local profile = obtenerPerfilConEspera(player)
	if not profile or not profile.Data.Equipados then
		warn(`[InventoryHandler] No se ha encontrado el perfil o los datos de equipamiento para el jugador '{player.Name}'`)
		return
	end

	for categoria, itemId in pairs(profile.Data.Equipados) do
		if not itemId or itemId == "" then continue end

		local carpetaAssets = SS.Assets:FindFirstChild(categoria)
		local modeloOriginal = carpetaAssets and carpetaAssets:FindFirstChild(itemId)
		local handler = EQUIP_HANDLERS[categoria]

		if modeloOriginal and handler then
			local clon = modeloOriginal:Clone()
			handler(player, character, clon)

			_itemEquipado[player] = _itemEquipado[player] or {}
			_itemEquipado[player][categoria] = clon
		end
	end
end

-- Configura los listeners del ciclo de vida y eventos de red
function InventoryHandler.Init()
	-- Evento de red para equipar o desequipar un ítem
	InventoryNet.EquiparItem:Server():On(function(player: Player, itemId: string?, categoria: string)
		if not categoria or categoria == "" then return end
		InventoryHandler.ProcesarEquipamiento(player, itemId, categoria)
	end)

	local function configurarPersonaje(player: Player)
		player.CharacterAdded:Connect(function(character)
			task.spawn(function()
				_itemEquipado[player] = {}
				InventoryHandler.RestaurarEquipamiento(player, character)
			end)
		end)

		if player.Character then
			task.spawn(function()
				_itemEquipado[player] = {}
				InventoryHandler.RestaurarEquipamiento(player, player.Character)
			end)
		end
	end

	-- Equipar los items del jugador al conectarse
	Players.PlayerAdded:Connect(configurarPersonaje)
	for _, player in ipairs(Players:GetPlayers()) do
		configurarPersonaje(player)
	end

	-- Limpieza al salir el jugador
	Players.PlayerRemoving:Connect(function(player)
		_itemEquipado[player] = nil
	end)
end

return InventoryHandler