showWallHack = false
markersCleared = true

function ClearWhMarkers()
    for k=1,64 do
        WebUI:ExecuteJS('UpdateWH(0,0,' .. k .. ', false, null, 0)')
    end
end

Events:Subscribe('Extension:Loaded', function()
    WebUI:Init()
end)

NetEvents:Subscribe('Chaos:WallHack', function(enable)
    showWallHack = enable
    if not showWallHack then
        ClearWhMarkers()
    end
end)
Events:Subscribe('Engine:Update', function(delta, simulationDelta) 
    if showWallHack then       
        local localPlayer = PlayerManager:GetLocalPlayer()
        if localPlayer == nil then
            return 
        end
        if not localPlayer.alive and not markersCleared then
            ClearWhMarkers()
            markersCleared = true
            return
        end
        local players = PlayerManager:GetPlayers()
        for k, vp in pairs(players) do
            if vp ~= nil then
                if vp ~= localPlayer then
                    if vp.soldier ~= nil then
                        if vp.teamId ~= localPlayer.teamId then             
                            local transform = vp.soldier.transform.trans:Clone()
                            transform.y = transform.y + 1.6
                            local worldToScreen = ClientUtils:WorldToScreen(transform)
                            if worldToScreen ~= nil then
                                WebUI:ExecuteJS('UpdateWH('.. worldToScreen.x ..','.. worldToScreen.y..',' .. k .. ',true,' .. '\"' .. vp.name .. '\",' .. MathUtils:Round(vp.soldier.health*100)/100 .. ')')
                            end
                        end 
                    else
                        WebUI:ExecuteJS('UpdateWH(10,10,' .. k .. ',false,null,0)')                   
                    end
                end
            end
        end
        markersCleared = false
        return
    end  
end)