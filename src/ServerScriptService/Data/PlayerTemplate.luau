local PlayerTemplate = {
    Economia = {
        Oro = 300,
        Gemas = 0
    },
    Armas = {},
    Auras = {},
    Equipados = {},
}

export type PlayerData = typeof(PlayerTemplate)
return PlayerTemplate