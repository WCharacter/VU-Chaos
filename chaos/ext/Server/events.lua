-- globals
vehicleTable = {}

weaponTable = {} -- weapons
unlockTables = {} -- gadgets
weaponKeys = {}
jumpStateData = {}
soldierBodyCompData = {}

event_started = false
insta_respawn = false

delayCounter = 0
event_timer = 0
current_event_index = 0
between_event_period = 15
event_end_period = 40 --time in seconds how much one event will be going
event_end_period_cpy = event_end_period

function OnPartitionLoaded(partition)
	local instances = partition.instances
	for _, ins in pairs(instances) do
		if ins ~= nil then
			if ins:Is('VehicleBlueprint') then			
				local vehicleBlueprint = VehicleBlueprint(ins)				
				local vehicleName = vehicleBlueprint.name:gsub(".+/.+/","")			
				vehicleTable[vehicleName] = vehicleBlueprint
			end
			if ins:Is('SoldierWeaponUnlockAsset') then					
				local weaponUnlockAsset = SoldierWeaponUnlockAsset(ins)			
                local weaponName = weaponUnlockAsset.name:match("/U_.+"):sub(4)		
                weaponKeys[#weaponKeys + 1] = weaponName	
				weaponTable[weaponName] = weaponUnlockAsset
			end
			if ins:Is('JumpStateData') then
				jumpStateData[#jumpStateData+1] = JumpStateData(ins)
			end
			if ins:Is('SoldierBodyComponentData') then				
				soldierBodyCompData[#soldierBodyCompData+1] = SoldierBodyComponentData(ins)				
			end
		end
	end
end

function OnLevelLoaded()
	print('Level loaded')
	for weaponName, weaponUnlockAsset in pairs(weaponTable) do	
		if SoldierWeaponData(SoldierWeaponBlueprint(weaponUnlockAsset.weapon).object).customization ~= nil then
			unlockTables[weaponName] = {}			
			local customizationUnlockParts = CustomizationTable(VeniceSoldierWeaponCustomizationAsset(SoldierWeaponData(SoldierWeaponBlueprint(weaponUnlockAsset.weapon).object).customization).customization).unlockParts			
			for _, unlockParts in pairs(customizationUnlockParts) do			
				for _, asset in pairs(unlockParts.selectableUnlocks) do				
					local unlockAssetName = asset.debugUnlockId:gsub("U_.+_","")
                    unlockTables[weaponName][unlockAssetName] = asset
				end
			end
		end
	end
end

Events:Subscribe('Level:Destroy', function()
	print('Level destroyed!')
	jumpStateData = {}
	soldierBodyCompData = {}
end)

Events:Subscribe('Server:RoundReset', function()
	print('Round reset!')	
end)

function EquipWeapon(player, args)
	local attachments = {}
	for i = 3, #args do
		attachments[i-2] = unlockTables[args[1]][args[i]]
	end
	local weaponslot = tonumber(args[2]) or player.soldier.weaponsComponent.currentWeaponSlot
	if(weaponslot == nil) then
		print('wnpslot is nil')
    end
	player:SelectWeapon(weaponslot, weaponTable[args[1]], attachments)
end

function SpawnVehicle(player, vehicle, amount, yellMessage)	
    if player.soldier ~= nil then
        if yellMessage then
            ChatManager:Yell('A lot of ' .. vehicle .. ' were spawned above ' .. player.name, 10.00)
        end
		for _=1, amount do
			local distance_x = 3 + MathUtils:GetRandom(-10, 12)
			local distance_z = 4 + MathUtils:GetRandom(-6, 12)
			local height = 600 + MathUtils:GetRandom(-16, 50)

			local transform = LinearTransform()

			transform.trans.x = player.soldier.transform.trans.x + distance_x
			transform.trans.y = player.soldier.transform.trans.y + height
			transform.trans.z = player.soldier.transform.trans.z + distance_z

			local params = EntityCreationParams()
			params.transform = transform
			params.networked = true

			local blueprint = vehicleTable[vehicle]

			local vehicleEntityBus = EntityBus(EntityManager:CreateEntitiesFromBlueprint(blueprint, params))

			for __, entity in pairs(vehicleEntityBus.entities) do
				entity = Entity(entity)
				entity:Init(Realm.Realm_ClientAndServer, true)
			end
		end
	end
end

-- events
function VehicleRain(enable, player) 
	if player ~= nil and enable then
		return
	end
	if enable then
		local players = PlayerManager:GetPlayers()
        if #players ~= 0 then
			print('Vehicle rain started!')
			local index = MathUtils:GetRandomInt(1, #players)
			local loopDetector = 0
			while players[index].soldier == nil do
				index = MathUtils:GetRandomInt(1, #players)
				loopDetector = loopDetector + 1
				if loopDetector > 1000 then
					print('No alive players to spawn vehicles on')
					return
				end
			end
            loopDetector = 0
            while not players[index].alive do
                index = MathUtils:GetRandomInt(1, #players)
                loopDetector = loopDetector + 1
                if loopDetector > 1000 then
                    return
                end
            end
            SpawnVehicle(players[index], 'GrowlerITV', 40, true)
        end
    else
		print('Vehicle rain ended!')
    end
end

function GiveRandomWeapons(player, weaponSlots, attachmentsAmount)
	if player.soldier ~= nil then
		if weaponSlots == nil then
			weaponSlots = {0,1}
		end
		for _, i in pairs(weaponSlots) do
			local args = {}
			local weaponName = weaponKeys[MathUtils:GetRandomInt(1, #weaponKeys)]
			if attachmentsAmount == nil then
				attachmentsAmount = 1
			end
			args[1] = weaponName
			args[2] = tostring(i)	 
			local attachmentKeys = {}
			if unlockTables[weaponName] ~= nil then
				for k, _ in pairs(unlockTables[weaponName]) do
					attachmentKeys[#attachmentKeys + 1] = k
				end
			end
			if #attachmentKeys > 0 then
				for j=1,attachmentsAmount do
					args[2+j] = attachmentKeys[MathUtils:GetRandomInt(1, #attachmentKeys)]
				end
		 end								
			EquipWeapon(player, args)
	 	end  
 	end   
end

function RandomWeapons(enable, player)
	if player ~= nil and enable then
		GiveRandomWeapons(player, {0, 1}, 3) 
		return
	end
	if enable then
		print('Random weapons started!')
		ChatManager:Yell('Random weapons!', 10.0)
		for _, pl in pairs(PlayerManager:GetPlayers()) do
			GiveRandomWeapons(pl, {0, 1}, 3)   
        end
    else
        print('Random weapons ended!')
    end
end

function SetHealth(health, player)
	if player ~= nil then		
		if player.soldier ~= nil then
			ChatManager:Yell('One HP!', 10.0, player)
			player.soldier.health = health
		end		
		return
	end
	for _, pl in pairs(PlayerManager:GetPlayers()) do
		if pl.soldier ~= nil then
			pl.soldier.health = health
		end         
	end
end

function OneHealth(enable, player)
	if enable then
		print('One health started!')
		SetHealth(1.0, player)
    else
        print('One health ended!')
    end
end

function HaloJumpAll(enable, player)
	if player ~= nil and enable then		
		if player.soldier ~= nil then
			ChatManager:Yell('Halo jump!', 10.0, player)
			if player.inVehicle then
				player:ExitVehicle(true, true)
			end			
			local newPos = Vec3(player.soldier.transform.trans.x, player.soldier.transform.trans.y + 700, player.soldier.transform.trans.z)
			player.soldier:SetPosition(newPos)
		end
		return
	end
	if enable then
		event_end_period = 10
		print('Halo jump started!')
        ChatManager:Yell('Halo jump!', 10.0)
		for _, pl in pairs(PlayerManager:GetPlayers()) do
			if pl.soldier ~= nil then
				if pl.inVehicle then
					pl:ExitVehicle(true, true)
				end	
				local newPos = Vec3(pl.soldier.transform.trans.x, pl.soldier.transform.trans.y + 700, pl.soldier.transform.trans.z)
				pl.soldier:SetPosition(newPos)
			end       
        end
	else
		event_end_period = event_end_period_cpy
        print('Halo jump ended!')
    end
end

function SuperJump(enable, player) 
	if player ~= nil then
		return
	end
	local newValue = 0.6
	if enable then
		print('Super jump started!')
		ChatManager:Yell('Super jump!', 10.0)
		newValue = 16.0
	else
		print('Super jump ended!')
	end

	for _, instance in pairs(jumpStateData) do
		if instance ~= nil then
			if instance:Is('JumpStateData') then
				if instance ~= nil then
					instance:MakeWritable()
					instance.jumpHeight = newValue
				end
			end
		end
	end
end

function ChangeWeaponProjectile(partition, instance, newProjectilePartition, newAmmoCapacity)
	local fireData = FiringFunctionData(ResourceManager:FindInstanceByGuid(Guid(partition), Guid(instance)))
	fireData:MakeWritable()
	fireData.shot.projectileData:MakeWritable()
	local newProjectileData = ResourceManager:SearchForInstanceByGuid(Guid(newProjectilePartition))
	fireData.shot.projectileData = ProjectileEntityData(newProjectileData)
	if newAmmoCapacity ~= nil then
		fireData.ammo.magazineCapacity = newAmmoCapacity
	end
end

function UltraAEK(enable, player)
	if player ~= nil and enable then
		ChatManager:Yell('Ultra AEK!', 10.0, player)
		if player.soldier ~= nil then		
			local args = {}
			local weaponName = 'AEK971'
			args[1] = weaponName
			args[2] = tostring(player.soldier.weaponsComponent.currentWeaponSlot)	
			args[3] = 'PKA'
			args[4] = 'Foregrip'			
			EquipWeapon(player, args)
		end
		return
	end
	local projectile = '168F529C-17F6-11E0-8CD8-85483A75A7C5'
	if enable then
		ChatManager:Yell('Ultra AEK!', 10.0)
		ChangeWeaponProjectile('64DB81AD-1F08-11E0-BE14-C6BC4F4ED27B', 'CE3372DA-991B-41C1-95BC-19B5D26AAE5B', projectile, nil)
		ChangeWeaponProjectile('64DB81AD-1F08-11E0-BE14-C6BC4F4ED27B', '4CDDF1C1-8494-41EC-8FF8-C0005D3904ED', projectile, nil)

		for _, player in pairs(PlayerManager:GetPlayers()) do
			if player.soldier ~= nil then		
				local args = {}
				local weaponName = 'AEK971'
				args[1] = weaponName
				args[2] = tostring(player.soldier.weaponsComponent.currentWeaponSlot)	
				args[3] = 'PKA'
				args[4] = 'Foregrip'			
				EquipWeapon(player, args)
			end
		end         
		print('Ultra AEK started!')
	else
		ChangeWeaponProjectile('64DB81AD-1F08-11E0-BE14-C6BC4F4ED27B', 'CE3372DA-991B-41C1-95BC-19B5D26AAE5B', '3B596DD4-B4AC-43C0-8822-8C816B03EA14', nil)
		ChangeWeaponProjectile('64DB81AD-1F08-11E0-BE14-C6BC4F4ED27B', '4CDDF1C1-8494-41EC-8FF8-C0005D3904ED', 'FE1AFD52-4E8B-46BB-A92E-9D7BAD364B43', nil)
		print('Ultra AEK ended!')
	end
end

function UltraC4(enable, player)
	--NetEvents:Broadcast('Explosion:Ultraboom', enable)
	if player ~= nil and enable then
		ChatManager:Yell('Ultra C4 Explosion!', 10.0, player)
		if player.soldier ~= nil then		
			local args = {}
			local weaponName = 'C4'
			args[1] = weaponName
			args[2] = tostring(3)				
			EquipWeapon(player, args)
		end
		return
	end
	local instance = ProjectileEntityData(ResourceManager:FindInstanceByGuid(Guid('910AD7C5-2558-11E0-96DC-FF63A5537869'), Guid('09DCA5BB-BB2E-4EC6-B07F-5F74863EB458')))
	if instance ~= nil then
		instance:MakeWritable()
        instance.explosion:MakeWritable()
		if enable then
			ChatManager:Yell('Ultra C4 Explosion!', 10.0)
			print('UltraC4 started!')
			instance.maxCount = 20
            instance.explosion.blastImpulse = instance.explosion.blastImpulse * 20
            instance.explosion.blastRadius =  instance.explosion.blastRadius * 20
            instance.explosion.shockwaveImpulse = instance.explosion.shockwaveImpulse * 20
			instance.explosion.shockwaveRadius = instance.explosion.shockwaveRadius * 20
			for _, pl in pairs(PlayerManager:GetPlayers()) do
				if pl.soldier ~= nil then		
					local args = {}
					local weaponName = 'C4'
					args[1] = weaponName
					args[2] = tostring(3)				
					EquipWeapon(pl, args)
				end
			end  
		else
			instance.maxCount = 6
            instance.explosion.blastImpulse = instance.explosion.blastImpulse / 20
            instance.explosion.blastRadius = instance.explosion.blastRadius / 20
            instance.explosion.shockwaveImpulse = instance.explosion.shockwaveImpulse / 20
            instance.explosion.shockwaveRadius = instance.explosion.shockwaveRadius / 20
			print('UltraC4 ended!')
		end
	end
end

function P90Saiga(enable, player)
	if player ~= nil and enable then
		ChatManager:Yell('P90 shots 12g now!', 10.0, player)
		if player.soldier ~= nil then		
			local args = {}
			local weaponName = 'P90'
			args[1] = weaponName
			args[2] = tostring(player.soldier.weaponsComponent.currentWeaponSlot)	
			args[3] = 'Acog'
			--args[4] = ''			
			EquipWeapon(player, args)
		end
		return
	end
	
	if enable then
		local projectile = 'EF265029-3291-4544-8081-ABFFA09D3D96'
		ChatManager:Yell('P90 shots 12g now!', 10.0)
		ChangeWeaponProjectile('C75DBA86-F326-11DF-ABE6-A89858BEBE43', '9629652F-135E-4EE6-A9FB-343D947A4861', projectile, nil)
		for _, player in pairs(PlayerManager:GetPlayers()) do
			if player.soldier ~= nil then		
				local args = {}
				local weaponName = 'P90'
				args[1] = weaponName
				args[2] = tostring(player.soldier.weaponsComponent.currentWeaponSlot)	
				args[3] = 'Acog'		
				EquipWeapon(player, args)
			end
		end         
		print('P90 is now Saiga!')
	else
		ChangeWeaponProjectile('C75DBA86-F326-11DF-ABE6-A89858BEBE43', '9629652F-135E-4EE6-A9FB-343D947A4861', '0B4A4BEA-89B4-42C1-B187-955BA57F6E55', nil)
		print('P90 is normal now!')
	end
end

function MixPlayers(enable, player)
	if player ~= nil then
		return
	end
	if enable then
		event_end_period = 2
		print('Player mix started!')
		local players = PlayerManager:GetPlayers()
		if #players < 2 then
			print('No players or only one player on the server')
			return
		end	
		ChatManager:Yell('Mix all the players!', 10.0)

		for k=1,#players do
			if players[#players + 1 - k].soldier ~= nil then
				local nextPlayer = players[k]
				while nextPlayer == nil do
					k = k + 1
					if k == #players then
						return --exit when there is no other players
					end
					nextPlayer = players[k]
				end
				while nextPlayer.soldier == nil do
					k = k + 1
					if k == #players then
						return --exit when there is no other players
					end
					nextPlayer = players[k]
				end
				if nextPlayer.inVehicle then
					player:ExitVehicle(true, true)
				end	
				if players[#players + 1 - k].inVehicle then
					player:ExitVehicle(true, true)
				end
	
				local positionVecCpy = nextPlayer.soldier.transform.trans:Clone()
								
				-- copying positions
				nextPlayer.soldier:SetPosition(players[#players + 1 - k].soldier.transform.trans)
				players[#players + 1 - k].soldier:SetPosition(positionVecCpy)
			end
		end
	else
		event_end_period = event_end_period_cpy
		print('Player mix ended!')
	end
end

function Wallhack(enable, player)
	if player ~= nil and enable then
		ChatManager:Yell('Wallhack!', 10.0, player)
		NetEvents:SendTo('Chaos:WallHack', player, enable)
		return
	end
	NetEvents:Broadcast('Chaos:WallHack', enable)
	if enable then
		ChatManager:Yell('Wallhack!', 10.0)
		print('Wallhack started!')
	else 
		print('Wallhack ended!')
	end
end

function LowGravity(enable, player)
	if player ~= nil and enable then
		ChatManager:Yell('Low gravity!', 10.0, player)
		return
	end

	if enable then
		ChatManager:Yell('Low gravity!', 10.0)
		for _, v in pairs(soldierBodyCompData) do
			v:MakeWritable()
			v.overrideGravity = true
			v.overrideGravityValue = -2.0
		end
		print('Low gravity started!')
	else 
		for _, v in pairs(soldierBodyCompData) do
			v:MakeWritable()
			v.overrideGravity = false
			-- v.overrideGravityValue = -9.81
		end
		print('Low gravity ended!')
	end
end

function InstaRespawnOnDeath(enable, player)
	if player ~= nil and enable then
		ChatManager:Yell('Instant respawn!', 10.0, player)
		return
	end
	insta_respawn = enable

	if enable then
		ChatManager:Yell('Low gravity!', 10.0)
		print('Instant respawn started!')
	else 
		print('Instant respawn ended!')
	end
end

-- event table
event_list = {
	--VehicleRain,
	--OneHealth,
	
	RandomWeapons,
	SuperJump,
	HaloJumpAll,
	UltraC4,
	UltraAEK,
	P90Saiga,
	MixPlayers,
	Wallhack,
	LowGravity,
}

Events:Subscribe('Player:Killed', function(player, inflictor, position, weapon, isRoadKill, isHeadShot, wasVictimInReviveState, info)
	if insta_respawn and event_started then
		
	end
end)

Events:Subscribe('Player:Respawn', function(player)
	if event_started then
		event_list[current_event_index](true, player)
	end
end)

function OnEngineUpdate(dt, simulationDeltaTime)
	if #PlayerManager:GetPlayers() == 0 then
		return
	end
	delayCounter = delayCounter + dt
	if MathUtils:Round(delayCounter * 1000) % 1000 == 0 and delayCounter < between_event_period then
		ChatManager:Yell(MathUtils:Round(between_event_period - delayCounter) .. ' seconds remaining', 0.3)
	end

	if delayCounter >= between_event_period and not event_started then
		event_timer = 0
		event_started = true
		local index = MathUtils:GetRandomInt(1, #event_list)
		if #event_list > 1 then
			while index == current_event_index do
				index = MathUtils:GetRandomInt(1, #event_list)
			end
		end
		current_event_index = index
		event_list[index](true, nil)	
	end
	if event_started and event_timer >= event_end_period then
		event_started = false
		delayCounter = 0
		event_list[current_event_index](false, nil)
		ChatManager:Yell(between_event_period .. ' seconds until next event', 6)
	end
	if event_started then
		event_timer = event_timer + dt
	end	
end