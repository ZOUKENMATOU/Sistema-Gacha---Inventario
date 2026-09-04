
--SERVICIOS
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SG = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

--DEPENDENCIAS
local InventoryNet = require(RS.Network.InventoryNet)
local RarezasConfig = require(RS.Config.RarezasConfig)
local ItemsIndex = require(RS.Config.Catalogo.ItemsIndex)
--Modulo render 3D

--
local Sonidos = SoundService:WaitForChild("Sonidos")

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
    local OpenInventory = inventoryVisuals:WaitForChild("OpenInventory") :: ImageButton
    local framePrincipal = inventoryVisuals:WaitForChild("FramePrincipal")
    local CloseInventory = framePrincipal:WaitForChild("CloseInventory") :: TextButton
    FrameContenedor = framePrincipal:WaitForChild("FrameContenedor")

    local visualizarItem = framePrincipal:WaitForChild("VisualizarItem")
    local equiparButton = visualizarItem:WaitForChild("EquiparButton") :: TextButton
    NombreItem = visualizarItem:WaitForChild("NombreItem")
    RarezaItem = visualizarItem:WaitForChild("RarezaItem")

    --ABRIR EL INVENTARIO
    OpenInventory.MouseButton1Click:Connect(function()
        local Pop = Sonidos:WaitForChild("Pop")
        local clonPop = Pop:Clone()
        clonPop.Parent = SoundService

        local Escape = Sonidos:WaitForChild("Escape")
        local clonEscape = Escape:Clone()
        clonEscape.Parent = SoundService

        if framePrincipal.Visible == false then
            clonPop:Play()
            framePrincipal.Visible = true
            Debris:AddItem(clonPop, 1)
        else
            clonEscape:Play()
            framePrincipal.Visible = false
            Debris:AddItem(clonEscape, 1)
        end
        
    end)

    --CERRAR EL INVENTARIO (ALTERNATIVA)
    CloseInventory.MouseButton1Click:Connect(function()
        local Escape = Sonidos:WaitForChild("Escape")
        local clonEscape = Escape:Clone()
        clonEscape.Parent = SoundService

        framePrincipal.Visible = false
        clonEscape:Play()
        Debris:AddItem(clonEscape, 1)
    end)

    --EQUIPAR ITEM FISICAMENTE
    equiparButton.MouseButton1Click:Connect(function()
        local Equip = Sonidos:WaitForChild("Equip")
        local clonEquip = Equip:Clone()
        clonEquip.Parent = SoundService

        InventoryUI:PedirEquipar()
        clonEquip:Play()
        Debris:AddItem(clonEquip, 1)
    end)

    --CAMBIO DE PESTAÑA EN GUI
    local pestaniasFolder = framePrincipal:FindFirstChild("Pestanias") --Busca la carpeta de pestanias en la GUI
    if pestaniasFolder then
        for _, boton in pestaniasFolder:GetChildren() do --Recorre todos los hijos dentro de la carpeta
            if boton:IsA("TextButton") or boton:IsA("ImageButton") then --Si el hijo es un botón de texto o imagen
                boton.MouseButton1Click:Connect(function() --Conecta el evento de clic del botón
                    local Flip = Sonidos:WaitForChild("Flip")
                    local clonFlip = Flip:Clone()
                    clonFlip.Parent = SoundService
                    clonFlip:Play()
                    Debris:AddItem(clonFlip, 1)
                    
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

function InventoryUI:PedirEquipar()
    InventoryNet.EquiparItem:Client():Fire(_itemSeleccionado, _pestaniaActual)
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

    slotVacio.TextLabel.Text = "Ninguno"
    slotVacio.TextLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    slotVacio.ImageButton.Image = "" --Icono vacio

    slotVacio.ImageButton.MouseButton1Click:Connect(function()
        InventoryUI:SeleccionarSlotVacio()
    end)
    slotVacio.Parent = FrameContenedor

    --Renderizado de los items
    for i, itemId in ipairs(listaOrdenada) do --Recorre la lista de items
        local itemData = ItemsIndex[itemId] --Busca los datos del item en el índice de items
        if not itemData then continue end

        local templateClone = InventoryTemplate:Clone() --Clona la plantilla de ítem
        --CONFIGURACIÓN DE LA PLANTILLA
        local colorRareza = RarezasConfig[itemData.Rareza].Color

        templateClone.Name = itemId
        templateClone.LayoutOrder = i
        templateClone.Visible = true

        templateClone.TextLabel.Text = itemData.NombreVisible
        templateClone.TextLabel.TextColor3 = colorRareza
        templateClone.ImageButton.Image = itemData.Imagen

        templateClone.ImageButton.MouseButton1Click:Connect(function() --Conecta el evento de clic del botón de imagen
            local Click = Sonidos:WaitForChild("Click")
            local clonClick = Click:Clone()
            clonClick.Parent = SoundService
            clonClick:Play()
            Debris:AddItem(clonClick, 1)
            
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

function InventoryUI:SeleccionarSlotVacio()
    _itemSeleccionado = nil

    --Limpieza
    NombreItem.Text = "Ninguno"
    RarezaItem.Text = "Desequipar"
    RarezaItem.TextColor3 = Color3.fromRGB(200, 200, 200)
end
return InventoryUI