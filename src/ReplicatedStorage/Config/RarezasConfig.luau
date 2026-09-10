-- TIPOS DE DATOS
export type NombresRareza = "Common" | "Uncommon"| "Rare" | "Epic" | "Legendary" | "Mythic" | "Divine"

export type RarezaData = {
    Color: Color3,
    ColorFondo: Color3,
    Orden: number,
}

-- CONFIGURACION DE RAREZAS
local RarezaConfig :{[NombresRareza] : RarezaData} = {
    Common = {
        Color = Color3.fromRGB(170, 170, 170),
        ColorFondo = Color3.fromRGB(70, 70, 70),
        Orden = 7
    },
    Uncommon = {
        Color  = Color3.fromRGB(46, 204, 113),
        ColorFondo = Color3.fromRGB(20, 88, 48),
        Orden = 6
    },
    Rare = {
        Color = Color3.fromRGB(52, 152, 219),
        ColorFondo = Color3.fromRGB(20, 58, 83),
        Orden = 5
    },
    Epic = {
        Color = Color3.fromRGB(154, 41, 199),
        ColorFondo = Color3.fromRGB(45, 16, 79),
        Orden = 4
    },
    Legendary = {
        Color = Color3.fromRGB(255, 165, 0),
        ColorFondo = Color3.fromRGB(100, 63, 0),
        Orden = 3
    },
    Mythic = {
        Color = Color3.fromRGB(255, 46, 23),
        ColorFondo = Color3.fromRGB(90, 15, 8),
        Orden = 2
    },
    Divine = {
        Color = Color3.fromRGB(0, 0, 255),
        ColorFondo = Color3.fromRGB(0, 0, 100),
        Orden = 1
    },
}
return RarezaConfig