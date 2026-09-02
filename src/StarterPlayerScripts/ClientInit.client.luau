local ControllersFolder = script.Parent.Controllers

local EconomyUI = require(ControllersFolder.EconomyUI)
local GachaClient = require(ControllersFolder.GachaClient)
local InventoryUI = require(ControllersFolder.InventoryUI)

print("[ClientInit] Iniciando sistemas del cliente...")
EconomyUI.Init() --Inicializa el controlador de economía
InventoryUI.Init() --Inicializa el controlador de inventario
GachaClient.Init() --Inicializa el controlador de gacha

print("[ClientInit] ¡Cliente cargado con éxito!")