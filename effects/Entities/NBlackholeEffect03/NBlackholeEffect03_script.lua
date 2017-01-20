local EmitterProjectile = import('/lua/sim/defaultprojectiles.lua').EmitterProjectile
local NomadEffectTemplate = import('/lua/nomadeffecttemplate.lua')
local Util = import('/lua/utilities.lua')
local RandomFloat = Util.GetRandomFloat

NBlackholeEffect03 = Class(EmitterProjectile) {

    FxTrails = NomadEffectTemplate.NukeBlackholeFireballTrail,

    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)
        self:SetCollideSurface(true)
        self:SetCollideEntity(true)
        self:SetCollision(true)
        self:ForkThread(self.EffectThread)
    end,

    EffectThread = function(self)
        local scale = RandomFloat(0.5, 1.5)
        local scaleDecStep = scale / Random(15,150)
        local army, emit = self:GetArmy()
        local emitters = {}

        self:SetBallisticAcceleration( -2 )  -- "gravity"

        for k, v in NomadEffectTemplate.NukeBlackholeFireball do
            emit = CreateEmitterOnEntity(self, army, v ):ScaleEmitter( scale )
            table.insert( emitters, emit )
            self.Trash:Add( emit )
        end

        WaitTicks(1)
        while self and scale > 0 do
            scale = scale - scaleDecStep
            for k, v in emitters do
                v:ScaleEmitter( scale )
            end
            WaitTicks(1)
        end

        if scale <= 0 then
            self:Destroy()
        end
    end,

    PassDamageData = function(self, data)
        self.DamageData = data
    end,

    OnImpact = function(self, targetType, targetEntity)
        local army = self:GetArmy()
        for k, v in NomadEffectTemplate.NukeBlackholeFireballHit do
            CreateEmitterAtEntity(self, army, v )
        end
        if self.DamageData then
            local dmg = self.DamageData['Damage'] or 100
            local radius = self.DamageData['Radius'] or 2
            local type = self.DamageData['DamageType'] or 'Normal'
            if dmg > 0 and radius > 0 then
                DamageArea(self, self:GetPosition(), radius, dmg, type, true)
            end
        end
        DamageArea(self, self:GetPosition(), 2, 1, 'BigFire', true)
        self:Destroy()
    end,
}

TypeClass = NBlackholeEffect03