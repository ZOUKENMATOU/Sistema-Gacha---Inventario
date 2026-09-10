--SERVICIOS
local RS = game:GetService("ReplicatedStorage")

-- DEPENDENCIAS
local RarezasConfig = require(RS.Config.RarezasConfig)

--TIPOS DE DATOS
export type ItemData = {
    Id: string,
    NombreVisible: string,
    Imagen: string,
    Rareza: RarezasConfig.NombresRareza,
}

local ItemsIndex: { [string]: ItemData } = {}

for _, child in script:GetChildren() do -- Recorre los hijos dentro de el
    local success, configData = pcall(require, child) -- Intenta requerir el ModuleScript
    if success and typeof(configData) == "table" then --Si se pudo requerir y el dato es una tabla
        for itemId, itemData in pairs(configData) do -- Recorre todos los items del ModuleScript
            if ItemsIndex[itemId] then -- Si el item ya existe en el índice, muestra una advertencia y omite la adición
                warn(`[ItemsIndex] ¡ID duplicado detectado! '{itemId}' ya existe.`)                
            end
            ItemsIndex[itemId] = itemData -- Agrega el item al índice
        end
    else
        warn(`[ItemsIndex] No se pudo cargar el módulo en: {child:GetFullName()}`)
    end
end
return ItemsIndex