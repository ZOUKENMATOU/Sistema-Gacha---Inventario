local RS = game:GetService("ReplicatedStorage")

local RarezasConfig = require(RS.Config.RarezasConfig) --Importacion de la configuración de rarezas
type NombreRareza = RarezasConfig.NombresRareza

export type InfoData = {
    ID: string,
    NombreVisible: string,
    Imagen: string,
    Rareza: NombreRareza
}

local Auras : {[string]: InfoData} = {

    --Comun
    ["aura_fuego"] = {
        ID = "aura_fuego",
        NombreVisible = "Aura de Fuego",
        Imagen = "rbxassetid://",
        Rareza = "Common"
    },
    ["aura_agua"] = {
        ID = "aura_agua",
        NombreVisible = "Aura de Agua",
        Imagen = "rbxassetid://",
        Rareza = "Common"
    },
    ["aura_tierra"] = {
        ID = "aura_tierra",
        NombreVisible = "Aura de Tierra",
        Imagen = "rbxassetid://",
        Rareza = "Common"
    },
    ["aura_aire"] = {
        ID = "aura_aire",
        NombreVisible = "Aura de Aire",
        Imagen = "rbxassetid://",
        Rareza = "Common"
    },

    --Poco comun
    ["aura_luz"] = {
        ID = "aura_luz",
        NombreVisible = "Aura de Luz",
        Imagen = "rbxassetid://",
        Rareza = "Uncommon"
    },
    ["aura_oscuridad"] = {
        ID = "aura_oscuridad",
        NombreVisible = "Aura de Oscuridad",
        Imagen = "rbxassetid://",
        Rareza = "Uncommon"
    },

    --Raro
    ["aura_electricidad"] = {
        ID = "aura_electricidad",
        NombreVisible = "Aura de Electricidad",
        Imagen = "rbxassetid://",
        Rareza = "Rare"
    },

    --Epico
    ["aura_hielo"] = {
        ID = "aura_hielo",
        NombreVisible = "Aura de Hielo",
        Imagen = "rbxassetid://",
        Rareza = "Epic"
    },

    --Legendario
    ["aura_dragon"] = {
        ID = "aura_dragon",
        NombreVisible = "Aura de Dragón",
        Imagen = "rbxassetid://",
        Rareza = "Legendary"
    },

    --Mitico
    ["aura_fenix"] = {
        ID = "aura_fenix",
        NombreVisible = "Aura de Fénix",
        Imagen = "rbxassetid://",
        Rareza = "Mythic"
    },

    --Divino
    ["aura_dios"] = {
        ID = "aura_dios",
        NombreVisible = "Aura de Dios",
        Imagen = "rbxassetid://",
        Rareza = "Divine"
    }
}
return Auras