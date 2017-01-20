do


local oldProjectile = Projectile

Projectile = Class(oldProjectile) {

    -- TODO: remove this var after FAF integration.
    CanDoInitialDamage = true,  -- used to prevent doing initialdamage twice in FAF games. This is set to false in FAF balance path.

    OnCreate = function(self, inWater)
        oldProjectile.OnCreate(self, inWater)
        self.ImpactOnType = "Unknown"
    end,

    PassDamageData = function(self, DamageData)
        oldProjectile.PassDamageData(self, DamageData)
        self.DamageData.DamageToShields = DamageData.DamageToShields
        self.DamageData.InitialDamageAmount = DamageData.InitialDamageAmount
    end,

    OnImpact = function(self, targetType, targetEntity)
        self.ImpactOnType = targetType   -- adding this var so destructively hooking is not necessary

        if targetType == 'Terrain' then  -- Terrain does not equal Land, it could also be the seabed...
            local pos = self:GetPosition()
            local surface = GetSurfaceHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
            if pos[2] < surface then
                self.FxImpactLand = self.FxImpactSeabed or self.FxImpactLand
            end
        end

        oldProjectile.OnImpact(self, targetType, targetEntity)
        if targetType == 'Shield' then
            self:DoShieldDamage( targetEntity )
        end
    end,

    DoDamage = function(self, instigator, DamageData, targetEntity)
        -- handles 'initial damage'. Basically copy-pasted from the projectiles DoDamage function
        local damage = DamageData.InitialDamageAmount or 0
        if self.CanDoInitialDamage and damage > 0 then
            local radius = DamageData.DamageRadius or 0
            if radius > 0 then
                DamageArea(instigator, self:GetPosition(), radius, damage, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
            elseif targetEntity then
                Damage(instigator, self:GetPosition(), targetEntity, damage, DamageData.DamageType)
            end
        end

        -- handles the DoT damage
        oldProjectile.DoDamage(self, instigator, DamageData, targetEntity)
    end,

    DoShieldDamage = function(self, shield)
        if self.DamageData.DamageToShields and self.DamageData.DamageToShields > 0 and shield then
            local damage = math.min( self.DamageData.DamageToShields, shield:GetHealth() )
            if damage > 0 then
                Damage( self:GetLauncher(), self:GetPosition(), shield, damage, self.DamageData.DamageType)
            end
        end
    end,

    DoUnitImpactBuffs = function(self, target)
        -- the original version of this function has the parent unit do the buffing when there's a radius specified. I also need the
        -- unit that was hit to fix a problem where that unit isn't stunned (see unit.lua for more info). Destructively overwriting this fn
        -- to fix the problem.

        local data = self.DamageData
        local ok = true

        if data.Buffs then

            local orgTarget = target  -- remember original unit
            for k, v in data.Buffs do

                if v.Add.OnImpact == true then

                    if v.Add.ImpactTypeDisallow and self.ImpactOnType then   -- check impact restrictions. In some cases we dont want buffs applied when hitting for example water or shields.
                        if table.find(v.Add.ImpactTypeDisallow, self.ImpactOnType) then
                            --LOG('*DEBUG: dont do impact buffs because surfacetype is disallowed: '..repr(self.ImpactOnType))
                            continue
                        end
                    end

                    if ( v.AppliedToTarget ~= true ) or ( v.Radius and (v.Radius > 0) ) then  -- right side of the OR is the problem
                        target = self:GetLauncher()
                    end

                    if target and IsUnit(target) then
                        if ( v.Radius and (v.Radius > 0) ) then
                            target:AddBuff(v, self:GetPosition(), orgTarget)  -- added last argument
                        else
                            target:AddBuff(v)
                        end
                    end
                end
            end
        end
    end,
}


end