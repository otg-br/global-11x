local taddmount_talk = TalkAction("!taddmount", "/taddmount")
function taddmount_talk.onSay(player, words, param, type)
    if not player:getGroup():getAccess() then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[MOUNT] - Você não tem permissão para usar este comando.")
        return false
    end

    local split = param:split(",")
    local targetName = split[1] and trim(split[1]) or ""
    local mountId = split[2] and tonumber(trim(split[2])) or 1

    if targetName == "" then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[MOUNT] - Uso: !taddmount playerName, mountId")
        return false
    end

    local targetPlayer = Player(targetName)
    if not targetPlayer then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[MOUNT] - Jogador não encontrado ou offline.")
        return false
    end

    if targetPlayer:hasMount(mountId) then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("[MOUNT] - %s já possui o mount ID %d.", targetPlayer:getName(), mountId))
        return false
    end

    if targetPlayer:addMount(mountId) then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("[MOUNT] - Mount ID %d foi dado com sucesso para %s.", mountId, targetPlayer:getName()))
        targetPlayer:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("[MOUNT] - Você recebeu o mount ID %d!", mountId))
    else
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[MOUNT] - Erro ao dar o mount.")
        return false
    end

    return false
end

local tremount_talk = TalkAction("!tremmount", "/tremmount")
function tremount_talk.onSay(player, words, param, type)
    if not player:getGroup():getAccess() then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[MOUNT] - Você não tem permissão para usar este comando.")
        return false
    end

    local split = param:split(",")
    local targetName = split[1] and trim(split[1]) or ""
    local mountId = split[2] and tonumber(trim(split[2])) or 1

    if targetName == "" then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[MOUNT] - Uso: !tremmount playerName, mountId")
        return false
    end

    local targetPlayer = Player(targetName)
    if not targetPlayer then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[MOUNT] - Jogador não encontrado ou offline.")
        return false
    end

    if not targetPlayer:hasMount(mountId) then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("[MOUNT] - %s não possui o mount ID %d.", targetPlayer:getName(), mountId))
        return false
    end

    if targetPlayer:removeMount(mountId) then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("[MOUNT] - Mount ID %d foi removido com sucesso de %s.", mountId, targetPlayer:getName()))
        targetPlayer:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("[MOUNT] - Seu mount ID %d foi removido!", mountId))
    else
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[MOUNT] - Erro ao remover o mount.")
        return false
    end

    return false
end

local tlistmounts_talk = TalkAction("!tlistmounts", "/tlistmounts")
function tlistmounts_talk.onSay(player, words, param, type)
    if not player:getGroup():getAccess() then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[MOUNT] - Você não tem permissão para usar este comando.")
        return false
    end

    local targetName = trim(param)
    local targetPlayer = nil

    if targetName ~= "" then
        targetPlayer = Player(targetName)
        if not targetPlayer then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[MOUNT] - Jogador não encontrado ou offline.")
            return false
        end
    end

    local mounts = Game.getMounts()
    if not mounts or #mounts == 0 then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[MOUNT] - Nenhum mount encontrado.")
        return false
    end

    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[MOUNT] - Lista de mounts disponíveis:")
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "ID | Nome | ClientID")
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "---|------|---------")

    for _, mount in ipairs(mounts) do
        local status = ""
        
        if targetPlayer then
            if targetPlayer:hasMount(mount.id) then
                status = " [POSSUI]"
            else
                status = " [NÃO POSSUI]"
            end
        end

        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("%d | %s | %d%s", 
            mount.id, mount.name, mount.clientId, status))
    end

    if targetPlayer then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("[MOUNT] - Status dos mounts para %s mostrado acima.", targetPlayer:getName()))
    end

    return false
end

function trim(s)
    return s:match("^%s*(.-)%s*$")
end
taddmount_talk:separator(" ")
taddmount_talk:register()
tremount_talk:separator(" ")
tremount_talk:register()
tlistmounts_talk:separator(" ")
tlistmounts_talk:register() 