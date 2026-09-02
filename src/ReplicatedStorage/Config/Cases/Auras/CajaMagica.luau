local RS = game:GetService("ReplicatedStorage")

local CajaBasica  = require(RS.Config.Cases.Armas.CajaBasica)
type CajaBasica = CajaBasica.CaseData

export type CaseData = CajaBasica

local CajaMagica : CaseData = {
    ID = "caja_magica",
    NombreVisible = "Caja Mágica",
    Precio = 1000,
    Moneda = "Gemas",
    Tipo = "Auras",
    Probabilidades = {
        {Rareza = "Common", Peso = 50000},
        {Rareza = "Uncommon", Peso = 30000},
        {Rareza = "Rare", Peso = 15000},
        {Rareza = "Epic", Peso = 4000},
        {Rareza = "Legendary", Peso = 1000},
        {Rareza = "Mythic", Peso = 500}, 
        {Rareza = "Divine", Peso = 0.1},
    },
    Contenido = {
        Common = {
            "aura_fuego",
            "aura_agua",
            "aura_tierra",
            "aura_aire"
        },
        Uncommon = {
            "aura_luz",
            "aura_oscuridad"
        },
        Rare = {
            "aura_electricidad"
        },
        Epic = {
            "aura_hielo"
        },
        Legendary = {
            "aura_dragon"
        },
        Mythic = {
            "aura_fenix"
        },
        Divine = {
            "aura_dios"
        },
    }
}
return CajaMagica