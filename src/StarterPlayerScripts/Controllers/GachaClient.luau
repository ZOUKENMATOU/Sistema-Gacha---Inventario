-- SERVICIOS
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local TS = game:GetService("TweenService")

-- DEPENDENCIAS
local CasesIndex = require(RS.Config.Cases.CasesIndex)
local ItemsIndex = require(RS.Config.Catalogo.ItemsIndex)
local RarezaConfig = require(RS.Config.RarezasConfig)
local SPP = require(RS.Utils.SelectorPorPeso)
local RNG = require(RS.Utils.RNG)
local GachaAnimator = require(RS.Utils.GachaAnimator)
local UIAnim = require(RS.Utils.UIAnim)
local GachaNet = require(RS.Network.GachaNet)

-- ASSETS DE AUDIO
local Sonidos = SoundService:WaitForChild("Sonidos")
local sonidoReward = Sonidos:WaitForChild("Reward") :: Sound
local sonidoProcessed = Sonidos:WaitForChild("Processed") :: Sound
local sonidoFail = Sonidos:WaitForChild("Fail") :: Sound
local sonidoPop = Sonidos:WaitForChild("Pop") :: Sound
local sonidoEscape = Sonidos:WaitForChild("Escape") :: Sound

-- CONFIGURACIÓN DE GACHA
local CANTIDAD_FRAMES_FALSOS = 70 -- Frames previos antes del ganador
local CANTIDAD_RELLENO_FRAME = 12 -- Frames posteriores al ganador

local TWEEN_BARRA_INFO = TweenInfo.new(
	0.6,
	Enum.EasingStyle.Cubic,
	Enum.EasingDirection.Out
)

local ICONOS_MONEDA: { [string]: string } = {
	["Oro"] = "rbxassetid://94421868384338",
	["Gemas"] = "rbxassetid://108026498141614",
}

-- REFERENCIAS GUI (Asignadas en Init)
local jugador = Players.LocalPlayer
local RollTemplate: Frame
local RarezaTemplate: TextLabel
local ShineBackground: ImageLabel

-- GachaVisuals
local GachaVisuals: ScreenGui
local Recompensa: Frame
local CloseVisuals: TextButton
local FrameItems: Frame
local FrameContenedor: Frame

-- GachaShop
local GachaShop: ScreenGui
local FrameCaja: Frame
local Precio: TextLabel
local IconoVisual: ImageLabel
local InfoCaja: Frame
local Probabilidades: Frame

-- ESTADO LOCAL
local _cajaActualId: string? = nil -- Almacena el ID de la caja seleccionada
local _itemsRoll: { string } = {} -- Recompensas falsas y ganador en orden
local _giroTween: Tween? = nil -- Animación de destello activa para cancelarla al cerrar

-- FUNCIONES AUXILIARES PRIVADAS

-- Clona y reproduce un efecto sonoro temporal
local function reproducirEfectoSonido(sonidoOriginal: Sound, duracionDebris: number?)
	local clon = sonidoOriginal:Clone()
	clon.Parent = SoundService
	clon:Play()
	Debris:AddItem(clon, duracionDebris or 1)
end

-- Genera un ítem falso aleatorio basado en las probabilidades de la caja
local function obtenerItemFalso(nombreCaja: string, pesos: any, pesoTotal: number): string?
	local rng = RNG.GenerarRNG(pesoTotal)
	local rarezaGanadora = SPP.SeleccionarRareza(pesos, rng)
	if not rarezaGanadora then
		warn(`[GachaClient] No se pudo generar una rareza ganadora para los items falsos de la caja: {nombreCaja}`)
		return nil
	end

	local tablaRareza = CasesIndex[nombreCaja].Contenido[rarezaGanadora]
	if not tablaRareza or #tablaRareza == 0 then
		warn(`[GachaClient] No hay items disponibles para la rareza seleccionada: {rarezaGanadora}`)
		return nil
	end

	local numeroRandom = math.random(#tablaRareza)
	return tablaRareza[numeroRandom]
end

-- Construye la secuencia completa de ítems para la ruleta (falsos previos, ganador, relleno posterior)
local function construirSecuenciaRuleta(nombreCaja: string, itemGanadorId: string): { string }
	local pesos = CasesIndex[nombreCaja].Probabilidades
	local pesoTotal = SPP.ObtenerTotal(pesos)

	table.clear(_itemsRoll)

	-- Frames falsos iniciales
	for _ = 1, CANTIDAD_FRAMES_FALSOS do
		local itemIdFalso = obtenerItemFalso(nombreCaja, pesos, pesoTotal)
		if itemIdFalso then
			table.insert(_itemsRoll, itemIdFalso)
		end
	end

	-- Ítem ganador real
	table.insert(_itemsRoll, itemGanadorId)

	-- Frames falsos de relleno posterior
	for _ = 1, CANTIDAD_RELLENO_FRAME do
		local itemIdFalso = obtenerItemFalso(nombreCaja, pesos, pesoTotal)
		if itemIdFalso then
			table.insert(_itemsRoll, itemIdFalso)
		end
	end

	return _itemsRoll
end

-- Puebla visualmente los frames de la ruleta en el FrameContenedor
local function poblarRuleta(tablaItems: { string })
	for i, item in ipairs(tablaItems) do
		local itemData = ItemsIndex[item]
		if not itemData then
			error(`[GachaClient] El ítem '{item}' no existe en ningún catálogo de ItemsIndex.`)
		end

		local frameClonado = RollTemplate:Clone()
		frameClonado.LayoutOrder = i

		local imagen = frameClonado.ItemIcon :: ImageLabel
		imagen.Image = itemData.Imagen

		local colorFondo = frameClonado.ColorFondo :: Frame
		local bordes = frameClonado.Bordes :: ImageLabel

		local datosRareza = RarezaConfig[itemData.Rareza]
		if datosRareza then
			bordes.ImageColor3 = datosRareza.Color
			colorFondo.BackgroundColor3 = datosRareza.ColorFondo
		end

		frameClonado.Parent = FrameContenedor
		frameClonado.Visible = true
	end
end

-- Puebla la lista de probabilidades en la interfaz de la tienda
local function poblarProbabilidadesTienda(cajaRequerida: any)
	for i, probabilidad in ipairs(cajaRequerida.Probabilidades) do
		local rareza = probabilidad.Rareza
		local configRareza = RarezaConfig[rareza]
		if not configRareza then continue end

		local templateClone = RarezaTemplate:Clone()
		templateClone.Name = "RarezaTemplate"
		templateClone.LayoutOrder = i
		templateClone.Visible = true

		local probabilidadText = templateClone:FindFirstChild("Probabilidad") :: TextLabel
		local rellenoBarra = templateClone:FindFirstChild("Relleno") :: Frame?
		local uiStroke = templateClone:FindFirstChildOfClass("UIStroke")

		local porcentaje = probabilidad.Peso / 1000

		-- Cálculo visual de escala logarítmica/raíz para hacer visibles probabilidades bajas
		local factorRaiz = math.sqrt(math.clamp(porcentaje / 100, 0, 1))
		local escalaVisual = math.clamp(0.06 + (factorRaiz * 1.1), 0.06, 0.92)

		if probabilidadText then
			probabilidadText.Text = `{rareza} {porcentaje}%`
			probabilidadText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end

		if uiStroke then
			uiStroke.Color = configRareza.Color
		end

		if rellenoBarra then
			rellenoBarra.BackgroundColor3 = configRareza.ColorFondo
			rellenoBarra.Size = UDim2.fromScale(0, 1)

			local animacionBarra = TS:Create(rellenoBarra, TWEEN_BARRA_INFO, {
				Size = UDim2.fromScale(escalaVisual, 1),
			})
			animacionBarra:Play()
		end

		templateClone.Parent = Probabilidades
	end
end

-- MÓDULO PÚBLICO
local GachaClient = {}

-- Solicita apertura al servidor y prepara la lista de ítems de la ruleta
function GachaClient.SolicitarAbrirCaja(selfOrNombre: any, maybeNombre: any): { string }?
	local nombreCaja = if maybeNombre ~= nil then maybeNombre else selfOrNombre
	if not nombreCaja or type(nombreCaja) ~= "string" then return nil end

	local success, resultado = GachaNet.AbrirCaja:Call(nombreCaja):Await()
	if not success then
		warn(`[GachaClient] Error al abrir la caja '{nombreCaja}': {resultado}`)
		reproducirEfectoSonido(sonidoFail, 1)
		return nil
	end

	print(`[GachaClient] La caja '{nombreCaja}' se ha abierto con éxito. Ítem ganador: {resultado}`)
	reproducirEfectoSonido(sonidoProcessed, 1)

	return construirSecuenciaRuleta(nombreCaja, resultado)
end

-- Despliega y anima el destello de recompensa para el ítem obtenido
function GachaClient.MostrarRecompensa(tablaItems: { string })
	local itemGanador = tablaItems[CANTIDAD_FRAMES_FALSOS + 1]
	local itemData = ItemsIndex[itemGanador]
	if not itemData then return end

	local datosRareza = RarezaConfig[itemData.Rareza]
	local colorRareza = (datosRareza and datosRareza.Color) or Color3.fromRGB(255, 255, 255)

	-- Limpieza de destellos anteriores
	for _, shine in Recompensa:GetChildren() do
		if shine:IsA("ImageLabel") and shine.Name == "ShineBackground" then
			shine:Destroy()
		end
	end

	-- Configuración del nuevo destello
	local templateShine = ShineBackground:Clone()
	templateShine.Parent = Recompensa
	templateShine.Visible = true
	templateShine.ImageColor3 = colorRareza

	reproducirEfectoSonido(sonidoReward, 4)
	Recompensa.Visible = true

	-- Iniciar animación de rotación continua
	_giroTween = UIAnim.IniarGiroDestello(templateShine, 15)
end

-- Ejecuta la secuencia completa del tiro de gacha y ruleta visual
function GachaClient.GenerarRoll(nombreCaja: string)
	local tablaItems = GachaClient.SolicitarAbrirCaja(nombreCaja)
	if not tablaItems then
		warn("[GachaClient] Compra cancelada o fondos insuficientes.")
		return
	end

	-- Ajustes de visibilidad de interfaces
	CloseVisuals.Visible = false
	Recompensa.Visible = false
	if GachaShop.Enabled then
		GachaShop.Enabled = false
		GachaVisuals.Enabled = true
	end

	GachaClient.LimpiarRuleta()
	poblarRuleta(tablaItems)

	GachaAnimator.Animar(FrameContenedor, FrameItems, CANTIDAD_FRAMES_FALSOS)
	GachaClient.MostrarRecompensa(tablaItems)

	CloseVisuals.Visible = true
end

-- Abre la tienda de una caja física inspeccionada
function GachaClient.AbrirTienda(selfOrCaja: any, maybeCaja: any)
	local cajaPart = if maybeCaja ~= nil then maybeCaja else selfOrCaja
	if not cajaPart then return end

	local nombreCaja = cajaPart.Name
	local cajaRequerida = CasesIndex[nombreCaja]
	if not cajaRequerida then
		error(`[GachaClient] No existe una caja configurada con el nombre: {nombreCaja}`)
	end

	_cajaActualId = nombreCaja

	local nombreCajaAbrir = InfoCaja:FindFirstChild("NombreCaja") :: TextLabel
	local tipoCaja = InfoCaja:FindFirstChild("TipoCaja") :: Frame
	local tipoColor = tipoCaja:FindFirstChild("Color") :: TextLabel
	local tipoStroke = tipoCaja:FindFirstChild("Stroke") :: TextLabel

	GachaClient.LimpiarProbabilidades()
	GachaShop.Enabled = true
    reproducirEfectoSonido(sonidoPop, 1)

	nombreCajaAbrir.Text = cajaRequerida.NombreVisible
	tipoColor.Text = cajaRequerida.Tipo
	tipoStroke.Text = cajaRequerida.Tipo
	Precio.Text = tostring(cajaRequerida.Precio)

	local assetIcono = ICONOS_MONEDA[cajaRequerida.Moneda]
	if assetIcono then
		IconoVisual.Image = assetIcono
	else
		warn(`[GachaClient] No hay icono configurado para la moneda: '{cajaRequerida.Moneda}'`)
	end

	poblarProbabilidadesTienda(cajaRequerida)
end

-- Limpia las tarjetas de ruleta generadas previamente
function GachaClient.LimpiarRuleta()
	for _, child in FrameContenedor:GetChildren() do
		if child:IsA("Frame") and child.Name == "RollTemplate" then
			child:Destroy()
		end
	end
end

-- Limpia las barras de probabilidad previas de la tienda
function GachaClient.LimpiarProbabilidades()
	for _, child in Probabilidades:GetChildren() do
		if child:IsA("Frame") and child.Name == "RarezaTemplate" then
			child:Destroy()
		end
	end
end

-- Inicializa referencias de interfaz, botones y conexiones de proximidad
function GachaClient.Init()
	local playerGui = jugador:WaitForChild("PlayerGui")
	local templates = playerGui:WaitForChild("Templates")
	RarezaTemplate = templates:WaitForChild("RarezaTemplate") :: TextLabel
	RollTemplate = templates:WaitForChild("RollTemplate") :: Frame
	ShineBackground = templates:WaitForChild("ShineBackground") :: ImageLabel

	-- GachaShop
	GachaShop = playerGui:WaitForChild("GachaShop") :: ScreenGui
	FrameCaja = GachaShop:WaitForChild("FrameCaja") :: Frame
	Probabilidades = GachaShop:WaitForChild("Probabilidades") :: Frame

	local closeShop = FrameCaja:WaitForChild("CloseShop") :: ImageButton
	local buyButton = FrameCaja:WaitForChild("BuyButton") :: ImageButton
	Precio = buyButton:WaitForChild("Precio") :: TextLabel
	IconoVisual = buyButton:WaitForChild("Icono") :: ImageLabel
	InfoCaja = FrameCaja:WaitForChild("Info") :: Frame

	-- GachaVisuals
	GachaVisuals = playerGui:WaitForChild("GachaVisuals") :: ScreenGui
	local framePrincipal = GachaVisuals:WaitForChild("FramePrincipal")
	Recompensa = GachaVisuals:WaitForChild("Recompensa") :: Frame
	CloseVisuals = GachaVisuals:WaitForChild("CloseVisuals") :: TextButton
	FrameItems = framePrincipal:WaitForChild("FrameItems") :: Frame
	FrameContenedor = FrameItems:WaitForChild("FrameContenedor") :: Frame

	-- Conexiones de botones
	buyButton.MouseButton1Click:Connect(function()
		if _cajaActualId ~= nil then
			GachaClient.GenerarRoll(_cajaActualId)
		end
	end)

	closeShop.MouseButton1Click:Connect(function()
        reproducirEfectoSonido(sonidoEscape, 1)
		GachaClient.LimpiarProbabilidades()
		GachaShop.Enabled = false
	end)

	CloseVisuals.MouseButton1Click:Connect(function()
		GachaClient.LimpiarRuleta()
		GachaClient.LimpiarProbabilidades()
		if _giroTween then
			_giroTween:Cancel()
			_giroTween = nil
		end
		GachaVisuals.Enabled = false
	end)

	-- Cajas físicas en Workspace
	local contenedorCajas = game.Workspace:WaitForChild("ContenedorCajas") :: Folder
	for _, caja in contenedorCajas:GetChildren() do
		if caja:IsA("BasePart") then
			local proxPrompt = caja:FindFirstChildOfClass("ProximityPrompt")
			if proxPrompt then
				proxPrompt.Triggered:Connect(function()
					GachaClient.AbrirTienda(caja)
				end)
			end
		end
	end
end

return GachaClient