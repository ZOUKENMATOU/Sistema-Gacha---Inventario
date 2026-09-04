--SERVICIOS
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

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

    local function configurarPersonaje(player : Player)
        player.CharacterAdded:Connect(function(char)
            task.spawn(function()
                _itemEquipado[player] = {}
                InventoryHandler.RestaurarEquipamiento(player, char)
            end)
        end)

        if player.Character then
            task.spawn(function()
                _itemEquipado[player] = {}
                InventoryHandler.RestaurarEquipamiento(player, player.Character)
            end)
        end
    end

    --Equipar los items del jugador al conectarse
    Players.PlayerAdded:Connect(configurarPersonaje)
    for _, player in ipairs(Players:GetPlayers()) do
        configurarPersonaje(player)
    end

    --Limpieza
    Players.PlayerRemoving:Connect(function(player)
        _itemEquipado[player] = nil
    end)
end

function InventoryHandler.ProcesarEquipamiento(player: Player, itemId: string, categoria: string)
    --Obtener personaje
    local char = player.Character
    if not char then return end

    --Validacion del item
    local profile = DataManager.ObtenerPerfil(player)
    if not profile then return end


    -- DESEQUIPAR ITEM --
    if not itemId or itemId == "" then
        _itemEquipado[player] = _itemEquipado[player] or {}
        local itemPrevio = _itemEquipado[player][categoria]
        if itemPrevio and itemPrevio.Parent then
            itemPrevio:Destroy()
        end

        _itemEquipado[player][categoria] = nil

        if profile.Data.Equipados then
            profile.Data.Equipados[categoria] = nil
        end
        return 
    end
    
    -- EQUIPAR ITEM --
    if not table.find(profile.Data[categoria], itemId) then
        warn(`[InventoryService] Intento ilegal: {player.Name} no posee '{itemId}'`)
        return
    end

    local carpetaAssets = SS.Assets:FindFirstChild(categoria)
    local modeloOriginal = carpetaAssets and carpetaAssets:FindFirstChild(itemId)
    if not modeloOriginal then return end
    
    local handler = EQUIP_HANDLERS[categoria]
    if not handler then
        warn(`[InventoryHandler] No se ha definido un handler para la categoria  '{categoria}'`)
        return
    end

    --Limpieza
    _itemEquipado[player] = _itemEquipado[player] or {}
    local itemPrevio = _itemEquipado[player][categoria]
    if itemPrevio and itemPrevio.Parent then
        itemPrevio:Destroy()
    end

    --Entrega fisica
    local clon = modeloOriginal:Clone()
    handler(player, char, clon)
    _itemEquipado[player][categoria] = clon --Guardar el clon activo en memoria
    
    if profile and profile.Data.Equipados then
        profile.Data.Equipados[categoria] = itemId
    end
end


local function obtenerPerfilConEspera(player: Player, timeout : number?): any
    local limite = timeout or 5 -- Tiempo de espera predeterminado de 5 segundos
    local inicio = os.clock()

    while not DataManager.ObtenerPerfil(player) do
        if not player:IsDescendantOf(Players) then return nil end

        if os.clock() - inicio > limite then
            warn(`[InventoryService] Tiempo de espera agotado cargando datos para {player.Name}`)
            return nil
        end
        task.wait(0.1)
    end
    return DataManager.ObtenerPerfil(player)
end

function InventoryHandler.RestaurarEquipamiento(player: Player, character: Model)
    local profile = obtenerPerfilConEspera(player)
    if not profile or not profile.Data.Equipados then
        warn(`[InventoryHandler] No se ha encontrado el perfil o los datos de equipamiento para el jugador '{player.Name}'`)
        return 
    end

    for categoria, itemId in pairs(profile.Data.Equipados) do
        if not itemId then continue end

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
return InventoryHandler