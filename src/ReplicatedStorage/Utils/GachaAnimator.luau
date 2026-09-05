local GachaAnimator = {}

--SERVICIOS
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

--CARPETA
local Sonidos = SoundService:WaitForChild("Sonidos")

--ANIMACION
local TWEEN_INFO = TweenInfo.new(
    10, --Segundos de movimiento
    Enum.EasingStyle.Circular, --Estilo
    Enum.EasingDirection.Out --Aceleracion
)

function GachaAnimator.Animar(frameContenedor : Frame, frameMascara : Frame, cantidadFramesClonados : number)
    frameContenedor.Position = UDim2.new(0, 0, frameContenedor.Position.Y.Scale, frameContenedor.Position.Y.Offset) --Reinicia la posición del frameContenedor antes de iniciar la amimacion

    local frameIndex = cantidadFramesClonados + 1--Cantidad de frame clonados SIN contrar los añadidos despuesde la recompensa

    local primerClon = frameContenedor:FindFirstChildOfClass("Frame") --Encuentra al primer frame que se clone en el contenedor
    if not primerClon then return end

    local anchoVentana = frameMascara.AbsoluteSize.X --Obtiene el ancho de la ventana "FrameItems"
    local anchoFrame = primerClon.AbsoluteSize.X --Obtiene el ancho del frame clonado

    local listLayout = frameContenedor:FindFirstChild("UIListLayout") --Encuentra el "UIListLayout" del frameContenedor
    local padding = listLayout and listLayout.Padding.Offset or 0 --Obtiene el padding del "UIListLayout"

    -- =================================== --
    --CONTADOR DE FRAMES CLONADOS--
    local totalFrames = 0 
    for _, child in frameContenedor:GetChildren() do
        if child:IsA("Frame") then
            totalFrames += 1
        end
    end

    --ESTIRAR EL FRAME CONTENEDOR PARA QUE ABARQUE TODOS LOS FRAMES CLONADOS
    local anchoTotal = totalFrames * (anchoFrame + padding) --Multiplica el total de frames clonados por el ancho del frame clon en X y suma la separacion entre cada uno
    frameContenedor.Size = UDim2.new(0, anchoTotal, frameContenedor.Size.Y.Scale, frameContenedor.Size.Y.Offset)
    -- =================================== --

    local posInicial = (anchoVentana / 2) - (anchoFrame / 2) --Posicion inicial del primer frame clonado
    local salto = -(anchoFrame + padding) --Salto entre cada frame para pasar al siguiente
    
    local objetivoFinal = posInicial + ((frameIndex - 1) * salto) --Posicion donde se encuentra el item ganador real

    local tween = TS:Create(frameContenedor, TWEEN_INFO, {
        Position = UDim2.new(0, objetivoFinal, frameContenedor.Position.Y.Scale, frameContenedor.Position.Y.Offset)
    })

    -- =================================== --
    --REPRODUCCION DE SONIDOS
    local tick = Sonidos:WaitForChild("Tick")
    local reward = Sonidos:WaitForChild("Reward")

    local ultimoIndice = 0

    local conexionAudio
    conexionAudio = RunService.RenderStepped:Connect(function() --Conecta el sonido de tick a cada frame clonado
        local distanciaRecorrida = math.abs(frameContenedor.Position.X.Offset) --Calcula la distancia recorrida por el frame
        local indiceActual = math.floor(distanciaRecorrida / salto) --Calcula en que item de la fila va

        if indiceActual ~= ultimoIndice then --Si el indice cambio desde el ultimo frame
            ultimoIndice = indiceActual --Actualizamos el indice

            local clonTick = tick:Clone() --Clonamos el sonido que reproducira cada frame
            clonTick.Parent = SoundService
            clonTick:Play()
            Debris:AddItem(clonTick, 1) --Lo destruye despues de 1 segundo
        end
    end)
    -- =================================== --

    tween:Play()
    tween.Completed:Wait()
    conexionAudio:Disconnect() --Desconectamos el RenderStepped

    -- REPRODUCIMOS EL SONIDO DE VICTORIA --
    local clonVictoria = reward:Clone() --PASARLO A LA ANIMACION UI
    clonVictoria.Parent = SoundService
    clonVictoria:Play()
    Debris:AddItem(clonVictoria, 4)
end
return GachaAnimator