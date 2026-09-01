local SelectorPorPeso = {}

function SelectorPorPeso.ObtenerTotal(tabla : {}) : number --Recibe una tabla de elementos que contengan un campo "peso" y devuelve la suma de todos los pesos
    local pesoTotal = 0 :: number--Inicializamos el peso total en 0

    for _, peso in pairs(tabla) do --Iteramos sobre la tabla
        pesoTotal += peso.Peso --Sumamos el peso de cada elemento al peso total
    end
    return pesoTotal --Retorna la suma de todos los pesos
end

function SelectorPorPeso.SeleccionarRareza(tablaProbabilidades : {}, numeroRNG : number) : string? | nil--Recibe la misma tabla de elementos y un numero pseudoaleatorio generado por el modulo RNG
    local pesoAcumulado = 0 :: number --Inicializamos el peso acumulado en 0
    for _, probabilidad in ipairs(tablaProbabilidades) do --Iteramos sobre la tabla de probabilidades
        pesoAcumulado += probabilidad.Peso --Sumamos el peso de cada elemento al peso acumulado
        if numeroRNG <= pesoAcumulado then --Si el numero pseudoaleatorio es menor o igual al peso acumulado, retornamos el elemento correspondiente
            return probabilidad.Rareza --Retornamos la rareza correspondiente al peso acumulado
        end 
    end
    return nil --Si no se encuentra ninguna rareza, retornamos nil
end
return SelectorPorPeso