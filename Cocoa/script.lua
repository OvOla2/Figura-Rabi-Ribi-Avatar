-- Auto generated script file --

-- hide vanilla model
vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(false)
vanilla_model.HELMET_ITEM:setVisible(true)
vanilla_model.CAPE:setVisible(false)
vanilla_model.ELYTRA:setVisible(false)

-- ===================================================
-- 炸弹系统
-- ===================================================

local Fidget = require("Fidget.FidgetSetup")

-- 辅助函数：检测固体方块（排除水、岩浆）
local function isSolidBlock(pos)
    local block = world.getBlockState(pos)
    if block:hasCollision() then
        local id = block.id
        if not id:find("water") and not id:find("lava") then
            return true
        end
    end
    return false
end

-- ========== 炸弹配置 ==========
local BombConfig = {}

local bomb1Explosion = function(pos, params)
    particles:newParticle("minecraft:explosion_emitter", pos):setScale(3)
    particles:newParticle("minecraft:flash", pos):setScale(2)
    sounds:playSound("minecraft:entity.generic.explode", pos, 1.0, 1.0)
    for _ = 1, 40 do
        local offset = vectors.vec3(
            (math.random()*2-1), (math.random()*2-1), (math.random()*2-1)
        ):normalize():scale(math.random()*3)
        particles:newParticle("minecraft:smoke", pos+offset):setScale(1.5):setLifetime(20)
    end
end

BombConfig.TYPES = {
    [1] = {
        name = "Bomb1",
        modelPath = {"Bomb", "World", "Bomb1"},
        physicsPreset = "DEFAULT",
        explosion = bomb1Explosion
    },
    [2] = {
        name = "Bomb2",
        modelPath = {"Bomb", "World", "Bomb2"},
        physicsPreset = "HEAVY",
        explosion = function(pos, params)
            particles:newParticle("minecraft:explosion_emitter", pos):setScale(5)
            particles:newParticle("minecraft:flash", pos):setScale(3)
            sounds:playSound("minecraft:entity.generic.explode", pos, 1.2, 1.0)
            for _ = 1, 60 do
                local offset = vectors.vec3(
                    (math.random()*2-1), (math.random()*2-1), (math.random()*2-1)
                ):normalize():scale(math.random()*5)
                particles:newParticle("minecraft:smoke", pos+offset):setScale(2):setLifetime(20)
            end
            for _ = 1, 30 do
                local offset = vectors.vec3(
                    (math.random()*2-1), (math.random()*2-1), (math.random()*2-1)
                ):normalize():scale(math.random()*4)
                particles:newParticle("minecraft:flame", pos+offset):setScale(1):setLifetime(15)
            end

            local innerTemplate = models.Bomb.World.PillarInner
            local outerTemplate = models.Bomb.World.PillarOuter
            if innerTemplate and outerTemplate then
                local inner = innerTemplate:copy("pillar_inner_" .. math.random(100000,999999))
                    :setParentType("WORLD")
                    :setVisible(true)
                    :setPrimaryRenderType("EMISSIVE_SOLID")
                    :setPos(pos * 16)
                    :setScale(20, 4096, 20)
                models.Bomb.World:addChild(inner)

                local outer = outerTemplate:copy("pillar_outer_" .. math.random(100000,999999))
                    :setParentType("WORLD")
                    :setVisible(true)
                    :setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
                    :setColor(1, 0, 0)
                    :setOpacity(0.4)
                    :setPos(pos * 16)
                    :setScale(25, 4096, 25)
                models.Bomb.World:addChild(outer)

                local lifetime = 60
                local function cleanup()
                    lifetime = lifetime - 1
                    if lifetime <= 0 then
                        inner:remove()
                        outer:remove()
                        events.TICK:remove(cleanup)
                    end
                end
                events.TICK:register(cleanup)
            end
        end
    },
    [3] = {
        name = "Bomb3",
        modelPath = {"Bomb", "World", "Bomb3"},
        physicsPreset = "LIGHT",
        explosion = function(pos, params)
            particles:newParticle("minecraft:explosion_emitter", pos):setScale(1.5)
            particles:newParticle("minecraft:flash", pos):setScale(1)
            sounds:playSound("minecraft:entity.generic.explode", pos, 0.6, 0.7)
            for _ = 1, 15 do
                local offset = vectors.vec3(
                    (math.random()*2-1), (math.random()*2-1), (math.random()*2-1)
                ):normalize():scale(math.random()*1.5)
                particles:newParticle("minecraft:smoke", pos+offset):setScale(1):setLifetime(10)
            end
            for _ = 1, 20 do
                local offset = vectors.vec3(
                    (math.random()*2-1), (math.random()*2-1), (math.random()*2-1)
                ):normalize():scale(math.random()*1.5)
                particles:newParticle("minecraft:soul_fire_flame", pos+offset):setScale(0.8):setLifetime(10)
            end
            if params.bulletManager then
                params.bulletManager:fireVolley(pos)
            end
        end
    },
    [4] = {
        name = "Bomb4",
        modelPath = {"Bomb", "World", "Bomb4"},
        physicsPreset = "FLYING",
        explosion = bomb1Explosion
    },
    [5] = {
        name = "Bomb5",
        modelPath = {"Bomb", "World", "Bomb5"},
        physicsPreset = "FLYING",
        explosion = bomb1Explosion
    },
    [6] = {
        name = "Bomb6",
        modelPath = {"Bomb", "World", "Bomb6"},
        physicsPreset = "FLYING",
        explosion = bomb1Explosion
    },
    [7] = {
        name = "Bomb7",
        modelPath = {"Bomb", "World", "Bomb7"},
        physicsPreset = "FLYING",
        explosion = bomb1Explosion
    },
    [8] = {
        name = "Bomb8",
        modelPath = {"Bomb", "World", "Bomb8"},
        physicsPreset = "FLYING",
        -- 球形灵魂火爆炸
        explosion = function(pos, params)
            particles:newParticle("minecraft:explosion_emitter", pos):setScale(4)
            particles:newParticle("minecraft:flash", pos):setScale(3)
            sounds:playSound("minecraft:entity.generic.explode", pos, 1.5, 0.8)
            -- 生成 200 个灵魂火粒子，半径 3 格
            for _ = 1, 200 do
                local offset = vectors.vec3(
                    (math.random()*2-1), (math.random()*2-1), (math.random()*2-1)
                ):normalized():scale(math.random() * 3)
                particles:newParticle("minecraft:soul_fire_flame", pos + offset)
                    :setScale(1.2)
                    :setLifetime(25)
            end
        end
    }
}

-- ========== 物理预设 ==========
local PhysicsPresets = {
    DEFAULT = {
        mass = 5,
        friction = 0.2,
        damping = 0.99,
        rotationDamping = 0.98,
        dimensions = vec(0.25, 0.25, 0.25),
        elasticCoefficient = 0.7,
        launchSpeed = 4.5
    },
    HEAVY = {
        mass = 8,
        friction = 0.25,
        damping = 0.985,
        rotationDamping = 0.95,
        dimensions = vec(0.25, 0.25, 0.25),
        elasticCoefficient = 0.25,
        launchSpeed = 4.0
    },
    LIGHT = {
        mass = 3,
        friction = 0.15,
        damping = 0.995,
        rotationDamping = 0.99,
        dimensions = vec(0.25, 0.25, 0.25),
        elasticCoefficient = 0.45,
        launchSpeed = 5.0
    }
}

-- ========== 弹幕管理器 ==========
local BulletManager = {}
BulletManager.__index = BulletManager

function BulletManager:new(modelTemplate, worldRoot)
    local obj = {
        model = modelTemplate,
        root = worldRoot,
        bullets = {},
        speed = 0.3,
        lifetime = 80
    }
    setmetatable(obj, self)
    return obj
end

function BulletManager:generateDirections()
    local dirs = {}
    local latSegs = 5
    local lonSegs = 12
    local latStep = math.pi / (latSegs + 1)
    for i = 1, latSegs do
        local lat = -math.pi/2 + i * latStep
        for j = 1, lonSegs do
            local lon = (j-1) * 2*math.pi / lonSegs
            dirs[#dirs+1] = vectors.vec3(
                math.cos(lat) * math.cos(lon),
                math.sin(lat),
                math.cos(lat) * math.sin(lon)
            )
        end
    end
    dirs[#dirs+1] = vectors.vec3(0, 1, 0)
    dirs[#dirs+1] = vectors.vec3(0, -1, 0)
    return dirs
end

function BulletManager:fireVolley(centerPos)
    local dirs = self:generateDirections()
    for _, dir in ipairs(dirs) do
        self:createBullet(centerPos, dir)
    end
end

function BulletManager:createBullet(pos, dir)
    if not self.model or not self.root then return end
    local copyModel = self.model:copy("bullet2_" .. math.random(100000,999999))
    self.root:addChild(copyModel)
    copyModel:setVisible(true)
    copyModel:setPos(pos * 16)
    copyModel:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
    local bullet = {
        model = copyModel,
        pos = pos:copy(),
        dir = dir:copy(),
        lifetime = self.lifetime,
        active = true
    }
    table.insert(self.bullets, bullet)
end

function BulletManager:update()
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        if b.active then
            b.pos = b.pos + b.dir * self.speed
            b.model:setPos(b.pos * 16)
            b.lifetime = b.lifetime - 1
            local bs = world.getBlockState(b.pos)
            if bs:hasCollision() then
                particles:newParticle("minecraft:soul_fire_flame", b.pos):setScale(0.8)
                b.active = false
            elseif b.lifetime <= 0 then
                particles:newParticle("minecraft:soul_fire_flame", b.pos):setScale(0.8)
                b.active = false
            end
        end
        if not b.active then
            b.model:remove()
            table.remove(self.bullets, i)
        end
    end
end

-- ========== 炸弹管理器 ==========
local BombManager = {}
BombManager.__index = BombManager

function BombManager:new(config, presetTable)
    local obj = {
        bombs = {},
        flyingBombs = {},
        bomb4Bullets = {},
        bomb5Bullets = {},
        bomb6Bullets3 = {},
        bomb6Bullets2 = {},
        bomb7Bullets = {},
        cooldown = 0,
        fuseTime = 80,
        currentType = 1,
        config = config,
        presets = presetTable,
        models = {},
        bulletManager = nil,
        pendingRigidbodyRemoval = {}
    }
    setmetatable(obj, self)
    return obj
end

function BombManager:init()
    for i, bt in ipairs(self.config.TYPES) do
        local mdl = models
        for _, part in ipairs(bt.modelPath) do
            mdl = mdl[part]
        end
        if mdl then
            self.models[i] = mdl
            mdl:setVisible(false)
        else
            print("警告: 未找到模型 " .. table.concat(bt.modelPath, "/") .. "！")
        end
    end

    -- 隐藏光柱模板
    if models.Bomb.World.PillarInner then
        models.Bomb.World.PillarInner:setVisible(false)
    end
    if models.Bomb.World.PillarOuter then
        models.Bomb.World.PillarOuter:setVisible(false)
    end

    -- 飞行动画
    if animations.Bomb and animations.Bomb.Fly then
        self.flyAnimation = animations.Bomb.Fly
        self.flyAnimation:setLoop("LOOP")
    else
        print("警告: 未找到 animations.Bomb.Fly")
    end

    -- 隐藏所有子弹模板
    if models.Bomb and models.Bomb.World then
        if models.Bomb.World.Bullet1 then models.Bomb.World.Bullet1:setVisible(false) end
        if models.Bomb.World.Bullet2 then models.Bomb.World.Bullet2:setVisible(false) end
        if models.Bomb.World.Bullet3 then models.Bomb.World.Bullet3:setVisible(false) end
        if models.Bomb.World.Bullet4 then models.Bomb.World.Bullet4:setVisible(false) end
        if models.Bomb.World.Bullet6 then models.Bomb.World.Bullet6:setVisible(false) end
    end

    print("炸弹系统就绪 - 当前: " .. self.config.TYPES[self.currentType].name)
end

function BombManager:makeElasticCallback(bomb, elasticCoeff)
    return function(rb, normal, points)
        if not bomb.active or rb._pendingRemove then return end
        local vel = rb.vel
        local dotVN = vel:dot(normal)
        if dotVN < 0 then
            rb.vel = vel - (1 + elasticCoeff) * dotVN * normal
        end
    end
end

-- ========== 普通炸弹 ==========
function BombManager:createBomb(startPos, direction)
    local bombType = self.config.TYPES[self.currentType]
    if not self.models[self.currentType] then return nil end

    local preset = self.presets[bombType.physicsPreset] or self.presets.DEFAULT
    local vel = direction:copy():normalize():scale(preset.launchSpeed)

    sounds:playSound("minecraft:entity.firework_rocket.launch", startPos, 0.8, 1.2)
    particles:newParticle("minecraft:smoke", startPos):setScale(0.5)

    local rigidbody = Fidget.rigidbodies.createRigidbody({
        pos = startPos,
        vel = vel,
        mass = preset.mass,
        friction = preset.friction,
        damping = preset.damping,
        rotationDamping = preset.rotationDamping,
        type = "cuboid",
        dimensions = preset.dimensions,
        model = self.models[self.currentType],
        modelScale = vectors.vec3(1, 1, 1),
        collisionBlacklist = {}
    })

    local bomb = {
        rigidbody = rigidbody,
        typeIndex = self.currentType,
        lifetime = self.fuseTime,
        active = true
    }
    rigidbody.onWorldCollision = self:makeElasticCallback(bomb, preset.elasticCoefficient)
    table.insert(self.bombs, bomb)
    return bomb
end

-- ========== 飞行炸弹 ==========
function BombManager:createFlyingBomb(startPos)
    local bombType = self.config.TYPES[self.currentType]
    if not self.models[self.currentType] then return nil end

    local copyModel = self.models[self.currentType]:copy("fly_bomb_" .. math.random(100000, 999999))
    copyModel:setParentType("WORLD")
    copyModel:setVisible(true)
    models.Bomb.World:addChild(copyModel)

    local bomb = {
        model       = copyModel,
        pos         = startPos:copy(),
        typeIndex   = self.currentType,
        lifetime    = 200,               -- 10秒飞行
        active      = true,
        flying      = true,
        targetPos   = startPos:copy(),
        targetTimer = 0,
        fallTimer   = nil,
        -- 各炸弹专用计时/状态
        fireTimer   = 0,   -- Bomb4
        cycleTimer  = 0,   -- Bomb5
        burstTimer  = 0,   -- Bomb5
        triggered   = false, -- Bomb6/Bomb7 触发标志
        phase       = 0,     -- Bomb6 攻击阶段
        phaseTimer  = 0,
        phase2Tick  = 0,
        bomb7FireTimer = 0, -- Bomb7 发射间隔计时
    }

    if self.flyAnimation then
        self.flyAnimation:play()
    end

    table.insert(self.flyingBombs, bomb)
    return bomb
end

-- ========== Bomb4 专属子弹 ==========
function BombManager:createBomb4Bullet(pos)
    local bt = models.Bomb.World.Bullet4
    if not bt then return end
    local m = bt:copy("bullet4_" .. math.random(100000,999999))
    m:setParentType("WORLD"):setVisible(true):setScale(4,4,4):setPrimaryRenderType("EMISSIVE_SOLID")
    models.Bomb.World:addChild(m)
    local b = {
        model = m, pos = pos:copy(), vel = vec(0,-2,0),
        active = true, rotationAngle = 0, particleTimer = 0
    }
    table.insert(self.bomb4Bullets, b)
end

function BombManager:updateBomb4Bullets()
    for i = #self.bomb4Bullets, 1, -1 do
        local b = self.bomb4Bullets[i]
        if not b.active then b.model:remove(); table.remove(self.bomb4Bullets,i)
        else
            b.pos = b.pos + b.vel * 0.05
            b.rotationAngle = b.rotationAngle + (math.pi/10)
            b.model:setPos(b.pos*16):setRot(0,0,math.deg(b.rotationAngle))
            b.particleTimer = b.particleTimer + 1
            if b.particleTimer >= 8 then
                b.particleTimer = 0
                particles:newParticle("dust 0.2 0.6 1 1", b.pos):setScale(0.8):setLifetime(15)
            end
            if isSolidBlock(b.pos) then
                for _=1,20 do
                    local t = math.random()*2*math.pi; local p = math.acos(2*math.random()-1)
                    local x,y,z = 0.5*math.sin(p)*math.cos(t), 0.5*math.sin(p)*math.sin(t), 0.5*math.cos(p)
                    particles:newParticle("dust 0.2 0.6 1 1", b.pos+vec(x,y,z)):setScale(0.5):setLifetime(20)
                end
                sounds:playSound("minecraft:entity.firework_rocket.blast", b.pos, 0.5, 1.5)
                b.active = false
            end
        end
    end
end

-- ========== Bomb5 专属子弹 ==========
local function generateSphereDirections(count)
    local dirs = {}
    local phi = math.pi * (3 - math.sqrt(5))
    for i=1,count do
        local y = 1 - (i-0.5)*(2/count)
        local r = math.sqrt(1-y*y)
        local theta = phi * i
        dirs[i] = vec(math.cos(theta)*r, math.sin(theta)*r, y)
    end
    return dirs
end

function BombManager:createBomb5Bullet(pos, dir)
    local bt = models.Bomb.World.Bullet1
    if not bt then return end
    local m = bt:copy("bullet1_"..math.random(100000,999999))
    m:setParentType("WORLD"):setVisible(true):setPrimaryRenderType("EMISSIVE_SOLID")
    models.Bomb.World:addChild(m)
    local nd = dir:normalized()
    local look = -nd
    local yaw = math.atan2(look.x, look.z)
    local pitch = -math.asin(look.y)
    m:setRot(math.deg(pitch), math.deg(yaw), 0)
    local b = { model=m, pos=pos:copy(), vel=nd:scale(3), active=true, lifetime=160 }
    table.insert(self.bomb5Bullets, b)
end

function BombManager:fireBomb5Volley(bomb)
    for _, d in ipairs(generateSphereDirections(62)) do
        self:createBomb5Bullet(bomb.pos, d)
    end
end

function BombManager:updateBomb5Bullets()
    for i=#self.bomb5Bullets,1,-1 do
        local b = self.bomb5Bullets[i]
        if not b.active then b.model:remove(); table.remove(self.bomb5Bullets,i)
        else
            b.pos = b.pos + b.vel * 0.05
            b.model:setPos(b.pos*16)
            b.lifetime = b.lifetime - 1
            if isSolidBlock(b.pos) or b.lifetime <= 0 then
                particles:newParticle("minecraft:soul_fire_flame", b.pos):setScale(0.8)
                b.active = false
            end
        end
    end
end

-- ========== Bomb6 专属子弹 ==========
function BombManager:createBomb6Bullet3(pos, dir)
    local bt = models.Bomb.World.Bullet3
    if not bt then return end
    local m = bt:copy("bullet3_"..math.random(100000,999999))
    m:setParentType("WORLD"):setVisible(true):setPrimaryRenderType("EMISSIVE_SOLID")
    models.Bomb.World:addChild(m)
    local b = { model=m, pos=pos:copy(), vel=dir:normalized():scale(2), active=true, lifetime=160 }
    table.insert(self.bomb6Bullets3, b)
end

function BombManager:updateBomb6Bullets3()
    for i=#self.bomb6Bullets3,1,-1 do
        local b = self.bomb6Bullets3[i]
        if not b.active then b.model:remove(); table.remove(self.bomb6Bullets3,i)
        else
            b.pos = b.pos + b.vel * 0.05
            b.model:setPos(b.pos*16)
            b.lifetime = b.lifetime - 1
            if isSolidBlock(b.pos) or b.lifetime <= 0 then
                particles:newParticle("minecraft:flame", b.pos):setScale(0.8)
                b.active = false
            end
        end
    end
end

function BombManager:createBomb6Bullet2(pos, dir)
    local bt = models.Bomb.World.Bullet2
    if not bt then return end
    local m = bt:copy("bullet2_"..math.random(100000,999999))
    m:setParentType("WORLD"):setVisible(true):setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
    models.Bomb.World:addChild(m)
    local b = { model=m, pos=pos:copy(), vel=dir:normalized():scale(0.2), active=true, lifetime=160, age=0 }
    table.insert(self.bomb6Bullets2, b)
end

function BombManager:updateBomb6Bullets2()
    for i=#self.bomb6Bullets2,1,-1 do
        local b = self.bomb6Bullets2[i]
        if not b.active then b.model:remove(); table.remove(self.bomb6Bullets2,i)
        else
            b.age = b.age + 1
            if b.age == 20 then
                b.vel = b.vel:normalized():scale(3)
            end
            b.pos = b.pos + b.vel * 0.05
            b.model:setPos(b.pos*16)
            b.lifetime = b.lifetime - 1
            if isSolidBlock(b.pos) or b.lifetime <= 0 then
                particles:newParticle("minecraft:happy_villager", b.pos):setScale(0.8)
                b.active = false
            end
        end
    end
end

function BombManager:triggerBomb6(bomb)
    for _, d in ipairs(generateSphereDirections(62)) do
        self:createBomb6Bullet3(bomb.pos, d)
    end
    bomb.phase = 1
    bomb.phaseTimer = 0
    bomb.triggered = true
end

function BombManager:fireBomb6Bullet2Volley(bomb)
    local baseDirs = {
        vec(0,1,0), vec(0,-1,0),
        vec(0,0,1), vec(0,0,-1),
        vec(1,0,0), vec(-1,0,0)
    }
    for _, base in ipairs(baseDirs) do
        local offsetAngle = math.rad(math.random() * 30)
        local perp = (math.abs(base.y) < 0.9) and vec(0,1,0) or vec(1,0,0)
        local axis = base:crossed(perp):normalized()
        local dir = vectors.rotateAroundAxis(offsetAngle, base, axis)
        self:createBomb6Bullet2(bomb.pos, dir)
    end
end

-- ========== Bomb7 专属子弹 ==========
function BombManager:createBomb7Bullet(pos, dir, leader)
    local bt = models.Bomb.World.Bullet6
    if not bt then return end
    local m = bt:copy("bullet6_" .. math.random(100000, 999999))
    m:setParentType("WORLD"):setVisible(true):setPrimaryRenderType("EMISSIVE_SOLID")
    models.Bomb.World:addChild(m)

    local b = {
        model = m,
        pos = pos:copy(),
        vel = leader and vec(0, 0, 0) or dir:normalized():scale(1.5),
        active = true,
        lifetime = 160,
        age = 0,
        leader = leader,
        spacing = 0.06,
        perpAccel = 0.40,            -- 向心加速度大小
    }
    table.insert(self.bomb7Bullets, b)
    return b
end

function BombManager:updateBomb7Bullets()
    local dt = 1 / 20
    for i = #self.bomb7Bullets, 1, -1 do
        local b = self.bomb7Bullets[i]
        if not b.active then
            b.model:remove()
            table.remove(self.bomb7Bullets, i)
        else
            b.age = b.age + 1

            if b.leader and b.leader.active then
                local leadVel = b.leader.vel
                if leadVel:length() > 0.001 then
                    b.pos = b.leader.pos - leadVel:normalized() * b.spacing
                    b.vel = leadVel
                else
                    b.pos = b.leader.pos
                    b.vel = vec(0, 0, 0)
                end
            else
                if b.vel:length() > 0.001 then
                    local vDir = b.vel:normalized()
                    local axis = vDir:crossed(vec(0, 1, 0))
                    if axis:length() < 0.1 then
                        axis = vDir:crossed(vec(1, 0, 0))
                    end
                    local perpDir = axis:normalized()
                    b.vel = b.vel + perpDir * b.perpAccel * dt
                    b.vel = b.vel:normalized():scale(1.5)
                end
            end

            b.pos = b.pos + b.vel * dt
            b.model:setPos(b.pos * 16)

            if b.vel:length() > 0.01 then
                local lookDir = b.vel:normalized()
                local yaw = math.atan2(lookDir.x, lookDir.z)
                local pitch = -math.asin(lookDir.y)
                b.model:setRot(math.deg(pitch), math.deg(yaw), 0)
            end

            b.lifetime = b.lifetime - 1

            if isSolidBlock(b.pos) or b.lifetime <= 0 then
                particles:newParticle("minecraft:flame", b.pos):setScale(0.8)
                b.active = false
            end
        end
    end
end

function BombManager:fireBomb7Volley(bomb)
    local dirs = generateSphereDirections(62)
    local baseDir = dirs[math.random(62)]:normalized()
    local perp = (math.abs(baseDir.y) < 0.9) and vec(0, 1, 0) or vec(1, 0, 0)
    local axis = baseDir:crossed(perp):normalized()
    local finalDir = vectors.rotateAroundAxis(math.rad(30), baseDir, axis)

    local previous = nil
    for _ = 1, 5 do
        previous = self:createBomb7Bullet(bomb.pos, finalDir, previous)
    end
end

-- ========== 爆炸与回收 ==========
function BombManager:explodeBomb(bomb, bulletManager)
    local pos = bomb.rigidbody and bomb.rigidbody.pos or bomb.pos
    local bombType = self.config.TYPES[bomb.typeIndex]
    if bombType and bombType.explosion then
        bombType.explosion(pos, { bulletManager = bulletManager })
    end
end

function BombManager:scheduleRigidbodyRemoval(rigidbody)
    if rigidbody and not rigidbody._pendingRemove then
        rigidbody.bodyCollision = false
        rigidbody.worldCollision = false
        rigidbody.isSleeping = true
        rigidbody.model:setVisible(false)
        rigidbody._pendingRemove = true
        table.insert(self.pendingRigidbodyRemoval, rigidbody)
    end
end

function BombManager:flushPendingRemovals()
    for _, rb in ipairs(self.pendingRigidbodyRemoval) do
        rb:remove()
    end
    self.pendingRigidbodyRemoval = {}
end

function BombManager:removeBomb(bomb)
    if bomb.rigidbody then
        self:scheduleRigidbodyRemoval(bomb.rigidbody)
    elseif bomb.model then
        bomb.model:remove()
    end
end

-- ========== 主更新循环 ==========
function BombManager:update(bulletManager)
    self:flushPendingRemovals()
    self.bulletManager = bulletManager

    if self.cooldown > 0 then
        self.cooldown = self.cooldown - 1
    end

    -- 普通炸弹更新
    for i = #self.bombs, 1, -1 do
        local bomb = self.bombs[i]
        if bomb.active then
            bomb.lifetime = bomb.lifetime - 1
            if bomb.lifetime <= 0 then
                self:explodeBomb(bomb, bulletManager)
                bomb.active = false
            end
        end
        if not bomb.active then
            self:removeBomb(bomb)
            table.remove(self.bombs, i)
        end
    end

    -- 飞行炸弹更新
    for i = #self.flyingBombs, 1, -1 do
        local bomb = self.flyingBombs[i]
        if not bomb.active then
            self:removeBomb(bomb)
            table.remove(self.flyingBombs, i)
        elseif bomb.flying then
            bomb.lifetime = bomb.lifetime - 1

            -- Bomb4 向下子弹
            if bomb.typeIndex == 4 then
                bomb.fireTimer = bomb.fireTimer + 1/20
                if bomb.fireTimer >= 2.0 then
                    bomb.fireTimer = 0
                    self:createBomb4Bullet(bomb.pos)
                end
            end

            -- Bomb5 球弹幕
            if bomb.typeIndex == 5 then
                local dt = 1/20
                bomb.cycleTimer = bomb.cycleTimer + dt
                if bomb.cycleTimer >= 5.0 then
                    bomb.cycleTimer = bomb.cycleTimer - 5.0
                    bomb.burstTimer = 0
                end
                if bomb.cycleTimer < 2.0 then
                    bomb.burstTimer = bomb.burstTimer + dt
                    if bomb.burstTimer >= 1.0 then
                        bomb.burstTimer = 0
                        self:fireBomb5Volley(bomb)
                    end
                end
            end

            -- Bomb6 特殊攻击
            if bomb.typeIndex == 6 then
                if not bomb.triggered and bomb.lifetime <= 100 then
                    self:triggerBomb6(bomb)
                end
                if bomb.triggered then
                    if bomb.phase == 1 then
                        bomb.phaseTimer = bomb.phaseTimer + 1
                        if bomb.phaseTimer >= 2 then
                            bomb.phase = 2
                            bomb.phaseTimer = 0
                            bomb.phase2Tick = 0
                        end
                    elseif bomb.phase == 2 then
                        if bomb.phase2Tick < 10 then
                            self:fireBomb6Bullet2Volley(bomb)
                            bomb.phase2Tick = bomb.phase2Tick + 1
                        else
                            bomb.phase = 3
                        end
                    end
                end
            end

            -- Bomb7 弹幕组
            if bomb.typeIndex == 7 then
                if not bomb.triggered and bomb.lifetime <= 160 then
                    bomb.triggered = true
                    bomb.bomb7FireTimer = 0
                end
                if bomb.triggered then
                    bomb.bomb7FireTimer = bomb.bomb7FireTimer + 1
                    if bomb.bomb7FireTimer >= 2 then
                        bomb.bomb7FireTimer = 0
                        self:fireBomb7Volley(bomb)
                    end
                end
            end

            -- 盘旋移动
            if bomb.targetTimer <= 0 then
                local p = player:getPos()
                local eyeY = player:getEyeHeight()
                local rx = (math.random() * 2 - 1) * 10
                local rz = (math.random() * 2 - 1) * 10
                local ry = math.random() * 5
                bomb.targetPos = p + vec(rx, eyeY + ry, rz)
                bomb.targetTimer = 20 + math.random(20)
            else
                bomb.targetTimer = bomb.targetTimer - 1
            end

            local toTarget = bomb.targetPos - bomb.pos
            local dist = toTarget:length()
            local newPos = bomb.pos
            if dist > 0.1 then
                local step = toTarget:normalized() * 0.15
                newPos = bomb.pos + step
            end

            if isSolidBlock(newPos) then
                self:explodeBomb(bomb, bulletManager)
                bomb.active = false
            else
                bomb.pos = newPos
                bomb.model:setPos(newPos * 16)
            end

            for _, other in pairs(world.getPlayers()) do
                if other ~= player then
                    if (bomb.pos - other:getPos()):length() < 1.5 then
                        self:explodeBomb(bomb, bulletManager)
                        bomb.active = false
                        break
                    end
                end
            end

            if bomb.lifetime <= 0 then
                bomb.flying = false
                bomb.vel = vectors.vec3(0, -5, 0)
            end
        else
            -- 自由落体
            local dt = 1/20
            local gravity = vec(0, -5, 0)
            bomb.vel = bomb.vel + gravity * dt
            local nextPos = bomb.pos + bomb.vel * dt

            if isSolidBlock(nextPos) then
                self:explodeBomb(bomb, bulletManager)
                bomb.active = false
            else
                bomb.pos = nextPos
                bomb.model:setPos(nextPos * 16)
            end

            if not bomb.fallTimer then
                bomb.fallTimer = 100
            else
                bomb.fallTimer = bomb.fallTimer - 1
                if bomb.fallTimer <= 0 then
                    self:explodeBomb(bomb, bulletManager)
                    bomb.active = false
                end
            end
        end
    end

    -- 更新各弹幕
    self:updateBomb4Bullets()
    self:updateBomb5Bullets()
    self:updateBomb6Bullets3()
    self:updateBomb6Bullets2()
    self:updateBomb7Bullets()
end

function BombManager:launch()
    if self.cooldown > 0 then
        sounds:playSound("minecraft:block.dispenser.fail", player:getPos(), 0.5, 1)
        return
    end
    self.cooldown = 20
    local eyePos = player:getPos():add(0, player:getEyeHeight(), 0)

    if self.currentType >= 4 and self.currentType <= 8 then
        self:createFlyingBomb(eyePos)
    else
        local dir = player:getLookDir()
        self:createBomb(eyePos, dir)
    end
end

function BombManager:switchType()
    self.currentType = self.currentType % #self.config.TYPES + 1
    print("已切换到: " .. self.config.TYPES[self.currentType].name)
    sounds:playSound("minecraft:block.note_block.hat", player:getPos(), 0.5, 2)
end

-- ========== 输入绑定 ==========
local InputManager = {}
InputManager.__index = InputManager

function InputManager:new(launchCallback, switchCallback)
    local obj = {}
    setmetatable(obj, self)
    obj:bindKeys(launchCallback, switchCallback)
    return obj
end

function InputManager:bindKeys(launchCallback, switchCallback)
    keybinds:newKeybind("发射炸弹", "key.keyboard.v").press = launchCallback
    keybinds:newKeybind("切换炸弹类型", "key.keyboard.g").press = switchCallback
end

-- ========== 主入口 ==========
local function main()
    local bulletRoot = models:newPart("bullet_root", "World")

    local bulletManager = nil
    if models.Bomb and models.Bomb.World and models.Bomb.World.Bullet2 then
        local bulletTemplate = models.Bomb.World.Bullet2
        bulletTemplate:setVisible(false)
        bulletManager = BulletManager:new(bulletTemplate, bulletRoot)
    else
        print("警告: 未找到子弹模型 Bullet2")
    end

    local bombManager = BombManager:new(BombConfig, PhysicsPresets)
    bombManager:init()

    InputManager:new(
        function() bombManager:launch() end,
        function() bombManager:switchType() end
    )

    events.TICK:register(function()
        bombManager:update(bulletManager)
        if bulletManager then
            bulletManager:update()
        end
    end)
end

function events.entity_init()
    main()
end
