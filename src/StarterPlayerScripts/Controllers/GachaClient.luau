local GachaClient = {}

--SERVICIOS
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

--DEPENDENCIAS
local CasesIndex = require(RS.Config.Cases.CasesIndex)
local ItemsIndex = require(RS.Config.Catalogo.ItemsIndex)
local RarezaConfig = require(RS.Config.RarezasConfig)

local SPP = require(RS.Utils.SelectorPorPeso)
local RNG = require(RS.Utils.RNG)

local GachaNet = require(RS.Network.GachaNet)

--CONFIGURACIONES
local cantidadFramesFalsos = 70 --Cantidad maxima de frames (recompensas falsas) que se van a clonar en el contenedor general de frames ANTES de que se agregue el frame ganador
--local cantidadTotalFrames = 71 --Numero total de frames creados sumando el item ganador en la ultima posicion (variable que recibe [GenerarRoll] )
local cantidadRellenoFrame = 5 --Frames de relleno creados DESPUES del frame ganador

--GUI REFERENCIAS
local jugador = Players.LocalPlayer
local RollTemplate

    --GachaVisuals
    local GachaVisuals
    local FramePVisuals
    local FrameItems
    local FrameContenedor



-- ESTADO LOCAL
local _cajaActual = nil --Almacena el nombre de la caja actual
    local itemsRoll = {} --Tabla que almacena los items ganadores y los items falsos

function GachaClient:SolicitarAbrirCaja(nombreCaja : string) : {} | nil
    local sucess, resultado = GachaNet.AbrirCaja:Call(nombreCaja):Await() --Solicita al servidor abrir la caja y espera la respuesta
    if not sucess then --Si la respuesta del servidor es negativa, muestra un mensaje de error en la consola y termina la funcion
        warn(`[GachaClient] Error al abrir la caja: {nombreCaja}. {resultado}`)
        return
    end

    --VISUALES DEL GACHA
    local pesos = CasesIndex[nombreCaja].Probabilidades --Obtiene las probabilidades de la caja para crear items fake
    local pesoTotal = SPP.ObtenerTotal(pesos) --Suma de todos los pesos de los items en la caja

    local function ObtenerItemsFalsos() --Funcion que obtiene los items falsos
        local rng = RNG.GenerarRNG(pesoTotal) --Genera un numero aleatorio entre 1 y el peso total
        local rarezaGanadora = SPP.SeleccionarRareza(pesos, rng) --Selecciona la rareza del item falso basado en el RNG generado
        if not rarezaGanadora then
            warn("[GachaClient] No se pudo generar una rareza ganadora para los items falsos de la caja: " .. nombreCaja)
            return
        end

        local tablaRareza = CasesIndex[nombreCaja].Contenido[rarezaGanadora] --Obtiene la tabla de items de la rareza ganadora
        if not tablaRareza or #tablaRareza == 0 then
            warn("[GachaClient] No hay items disponibles para la rareza seleccionada: " .. rarezaGanadora)
            return
        end
        local numeroRandom = math.random(#tablaRareza) --Elegir un item aleatorio de la tabla de items de la rareza ganadora
        return tablaRareza[numeroRandom] --Devuelve un item falso ganador
    end

    for i = 1, cantidadFramesFalsos do --Crea los frames falsos ANTES de que se agregue el frame ganador
        local itemIdFalso = ObtenerItemsFalsos()
        table.insert(itemsRoll, itemIdFalso) --Se agrega a la tabla de items falsos el item obtenido
    end
    
    --ITEM GANADOR REAL
    table.insert(itemsRoll, resultado) --Item real siguiente en la lista

    for i = 1, cantidadRellenoFrame do --Crea los frames falsos DESPUES de que se agregue el frame ganador
        local itemIdFalso = ObtenerItemsFalsos()
        table.insert(itemsRoll, itemIdFalso) --Se agrega a la tabla de items falsos el item obtenido
    end
    return itemsRoll --Devuelve la tabla de items
end

local function PoblarRuleta(tablaItems: {string})
    for i, item in ipairs(tablaItems) do --Recorre la tabla de items y crea un frame para cada item
        local itemData = ItemsIndex[item] --Obtiene los datos del item del catalogo de items
        if not itemData then
            error(`[GachaClient] El item '{item}' no existe en ningún catálogo de ItemsIndex.`)
            return
        end

        local frameClonado = RollTemplate:Clone() --Clona el frame a clonar 
        frameClonado.LayoutOrder = i --Asigna el orden del frame clonado

        local textLabel = frameClonado.NombreItem :: TextLabel
        textLabel.Text = itemData.NombreVisible --Asigna el nombre del item al textLabel del frame clonado
        
        local imagen = frameClonado.ItemIcon :: ImageLabel
        imagen.Image = itemData.Imagen

        local colorRareza = RarezaConfig[itemData.Rareza].Color
        frameClonado.BackgroundColor3 = colorRareza
        
        frameClonado.Parent = FrameContenedor
        frameClonado.Visible = true
    end
end
function GachaClient.GenerarRoll(nombreCaja : string) --Genera el roll de la ruleta
    local tablaItems = GachaClient:SolicitarAbrirCaja(nombreCaja) :: {} --Tabla con iDs de items--
    if not tablaItems then
        warn("[GachaClient] No se pudieron obtener los items de la caja: " .. nombreCaja)
        return 
    end
    
    --DESTRUIR LOS FRAMES GENERADOS ANTERIORMENTE
    for _, frame in FrameContenedor:GetChildren() do --Itera sobre todos los hijos del contenedor de frames
        if frame:IsA("Frame") and frame.Name == "RollTemplate" then
            frame:Destroy()
        end
    end

    PoblarRuleta(tablaItems) --Puebla la ruleta con los items obtenidos
    --Animacion de la ruleta
end

function GachaClient.Init()
    local playerGui = jugador:WaitForChild("PlayerGui")
    RollTemplate = StarterGui:WaitForChild("Templates"):WaitForChild("RollTemplate")

    --GACHA_VISUALS--
    GachaVisuals = playerGui:WaitForChild("GachaVisuals")
    FramePVisuals = GachaVisuals:WaitForChild("FramePrincipal")
    FrameItems = FramePVisuals:WaitForChild("FrameItems")
    FrameContenedor = FrameItems:WaitForChild("FrameContenedor") 

    --PRUEBA
    local caja = game.Workspace.caja_basica :: BasePart --Caja de prueba
    local proximityPromt = caja:FindFirstChildOfClass("ProximityPrompt")

    proximityPromt.Triggered:Connect(function()
        GachaVisuals.Enabled = true
        _cajaActual = caja.Name
        GachaClient.GenerarRoll(tostring(_cajaActual))
    end)
end
return GachaClient