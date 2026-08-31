local SSS = script.Parent :: Folder --Folder que contiene los servicios del servidor

for _, child in SSS:GetChildren() do --Recorre todos losa hijos del folder SSS
    if child:IsA("Folder") and (child.Name == "Services" or child.Name == "Data") then --Si el hijo es un Folder y su nombre es "Services" o "Data"
        for _, modulo in child:GetChildren() do
            if modulo:IsA("ModuleScript") then --Si el hijo es un ModuleScript
                local success, service = pcall(require, modulo) --Requiere al modulo mediante una llamada protegida que evita que un modulo detenga los demas
                
                if not success then --Si no se pudo requerir el modulo
                    warn(`[ServerLoader] Error al requerir {modulo.Name} : {service}`)
                    continue
                end

                if typeof(service) == "table" and typeof(service.Init) == "function" then --Si el servicio es una tabla y tiene una funcion Init
                    task.spawn(function()
                        service.Init() --Llama a la funcion Init del servicio en un hilo separado para evitar bloqueos del servidor
                        print(`[ServerLoader] Servicio {modulo.Name} iniciado con éxito!`)
                    end)
                end
            end
        end
    end
end