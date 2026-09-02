local ControllersFolder = script.Parent.Controllers

local EconomyController = require(ControllersFolder.EconomyUI)
local GachaClient = require(ControllersFolder.GachaClient)

print("[ClientInit] Iniciando sistemas del cliente...")
EconomyController.Init() --Inicializa el controlador de economía
GachaClient.Init() --Inicializa el controlador de gacha

print("[ClientInit] ¡Cliente cargado con éxito!")