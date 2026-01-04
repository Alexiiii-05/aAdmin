ESX = nil
Citizen.CreateThread(function()  while ESX == nil do ESX = exports["es_extended"]:getSharedObject() while ESX.GetPlayerData().job == nil do Wait(10) end PlayerData = ESX.GetPlayerData()Citizen.Wait(50) end end)
local vehicleDeleteActive = false
local vehicleTarget = nil
local itemSearch = ""
local arrowColors = {"~r~",  "~o~",  "~y~",  "~g~",  "~c~",  "~b~",  "~p~",  "~m~",  "~w~",}
local vehicleColors = {{label = "Noir", id = 0},{label = "Blanc", id = 111},{label = "Rouge", id = 27},{label = "Bleu", id = 64},{label = "Vert", id = 55},{label = "Jaune", id = 88},{label = "Orange", id = 38},{label = "Violet", id = 145},{label = "Rose", id = 135},{label = "Gris", id = 4},}
local selectedColorIndex = 1
local arrowIndex = 1
local itemList = {}
local isMenuOpen = false
local staffMode = false
local showNames = false
local invisbilty = false
local godmode = false
local noclip = false
local noclipSpeed = 1.5
local nameDistance = 150.0
local playerCount = 1
local staffCount = 1
local reportsCount = 0
local showCoords = false
local showPlayerBlips = false
local playerBlips = {}
local search = ""
local selectedPlayer = nil
local frozen = false
local playerInfos = nil
local playerInventory = nil
local reportsList = {} 
local selectedReport = nil
local moneyActions = { "~g~Ajouter~s~", "~r~Retirer~s~" }
local cashIndex = 1
local bankIndex = 1
local blackIndex = 1
local savedSkin = nil
local onlinePlayers = {}
local STAFF_GROUPS = {mod = true, admin = true,superadmin = true}
local enlignePlayers = 0
local onlineStaff = 0

RegisterNetEvent("admin:receiveOnlinePlayers")
AddEventHandler("admin:receiveOnlinePlayers", function(list)
    onlinePlayers = list
end)

local StaffOutfitMale = {
    tshirt_1 = 15, tshirt_2 = 0,
    torso_1 = 178, torso_2 = 0,
    arms = 31,
    pants_1 = 77, pants_2 = 0,
    shoes_1 = 55, shoes_2 = 0,
    chain_1 = 0, chain_2 = 0
}

local StaffOutfitFemale = {
    tshirt_1 = 15, tshirt_2 = 0,
    torso_1 = 180, torso_2 = 0,
    arms = 31,
    pants_1 = 79, pants_2 = 0,
    shoes_1 = 58, shoes_2 = 0,
    chain_1 = 0, chain_2 = 0
}

RegisterNetEvent("admin:receivePlayerCounts")
AddEventHandler("admin:receivePlayerCounts", function(players, staff)
    enlignePlayers = players
    onlineStaff = staff
end)

CreateThread(function()
    while true do
        TriggerServerEvent("admin:getPlayerCounts")
        Wait(5000)
    end
end)

function EnableStaffMode()
    TriggerEvent('skinchanger:getSkin', function(skin)
        savedSkin = skin
        if skin.sex == 0 then
            TriggerEvent('skinchanger:loadClothes', skin, StaffOutfitMale)
        else
            TriggerEvent('skinchanger:loadClothes', skin, StaffOutfitFemale)
        end

        TriggerServerEvent('esx_skin:save', skin)
    end)
    ESX.ShowNotification("~g~Service staff activé")
end

function DisableStaffMode()
    if savedSkin then
        TriggerEvent('skinchanger:loadSkin', savedSkin)
        TriggerServerEvent('esx_skin:save', savedSkin)
        savedSkin = nil
    end
    ESX.ShowNotification("~r~Service staff désactivé")
end

local function PlacePlayerOnGround(ped)
    local coords = GetEntityCoords(ped)

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    local timeout = GetGameTimer() + 2000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do
        Wait(0)
    end

    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 100.0)
    if found then
        SetEntityCoords(ped, coords.x, coords.y, groundZ + 0.2)
    end
end

function EnableNoClip()
    local ped = PlayerPedId()
    noclip = true
    SetEntityCollision(ped, false, false)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
end

function DisableNoClip()
    local ped = PlayerPedId()
    noclip = false
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, true)
    PlacePlayerOnGround(ped)
    Wait(100)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, false)
end

AddEventHandler("onClientPlayerDropped", function(playerId)
    if playerBlips[playerId] then
        if DoesBlipExist(playerBlips[playerId]) then
            RemoveBlip(playerBlips[playerId])
        end
        playerBlips[playerId] = nil
    end
end)

function KeyboardInput(text, example, max)
    AddTextEntry("FMMC_KEY_TIP1", text)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", example or "", "", "", "", max or 64)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Wait(0)
    end
    if UpdateOnscreenKeyboard() == 1 then
        local result = GetOnscreenKeyboardResult()
        return result
    end
    return nil
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
        SetTextCentre(true)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(_x, _y)
    end
end

function ToggleNoClip()
    local ped = PlayerPedId()
    noclip = not noclip

    if noclip then
        SetEntityInvincible(ped, true)
        SetEntityVisible(ped, false, false)
        FreezeEntityPosition(ped, true)
        ESX.ShowNotification("~g~NoClip activé")
    else
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, false)
        FreezeEntityPosition(ped, false)
        ESX.ShowNotification("~r~NoClip désactivé")
    end
end

local function NoClipMovement()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local camDir = GetGameplayCamDirection()
    if IsControlPressed(0, 32) then  
        coords = coords + camDir * noclipSpeed
    end
    if IsControlPressed(0, 33) then  
        coords = coords - camDir * noclipSpeed
    end
    if IsControlPressed(0, 22) then  
        coords = coords + vector3(0, 0, noclipSpeed)
    end
    if IsControlPressed(0, 36) then 
        coords = coords - vector3(0, 0, noclipSpeed)
    end

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, true, true, true)
end
function GetGameplayCamDirection()
    local rot = GetGameplayCamRot(2)
    local rad = math.rad(rot.z)
    local pitch = math.rad(rot.x)

    local dirX = -math.sin(rad) * math.cos(pitch)
    local dirY = math.cos(rad) * math.cos(pitch)
    local dirZ = math.sin(pitch)

    return vector3(dirX, dirY, dirZ)
end

function InvisibilityStaff()
    invisible = not invisible
    local ped = GetPlayerPed(-1)
    
    if invisible then 
          SetEntityVisible(ped, false, false)
      else
          SetEntityVisible(ped, true, false)
    end
end

function GodmodeStaff()
    godmode = not godmode
    local ped = GetPlayerPed(-1)
    
    if godmode then
          SetEntityInvincible(ped, true)
      else
        SetEntityInvincible(ped, false)
    end
end

function TpMarker()
    local playerPed = GetPlayerPed(-1)
    local WaypointHandle = GetFirstBlipInfoId(8)
    if DoesBlipExist(WaypointHandle) then
        local coord = Citizen.InvokeNative(0xFA7C7F0AADF25D09, WaypointHandle, Citizen.ResultAsVector())
        SetEntityCoordsNoOffset(playerPed, coord.x, coord.y, -199.5, false, false, false, true)
        ESX.ShowNotification("~g~Tp marqueur effectué avec succès")
    else
        ESX.ShowNotification("~r~Aucun marqueur placé")        
    end
end

CreateThread(function()
    while true do
        if not noclip then
            Wait(500)
        else
            local ped = PlayerPedId()
            SetEntityCollision(ped, false, false)
            NoClipMovement()
            if IsControlJustPressed(0, 15) then
                noclipSpeed = noclipSpeed + 0.5
            elseif IsControlJustPressed(0, 14) then
                noclipSpeed = math.max(0.5, noclipSpeed - 0.5)
            end
            DisableControlAction(0, 37, true)

            Wait(0)
        end
    end
end)

CreateThread(function()
    while true do
        arrowIndex = arrowIndex + 1
        if arrowIndex > #arrowColors then arrowIndex = 1 end
        Wait(500)
    end
end)

function AnimatedArrow()
    return arrowColors[arrowIndex]
end

RMenu.Add('admin', 'main', RageUI.CreateMenu("Administration", "Menu administratif"))
RMenu:Get('admin', 'main'):SetRectangleBanner(0, 0, 0, 200) 
RMenu.Add('admin', 'assist', RageUI.CreateSubMenu(RMenu:Get('admin', 'main'), "Assistance", "Options d'assistance"))
RMenu:Get('admin', 'assist'):SetRectangleBanner(0, 0, 0, 200)
RMenu.Add('admin', 'reportOptions', RageUI.CreateSubMenu(RMenu:Get('admin', 'assist'), "Report", "Actions report"))
RMenu:Get('admin', 'reportOptions'):SetRectangleBanner(0, 0, 0, 200)
RMenu.Add('admin', 'perso', RageUI.CreateSubMenu(RMenu:Get('admin', 'main'), "Personnel", "Options personnelles"))
RMenu:Get('admin', 'perso'):SetRectangleBanner(0, 0, 0, 200)
RMenu.Add('admin', 'players', RageUI.CreateSubMenu(RMenu:Get('admin', 'main'), "Joueurs", "Liste des joueurs connectés"))
RMenu:Get('admin', 'players'):SetRectangleBanner(0, 0, 0, 200)
RMenu.Add('admin', 'playerOptions', RageUI.CreateSubMenu(RMenu:Get('admin', 'players'), "Gestion", "Options joueur"))
RMenu:Get('admin', 'playerOptions'):SetRectangleBanner(0, 0, 0, 200)
RMenu.Add('admin', 'playerInfos', RageUI.CreateSubMenu(RMenu:Get('admin', 'playerOptions'),"Informations joueur","Détails du joueur"))
RMenu:Get('admin', 'playerInfos'):SetRectangleBanner(0, 0, 0, 200)
RMenu.Add('admin', 'PlayerInventory', RageUI.CreateSubMenu(RMenu:Get('admin', 'playerOptions'),"Inventaire ","Inventaire du joueur"))
RMenu:Get('admin', 'PlayerInventory'):SetRectangleBanner(0, 0, 0, 200)
RMenu.Add('admin', 'removeItem', RageUI.CreateSubMenu(RMenu:Get('admin', 'playerOptions'),"Retirer un item","Gestion inventaire"))
RMenu:Get('admin', 'removeItem'):SetRectangleBanner(0, 0, 0, 200)
RMenu.Add('admin', 'listeitems', RageUI.CreateSubMenu(RMenu:Get('admin', 'playerOptions'), "Remboursement", "Liste des items"))
RMenu:Get('admin', 'listeitems'):SetRectangleBanner(0, 0, 0, 200)
RMenu.Add('admin', 'vehicle', RageUI.CreateSubMenu(RMenu:Get('admin', 'main'), "Gestion véhicule", "Actions véhicules"))
RMenu:Get('admin', 'vehicle'):SetRectangleBanner(0, 0, 0, 200)

RegisterNetEvent("admin:receiveAllItems")
AddEventHandler("admin:receiveAllItems", function(items)
    itemList = items
end)

function OpenAdminMenu()
    if isMenuOpen then
        isMenuOpen = false
         if not RageUI.Visible(RMenu:Get('admin', 'main')) then
                isMenuOpen = false
        end
        RageUI.Visible(RMenu:Get('admin', 'main'), false)
        return
    else
        isMenuOpen = true
        RageUI.Visible(RMenu:Get('admin', 'main'), true)
        TriggerServerEvent("admin:requestSync")
        TriggerServerEvent("admin:requestReportsList")
        TriggerServerEvent("admin:getOnlinePlayers")
        CreateThread(function()
            while isMenuOpen do
                vehicleDeleteActive = false
                RageUI.IsVisible(RMenu:Get('admin', 'main'), function()
                    RageUI.Separator("Joueurs Connectés: ~g~"..enlignePlayers)
                    RageUI.Separator("Staff en ligne: ~r~"..onlineStaff)
                    RageUI.Checkbox("Activer le Staff Mode", nil, staffMode, {}, {
                        onChecked = function()
                            staffMode = true
                            EnableStaffMode()
                        end,
                        onUnChecked = function()
                            staffMode = false
                            showNames = false
                            vehicleDeleteActive = false
                            DisableNoClip()
                            godmode = false
                            showCoords = false
                            showPlayerBlips = false
                            DisableStaffMode()
                            SetEntityInvincible(PlayerPedId(), false)
                            SetEntityVisible(PlayerPedId(), true, false)
                            FreezeEntityPosition(PlayerPedId(), false)
                        end
                    })
                    if staffMode  then
                            RageUI.Separator("↓ Gestion serveur ↓")
                        RageUI.Button(AnimatedArrow().."→ ~s~Gestion report (~y~"..tostring(reportsCount).."~s~)", nil, {RightLabel = "→→"}, true, {}, RMenu:Get('admin', 'assist'))
                        RageUI.Button(AnimatedArrow().."→ ~s~Gestion Joueurs", nil, {RightLabel = "→→"}, true, {}, RMenu:Get('admin', 'players'))
                        RageUI.Button(AnimatedArrow().."→ ~s~Gestion véhicule", nil, {RightLabel = "→→"}, true, {}, RMenu:Get('admin', 'vehicle'))
                            RageUI.Separator("↓ Autres ↓")
                            RageUI.Button(AnimatedArrow().."→ ~s~Annonce Serveur",nil,{RightLabel = "→→"},true, {
                                onSelected = function()
                                    local msg = KeyboardInput("Annonce serveur","",200)
                                    if msg and msg ~= "" then
                                        TriggerServerEvent("admin:sendSimpleAnnouncement", msg)
                                    else 
                                        ESX.ShowNotification("~r~Veuillez introduire une annonce valide")
                                    end
                                end
                            })
                                        
                        RageUI.Button(AnimatedArrow().."→ ~s~Personnel", nil, {RightLabel = "→→"}, true, {}, RMenu:Get('admin', 'perso'))
                    else
                        RageUI.Separator("~r~Veuillez activer le Staff Mode")
                        RageUI.Separator("~r~pour accéder aux options.")
                    end

                end)
                RageUI.IsVisible(RMenu:Get('admin', 'assist'), function()
                    if reportsCount == 0 then 
                           RageUI.Separator("")RageUI.Separator(AnimatedArrow().." Aucun report")RageUI.Separator("")
                    else

                    RageUI.Separator("Reports en attente : ~r~" .. tonumber(reportsCount or 0))
                    if next(reportsList) ~= nil then
                        local ordered = {}
                        for id, r in pairs(reportsList) do
                            table.insert(ordered, r)
                        end
                        table.sort(ordered, function(a,b)
                            if a.status == b.status then
                                return a.id < b.id
                            end
                            local order = { Ouvert = 1, prisencharge = 2, resolved = 3 }
                            return (order[a.status] or 99) < (order[b.status] or 99)
                        end)

                        for _, r in ipairs(ordered) do
                            local colorPref = "~g~"
                            if r.status == AnimatedArrow().."Pris en charge" then colorPref = "~o~" end
                            if r.status == "resolved" then colorPref = "~g~" end

                            local label = colorPref .. "[" .. tostring(r.id) .. "] " .. r.name .. " (ID:" .. tostring(r.playerId) .. ")"
                            local desc = ""
                            if selectedReport == r.id then
                                desc = r.msg ..
                                    "\n~c~Heure: ~s~" .. tostring(r.time)

                                if r.prisencharge then
                                    desc = desc .. "\n~c~Pris par: ~s~" .. tostring(r.prisencharge)
                                end

                                desc = desc .. "\n~c~Statut: ~s~" .. tostring(r.status)
                            end
                            RageUI.Button(label, desc, { RightLabel = r.prisencharge and AnimatedArrow().."pris par "..tostring(r.prisencharge) or "" }, true, {
                                onSelected = function()
                                    selectedReport = r.id
                                end
                            }, RMenu:Get('admin', 'reportOptions'))
                        end
                    else
                        RageUI.Separator("~r~Aucun report.")
                        end
                    end
                end)

                RageUI.IsVisible(RMenu:Get('admin', 'reportOptions'), function()
                    if not selectedReport or not reportsList[selectedReport] then
                        RageUI.Separator("~r~Report introuvable.")
                        return
                    end

                    local r = reportsList[selectedReport]

                    RageUI.Separator("Report ID: ~b~" .. tostring(r.id) .. " ~s~par ~b~" .. tostring(r.name))
                    RageUI.Separator("Heure: ~g~" .. tostring(r.time))
                    RageUI.Separator("Statut: ~s~" .. tostring(r.status) .. (r.prisencharge and (" par ".. tostring(r.prisencharge)) or ""))
                    RageUI.Separator(AnimatedArrow().."→~s~ Message: ~o~".. tostring(r.msg))
                    RageUI.Button("→ Prendre le report",r.prisencharge and ("~c~Pris par "..r.prisencharge) or "Prendre en charge ce report",{},r.status == "Ouvert",{
                            onSelected = function()
                                TriggerServerEvent("admin:assignReport", tonumber(r.id))
                            end
                        }
                    )
                    RageUI.Button("→ Clôturer ce report","Supprimer définitivement ce report",{},r.status == "~g~Pris en charge" and r.prisenchargeId == GetPlayerServerId(PlayerId()),{
                            onSelected = function()
                                TriggerServerEvent("admin:resolveReport", tonumber(r.id))
                                selectedReport = nil
                                RageUI.GoBack()
                            end
                        }
                    )
                    RageUI.Button("→ TP au joueur",r.status ~= "~g~Pris en charge" and "~r~Le report doit être pris en charge" or "Se téléporter au joueur",{},r.status == "~g~Pris en charge",{
                            onSelected = function()
                             
                                TriggerServerEvent("admin:gotoPlayer", tonumber(r.playerId))
                            end
                        }
                    )

                    RageUI.Button("→ Répondre au joueur",r.status ~= "~g~Pris en charge" and "~r~Le report doit être pris en charge" or "Envoyer un message au joueur",{},r.status == "~g~Pris en charge",{
                        onSelected = function()
                            local answer = KeyboardInput("Message pour le joueur (vide = annuler)", "", 140)
                            if answer and answer ~= "" then
                                TriggerServerEvent("admin:replyReport", tonumber(r.playerId), tonumber(r.id), answer)
                                ESX.ShowNotification("~g~Réponse envoyée au joueur.")
                            end
                        end
                        }
                    )
                end)
                
            RageUI.IsVisible(RMenu:Get('admin', 'perso'), function()
                RageUI.Separator("~o~↓~s~ Actions Perso ~o~↓")
                RageUI.Checkbox(AnimatedArrow().."→~s~ NoClip", nil, noclip, {}, {
                    onChecked = function()
                        EnableNoClip()
                    end,
                    onUnChecked = function()
                        DisableNoClip()
                    end
                })

                RageUI.Checkbox(AnimatedArrow().."→~s~ Afficher les noms", nil, showNames, {}, {
                    onChecked = function()
                        showNames = true
                        ESX.ShowNotification("~g~Affichage des noms activé")
                    end,
                    onUnChecked = function()
                        showNames = false
                        ESX.ShowNotification("~r~Affichage des noms désactivé")
                    end
                })

                    RageUI.Checkbox(AnimatedArrow().."→~s~ Invisibilité", nil, invisbilty, {}, {
                    onChecked = function()
                        InvisibilityStaff()
                        invisbilty = true
                        ESX.ShowNotification("~g~Invisibilité activé")
                    end,
                    onUnChecked = function()
                        InvisibilityStaff()
                        invisbilty = false
                        ESX.ShowNotification("~r~Invisibilité désactivé")
                    end
                })

                RageUI.Button(AnimatedArrow().."→~s~ TP sur le marqueur", nil, {RightLabel = "→→"}, true, {
                    onSelected = function()
                        TpMarker()
                    end
                })
                RageUI.Checkbox(AnimatedArrow().."→~s~ GodMode", nil, godmode, {}, {
                    onChecked = function()
                        GodmodeStaff()
                        godmode = true
                        ESX.ShowNotification("~g~GodMode activé")
                    end,
                    onUnChecked = function()
                        GodmodeStaff()
                        godmode = false
                        ESX.ShowNotification("~r~GodMode désactivé")
                    end
                })

                RageUI.Separator("~r~↓~s~ Actions Serveur ~r~↓")
                RageUI.Checkbox(AnimatedArrow().."→~s~ Afficher coordonnées","Afficher vos coordonnées en temps réel",showCoords,{},{
                        onChecked = function()
                            showCoords = true
                        end,
                        onUnChecked = function()
                            showCoords = false
                        end
                    }
                )
                RageUI.Checkbox(AnimatedArrow().."→~s~ Afficher blips joueurs","Afficher les blips de tous les joueurs sur la carte",showPlayerBlips,{},{
                        onChecked = function()
                            showPlayerBlips = true
                        end,
                        onUnChecked = function()
                            showPlayerBlips = false
                            for _, blip in pairs(playerBlips) do
                                if DoesBlipExist(blip) then
                                    RemoveBlip(blip)
                                end
                            end
                            playerBlips = {}
                        end
                    }
                )
            end)

                RageUI.IsVisible(RMenu:Get('admin', 'players'), function()
                    RageUI.Button("🔍 Recherche : " .. (search ~= "" and search or "tous"), nil, {}, true, {
                        onSelected = function()
                            local input = KeyboardInput("Nom du joueur (vide pour annuler)", "", 25)
                            if input ~= nil then
                                search = input
                            end
                        end
                    })

                    RageUI.Separator("Liste triée : ~g~Staff~s~ "..AnimatedArrow().."→~s~ Joueurs")
                    local list = {}
                    for _, p in ipairs(onlinePlayers) do
                        table.insert(list, {
                            serverId = p.id,
                            name = p.name,
                            group = p.group
                        })
                    end
                        table.sort(list, function(a, b)
                            local aStaff = STAFF_GROUPS and STAFF_GROUPS[a.group]
                            local bStaff = STAFF_GROUPS and STAFF_GROUPS[b.group]

                            if aStaff ~= bStaff then
                                return aStaff and not bStaff
                            end
                            return string.lower(a.name) < string.lower(b.name)
                        end)
                        for _, d in ipairs(list) do
                        if search == "" or string.find(string.lower(d.name), string.lower(search)) then
                            local isStaff = STAFF_GROUPS and STAFF_GROUPS[d.group]
                            local colorPrefix = isStaff and "~g~" or "~s~"
                            local tag = isStaff and "⭐ " or AnimatedArrow().."• ~s~"
                            local rightLabel = isStaff and "~g~STAFF" or "~s~USER"

                            RageUI.Button(colorPrefix .. tag .. d.name .. " ~c~(ID: ~y~" .. d.serverId .. "~c~)",nil,{ RightLabel = rightLabel },true,{
                                    onSelected = function()
                                        selectedPlayer = d
                                    end
                            },RMenu:Get('admin', 'playerOptions'))
                        end
                    end
                end)
                RageUI.IsVisible(RMenu:Get('admin', 'playerOptions'), function()
                    if not selectedPlayer then
                        RageUI.Separator("Aucun joueur sélectionné")
                        return
                    end
                    RageUI.Separator("Gestion de : ~b~" .. selectedPlayer.name)
                    RageUI.Separator("ID : ~b~" .. selectedPlayer.serverId)

                    RageUI.Button("→ TP à lui", nil, {}, true, {
                        onSelected = function()
                            TriggerServerEvent("admin:gotoPlayer", tonumber(selectedPlayer.serverId))
                        end
                    })

                    RageUI.Button("→ TP lui à toi", nil, {}, true, {
                        onSelected = function()
                            TriggerServerEvent("admin:bringPlayer", tonumber(selectedPlayer.serverId))
                        end
                    })

                    RageUI.Button("→ Freeze / Unfreeze", nil, {}, true, {
                        onSelected = function()
                            TriggerServerEvent("admin:toggleFreeze", tonumber(selectedPlayer.serverId))
                        end
                    }) 

                    RageUI.Button("→ Kick", nil, {}, true, {
                        onSelected = function()
                            local reason = KeyboardInput("Motif du kick (vide = sans motif)", "", 100) or "Aucun motif"
                            TriggerServerEvent("admin:kick", tonumber(selectedPlayer.serverId), reason)
                        end
                    })

                    RageUI.Button("→ Ban", nil, {}, true, {
                        onSelected = function()
                        local days = KeyboardInput("Durée du banissement (en heures)", "", 20, true)
                            if days ~= nil then
                                local reason = KeyboardInput("Raison", "", 80, false)
                                if reason ~= nil then
                                    ESX.ShowNotification("~y~Application de la sanction en cours...")
                                    ExecuteCommand(("sqlban %s %s %s"):format(selectedPlayer, days, reason))
                                end
                            end
                        end
                    })

                    RageUI.Separator("~g~↓~s~ Options avancées ~g~↓")
                    RageUI.Button(AnimatedArrow().."→ ~s~ Informations supplémentaires","Voir les informations détaillées du joueur",{},true,{
                        onSelected = function()
                            playerInfos = nil
                            TriggerServerEvent("admin:getPlayerInfos", selectedPlayer.serverId)
                        end
                    },RMenu:Get('admin', 'playerInfos'))
                    RageUI.Button(AnimatedArrow().."→ ~s~ Voir l'inventaire","Afficher l'inventaire du joueur",{},true,{
                        onSelected = function()
                            playerInventory = nil
                            TriggerServerEvent("admin:getPlayerInventory", selectedPlayer.serverId)
                        end
                    },RMenu:Get('admin', 'PlayerInventory'))

                    RageUI.Button(AnimatedArrow().."→~s~ remboursement (Items)", nil, {RightLabel = nil}, true, {
                        onSelected = function()
                            TriggerServerEvent("admin:getAllItems")
                        end
                    },RMenu:Get('admin', 'listeitems'))
                end)

                RageUI.IsVisible(RMenu:Get('admin', 'vehicle'), function()
                    
                    RageUI.Separator("↓ Gestion des véhicules ↓")
                    RageUI.Button(AnimatedArrow().."→~s~ Supprimer un véhicule","Regarde un véhicule puis appuie sur ~b~ENTRÉE",{},true,{
                            onActive = function()
                                vehicleDeleteActive = true
                            end,
                            onSelected = function()
                                if vehicleTarget and DoesEntityExist(vehicleTarget) then
                                    ESX.ShowNotification("~g~Véhicule supprimé")
                                    DeleteEntity(vehicleTarget)
                                else
                                    ESX.ShowNotification("~r~Aucun véhicule ciblé")
                                end
                            end,
                            onHovered = function()
                                vehicleDeleteActive = true
                            end,
                            onLeft = function()
                                vehicleDeleteActive = false
                                vehicleTarget = nil
                            end
                        }
                    )
                        RageUI.Button(AnimatedArrow().."→~s~ Réparer le véhicule","Regarde un véhicule puis appuie sur ~b~ENTRÉE",{},true,{
                            onActive = function()
                                vehicleDeleteActive = true 
                            end,
                            onSelected = function()
                                if vehicleTarget and DoesEntityExist(vehicleTarget) then
                                    SetVehicleFixed(vehicleTarget)
                                    SetVehicleDeformationFixed(vehicleTarget)
                                    SetVehicleEngineHealth(vehicleTarget, 1000.0)
                                    SetVehicleBodyHealth(vehicleTarget, 1000.0)
                                    SetVehiclePetrolTankHealth(vehicleTarget, 1000.0)
                                    ESX.ShowNotification("~g~Véhicule réparé")
                                else
                                    ESX.ShowNotification("~r~Aucun véhicule ciblé")
                                end
                            end,
                            onLeft = function()
                                vehicleDeleteActive = false
                                vehicleTarget = nil
                            end
                        }
                    )
                    local vehicleDetected = (vehicleTarget ~= nil and DoesEntityExist(vehicleTarget))
                        if vehicleDetected then

                    RageUI.List(AnimatedArrow().."→~s~ Couleur du véhicule",(function()
                            local labels = {}
                            for _, c in ipairs(vehicleColors) do
                                labels[#labels+1] = c.label
                            end
                            return labels
                        end)(),selectedColorIndex,vehicleDetected and "Choisis une couleur puis appuie sur ~b~ENTRÉE"or "~r~Aucun véhicule détecté",{},vehicleDetected,{
                            onListChange = function(index)
                                selectedColorIndex = index
                            end,
                            onSelected = function()
                                if vehicleDetected then
                                    local colorId = vehicleColors[selectedColorIndex].id
                                    SetVehicleColours(vehicleTarget, colorId, colorId)
                                    ESX.ShowNotification("~g~Couleur appliquée")
                                end
                            end
                        }
                    )
                else
                    RageUI.Button(AnimatedArrow().."→~s~ Couleur du véhicule", false, {})
                end
            end)

                RageUI.IsVisible(RMenu:Get('admin', 'playerInfos'), function()

                    if not playerInfos then
                        RageUI.Separator("~c~Chargement des informations...")
                        return
                    end

                    RageUI.Separator(AnimatedArrow().."↓~s~ Identié "..AnimatedArrow().."↓")
                    RageUI.Separator("Nom : "..playerInfos.name)
                    RageUI.Separator(AnimatedArrow().."↓~s~ Métier "..AnimatedArrow().."↓")
                    RageUI.Separator("Job : "..playerInfos.job)
                    RageUI.Separator("Grade : "..playerInfos.grade)
                    RageUI.Separator(AnimatedArrow().."↓~s~ Finances "..AnimatedArrow().."↓")
                    RageUI.List("Liquide : ~g~$" .. playerInfos.cash,moneyActions,cashIndex,"Gérer l'argent liquide",{},true,{
                            onListChange = function(index)
                                cashIndex = index
                            end,
                            onSelected = function()
                                local amount = KeyboardInput(moneyActions[cashIndex] .. " de l'argent liquide","",8)
                                amount = tonumber(amount)
                                if not amount or amount <= 0 then return end
                                TriggerServerEvent("admin:managePlayerMoney",selectedPlayer.serverId,"cash",cashIndex,amount)
                            end
                        }
                    )
                    RageUI.List("Banque : ~b~$" .. playerInfos.bank,moneyActions,bankIndex,"Gérer l'argent en banque",{},true,{
                            onListChange = function(index)
                                bankIndex = index
                            end,
                            onSelected = function()
                                local amount = KeyboardInput(moneyActions[bankIndex] .. " de l'argent en banque","",8)
                                amount = tonumber(amount)
                                if not amount or amount <= 0 then return end
                                TriggerServerEvent("admin:managePlayerMoney",selectedPlayer.serverId,"bank",bankIndex,amount)
                            end
                        }
                    )
                    RageUI.List("Argent sale : ~r~$" .. playerInfos.black,moneyActions,blackIndex,"Gérer l'argent sale",{},true,{
                            onListChange = function(index)
                                blackIndex = index
                            end,
                            onSelected = function()
                                local amount = KeyboardInput(moneyActions[blackIndex] .. " de l'argent sale","",8)
                                amount = tonumber(amount)
                                if not amount or amount <= 0 then return end
                                TriggerServerEvent("admin:managePlayerMoney",selectedPlayer.serverId,"black",blackIndex,amount)
                            end
                        }
                    )
                end)

                RageUI.IsVisible(RMenu:Get('admin', 'PlayerInventory'), function()

                    if playerInventory then
                        RageUI.Separator("📦 Inventaire du joueur")

                        if #playerInventory == 0 then
                            RageUI.Separator("")
                            RageUI.Separator(AnimatedArrow().."Inventaire vide")
                            RageUI.Separator("")
                        else
                            for _, item in ipairs(playerInventory) do
                                RageUI.Button(AnimatedArrow().."→ ~s~"..item.label .. " (x~o~" .. item.count.."~s~)","Retirer cet item au joueur",{RightLabel = "→→"},true,{
                                    onSelected = function()
                                        selectedItem = item
                                    end
                                },
                                    RMenu:Get('admin', 'removeItem')
                                )
                            end
                        end
                    end
                end)

                RageUI.IsVisible(RMenu:Get('admin', 'removeItem'), function()

                    if not selectedItem then
                        RageUI.Separator("~c~Aucun item sélectionné")
                        return
                    end

                    RageUI.Separator("Item : "..selectedItem.label)
                    RageUI.Separator("Quantité : "..selectedItem.count)

                    RageUI.Button(AnimatedArrow().."→ ~s~Retirer l'item","Supprimer une quantité de cet item",{},true,{
                        onSelected = function()
                            local qty = KeyboardInput("Quantité à retirer", "", 3)
                            qty = tonumber(qty)
                            if not qty or qty <= 0 then return end
                            if qty > selectedItem.count then qty = selectedItem.count end
                            TriggerServerEvent("admin:removePlayerItem",selectedPlayer.serverId,selectedItem.name,qty)
                                selectedItem = nil
                                RageUI.GoBack()
                            end
                        }
                    )
                end)

                    RageUI.IsVisible(RMenu:Get('admin', 'listeitems'), function()

                    RageUI.Button("🔍 Rechercher un item",itemSearch ~= "" and ("Recherche actuelle : ~y~" .. itemSearch) or "Afficher tous les items",{},true,{
                            onSelected = function()
                                local input = KeyboardInput("Nom de l'item (vide = tout afficher)", "", 30)
                                if input ~= nil then
                                    itemSearch = string.lower(input)
                                end
                            end
                        }
                    )
                        RageUI.Separator("↓ ~g~Items disponibles ~s~↓")

                        for _, item in ipairs(itemList) do 
                            if itemSearch == "" or string.find(string.lower(item.label), itemSearch) then 
                            RageUI.Button(AnimatedArrow().."→ ~s~"..item.label,"Nom interne : "..item.name,{RightLabel = "→→"},true,{
                                    onSelected = function()
                                        local qty = tonumber(KeyboardInput("Quantité", "", 5))
                                        if not qty or qty <= 0 then
                                            ESX.ShowNotification("~r~Quantité invalide")
                                            return
                                        end
                                        TriggerServerEvent("admin:refundItem",selectedPlayer.serverId,item.name,qty) 
                                    end
                                }
                            )
                        end
                        end
                    end)
                Wait(0)
            end
        end)
    end
end

RegisterNetEvent("admin:teleport")
AddEventHandler("admin:teleport", function(coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
end)

RegisterCommand("adminmenu", function() TriggerServerEvent("admin:requestOpenMenu") end, false)
RegisterKeyMapping("adminmenu","Ouvrir le menu admin","keyboard","F2")

RegisterNetEvent("admin:openMenu")
AddEventHandler("admin:openMenu", function()
    OpenAdminMenu()
end)

RegisterNetEvent("admin:setStaffList")
AddEventHandler("admin:setStaffList", function(list)
    if type(list) == "table" then
        staffList = list
    end
end)

RegisterNetEvent("admin:updatePlayersData")
AddEventHandler("admin:updatePlayersData", function(data)
    if type(data) == "table" then
        playersData = data
    end
end)

RegisterNetEvent("admin:updateCounts")
AddEventHandler("admin:updateCounts", function(pCount, sCount, reportC)
    playerCount = tonumber(pCount) or playerCount
    staffCount  = tonumber(sCount) or staffCount
    reportsCount = tonumber(reportC) or reportsCount
end)

RegisterNetEvent("admin:updateReportList")
AddEventHandler("admin:updateReportList", function(list)
    if type(list) == "table" then
        reportsList = list
        local cnt = 0
        for k,v in pairs(reportsList) do cnt = cnt + 1 end
        reportsCount = cnt
    end
end)

RegisterNetEvent("admin:tpToClient")
AddEventHandler("admin:tpToClient", function(target)
    local ped = PlayerPedId()
    local targetPlayer = GetPlayerFromServerId(target)
    if targetPlayer ~= nil and targetPlayer ~= -1 then
        local tPed = GetPlayerPed(targetPlayer)
        if tPed and tPed ~= 0 then
            local coords = GetEntityCoords(tPed)
            SetEntityCoords(ped, coords.x, coords.y, coords.z)
            ESX.ShowNotification("~g~Teleporté au joueur.")
        else
            ESX.ShowNotification("~r~Joueur introuvable.")
        end
    end
end)

RegisterNetEvent("admin:receivePlayerInfos")
AddEventHandler("admin:receivePlayerInfos", function(infos)
    playerInfos = infos
end)

RegisterNetEvent("admin:receivePlayerInventory")
AddEventHandler("admin:receivePlayerInventory", function(inventory)
    playerInventory = inventory
end)

RegisterNetEvent("admin:tpHereClient")
AddEventHandler("admin:tpHereClient", function(admin)
    local ped = PlayerPedId()
    local adminPlayer = GetPlayerFromServerId(admin)
    if adminPlayer ~= nil and adminPlayer ~= -1 then
        local aPed = GetPlayerPed(adminPlayer)
        if aPed and aPed ~= 0 then
            local coords = GetEntityCoords(aPed)
            SetEntityCoords(ped, coords.x, coords.y, coords.z)
            ESX.ShowNotification("~g~Vous avez été téléporté.")
        end
    end
end)

RegisterNetEvent("admin:updatePlayerMoney")
AddEventHandler("admin:updatePlayerMoney", function(type, newAmount)
    if not playerInfos then return end
    if type == "cash" then
        playerInfos.cash = newAmount
    elseif type == "bank" then
        playerInfos.bank = newAmount
    elseif type == "black" then
        playerInfos.black = newAmount
    end
end)

RegisterNetEvent("admin:toggleFreezeClient")
AddEventHandler("admin:toggleFreezeClient", function()
    frozen = not frozen
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, frozen)
    SetEntityInvincible(ped, frozen)
    if frozen then
        ESX.ShowNotification("~b~Vous avez été gelé par un admin.")
    else
        ESX.ShowNotification("~g~Vous avez été dégelé.")
    end
end)

RegisterNetEvent("admin:setGroup")
AddEventHandler("admin:setGroup", function(group)
    playerGroup = group
end)

RegisterNetEvent("admin:showCenterAnnouncement")
AddEventHandler("admin:showCenterAnnouncement", function(message)
    Citizen.CreateThread(function()
        local displayTime = 10000
        local startTime = GetGameTimer()
        while GetGameTimer() - startTime < displayTime do
            Citizen.Wait(0)
            SetTextFont(4)
            SetTextScale(0.7, 0.7)
            SetTextColour(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextOutline()
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName(" ANNONCE SERVEUR\n~y~" .. message)
            EndTextCommandDisplayText(0.5, 0.4)
        end
    end)
end)

RegisterCommand("report", function()
    local msg = KeyboardInput("Décris ton problème (report)", "", 200)
    if msg == nil or msg == "" then
        ESX.ShowNotification("~r~Report annulé.")
        return
    end
    TriggerServerEvent("admin:sendReport", msg)
    ESX.ShowNotification("~g~Ton report a été envoyé.")
end)

CreateThread(function()
    while true do
        if showNames then
            local players = GetActivePlayers()
            local pPed = PlayerPedId()
            local pCoords = GetEntityCoords(pPed)
            for _, playerId in ipairs(players) do
                if playerId ~= PlayerId() then
                    local ped = GetPlayerPed(playerId)
                    local coords = GetEntityCoords(ped)
                    local dist = #(coords - pCoords)
                    if dist < nameDistance then
                        local serverId = GetPlayerServerId(playerId)
                        local name = GetPlayerName(playerId)
                        DrawText3D(coords.x, coords.y, coords.z + 1.0, "~b~"..name.." ~s~["..serverId.."]")
                    end
                end
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if vehicleDeleteActive then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                vehicleTarget = GetVehiclePedIsIn(ped, false)
            else
                local camCoords = GetGameplayCamCoord()
                local camRot = GetGameplayCamRot(2)
                local direction = vector3(-math.sin(math.rad(camRot.z)) * math.cos(math.rad(camRot.x)),math.cos(math.rad(camRot.z)) * math.cos(math.rad(camRot.x)),math.sin(math.rad(camRot.x)))
                local dest = camCoords + direction * 60.0
                local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z,dest.x, dest.y, dest.z,10,ped,0)
                local _, hit, _, _, entity = GetShapeTestResult(ray)
                if hit == 1 and IsEntityAVehicle(entity) then
                    vehicleTarget = entity
                else
                    vehicleTarget = nil
                end
            end
        else
            Wait(300)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if showPlayerBlips then
            for _, playerId in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(playerId)
                if ped ~= PlayerPedId() then
                    if not playerBlips[playerId] or not DoesBlipExist(playerBlips[playerId]) then
                        local blip = AddBlipForEntity(ped)
                        SetBlipSprite(blip, 1)
                        SetBlipColour(blip, 0)
                        SetBlipScale(blip, 0.85)
                        SetBlipAsShortRange(blip, false)
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentSubstringPlayerName(GetPlayerName(playerId))
                        EndTextCommandSetBlipName(blip)
                        playerBlips[playerId] = blip
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if showCoords then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local text = string.format("X: %.2f | Y: %.2f | Z: %.2f | H: %.2f",coords.x, coords.y, coords.z, heading)
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextOutline()
            SetTextCentre(true)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName(text)
            EndTextCommandDisplayText(0.5, 0.02)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if vehicleDeleteActive and vehicleTarget and DoesEntityExist(vehicleTarget) then
            local coords = GetEntityCoords(vehicleTarget)
            DrawMarker(2,coords.x, coords.y, coords.z + 2.5,0.0, 0.0, 0.0,0.0, 0.0, 0.0,0.5, 0.5, 0.5,255, 0, 0, 200,false, true, 2, false, nil, nil, false)
        else
            Wait(300)
        end
    end
end)