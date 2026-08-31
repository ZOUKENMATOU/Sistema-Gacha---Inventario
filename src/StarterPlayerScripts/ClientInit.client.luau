local ControllersFolder = script.Parent.Controllers

local EconomyController = require(ControllersFolder.EconomyController)

print("[ClientInit] Iniciando sistemas del cliente...")
EconomyController.Init() --Inicializa el controlador de economía

print("[ClientInit] ¡Cliente cargado con éxito!")