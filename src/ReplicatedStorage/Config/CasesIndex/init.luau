local CajaBasica = require(script.CajaBasica)
local CajaComun = require(script.CajaComun)

export type CaseData = CajaBasica.CaseData --Importacion de molde generico de X modulo

local CaseIndex : {[string] : CaseData} = { --La llave es el ID exacto, el valor es el modulo
    ["caja_basica"] =  CajaBasica,
    ["caja_comun"] = CajaComun,
    --[...] =  --Aquí irían más modulos nuevos de cajas
}
return CaseIndex