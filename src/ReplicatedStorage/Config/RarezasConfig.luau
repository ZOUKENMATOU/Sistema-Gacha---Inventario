export type NombresRareza = "Common" | "Uncommon"| "Rare" | "Epic" | "Legendary" | "Mythic" | "Divine"

export type RarezaData = {
    Color: Color3,
    Orden: number,
}

local RarezaConfig :{[NombresRareza] : RarezaData} = {
    Common = {
        Color = Color3.fromRGB(170, 170, 170),
        Orden = 7
    },
    Uncommon = {
        Color  = Color3.fromRGB(46, 204, 113),
        Orden = 6
    },
    Rare = {
        Color = Color3.fromRGB(52, 152, 219),
        Orden = 5
    },
    Epic = {
        Color = Color3.fromRGB(154, 41, 199),
        Orden = 4
    },
    Legendary = {
        Color = Color3.fromRGB(255, 165, 0),
        Orden = 3
    },
    Mythic = {
        Color = Color3.fromRGB(255, 46, 23),
        Orden = 2
    },
    Divine = {
        Color = Color3.fromRGB(0, 0, 255),
        Orden = 1
    },
}
return RarezaConfig