local CajaBasica = require(script.Parent.CajaBasica)
type CajaBasica = CajaBasica.CaseData

export type CaseData = CajaBasica

local CajaComun : CaseData = {
    ID = "caja_comun",
    NombreVisible = "Caja Común",
    Precio = 200,
    Moneda = "Oro",
    Tipo = "Armas",

    Probabilidades = {
        {Rareza = "Common", Peso = 40000}, --40%
        {Rareza = "Uncommon", Peso = 31500}, --31.5%
        {Rareza = "Rare", Peso = 19000}, --19%
        {Rareza = "Epic", Peso = 5500}, --5.5%
        {Rareza = "Legendary", Peso = 2000}, --2%
        {Rareza = "Mythic", Peso = 1500}, --1.5%
        {Rareza = "Divine", Peso = 500}, --0-5%
    },
    Contenido = {
        --Comunes
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
        
        --Raro
        Rare = {
            "espada_luna"
        },

        --Epico
        Epic = {
            "espada_eclipse",
            "baston_estelar",
        },

        --Legendario
        Legendary = {
            "daga_sombra",
            "arco_fenix",
        },

        --Mitico
        Mythic = {
            "martillo_titan",
            "guadana_vacio",
        },

        --Divino
        Divine = {
            "lanza_primordial",
        },
    }
}
return CajaComun