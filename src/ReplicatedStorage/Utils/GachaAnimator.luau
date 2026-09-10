-- SERVICIOS
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- ASSETS DE AUDIO
local Sonidos = SoundService:WaitForChild("Sonidos")
local sonidoTick = Sonidos:WaitForChild("Tick") :: Sound

-- CONFIGURACION DE ANIMACION
local TWEEN_INFO = TweenInfo.new(
    10, --Segundos de movimiento
    Enum.EasingStyle.Circular, --Estilo
    Enum.EasingDirection.Out --Aceleracion
)

-- FUNCIONES AUXILIARES PRIVADAS
local function reproducirSonido(sonidoOriginal : Sound, duracionDebris : number)
    local clon = sonidoOriginal:Clone()
    clon.Parent = SoundService
    clon:Play()
    Debris:AddItem(clon, duracionDebris)
end

-- MODULO PUBLICO
local GachaAnimator = {}

function GachaAnimator.Animar(frameContenedor : Frame, frameMascara : Frame, cantidadFramesClonados : number)
    local primerClon = frameContenedor:FindFirstChildOfClass("Frame") --Encuentra al primer frame que se clone en el contenedor
    if not primerClon then return end

    if frameMascara.AbsoluteSize.X == 0 or primerClon.AbsoluteSize.X == 0 then
        task.wait()
    end
    
    local anchoVentana = frameMascara.AbsoluteSize.X --Obtiene el ancho de la ventana "FrameItems"
    local anchoFrame = primerClon.AbsoluteSize.X --Obtiene el ancho del frame clonado

    local padding = 0
    local listLayout = frameContenedor:FindFirstChild("UIListLayout") --Encuentra el "UIListLayout" del frameContenedor
    if listLayout then
        padding = listLayout.Padding.Offset + (listLayout.Padding.Scale * anchoVentana)
    end

    local pasoUnitario = anchoFrame + padding
    local salto = -pasoUnitario

    
    -- =================================== --
    --CONTADOR DE FRAMES CLONADOS--
    local totalFrames = 0 
    for _, child in frameContenedor:GetChildren() do
        if child:IsA("Frame") then
            totalFrames += 1
        end
    end
    if totalFrames == 0 then 
        totalFrames = cantidadFramesClonados + 15
    end


    --ESTIRAR EL FRAME CONTENEDOR PARA QUE ABARQUE TODOS LOS FRAMES CLONADOS
    local anchoTotal = totalFrames * pasoUnitario
    frameContenedor.Size = UDim2.new(0, anchoTotal, frameContenedor.Size.Y.Scale, frameContenedor.Size.Y.Offset)
    -- =================================== --

    local posInicial = (anchoVentana / 2) - (anchoFrame / 2) --Posicion inicial del primer frame clonado
    frameContenedor.Position = UDim2.new(0, posInicial, frameContenedor.Position.Y.Scale, frameContenedor.Position.Y.Offset)

    local frameIndex = cantidadFramesClonados + 1
    local objetivoFinal = posInicial + ((frameIndex - 1) * salto)

    local tween = TS:Create(frameContenedor, TWEEN_INFO, {
        Position = UDim2.new(0, objetivoFinal, frameContenedor.Position.Y.Scale, frameContenedor.Position.Y.Offset)
    })

    -- =================================== --
    local ultimoIndice = 0

    local conexionAudio : RBXScriptConnection
    conexionAudio = RunService.RenderStepped:Connect(function() --Conecta el sonido de tick a cada frame clonado
        local distanciaRecorrida = math.abs(frameContenedor.Position.X.Offset - posInicial) --Calcula la distancia recorrida por el frame
        local indiceActual = math.floor(distanciaRecorrida / pasoUnitario) --Calcula en que item de la fila va

        if indiceActual ~= ultimoIndice then --Si el indice cambio desde el ultimo frame
            ultimoIndice = indiceActual --Actualizamos el indice
            reproducirSonido(sonidoTick, 1)
        end
    end)
    -- =================================== --

    tween:Play()
    tween.Completed:Wait()

    conexionAudio:Disconnect() --Desconectamos el RenderStepped
end

return GachaAnimator