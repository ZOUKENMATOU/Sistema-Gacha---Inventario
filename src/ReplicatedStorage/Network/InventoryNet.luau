local RS = game:GetService("ReplicatedStorage")

local Red = require(RS.Packages.Red)

local function validarCache(datos: unknown)
    assert(type(datos) == "table", "[InventoryNet] El inventario debe ser una tabla")
    return datos :: {}
end

local function validarStrings(texto1 : unknown, texto2 : unknown)
    assert(type(texto1) == "string" and type(texto2) == "string", "[InventoryNet] Los datos deben ser strings")
    return texto1 :: string, texto2 :: string
end

local InventoryNet = {
    SyncInventario = Red.Event("SyncInventario", validarCache),
    PedirEquipar = Red.Event("PedirEquipar", validarStrings),
}
return InventoryNet