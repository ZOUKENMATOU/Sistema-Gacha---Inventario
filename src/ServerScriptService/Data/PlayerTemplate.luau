local PlayerTemplate = {
    Economia = {
        Oro = 300,
        Gemas = 0
    },
    Armas = {} :: {string},
    Auras = {} :: {string},
    Equipados = {} :: {string},
}

export type PlayerData = typeof(PlayerTemplate)
return PlayerTemplate