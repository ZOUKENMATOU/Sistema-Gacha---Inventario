local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local ProfileStore = require(SSS.ServerPackages.profilestore)
local PlayerTemplate = require(SSS.Data.PlayerTemplate)

local RarezasConfig = require(RS.Config.RarezasConfig) --Importacion de la configuración de rarezas
local InventoryNet = require(RS.Network.InventoryNet)
local EconomyNet = require(RS.Network.EconomyNet)

--Datos separados entre Studio y datos Reales
local function STORE_KEY()
    return RunService:IsStudio() and "Data_TestV1" or "Data_Live"
end

local PlayerStore = ProfileStore.New(STORE_KEY(), PlayerTemplate)

local Profiles = {} --Perfiles activos

type NombreRareza = RarezasConfig.NombresRareza

export type RecompensasData = {
    Oro: number,
    Gemas: number,
}

local COMPENSACION_RAREZAS: {[NombreRareza]: RecompensasData} = {
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
        Gemas = 5
    },
    Mythic = {
        Oro = 200,
        Gemas = 10
    },
    Divine = {
        Oro = 400,
        Gemas = 15
    }
}

-- INICIO DEL SISTEMA --
local DataManager = {}

function DataManager.CargarPerfil(player : Player)
    local profile = PlayerStore:StartSessionAsync("Player_".. player.UserId) -- Crea una sesión de perfil para el jugador
    if profile == nil then
        player:Kick("Error al cargar tus datos. Vuelve a intentarlo")
    end

    --GDPR (General Data Protection Regulation) Si un jugador pide borrar sus datos Roblox sepa donde estan almacenados
    profile:AddUserId(player.UserId)

    profile:Reconcile() -- Si se agregan nuevos datos a la plantilla, se actualizan automáticamente

    -- Desconexion forzada del jugador
    profile.OnSessionEnd:Connect(function()
        Profiles[player] = nil --Si los datos del jugador son nulos, se desconecta del servidor
        player:Kick("Tus datos se cargaron en otro servidor.")
    end)

    -- Verificacion de estado del perfil (activo o inactivo)
    if player:IsDescendantOf(Players) then
        if profile:IsActive() then --Si el jugador sigue en el servidor, se guarda el perfil
            print(`[DataManager] Cargando datos de {player.Name}`)
            Profiles[player] = profile
            
            --Obtener los datos del inventariol y economia del jugador
            local datosInventario = {
                Armas = profile.Data.Armas,
                Auras = profile.Data.Auras
            }
            local datosEconomia = {
                Oro = profile.Data.Economia.Oro,
                Gemas = profile.Data.Economia.Gemas,
            }
            InventoryNet.SyncInventario:Server():Fire(player, datosInventario) --Envía los datos del inventario al cliente
            EconomyNet.SyncEconomia:Server():Fire(player, datosEconomia) --Envía los datos de la economía al cliente

        else --Si el jugador no está en el servidor, se guarda el perfil pero no se envían los datos
            profile:EndSession()
        end
    end
end

function DataManager.GuardarPerfil(player : Player)
    --Cuando el jugador se sale
    local profile = Profiles[player] --Obtiene el perfil del jugador
    if profile ~= nil then --Si el perfil existe
        profile:EndSession()
        Profiles[player] = nil --Elimina el perfil del jugador
        print(`[DataManager] Se han guardado los datos de {player.Name}.`)
    end
end

function DataManager.ObtenerPerfil(player : Player)
    --Sirve para obtener el perfil del jugador actual (para otros scripts)
    print(`[DataManager] Obteniendo datos de {player.Name}`)
    return Profiles[player] --Devuelve el perfil del jugador
end

--Funciones para cargar y guardar perfiles de jugador
function DataManager.Init()
    Players.PlayerAdded:Connect(DataManager.CargarPerfil) --Cuando un jugador se une al juego
    Players.PlayerRemoving:Connect(DataManager.GuardarPerfil) --Cuando un jugador se sale del juego

    -- Carga los perfiles de los jugadores que ya están en el juego
    for _, player in Players:GetPlayers() do --Recorre todos los jugadores en el juego
        task.spawn(function() --Se ejecuta en un hilo separado para evitar bloquear el juego
            DataManager.CargarPerfil(player) --Carga el perfil del jugador
        end)
    end
end

-- COMPRAS --
function DataManager.GastarOro(player : Player, cantidad : number)
    local profile = Profiles[player] --Busca al jugador en la tabla de perfiles
    if not profile then return false end --Si no hay un perfil para el jugador, no se puede gastar

    if profile.Data.Economia.Oro >= cantidad then --Si la cantidad de oro es mayor o igual a la cantidad a gastar, se realiza la compra
        profile.Data.Economia.Oro -= cantidad --Se resta la cantidad de oro del jugador
        print(`[DataManager] Se ha restado ${cantidad} oro a {player.Name} `)
        local datosEconomia = { --Se preparan los datos de la economía para enviar al cliente
            Oro = profile.Data.leaderstats.Oro,
            Gemas = profile.Data.leaderstats.Gemas
        }
        EconomyNet.SyncEconomia:Server():Fire(player, datosEconomia) --Llama al evento de economía para enviar los datos al cliente
        return true --Compra exitosa
     else
        warn(`[DataManager] Compra rechazada. Fondos insuficientes`)
        return false --Sin fondos suficientes
    end
end

function DataManager.GastarGemas(player : Player, cantidad : number)
    local profile = Profiles[player] --Busca al jugador en la tabla de perfiles
    if not profile then return false end --Si no hay un perfil para el jugador, no se puede gastar

    if profile.Data.leaderstats.Gemas >= cantidad then
        profile.Data.leaderstats.Gemas -= cantidad
        print(`[DataManager] Se ha restado ${cantidad} oro a {player.Name} `)
        local datosEconomia = {
            Oro = profile.Data.leaderstats.Oro,
            Gemas = profile.Data.leaderstats.Gemas
        }
        EconomyNet.SyncEconomia:Server():Fire(player, datosEconomia)
        return true
    else
        warn(`[DataManager] Compra rechazada. Fondos insuficientes`)
        return false
    end
end

-- AÑADIR FONDOS --
function DataManager.AgregarOro(player : Player, cantidad : number)
    local profile = Profiles[player]
    if not profile then return end

    profile.Data.leaderstats.Oro += cantidad
    local datosEconomia = {
        Oro = profile.Data.leaderstats.Oro,
        Gemas = profile.Data.leaderstats.Gemas
    }
    EconomyNet.SyncEconomia:Server():Fire(player, datosEconomia)
end

function DataManager.AgregarGemas(player : Player, cantidad : number)
    local profile = Profiles[player]
    if not profile then return end

    profile.Data.leaderstats.Gemas += cantidad
    local datosEconomia = {
        Oro = profile.Data.leaderstats.Oro,
        Gemas = profile.Data.leaderstats.Gemas
    }
    EconomyNet.SyncEconomia:Server():Fire(player, datosEconomia)
end

-- AÑADIR ITEMS --
function DataManager.AgregarArmas(player : Player, armaId : string, rarezaGanadora : NombreRareza)
    local profile = Profiles[player]
    if not profile then return end

    if table.find(profile.Data.Armas, armaId) then
        local oroExtra = COMPENSACION_RAREZAS[rarezaGanadora].Oro or 0 
        local gemasExtra = COMPENSACION_RAREZAS[rarezaGanadora].Gemas or 0

        DataManager.AgregarOro(player, oroExtra)
        DataManager.AgregarGemas(player, gemasExtra)
        warn(`[DataManager] El jugador {player.Name} ha ganado {oroExtra} Oro y {gemasExtra} Gemas extras por obtener un item duplicado `)
        return
    else
        table.insert(profile.Data.Armas, armaId)
        print(`[DataManager] Se agrego el item {armaId} a el inventario de {player.Name}`)

        -- ACTUALIZAR GUI DE INVENTARIO --
        local datosActualizados = {
            Armas = profile.Data.Armas,
            Auras = profile.Data.Auras
        }
        InventoryNet.SyncInventario:Server():Fire(player, datosActualizados)
        return
    end
end

function DataManager.AgregarAuras(player : Player, auraId : string, rarezaGanadora : NombreRareza)
    local profile = Profiles[player]
    if not profile then return end

    if table.find(profile.Data.Auras, auraId) then
        local oroExtra = COMPENSACION_RAREZAS[rarezaGanadora].Oro or 0 
        local gemasExtra = COMPENSACION_RAREZAS[rarezaGanadora].Gemas or 0

        DataManager.AgregarOro(player, oroExtra)
        DataManager.AgregarGemas(player, gemasExtra)
        warn(`[DataManager] El jugador {player.Name} ha ganado {oroExtra} Oro y {gemasExtra} Gemas extras por obtener un item duplicado`)
        return
    else
        table.insert(profile.Data.Auras, auraId)
        print(`[DataManager] Se agrego la aura {auraId} a el inventario de {player.Name}`)

        -- ACTUALIZAR GUI DE INVENTARIO --
        local datosActualizados = {
            Armas = profile.Data.Armas,
            Auras = profile.Data.Auras
        }
        InventoryNet.SyncInventario:Server():Fire(player, datosActualizados)
        return
    end
end
return DataManager