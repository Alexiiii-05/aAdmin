
local ESX = nil
ESX = exports["es_extended"]:getSharedObject()

local STAFF_GROUPS = {
    ["mod"] = true,
    ["admin"] = true,
    ["superadmin"] = true,
}
RegisterNetEvent("admin:requestOpenMenu")
AddEventHandler("admin:requestOpenMenu", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not STAFF_GROUPS[xPlayer.getGroup()] then
        TriggerClientEvent("esx:showNotification",src,"~r~Vous n'avez pas accès au menu admin")
        return
    end

    TriggerClientEvent("admin:openMenu", src)
end)
local staffList = {}
local playersData = {}

local function GetPlayerIdentifiersFull(playerId)
    local identifiers = {
        steam = "N/A",
        license = "N/A",
        discord = nil
    }

    for _, id in pairs(GetPlayerIdentifiers(playerId)) do
        if string.find(id, "steam:") then
            identifiers.steam = id
        elseif string.find(id, "license:") then
            identifiers.license = id
        elseif string.find(id, "discord:") then
            identifiers.discord = id:gsub("discord:", "")
        end
    end

    return identifiers
end

function LogAdminAction(logType, data)
    local webhook = Config.Webhooks[logType] or Config.Webhooks.admin
    if not webhook or webhook == "" then return end
    local staffIds = data.staffId and GetPlayerIdentifiersFull(data.staffId)
    local targetIds = data.targetId and GetPlayerIdentifiersFull(data.targetId)
    local description = data.description or ""
    if staffIds then
        description = description ..
            "\n\n👮 **Staff**" ..
            "\nID : "..data.staffId ..
            "\nSteam : "..staffIds.steam ..
            "\nLicense : "..staffIds.license ..
            "\nDiscord : " .. (staffIds.discord and "<@"..staffIds.discord..">" or "Non lié")
    end

    if targetIds then
        description = description ..
            "\n\n🧑 **Joueur**" ..
            "\nID : "..data.targetId ..
            "\nSteam : "..targetIds.steam ..
            "\nLicense : "..targetIds.license ..
            "\nDiscord : " .. (targetIds.discord and "<@"..targetIds.discord..">" or "Non lié")
    end

    local embed = {
        {
            title = data.title or "Action Admin",
            description = description,
            color = Config.LogColors[logType] or Config.LogColors.admin,
            footer = {
                text = Config.ServerName .. " • " .. os.date("%d/%m/%Y %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(
        webhook,
        function() end,
        "POST",
        json.encode({
            username = Config.ServerName,
            embeds = embed
        }),
        { ["Content-Type"] = "application/json" }
    )
end

local function UpdatePlayerData(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job = xPlayer.getJob().label or "N/A"
    local group = xPlayer.getGroup() or "user"
    local name = xPlayer.getName() or ("ID_" .. src)

    playersData[src] = {
        job = job,
        group = group,
        name = name
    }
    if STAFF_GROUPS[group] then
        staffList[#staffList + 1] = src
    end
end

AddEventHandler("esx:playerLoaded", function(src)
    UpdatePlayerData(src)
    TriggerClientEvent("admin:setStaffList", -1, staffList)
    TriggerClientEvent("admin:updatePlayersData", -1, #playersData)
    TriggerClientEvent("admin:updateCounts", -1, #staffList)
end)


RegisterNetEvent("admin:getPlayerCounts")
AddEventHandler("admin:getPlayerCounts", function()
    local src = source

    local totalPlayers = 0
    local staffPlayers = 0

    for _, playerId in ipairs(GetPlayers()) do
        totalPlayers = totalPlayers + 1

        local xPlayer = ESX.GetPlayerFromId(tonumber(playerId))
        if xPlayer then
            local group = xPlayer.getGroup()

            if group ~= "user" then
                staffPlayers = staffPlayers + 1
            end
        end
    end

    TriggerClientEvent("admin:receivePlayerCounts", src, totalPlayers, staffPlayers)
end)

local function IsStaff(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    return STAFF_GROUPS[xPlayer.getGroup()] == true
end


RegisterServerEvent("admin:tpTo")
AddEventHandler("admin:tpTo", function(target)
    local src = source
    if not IsStaff(src) then return end

    TriggerClientEvent("admin:tpToClient", src, target)
end)

RegisterServerEvent("admin:tpHere")
AddEventHandler("admin:tpHere", function(target)
    local src = source
    if not IsStaff(src) then return end

    TriggerClientEvent("admin:tpHereClient", target, src)
end)

RegisterServerEvent("admin:toggleFreeze")
AddEventHandler("admin:toggleFreeze", function(target)
    local src = source
    if not IsStaff(src) then return end

    TriggerClientEvent("admin:toggleFreezeClient", target)
end)

RegisterServerEvent("admin:startSpectate")
AddEventHandler("admin:startSpectate", function(target)
    local src = source
    if not IsStaff(src) then return end

    TriggerClientEvent("admin:startSpectateClient", src, target)
end)

RegisterServerEvent("admin:kick")
AddEventHandler("admin:kick", function(target, reason)
    local src = source
    if not IsStaff(src) then return end

    DropPlayer(target, "🛑 Kick administrateur: " .. (reason or "Aucun motif"))
end)


RegisterServerEvent("admin:requestSync")
AddEventHandler("admin:requestSync", function()
    local src = source
    TriggerClientEvent("admin:setStaffList", src, staffList)
    TriggerClientEvent("admin:updatePlayersData", src, playersData)
end)

local reports = {}
local reportIndex = 0

local items = {}

MySQL.ready(function()
    MySQL.Async.fetchAll("SELECT * FROM items", {}, function(result)
        for k, v in pairs(result) do
            items[k] = { label = v.label}
        end
    end)
end)

RegisterNetEvent("admin:getAllItems")
AddEventHandler("admin:getAllItems", function()
    local src = source
    MySQL.Async.fetchAll("SELECT name, label FROM items",{},function(result)
            TriggerClientEvent("admin:receiveAllItems", src, result)
        end
    )
end)

RegisterNetEvent("admin:refundItem")
AddEventHandler("admin:refundItem", function(targetId, itemName, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent("esx:showNotification", src, "~r~Quantité invalide")
        return
    end

    if not itemName or itemName == "" then
        TriggerClientEvent("esx:showNotification", src, "~r~Item invalide (nil)")
        print("[SERVER] ERREUR : itemName nil")
        return
    end
    xTarget.addInventoryItem(itemName, amount)
    TriggerClientEvent("esx:showNotification", src,("~g~Remboursement : %sx %s"):format(amount, itemName))
    TriggerClientEvent("esx:showNotification", targetId,("~g~Vous avez reçu %sx %s"):format(amount, itemName))
end)

RegisterServerEvent("admin:sendReport")
AddEventHandler("admin:sendReport", function(msg)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local name = xPlayer.getName()
    reportIndex = reportIndex + 1
    reports[reportIndex] = {
        id = reportIndex,
        playerId = src,
        name = name,
        msg = msg,
        time = os.date("%H:%M:%S"),
        status = "Ouvert",
        prisencharge = nil
    }
    for _, playerId in pairs(ESX.GetPlayers()) do
        local p = ESX.GetPlayerFromId(playerId)
    end
        for _, playerId in pairs(ESX.GetPlayers()) do
        local xStaff = ESX.GetPlayerFromId(playerId)
        if xStaff and STAFF_GROUPS[xStaff.getGroup()] then
            TriggerClientEvent("esx:showNotification",playerId,"~r~🔔 Nouveau report reçu")
        end
    end
    TriggerClientEvent("admin:updateReportList", -1, reports)
end)

RegisterServerEvent("admin:requestReportsList")
AddEventHandler("admin:requestReportsList", function()
    local src = source
    TriggerClientEvent("admin:updateReportList", src, reports)
end)

RegisterServerEvent("admin:assignReport")
AddEventHandler("admin:assignReport", function(id)
    local src = source
    local xAdmin = ESX.GetPlayerFromId(src)
    if not xAdmin then return end
    if not reports[id] then return end
    if reports[id].status ~= "Ouvert" then
        TriggerClientEvent("esx:showNotification",src,"~r~Ce report est déjà pris en charge")
        return
    end
    reports[id].status = "~g~Pris en charge"
    reports[id].prisencharge = xAdmin.getName()
    reports[id].prisenchargeId = src
    TriggerClientEvent("admin:updateReportList", -1, reports)
    LogAdminAction("report", {
    staffId = src,
    targetId = targetId,
    title = "📜 Report pris",
    description =
        "**Staff :** "..xAdmin.getName() ..
        "\n**Report ID :** "..id
        
})
end)


RegisterServerEvent("admin:resolveReport")
AddEventHandler("admin:resolveReport", function(id)
    local src = source
    local xAdmin = ESX.GetPlayerFromId(src)
    if not xAdmin then return end
    if not reports[id] then return end
    if reports[id].prisenchargeId ~= src then
        TriggerClientEvent("esx:showNotification",src,"~r~Tu ne peux pas clôturer un report qui ne t'est pas assigné")
        return
    end
    reports[id] = nil
    TriggerClientEvent("admin:updateReportList", -1, reports)
    TriggerClientEvent("esx:showNotification",src,"~g~Report clôturé et supprimé")
    LogAdminAction("report", {
    title = "📜 Report clôturé",
    staffId = src,
    targetId = targetId,
    description =
        "**Staff :** "..xAdmin.getName() ..
        "\n**Report ID :** "..id
})
end)
RegisterServerEvent("admin:replyReport")
AddEventHandler("admin:replyReport", function(targetId, reportId, msg)
    local src = source
    local xAdmin = ESX.GetPlayerFromId(src)
    if not xAdmin then return end
    TriggerClientEvent('esx:showNotification', targetId, "~b~Réponse admin: ~s~"..msg)
end)

RegisterServerEvent("admin:getPlayerInfos")
AddEventHandler("admin:getPlayerInfos", function(targetId)
    local src = source
    local xAdmin = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)

    if not xAdmin or not xTarget then return end

    local infos = {
        id = targetId,
        name = xTarget.getName(),
        job = xTarget.job.label,
        grade = xTarget.job.grade_label,
        cash = xTarget.getMoney(),
        bank = xTarget.getAccount('bank').money,
        black = xTarget.getAccount('black_money').money
    }

    TriggerClientEvent("admin:receivePlayerInfos", src, infos)
end)

RegisterServerEvent("admin:getPlayerInventory")
AddEventHandler("admin:getPlayerInventory", function(targetId)
    local src = source
    local xAdmin = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)

    if not xAdmin or not xTarget then return end

    local inventory = {}

    for _, item in pairs(xTarget.inventory) do
        if item.count > 0 then
            table.insert(inventory, {
                name = item.name,
                label = item.label,
                count = item.count
            })
        end
    end

    TriggerClientEvent("admin:receivePlayerInventory", src, inventory)
end)

RegisterServerEvent("admin:managePlayerMoney")
AddEventHandler("admin:managePlayerMoney", function(targetId, moneyType, actionIndex, amount)
    local src = source
    local xAdmin = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xAdmin or not xTarget then return end
    if not amount or amount <= 0 then return end
    local isAdd = (actionIndex == 1)
    if moneyType == "cash" then
        if isAdd then
            xTarget.addMoney(amount)
        else
            xTarget.removeMoney(amount)
        end
        TriggerClientEvent("admin:updatePlayerMoney", src, "cash", xTarget.getMoney())
    elseif moneyType == "bank" then
        if isAdd then
            xTarget.addAccountMoney("bank", amount)
        else
            xTarget.removeAccountMoney("bank", amount)
        end

        TriggerClientEvent("admin:updatePlayerMoney",src,"bank",xTarget.getAccount("bank").money)
    elseif moneyType == "black" then
        if isAdd then
            xTarget.addAccountMoney("black_money", amount)
        else
            xTarget.removeAccountMoney("black_money", amount)
        end
        TriggerClientEvent("admin:updatePlayerMoney",src,"black",xTarget.getAccount("black_money").money)
    end
    local actionLabel = (actionIndex == 1) and "AJOUT" or "RETRAIT"

        LogAdminAction("money", {
            title = "💰 Gestion Argent",
                staffId = src,
            targetId = targetId,
            description =
                "**Staff :** "..xAdmin.getName().." (ID "..src..")" ..
                "\n**Joueur :** "..xTarget.getName().." (ID "..targetId..")" ..
                "\n**Type :** "..moneyType ..
                "\n**Action :** "..(actionIndex == 1 and "AJOUT" or "RETRAIT") ..
                "\n**Montant :** $"..amount
        })
end)

RegisterServerEvent("admin:removePlayerItem")
AddEventHandler("admin:removePlayerItem", function(targetId, itemName, count)
    local src = source
    local xAdmin = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)

    if not xAdmin or not xTarget then return end
    if not itemName or count <= 0 then return end

    local item = xTarget.getInventoryItem(itemName)
    if not item or item.count <= 0 then return end

    if count > item.count then
        count = item.count
    end

    xTarget.removeInventoryItem(itemName, count)
    TriggerClientEvent("admin:receivePlayerInventory", src, (function()
        local inv = {}
        for _, it in pairs(xTarget.inventory) do
            if it.count > 0 then
                table.insert(inv, {name = it.name,label = it.label,count = it.count})
            end
        end
        return inv
    end)())

    TriggerClientEvent("esx:showNotification",src,"~g~Item retiré"
)
LogAdminAction("inventory", {
    title = "📦 Retrait Item",
        staffId = src,
    targetId = targetId,
    description =
        "**Staff :** "..xAdmin.getName().." (ID "..src..")" ..
        "\n**Joueur :** "..xTarget.getName().." (ID "..targetId..")" ..
        "\n**Item :** "..itemName ..
        "\n**Quantité :** "..count
})
end)

RegisterServerEvent("admin:sendSimpleAnnouncement")
AddEventHandler("admin:sendSimpleAnnouncement", function(message)
    local src = source
    local xAdmin = ESX.GetPlayerFromId(src)
    if not xAdmin then return end
    if not message or message == "" then return end
    TriggerClientEvent("admin:showCenterAnnouncement", -1, message)
    LogAdminAction("admin", {
        title = "📢 Annonce serveur",
        staffId = src,
        description = "**Message :**\n" .. message
    })
end)

RegisterServerEvent("admin:gotoPlayer")
AddEventHandler("admin:gotoPlayer", function(targetId)
    local src = source
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end

    local coords = xTarget.getCoords(true)
    TriggerClientEvent("admin:teleport", src, coords)
end)

RegisterServerEvent("admin:bringPlayer")
AddEventHandler("admin:bringPlayer", function(targetId)
    local src = source
    local xAdmin = ESX.GetPlayerFromId(src)
    if not xAdmin then return end

    local coords = xAdmin.getCoords(true)
    TriggerClientEvent("admin:teleport", targetId, coords)
end)

RegisterNetEvent("admin:getOnlinePlayers")
AddEventHandler("admin:getOnlinePlayers", function()
    local src = source
    local list = {}

    for _, playerId in ipairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            table.insert(list, {
                id = tonumber(playerId),
                name = xPlayer.getName(),
                group = xPlayer.getGroup()
            })
        end
    end

    TriggerClientEvent("admin:receiveOnlinePlayers", src, list)
end)