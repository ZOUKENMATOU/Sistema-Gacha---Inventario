--SERVICIOS
local TS = game:GetService("TweenService")


local UIAnim = {}

function UIAnim.IniarGiroDestello(elementoRotar : ImageLabel, duracionVuelta: number?) --ANIMA EL BRILLO AL FINAL DE GACHA
    local duracion = duracionVuelta or 10

    local info = TweenInfo.new(
        duracion,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut,
        -1,
        false
    )

    local tween = TS:Create(elementoRotar, info, {Rotation = 360})

    tween:Play()
    return tween
end
return UIAnim