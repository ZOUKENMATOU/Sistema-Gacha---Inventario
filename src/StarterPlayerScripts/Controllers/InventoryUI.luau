-- SERVICIOS
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SG = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TS = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- DEPENDENCIAS
local InventoryNet = require(RS.Network.InventoryNet)
local RarezasConfig = require(RS.Config.RarezasConfig)
local ItemsIndex = require(RS.Config.Catalogo.ItemsIndex)
local ItemStudioPreview = require(RS.Utils.ItemPreviewStudio)

-- ASSETS
local Sonidos = SoundService:WaitForChild("Sonidos")
local Assets = RS.Assets :: Folder

-- SET 3D
local PreviewSet
local Podio
local CameraAnchor

-- CONSTANTES ANIMACION
local POSICIONES_SELECTOR : {[string]: UDim2} = {
    ["Armas"] = UDim2.fromScale(0.067, 0.956),
    ["Auras"] = UDim2.fromScale(1.374, 0.956),
}

local TWEEN_SELECTOR_INFO = TweenInfo.new(
    .25,
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out
)

--REFERENCIAS GUI
local jugador = Players.LocalPlayer
local InventoryTemplate: Frame

local FrameCaja: GuiObject
local FrameContenedor : ScrollingFrame
local ClosePreview : ImageButton
local OpenInventory : ImageButton
local NombreItem: TextLabel
local RarezaItem: TextLabel
local SelectorIndicador : GuiObject

-- ESTADO LOCAL
local _pestaniaActual = "Armas"
local _itemSeleccionado: string? = nil
local _tweenSelectorActivo: Tween? = nil
local _cacheInventario: { [string]: { string } } = {
    Armas = {},
    Auras = {},
}

-- FUNCIONES AUXILIARES PRIVADAS
local function reproducirSonido(nombre : string)
    local original = Sonidos:FindFirstChild(nombre) :: Sound?
    if original then
        local clon = original:Clone()
        clon.Parent = SoundService
        clon:Play()
        Debris:AddItem(clon, 1)
    end
end

local function animarSelector(nuevaPestania : string)
    local posicionDestino = POSICIONES_SELECTOR[nuevaPestania]
    if not posicionDestino or not SelectorIndicador then return end

    -- Si hay un tween activo por un clic previo, lo cancelamos
    if _tweenSelectorActivo then
        _tweenSelectorActivo:Cancel()
        _tweenSelectorActivo = nil
    end

    local nuevoTween = TS:Create(SelectorIndicador, TWEEN_SELECTOR_INFO, {
        Position = posicionDestino
    })
    _tweenSelectorActivo = nuevoTween
    nuevoTween:Play()
end

-- MODULO PUBLICO
local InventoryUI = {}

function InventoryUI.Init()
    PreviewSet = Workspace:WaitForChild("PreviewStage")
    Podio = PreviewSet:WaitForChild("Podio")
    CameraAnchor = PreviewSet:WaitForChild("Camera")

    --REFERENCIAS GUI
    local GUI = jugador:WaitForChild("PlayerGui")
    local InventoryVisuals = GUI:WaitForChild("InventoryVisuals") --Conenedor GUI

    OpenInventory = InventoryVisuals:WaitForChild("OpenInventory") :: ImageButton
    ClosePreview = InventoryVisuals:WaitForChild("ClosePreview") :: ImageButton
    FrameCaja = InventoryVisuals:WaitForChild("FrameCaja") :: GuiObject

    --Estructura FrameCaja
    local FramePrincipal = FrameCaja:WaitForChild("FramePrincipal")
    local CloseButton = FrameCaja:WaitForChild("CloseButton") :: ImageButton

    local contenedorItems = FramePrincipal:WaitForChild("ContenedorItems")
    FrameContenedor = contenedorItems:WaitForChild("FrameContenedor") :: ScrollingFrame

    local frameInfo = FramePrincipal:WaitForChild("FrameInfo")
    local EquiparButton =frameInfo:WaitForChild("EquiparButton") :: ImageButton
    local Principal = frameInfo:WaitForChild("Principal") :: ImageLabel

    local ImageItem = Principal:WaitForChild("ImageItem") :: ImageButton
    NombreItem = Principal:WaitForChild("Nombre") :: TextLabel
    RarezaItem = Principal:WaitForChild("Rareza") :: TextLabel

    local SelectorTipo = FramePrincipal:WaitForChild("SelectorTipo")
    local Pestanias = SelectorTipo:WaitForChild("Pestanias") :: Folder
    SelectorIndicador = SelectorTipo:WaitForChild("ImagenSelector") :: ImageLabel

    local templateLocal = FrameContenedor:FindFirstChild("InventoryTemplate") or (SG:FindFirstChild("Templates") and SG.Templates:FindFirstChild("InventoryTemplate"))
    
    if templateLocal then
        InventoryTemplate = templateLocal:Clone() :: Frame
        InventoryTemplate.Visible = false
    else
        warn("[InventoryUI] Error: No se encontró 'InventoryTemplate' en FrameContenedor ni en ReplicatedStorage.Templates")
    end
    --ABRIR EL INVENTARIO
    OpenInventory.MouseButton1Click:Connect(function()
        if not FrameCaja.Visible then
            reproducirSonido("Pop")
            FrameCaja.Visible = true
        else
            reproducirSonido("Escape")
            FrameCaja.Visible = false
        end
    end)

    --CERRAR EL INVENTARIO (ALTERNATIVA)
    CloseButton.MouseButton1Click:Connect(function()
        reproducirSonido("Escape")
        FrameCaja.Visible = false
    end)

    --PRE VISUALIZACION
    ImageItem.MouseButton1Click:Connect(function()
        if not _itemSeleccionado then return end

        FrameCaja.Visible = false
        OpenInventory.Visible = false
        ClosePreview.Visible = true

        ItemStudioPreview.AbrirEstudio(Podio, CameraAnchor, .5)
        
        local folderCategoria = Assets:FindFirstChild(_pestaniaActual)
        local asset = folderCategoria and folderCategoria:FindFirstChild(_itemSeleccionado)
        if asset then
            ItemStudioPreview.MostrarItem(_pestaniaActual, asset)
        end
    end)
    
    ClosePreview.MouseButton1Click:Connect(function()
        ClosePreview.Visible = false
        FrameCaja.Visible = true
        OpenInventory.Visible = true
        ItemStudioPreview.CerrarEstudio()
    end)

    --EQUIPAR ITEM FISICAMENTE
    EquiparButton.MouseButton1Click:Connect(function()
        reproducirSonido("Equip")
        InventoryUI:PedirEquipar()
    end)

    --CAMBIO DE PESTAÑA EN GUI
    for _, boton in Pestanias:GetChildren() do
        if boton:IsA("TextButton") or boton:IsA("ImageButton") then
            boton.MouseButton1Click:Connect(function()
                reproducirSonido("Flip")
                InventoryUI:CambiarPestania(boton.Name)
            end)
        end
    end

    InventoryNet.SyncInventario:Client():On(function(datosDelServidor) --Recibe los datos del inventario del servidor
        _cacheInventario = datosDelServidor
        InventoryUI:RenderizarLista()
    end)
end

function InventoryUI:PedirEquipar()
    InventoryNet.EquiparItem:Client():Fire(_itemSeleccionado, _pestaniaActual)
end

function InventoryUI:CambiarPestania(nuevaPestania : string)
    if _pestaniaActual == nuevaPestania then return end --Si la pestania actual es la misma que la nueva, no hace nada y termina la función
    _pestaniaActual = nuevaPestania --Actualiza la pestania actual con la nueva
    _itemSeleccionado = nil

    animarSelector(nuevaPestania) --Animar el selector de pestanias

    InventoryUI:RenderizarLista()
end

function InventoryUI:RenderizarLista()
    if not FrameContenedor or not InventoryTemplate then return end

    -- LIMPIEZA DE PLANTILLAS ANTERIORES --
    for _, child in FrameContenedor:GetChildren() do
        if child:IsA("GuiObject") and child.Name ~= "InventoryTemplate" and child.Name ~= "UIGridLayout" and child.Name ~= "UIPadding"then
            child:Destroy()
        end
    end

    local listaOriginal = _cacheInventario[_pestaniaActual] --Obtiene la lista de items de la pestania actual
    if not listaOriginal then return end --Si no hay items en la lista, no hace nada y termina la función

    --ORDENAR LA LISTA DE ITEMS EN BASE A SU RARESA --
    local listaOrdenada = table.clone(listaOriginal)

    table.sort(listaOrdenada, function(itemAId : string, itemBId : string)
        local dataA = ItemsIndex[itemAId]
        local dataB = ItemsIndex[itemBId]

        if not dataA or not dataB then return false end

        local ordenA = RarezasConfig[dataA.Rareza].Orden
        local ordenB = RarezasConfig[dataB.Rareza].Orden

        --Si el numero es menor MAYOR es la rareza
        if ordenA ~= ordenB then
            return ordenA < ordenB
        end

        --Si tiene la misma rareza se ordena por orden alfabetico
        return (dataA.NombreVisible or itemAId) < (dataB.NombreVisible or itemBId)
    end)

    -- GENERACION DE PLANTILLAS --

    --Frame vacio para desequipar
    local slotVacio = InventoryTemplate:Clone()
    slotVacio.Name = "SlotVacio"
    slotVacio.LayoutOrder =  0 --Se coloca al inicio del todo
    slotVacio.Visible = true

    local vacioNombre = slotVacio:FindFirstChild("NombreItem") :: TextLabel?
    if vacioNombre then
        vacioNombre.Text = "Ninguno"
        vacioNombre.TextColor3 = Color3.fromRGB(200, 200, 200)
    end

    local vacioBtn = slotVacio:FindFirstChild("ImageItem") :: ImageButton?
    if vacioBtn then
        vacioBtn.Image = ""
        vacioBtn.MouseButton1Click:Connect(function()
            InventoryUI:SeleccionarSlotVacio()
        end)
    end
    slotVacio.Parent = FrameContenedor

    --Renderizado de los items
    for i, itemId in ipairs(listaOrdenada) do --Recorre la lista de items
        local itemData = ItemsIndex[itemId] --Busca los datos del item en el índice de items
        if not itemData then continue end

        local infoRareza = RarezasConfig[itemData.Rareza]        
        local templateClone = InventoryTemplate:Clone() --Clona la plantilla de ítem
        
        --CONFIGURACIÓN DE LA PLANTILLA
        templateClone.Name = itemId
        templateClone.LayoutOrder = i
        templateClone.Visible = true

        --ASIGNACION DE COLOR BASADO EN LA RAREZA
        local colorBox = templateClone:FindFirstChild("Color") :: Frame?
        if colorBox then 
            colorBox.BackgroundColor3 = infoRareza.ColorFondo
        end

        local bordeExt = templateClone:FindFirstChild("BordeExt") :: ImageLabel?
        if bordeExt then
            bordeExt.ImageColor3 = infoRareza.Color
        end

        local lineasInt = templateClone:FindFirstChild("LineasInt") :: ImageLabel?
        if lineasInt then
            lineasInt.ImageColor3 = infoRareza.Color
        end

        local nombreLabel = templateClone:FindFirstChild("NombreItem") :: TextLabel?
        if nombreLabel then
            nombreLabel.Text = itemData.NombreVisible or itemId
            nombreLabel.TextColor3 = infoRareza.Color
        end

        --ASIGANCION DE IMAGEN DEL ITEM
        local itemBtn = templateClone:FindFirstChild("ImageItem") :: ImageButton?
        if itemBtn then
            print("Se ha encontrado el boton para clickear")
            itemBtn.Image = itemData.Imagen
            itemBtn.MouseButton1Click:Connect(function()
                reproducirSonido("Click")
                InventoryUI:SeleccionarItem(itemId)
            end)
        end
        templateClone.Parent = FrameContenedor
    end
end

function InventoryUI:SeleccionarItem(itemId : string)
    local itemData = ItemsIndex[itemId] --Obtiene los datos del ítem seleccionado
    if not itemData then return end

    _itemSeleccionado = itemId --Guarda el ítem seleccionado
    
    NombreItem.Text = itemData.NombreVisible or itemId
    RarezaItem.Text = itemData.Rareza
    RarezaItem.TextColor3 = RarezasConfig[itemData.Rareza].Color

    local principalFrame = NombreItem.Parent :: ImageLabel?
    local imagenPreview = principalFrame and principalFrame:FindFirstChild("ImageItem") :: ImageButton?
    if imagenPreview then
        imagenPreview.Image = itemData.Imagen
    end
end

function InventoryUI:SeleccionarSlotVacio()
    _itemSeleccionado = nil

    --Limpieza
    NombreItem.Text = "Ninguno"
    RarezaItem.Text = "Desequipar"
    RarezaItem.TextColor3 = Color3.fromRGB(200, 200, 200)

    local principalFrame = NombreItem.Parent :: ImageLabel?
    local imagenPreview = principalFrame and principalFrame:FindFirstChild("ImageItem") :: ImageButton?
    if imagenPreview then
        imagenPreview.Image = ""
    end
end
return InventoryUI