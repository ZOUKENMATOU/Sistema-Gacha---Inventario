local RS = game:GetService("ReplicatedStorage")

local RarezasConfig = require(RS.Config.RarezasConfig) --Importacion de la configuración de rarezas
type NombreRareza = RarezasConfig.NombresRareza

export type TipoData = "Armas" | "Auras"
export type TipoMoneda = "Oro" | "Gemas" | "Robux"

export type ProbabilidadData = {
    Rareza: NombreRareza,
    Peso: number
}

export type CaseData = {
    ID: string,
    NombreVisible: string,
    Precio: number,
    Moneda: TipoMoneda,
    ProductId: number?, --En caso de que la moneda sea Robux, se debe especificar el ProductId del producto en la tienda de Roblox
    Tipo: TipoData,
    Probabilidades: {ProbabilidadData}, --Array de probabilidades
    Contenido: {[NombreRareza]: {string}} --Diccionario de Arrays
}

--[[
ID = "",
NombreVisual = "",
Precio = ,
Moneda = "",
Tipo = "",

Probabilidades = {
    {Rareza = "Common", Peso = },
    {Rareza = "Uncommon", Peso = },
    {Rareza = "Rare", Peso = },
    {Rareza = "Epic", Peso = },
    {Rareza = "Legendary", Peso = },
    {Rareza = "Mythic", Peso = }, 
    {Rareza = "Divine", Peso = },
},
Contenido = {
    Common = {
    },
    Uncommon = {
    },
    Rare = {
    },
    Epic = {
    },
    Legendary = {
    },
    Mytic = {
    },
    Divine = {
    },
}
]]

local CajaBasica : CaseData = {
    ID = "caja_basica",
    NombreVisible = "Caja Básica",
    Precio = 100,
    Moneda = "Oro",
    Tipo = "Armas",

    Probabilidades = { --Tipo y probabilidad de cada rareza
        {Rareza = "Common", Peso = 45000}, --45%
        {Rareza = "Uncommon", Peso = 30000},--30%
        -- {Rareza = "Rare", Peso = 18000}, --18%
        -- {Rareza = "Epic", Peso = 5000}, --5%
        -- {Rareza = "Legendary", Peso = 1500}, --1.5%
        -- {Rareza = "Mythic", Peso = 450}, --0.45%
        -- {Rareza = "Divine", Peso = 50}, --0.05%
    },

    Contenido = { --Contenido de la caja (items que pueden salir en base a su rareza)
        Common = {
            "espada_hierro",
            "espada_gris",
            "espada_espina",
            "espada_morada",
        },
        --Poco comunes
        Uncommon = {
            "espada_minecraft",
            "espada_brillante",
            "espada_oscura",
            "espada_negra",
        },
        -- Rare = {

        -- },
        -- Epic = {

        -- },
        -- Legendary = {

        -- },
        -- Mythic = {

        -- },
        -- Divine = {

        -- },
    }
}
return CajaBasica