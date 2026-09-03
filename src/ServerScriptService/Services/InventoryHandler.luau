--SERVICIOS
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")

--DEPENDENCIAS
local InventoryNet = require(RS.Network.InventoryNet)
local DataManager = require(SSS.Data.DataManager)


type EquipHanlder = (player: Player, character: Model, clon: Instance) -> ()

local EQUIP_HANDLERS: {[string]: EquipHanlder} = {
    [`Armas`] = function(player: Player, _character: Model, clon: Instance)
        clon.Parent = player.Backpack
    end,

    [`Auras`] = function(_player: Player, character: Model, clon: Instance)
        local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if clon:IsA("Model") and clon.PrimaryPart and rootPart then
            clon:PivotTo(rootPart.CFrame)

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = rootPart
            weld.Part1 = clon.PrimaryPart
            weld.Parent = clon
        end
        clon.Parent = character
    end
}
local InventoryHandler = {}

--ESTADO LOCAL 
local _itemEquipado: {[Player]: {[string]: Instance}} = {} --Memoria que almacena los items equipados por cada jugador



function InventoryHandler.Init()
    InventoryNet.EquiparItem:Server():On(function(player : Player, itemId : string, categoria : string) --Funcion que se ejecuta cuando un jugador intenta equipar un item
        InventoryHandler.ProcesarEquipamiento(player, itemId, categoria)
    end)
end

function InventoryHandler.ProcesarEquipamiento(player: Player, itemId: string, categoria: string)
    --Obtener personaje
    local char = player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not rootPart then return end

    --Validacion del item
    local profile = DataManager.ObtenerPerfil(player)
    if not profile or not table.find(profile.Data[categoria], itemId) then
        warn(`[InventoryHandler] Intento ilegal: {player.Name} no posee '{itemId}'`)
        return
    end

    --Localizacion de item
    local carpetaAssets = SS.Assets:FindFirstChild(categoria)
    local modeloOriginal = carpetaAssets and carpetaAssets:FindFirstChild(itemId)
    if not modeloOriginal then
        warn(`[InventoryHandler] Asset '{itemId}' no encontrado en ServerStorage`)
        return
    end

    --Limpieza
    _itemEquipado[player] = _itemEquipado[player] or {}
    local itemPrevio = _itemEquipado[player][categoria]
    if itemPrevio and itemPrevio.Parent then
        itemPrevio:Destroy()
    end

    --Entrega fisica
    local handler = EQUIP_HANDLERS[categoria]
    if not handler then
        warn(`[InventoryHandler] No se ha definido un handler para la categoria  '{categoria}'`)
        return
    end

    local clon = modeloOriginal:Clone()
    handler(player, char, clon)

    --Guardar el clon activo en memoria
    _itemEquipado[player][categoria] = clon
end
return InventoryHandler