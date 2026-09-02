
--SERVICIOS
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SG = game:GetService("StarterGui")

--DEPENDENCIAS
local InventoryNet = require(RS.Network.InventoryNet)
local RarezasConfig = require(RS.Config.RarezasConfig)
local ItemsIndex = require(RS.Config.Catalogo.ItemsIndex)
--Modulo render 3D

local InventoryUI = {}

local _cacheInventario: { [string]: { string } } = {
    Armas = {},
    Auras = {},
}

--ESTADO LOCAL
local _pestaniaActual = "Armas"
local _itemSeleccionado: string? = nil

--REFERENCIAS GUI
local InventoryTemplate = SG.Templates.InventoryTemplate
local jugador = Players.LocalPlayer

local GUI: PlayerGui
local FrameContenedor: GuiObject
local NombreItem: TextLabel
local RarezaItem: TextLabel

function InventoryUI.Init()
    GUI = jugador:WaitForChild("PlayerGui")

    local inventoryVisuals = GUI:WaitForChild("InventoryVisuals")
    local framePrincipal = inventoryVisuals:WaitForChild("FramePrincipal")
    FrameContenedor = framePrincipal:WaitForChild("FrameContenedor")

    local visualizarItem = framePrincipal:WaitForChild("VisualizarItem")
    NombreItem = visualizarItem:WaitForChild("NombreItem")
    RarezaItem = visualizarItem:WaitForChild("RarezaItem")

    --CAMBIO DE PESTAÑA EN GUI
        --Generico
    local pestaniasFolder = framePrincipal:FindFirstChild("Pestanias") --Busca la carpeta de pestanias en la GUI
    if pestaniasFolder then
        for _, boton in pestaniasFolder:GetChildren() do --Recorre todos los hijos dentro de la carpeta
            if boton:IsA("TextButton") or boton:IsA("ImageButton") then --Si el hijo es un botón de texto o imagen
                boton.MouseButton1Click:Connect(function() --Conecta el evento de clic del botón
                    InventoryUI:CambiarPestania(boton.Name) --Activa la función CambiarPestania con el nombre del botón clickeado
                end)
            end
        end
    end

    InventoryNet.SyncInventario:Client():On(function(datosDelServidor) --Recibe los datos del inventario del servidor
        _cacheInventario = datosDelServidor
        InventoryUI:RenderizarLista()
    end)
end

function InventoryUI:CambiarPestania(nuevaPestania : string)
    if _pestaniaActual == nuevaPestania then return end --Si la pestania actual es la misma que la nueva, no hace nada y termina la función
    _pestaniaActual = nuevaPestania --Actualiza la pestania actual con la nueva
    _itemSeleccionado = nil
    InventoryUI:RenderizarLista()
end

function InventoryUI:RenderizarLista()
    -- LIMPIEZA DE PLANTILLAS ANTERIORES --
    for _, child in FrameContenedor:GetChildren() do
        if child:IsA("GuiObject") and child.Name ~= "InventoryTemplate" then
            child:Destroy()
        end
    end

    local listaItems = _cacheInventario[_pestaniaActual] --Obtiene la lista de items de la pestania actual
    if not listaItems then return end --Si no hay items en la lista, no hace nada y termina la función

    -- GENERACION DE PLANTILLAS --
    for _, itemId in ipairs(listaItems) do --Recorre la lista de items
        local itemData = ItemsIndex[itemId] --Busca los datos del item en el índice de items
        if not itemData then
            warn(`[InventoryUI] El ítem '{itemId}' no existe en ItemsIndex.`)
            continue
        end

        local templateClone = InventoryTemplate:Clone() --Clona la plantilla de ítem
        --CONFIGURACIÓN DE LA PLANTILLA
        local colorRareza = RarezasConfig[itemData.Rareza].Color

        templateClone.Name = itemId
        templateClone.Visible = true

        templateClone.TextLabel.Text = itemData.NombreVisible
        templateClone.TextLabel.TextColor3 = colorRareza
        templateClone.ImageButton.Image = itemData.Imagen

        templateClone.ImageButton.MouseButton1Click:Connect(function() --Conecta el evento de clic del botón de imagen
            InventoryUI:SeleccionarItem(itemId)
        end)

        templateClone.Parent = FrameContenedor
    end
end

function InventoryUI:SeleccionarItem(itemId : string)
    local itemData = ItemsIndex[itemId] --Obtiene los datos del ítem seleccionado
    if not itemData then return end

    _itemSeleccionado = itemId --Guarda el ítem seleccionado
    
    NombreItem.Text = itemData.NombreVisible
    RarezaItem.Text = itemData.Rareza
    RarezaItem.TextColor3 = RarezasConfig[itemData.Rareza].Color

    --Modulo modelo 3D
end
return InventoryUI