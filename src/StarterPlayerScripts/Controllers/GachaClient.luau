local GachaClient = {}

--SERVICIOS
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

--DEPENDENCIAS
local CasesIndex = require(RS.Config.Cases.CasesIndex)
local ItemsIndex = require(RS.Config.Catalogo.ItemsIndex)
local RarezaConfig = require(RS.Config.RarezasConfig)

local SPP = require(RS.Utils.SelectorPorPeso)
local RNG = require(RS.Utils.RNG)
local GachaAnimator = require(RS.Utils.GachaAnimator)
local UIAnim = require(RS.Utils.UIAnim)

local GachaNet = require(RS.Network.GachaNet)

--FOLDERS
local Sonidos = SoundService:WaitForChild("Sonidos")

--SONIDOS--
local reward = Sonidos:WaitForChild("Reward")

--CONFIGURACIONES
local cantidadFramesFalsos = 70 --Cantidad maxima de frames (recompensas falsas) que se van a clonar en el contenedor general de frames ANTES de que se agregue el frame ganador
local cantidadRellenoFrame = 5 --Frames de relleno creados DESPUES del frame ganador

--GUI REFERENCIAS
local RollTemplate
local RarezaTemplate
local ShineBackground
local jugador = Players.LocalPlayer

    --GachaVisuals
    local GachaVisuals
    local FramePVisuals
    local Recompensa : Frame
    local CloseVisuals
    local FrameItems
    local FrameContenedor

    --GachaShop
    local GachaShop
    local FramePShop
    local Precio
    local CajaVisual
    local InfoCaja

local GiroUI --Varible donde se guarda la animacion de UIAnim para cancelarla al precionar el boton

-- ESTADO LOCAL
local _cajaActual = nil --Almacena el nombre de la caja actual
local itemsRoll = {} --Tabla que almacena los items ganadores y los items falsos

function GachaClient:SolicitarAbrirCaja(nombreCaja : string) : {} | nil
    --SONIDOS--
    local Processed = Sonidos:WaitForChild("Processed")
    local Fail= Sonidos:WaitForChild("Fail") 

    local sucess, resultado = GachaNet.AbrirCaja:Call(nombreCaja):Await() --Solicita al servidor abrir la caja y espera la respuesta
    if not sucess then --Si la respuesta del servidor es negativa, muestra un mensaje de error en la consola y termina la funcion
        warn(`[GachaClient] Error al abrir la caja: {nombreCaja}. {resultado}`)
        local clonFail = Fail:Clone()
        clonFail.Parent = SoundService
        clonFail:Play()
        Debris:AddItem(clonFail, 1)
        return
    end

    print(`[GachaClient] La caja {nombreCaja} se ha abierto con éxito y el item ganador es {resultado}`)
    local clonProcessed = Processed:Clone()
    clonProcessed.Parent = SoundService
    clonProcessed:Play()
    Debris:AddItem(clonProcessed, 1)
    
    --VISUALES DEL GACHA
    local pesos = CasesIndex[nombreCaja].Probabilidades --Obtiene las probabilidades de la caja para crear items fake
    local pesoTotal = SPP.ObtenerTotal(pesos) --Suma de todos los pesos de los items en la caja

    --LIMPIEZA DE LA TABLA DE RECOMPENSAS VIEJAS--
    local limpiezaTabla = table.clear(itemsRoll)
    if limpiezaTabla then 
        print(`[GachaClient] La tabla de recompensas de la caja {nombreCaja} ha sido limpiada con éxito.`)
    end

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

    for _ = 1, cantidadFramesFalsos do --Crea los frames falsos ANTES de que se agregue el frame ganador
        local itemIdFalso = ObtenerItemsFalsos()
        table.insert(itemsRoll, itemIdFalso) --Se agrega a la tabla de items falsos el item obtenido
    end
    
    --ITEM GANADOR REAL
    table.insert(itemsRoll, resultado) --Item real siguiente en la lista

    for _ = 1, cantidadRellenoFrame do --Crea los frames falsos DESPUES de que se agregue el frame ganador
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
        warn("[GachaClient] Compra cancelada o fondos insuficientes.")
        return 
    end

    --VERIFICACION DE VENTANAS GUI
    CloseVisuals.Visible = false
    Recompensa.Visible = false
    if GachaShop.Enabled == true then 
        GachaShop.Enabled = false
        GachaVisuals.Enabled = true
    end

    --DESTRUIR LOS FRAMES GENERADOS ANTERIORMENTE
    for _, frame in FrameContenedor:GetChildren() do --Itera sobre todos los hijos del contenedor de frames
        if frame:IsA("Frame") and frame.Name == "RollTemplate" then
            frame:Destroy()
        end
    end

    PoblarRuleta(tablaItems) --Puebla la ruleta con los items obtenidos

    GachaAnimator.Animar(FrameContenedor, FrameItems, cantidadFramesFalsos)

    GachaClient.MostrarRecompensa(tablaItems)
    
    --CLONAR MODELO 3D
    CloseVisuals.Visible = true
end

function GachaClient.MostrarRecompensa(tablaItems : {})
    --OBTIENE EL COLOR DEL ITEM--
    local itemGanador = tablaItems[cantidadFramesFalsos + 1] --Obtiene el item ganador
    local rarezaItem = ItemsIndex[itemGanador].Rareza
    local colorRareza = RarezaConfig[rarezaItem].Color
    
    --LIMPIEZA DE SHINES VIEJOS--
    for _, shine in Recompensa:GetChildren() do
        if shine:IsA("ImageLabel") and shine.Name == "ShineBackground" then
            shine:Destroy()
        end
    end
    
    --CONFIGURACION DEL DESTELLO-
    local templateShine = ShineBackground:Clone() :: ImageLabel
    templateShine.Parent = Recompensa
    templateShine.Visible = true
    templateShine.ImageColor3 = colorRareza
    
    
    -- REPRODUCIR EL SONIDO DE VICTORIA --
    local clonVictoria = reward:Clone() --PASARLO A LA ANIMACION UI
    clonVictoria.Parent = SoundService
    clonVictoria:Play()
    Debris:AddItem(clonVictoria, 4)
    
    Recompensa.Visible = true --Activa el frame que muestra las recompensas

    --ANIMAR EL DESTELLO
    GiroUI = UIAnim.IniarGiroDestello(templateShine, 15)
end

function GachaClient:AbrirTienda(nombreCaja : BasePart)
    local NombreCaja = nombreCaja.Name
    local cajaRequerida = CasesIndex[NombreCaja]
    if not cajaRequerida then
        error(`[GachaClient] No existe una caja con el nombre {NombreCaja}`)
    end
    _cajaActual = nombreCaja

    --LIMPIEZA DE TEMPLATES VIEJAS--
    local Probabilidades = InfoCaja:FindFirstChild("Probabilidades") :: Frame
    local NombreCaja = InfoCaja:FindFirstChild("NombreCaja") :: TextLabel
    local TipoCaja = InfoCaja:FindFirstChild("TipoCaja") :: TextLabel

    for _, template in Probabilidades:GetChildren() do
        if template:IsA("TextLabel") and template.Name == "RarezaTemplate" then
            template:Destroy()
        end
    end

    GachaShop.Enabled = true --Activar la interfaz de la tienda

    NombreCaja.Text = cajaRequerida.NombreVisible
    TipoCaja.Text = "Tipo: ".. cajaRequerida.Tipo
    Precio.Text = cajaRequerida.Precio

    --CREACION DE TEMPLATES--
    for _, probabilidad in ipairs(cajaRequerida.Probabilidades) do
        local templateClone = RarezaTemplate:Clone()
        templateClone.Parent = Probabilidades
        templateClone.Visible = true

        local porcentaje = probabilidad.Peso / 1000
        local rareza = probabilidad.Rareza
        templateClone.Text = `{probabilidad.Rareza}: {porcentaje}`
        templateClone.TextColor3 = RarezaConfig[rareza].Color
    end

end

function GachaClient.LimpiarRuleta()
    for i, child in FrameContenedor:GetChildren() do
       if child:IsA("Frame") and child.Name == "RollTemplate" then
            child:Destroy()
       end
    end
end
function GachaClient.Init()
    local playerGui = jugador:WaitForChild("PlayerGui")
    RarezaTemplate = StarterGui:WaitForChild("Templates"):WaitForChild("RarezaTemplate")
    RollTemplate = StarterGui:WaitForChild("Templates"):WaitForChild("RollTemplate")
    ShineBackground = StarterGui:WaitForChild("Templates"):WaitForChild("ShineBackground")

    --GACHA SHOP--
    GachaShop = playerGui:WaitForChild("GachaShop")
    FramePShop = GachaShop:WaitForChild("FramePrincipal")
    local CloseShop = FramePShop:WaitForChild("CloseShop") :: TextButton
    Precio = FramePShop:WaitForChild("Precio")
    InfoCaja = FramePShop:WaitForChild("InfoCaja")
    CajaVisual = FramePShop:WaitForChild("CajaVisual")
    local Buy = CajaVisual:WaitForChild("BuyButton") :: TextButton

    --GACHA VISUALS--
    GachaVisuals = playerGui:WaitForChild("GachaVisuals")
    FramePVisuals = GachaVisuals:WaitForChild("FramePrincipal")
    Recompensa = GachaVisuals:WaitForChild("Recompensa")
    CloseVisuals = GachaVisuals:WaitForChild("CloseVisuals") :: TextButton
    FrameItems = FramePVisuals:WaitForChild("FrameItems")
    FrameContenedor = FrameItems:WaitForChild("FrameContenedor") 

    --==BOTON DE COMPRA==--
    Buy.MouseButton1Click:Connect(function()
        if _cajaActual ~= nil then
          GachaClient.GenerarRoll(tostring(_cajaActual))
        end
    end)

    --==BOTONES CERRAR==--
    CloseShop.MouseButton1Click:Connect(function()
        GachaShop.Enabled = false
    end)

    CloseVisuals.MouseButton1Click:Connect(function()
        GachaClient.LimpiarRuleta()
        GiroUI:Cancel() --Detener la animacion del shine
        GachaVisuals.Enabled = false
    end)

    --==CAJAS FISICAS==--
    local ContenedorCajas = game.Workspace.ContenedorCajas :: Folder
    for _, caja in ContenedorCajas:GetChildren() do
        if caja:IsA("BasePart") then
            local ProxPromt = caja:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
            ProxPromt.Triggered:Connect(function()
                GachaClient:AbrirTienda(caja)
            end)
        end
    end
end
return GachaClient