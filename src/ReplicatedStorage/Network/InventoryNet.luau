local RS = game:GetService("ReplicatedStorage")

local Red = require(RS.Packages.Red)
local Guard = require(RS.Packages.Guard)

local function validarInventario(datosDesconocidos: unknown)
    assert(type(datosDesconocidos) == "table", "[InventoryNet] El inventario debe ser una tabla")
    local datos: any = datosDesconocidos
    return {
        Armas = Guard.Check(datos.Armas), -- Asegúra de que Armas es una tabla
        Auras = Guard.Check(datos.Auras) --Asegúra de que Auras es una tabla
    }
end

local function validarStrings(itemId : unknown, categoria : unknown)
    return Guard.String(itemId), Guard.String(categoria)
end

local InventoryNet = {
    SyncInventario = Red.Event("SyncInventario", validarInventario), -- Evento para sincronizar el inventario
    EquiparItem= Red.Event("EquiparItem", validarStrings) -- Evento para equipar un item
}
return InventoryNet