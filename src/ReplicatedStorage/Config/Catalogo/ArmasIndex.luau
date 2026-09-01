local RS = game:GetService("ReplicatedStorage")

local RarezasConfig = require(RS.Config.RarezasConfig) --Importacion de la configuración de rarezas
type NombreRareza = RarezasConfig.NombresRareza

export type InfoData = {
    ID: string,
    NombreVisible: string,
    Imagen: string,
    Rareza: NombreRareza
}
--[[
[""] = {
    ID = "",
    NombreVisible = "",
    Image = "rbxassetid://",
    Rareza = ""
}
]]

local ArmasIndex : {[string]: InfoData} = {
        --Comunes
    ["espada_hierro"] = {
        ID = "espada_hierro",
        NombreVisible = "Espada de hierro",
        Imagen = "rbxassetid://116861400983248",
        Rareza = "Common",
    },
    ["espada_gris"] = {
        ID = "espada_gris",
        NombreVisible = "Espada gris",
        Imagen = "rbxassetid://104145483687109",
        Rareza = "Common",
    },
    ["espada_espina"] = {
        ID = "espada_espina",
        NombreVisible = "Espada de espina",
        Imagen = "rbxassetid://90166041605612",
        Rareza = "Common",
    },
    ["espada_morada"] = {
        ID = "espada_morada",
        NombreVisible = "Espada morada",
        Imagen = "rbxassetid://93717550492578",
        Rareza = "Common",
    },

    --Poco comunes
    ["espada_minecraft"] = {
        ID = "espada_minecraft",
        NombreVisible = "Espada de minecraft",
        Imagen = "rbxassetid://124660671315978",
        Rareza = "Uncommon",
    },
    ["espada_brillante"] = {
        ID = "espada_brillante",
        NombreVisible = "Espada brillante",
        Imagen = "rbxassetid://73973224253350",
        Rareza = "Uncommon",
    },
    ["espada_oscura"] = {
        ID = "espada_oscura",
        NombreVisible = "Espada oscura",
        Imagen = "rbxassetid://91952589072226",
        Rareza = "Uncommon",
    },
    ["espada_negra"] = {
        ID = "espada_negra",
        NombreVisible = "Espada negra",
        Imagen = "rbxassetid://93573265493567",
        Rareza = "Uncommon"
    },

    --Raro

    --Epico

    --Legendario

    --Mitico

    --Divino
}
return ArmasIndex