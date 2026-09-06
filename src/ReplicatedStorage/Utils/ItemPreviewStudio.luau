--SERVICIOS
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ItemPreviewStudio = {}

--CONFIGURACION
local VELOCIDAD_GIRO = 45 -- Grados sexagesimales por segundo

--ESTADO LOCAL
local _maniqui : Model? = nil
local _itemsMontados: {[string]: Instance} = {}
local _camaraOriginalCFrame : CFrame? = nil
local _camaraOriginalType : Enum.CameraType? = nil
local _conexionRotacion : RBXScriptConnection? = nil

type EstrategiaMontaje = (maniqui: Model, clonAsset: Instance) -> ()

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

function ItemPreviewStudio.AbrirEstudio(podioPart : BasePart, cameraAnchor : BasePart, transicionSegundos : number?)
    local camera = Workspace.CurrentCamera
    if not camera then return end

    --RESPALDO POSICIONES CAMARA
    _camaraOriginalCFrame = camera.CFrame
    _camaraOriginalType = camera.CameraType

    --SPAWN Y MONTAJE
    local targetPlayer = Players.LocalPlayer
    local humanodDescription = Players:GetHumanoidDescriptionFromUserIdAsync(targetPlayer.UserId)
    local clon = Players:CreateHumanoidModelFromDescriptionAsync(humanodDescription, Enum.HumanoidRigType.R15)
    clon.Name = "PreviewRig"

    local hum = clon:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end

    --POSICIONAR EL RIG
    local alturaOffset = Vector3.new(0, (podioPart.Size.Y / 3.5) , 0)
    local posSpawn = podioPart.Position + alturaOffset
    local puntoMira = Vector3.new(cameraAnchor.Position.X, posSpawn.Y, cameraAnchor.Position.Z)
    
    clon:PivotTo(CFrame.lookAt(posSpawn, puntoMira))

    --ANCLAR RIG
    local hrp = clon:FindFirstChild("HumanodiRootPart") :: BasePart?
    if hrp then
        hrp.Anchored = true
    end

    for _, desc in ipairs(clon:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.CanCollide = false
            if desc ~= hrp then
                desc.Anchored = false
            end
        end
    end

    clon.Parent = Workspace
    _maniqui = clon
    --BUBLE DE ROTACION
    _conexionRotacion = RunService.RenderStepped:Connect(function(deltaTime : number)
        if _maniqui and _maniqui.PrimaryPart then
            local rotacionDelta = math.rad(VELOCIDAD_GIRO * deltaTime)
            _maniqui:PivotTo(_maniqui:GetPivot() * CFrame.Angles(0, rotacionDelta, 0))
        end
    end)

    --TRANSICION DE LA CAMARA
    camera.CameraType = Enum.CameraType.Scriptable

    local duracion = transicionSegundos or 0.6
    if duracion > 0 then
        local tween = TweenService:Create(camera, TweenInfo.new(duracion, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
            CFrame = cameraAnchor.CFrame
        })
        tween:Play()
    else
        camera.CFrame = cameraAnchor.CFrame
    end
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
    if _itemsMontados[categoria] then
        _itemsMontados[categoria]:Destroy()
        _itemsMontados[categoria] = nil
    end

    --CLONACION--
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
    --DESCONECTAR EL EVENTO DE ROTACION
    if _conexionRotacion then
        _conexionRotacion:Disconnect()
        _conexionRotacion = nil
    end

    --LIMPIEZA
    for _, instancia in pairs(_itemsMontados) do
        instancia:Destroy()
    end
    _itemsMontados = {}

    if _maniqui then 
        _maniqui:Destroy()
        _maniqui = nil
    end

    --RESTAURAR CAMARA
    local camera = Workspace.CurrentCamera
    if camera and _camaraOriginalType then
        camera.CameraType = _camaraOriginalType
        if _camaraOriginalCFrame then
            camera.CFrame =_camaraOriginalCFrame
        end
    end

    _camaraOriginalCFrame = nil
    _camaraOriginalType = nil
end

return ItemPreviewStudio