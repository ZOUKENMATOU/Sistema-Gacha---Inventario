-- SERVICIOS
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- CONFIGURACION
local VELOCIDAD_GIRO = 45 -- Grados sexagesimales por segundo
local DURACION_TRANSICION_CAMARA_DEFAULT = .6

-- TIPOS DE DATOS
type EstrategiaMontaje = (maniqui: Model, clonAsset: Instance) -> ()

-- ESTADO LOCAL
local _maniqui : Model? = nil
local _itemsMontados: {[string]: Instance} = {}
local _camaraOriginalCFrame : CFrame? = nil
local _camaraOriginalType : Enum.CameraType? = nil
local _conexionRotacion : RBXScriptConnection? = nil


--FUNCIONES AUXILIARES

-- Crea y configura el modelo del jugador
local function crearManiqui(player: Player): Model
	local humanoidDescription = Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
	local clon = Players:CreateHumanoidModelFromDescriptionAsync(humanoidDescription, Enum.HumanoidRigType.R15)
	clon.Name = "PreviewRig"

	local hum = clon:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	end

	return clon
end

-- Posicionar el maniqui en el podio
local function posicionarManiqui(maniqui: Model, podioPart: BasePart, cameraAnchor: BasePart)
	local alturaOffset = Vector3.new(0, podioPart.Size.Y / 3.5, 0)
	local posSpawn = podioPart.Position + alturaOffset
	local puntoMira = Vector3.new(cameraAnchor.Position.X, posSpawn.Y, cameraAnchor.Position.Z)

	maniqui:PivotTo(CFrame.lookAt(posSpawn, puntoMira))

	local hrp = maniqui:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.Anchored = true
	end

	for _, desc in ipairs(maniqui:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			if desc ~= hrp then
				desc.Anchored = false
			end
		end
	end

	maniqui.Parent = Workspace
end

-- Detiene el bucle de rotación, si existe
local function detenerRotacion()
	if _conexionRotacion then
		_conexionRotacion:Disconnect()
		_conexionRotacion = nil
	end
end

-- Inicia el bucle de rotación
local function iniciarRotacion()
	detenerRotacion()
	_conexionRotacion = RunService.RenderStepped:Connect(function(deltaTime: number)
		if _maniqui then
			local rotacionDelta = math.rad(VELOCIDAD_GIRO * deltaTime)
			_maniqui:PivotTo(_maniqui:GetPivot() * CFrame.Angles(0, rotacionDelta, 0))
		end
	end)
end

-- Ajusta la cámara hacia el ancla
local function moverCamara(cameraAnchor: BasePart, transicionSegundos: number?)
	local camera = Workspace.CurrentCamera
	if not camera then return end

	-- Respaldo de cámara actual
	_camaraOriginalCFrame = camera.CFrame
	_camaraOriginalType = camera.CameraType

	camera.CameraType = Enum.CameraType.Scriptable

	local duracion = transicionSegundos or DURACION_TRANSICION_CAMARA_DEFAULT
	if duracion > 0 then
		local tween = TweenService:Create(
			camera,
			TweenInfo.new(duracion, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
			{ CFrame = cameraAnchor.CFrame }
		)
		tween:Play()
	else
		camera.CFrame = cameraAnchor.CFrame
	end
end

-- Restablece la cámara a su estado original
local function restaurarCamara()
	local camera = Workspace.CurrentCamera
	if camera and _camaraOriginalType then
		camera.CameraType = _camaraOriginalType
		if _camaraOriginalCFrame then
			camera.CFrame = _camaraOriginalCFrame
		end
	end

	_camaraOriginalCFrame = nil
	_camaraOriginalType = nil
end

-- Estrategia a usar segun la categoria
local ESTRATEGIA_MONTAJE: { [string]: EstrategiaMontaje} = {
    ["Armas"] = function(maniqui : Model, clonAsset : Instance)
        local rightHand = maniqui:FindFirstChild("RightHand")
        if not rightHand or not rightHand:IsA("BasePart") then return end
        
        if clonAsset:IsA("Tool") then
            local handle = clonAsset:FindFirstChild("Handle") :: BasePart?
            if handle then
                handle.Anchored = false
                handle.CanCollide = false

                local weld = Instance.new("WeldConstraint")
                weld.Part0 = rightHand
                weld.Part1 = handle
                weld.Parent = handle

                handle.CFrame = rightHand.CFrame
            end
            clonAsset.Parent = maniqui
        end
    end,

    ["Auras"] = function(maniqui: Model, clonAsset: Instance)
        local rootPart = maniqui:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not rootPart then return end
        
        if clonAsset:IsA("Attachment") then
            clonAsset.Parent = rootPart
        elseif clonAsset:IsA("Model") then
            clonAsset:PivotTo(rootPart.CFrame)

            for _, desc in ipairs(clonAsset:GetDescendants()) do
                if desc:IsA("BasePart") then
                    desc.Anchored = true
                    desc.CanCollide = false
                end
            end
            clonAsset.Parent = maniqui
        end
    end
}

local ItemPreviewStudio = {} --Modulo publico


function ItemPreviewStudio.AbrirEstudio(podioPart : BasePart, cameraAnchor : BasePart, transicionSegundos : number?)
    local targetPlayer = Players.LocalPlayer
    if not targetPlayer then return end

    --Si hay un estudio abierto previamente, cerrarlo
    if _maniqui then
        ItemPreviewStudio.CerrarEstudio()
    end

    --Transicion de la camara
    moverCamara(cameraAnchor, transicionSegundos)

    --Crear y posicionar el maniquí
    local clon = crearManiqui(targetPlayer)
    posicionarManiqui(clon, podioPart, cameraAnchor)
    _maniqui = clon

    iniciarRotacion()
end

function ItemPreviewStudio.MostrarItem(categoria : string, assetOriginal : Instance)
    if not _maniqui then
        warn("[ItemPreviewStudio] El maniquí no ha sido preparado aún.")
        return
    end

    local estrategia = ESTRATEGIA_MONTAJE[categoria]
    if not estrategia then
        warn(`[ItemPreviewStudio] No existe estrategia de montaje para '{categoria}'`)
        return
    end

    --LIMPIEZA MONTAJE PREVIO--
    ItemPreviewStudio.LimpiarCategoria(categoria)

    --CLONACION DEL ASSET--
    local clon = assetOriginal:Clone()
    estrategia(_maniqui, clon)
    _itemsMontados[categoria] = clon
end

function ItemPreviewStudio.LimpiarCategoria(categoria : string)
    if _itemsMontados[categoria] then 
        _itemsMontados[categoria]:Destroy()
        _itemsMontados[categoria] = nil
    end
end

--CIERRE
function ItemPreviewStudio.CerrarEstudio()
    detenerRotacion()

    --LIMPIEZA DE ITEMS MONTADOS--
    for _, instancia in pairs(_itemsMontados) do
        instancia:Destroy()
    end

    _itemsMontados = {}

    --Destruccion del maniqui
    if _maniqui then
        _maniqui:Destroy()
        _maniqui = nil
    end

    restaurarCamara()
end

return ItemPreviewStudio