local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local ProfileStore = require(SSS.ServerPackages.profilestore)
local PlayerTemplate = require(script.Parent.PlayerTemplate)

local InventoryNet = require(RS.Network.InventoryNet)
local EconomyNet = require(RS.Network.EconomyNet)

local function STORE_KEY() -- Define la key para el almacenamiento de datos
    -- En el Studio se usa "Data_Test" y en producción "Data_Live"
    return RunService:IsStudio() and "Data_Test" or "Data_Live"
end

local PlayerStore = ProfileStore.New(STORE_KEY(), PlayerTemplate)

local Profiles = {} -- Tabla con los perfiles activos de los jugadores

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
return DataManager