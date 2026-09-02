--SERVICIOS
local RS = game:GetService("ReplicatedStorage")

--MODULOS
local RarezaConfig = require(RS.Config.RarezasConfig)

--TIPOS DE DATO
export type TipoData = "Armas" | "Auras" | string --Tipo de contenido de la caja, puede ser "Armas", "Auras" o cualquier otro tipo

export type ProbabilidadData = { --Datos de probabilidad para cada ítem en la caja
    Rareza: RarezaConfig.NombresRareza,
    Peso: number,
}

export type CaseData = { --Datos de la caja
    ID: string,
    NombreVisual: string,
    Precio: number,
    Tipo: TipoData,
    Probabilidades: { ProbabilidadData },
    Contenido: { [RarezaConfig.NombresRareza]: { string } },
}

local CasesIndex: { [string]: CaseData} = {}

for _, descendant in script.Parent:GetDescendants() do --Obtiene todos los objetos descendientes de la carpeta principal ("Cases") y los recorre
    if descendant:IsA("ModuleScript") and descendant ~= script then --Si el objeto es un ModuleScript y no es el script principal
        local success, caseData = pcall(require, descendant) --Intenta requerir el ModuleScript
        if success and typeof(caseData) == "table" and caseData.ID then --Si el requerimiento fue exitoso y el resultado es una tabla con un ID válido
            CasesIndex[caseData.ID] = caseData 
        else
            warn(`[CasesIndex] No se pudo cargar la caja en: {descendant:GetFullName()}`)
        end
    end
end
return CasesIndex