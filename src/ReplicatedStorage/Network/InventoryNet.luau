-- SERVICIOS
local RS = game:GetService("ReplicatedStorage")

-- DEPENDENCIAS
local Red = require(RS.Packages.Red)
local Guard = require(RS.Packages.Guard)

-- FUNCION DE VALIDACION
local function validarInventario(datosDesconocidos: unknown)
    assert(type(datosDesconocidos) == "table", "[InventoryNet] El inventario debe ser una tabla")
    local datos: any = datosDesconocidos
    return {
        Armas = Guard.Check(datos.Armas), -- Asegúra de que Armas es una tabla
        Auras = Guard.Check(datos.Auras) --Asegúra de que Auras es una tabla
    }
end

local ItemIdValidator = Guard.Optional(Guard.String)

local function validarStrings(itemId : unknown, categoria : unknown): (string?, string)
    return ItemIdValidator(itemId), Guard.String(categoria)
end

-- DEFINICION DEL EVENTO
local InventoryNet = {
    SyncInventario = Red.Event("SyncInventario", validarInventario), -- Evento para sincronizar el inventario
    EquiparItem= Red.Event("EquiparItem", validarStrings) -- Evento para equipar un item
}
return InventoryNet