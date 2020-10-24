Events:Subscribe('Player:Killed', function(player, inflictor, position, weapon, isRoadKill, isHeadShot, wasVictimInReviveState, info)  
    if weapon == 'Knife_RazorBlade' or weapon == 'Melee' then
        NetEvents:Broadcast('Chaos:Knifed')
    end
end)