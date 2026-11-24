-- Auto generated script file --

-- hide vanilla model
vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(false)
vanilla_model.HELMET_ITEM:setVisible(true)
vanilla_model.CAPE:setVisible(false)
vanilla_model.ELYTRA:setVisible(false)

-- ===================================================
-- 粒子生成抽象层（兼容 Minecraft 1.21.4 与 26.3+）
-- ===================================================
-- 说明：
--   * 1.21.9 / 26.x 起，带颜色选项的粒子（如 flash、dust 等）
--     必须在名称字符串中携带 SNBT 选项，否则会抛出
--     "No key color in MapLike[{}]" 之类的解析错误。
--   * 所有粒子生成统一走 spawnParticle，名字归一化和 newParticle 都在 pcall 内，
--     单个粒子失败不会中断整个脚本；首次失败会打印一次提示。
-- ===================================================

local particleSpawner = {}

-- 解析 Minecraft 版本（失败时按旧版处理，保证抽象层自身不崩）
local mcVersion = ""
pcall(function()
    local v = client.getVersion()
    -- 版本号必须是字符串：非字符串会让下面的 gmatch 在加载期抛错，整个脚本都起不来
    if v ~= nil then mcVersion = tostring(v) end
end)

local versionParts = {}
for num in mcVersion:gmatch("%d+") do
    versionParts[#versionParts + 1] = tonumber(num)
end
local mcMajor = versionParts[1] or 0
local mcMinor = versionParts[2] or 0
local mcPatch = versionParts[3] or 0

-- 1.21.9 / 26.x 起，彩色粒子需要 SNBT color 选项
local needsParticleOptions = false
if mcMajor > 1 then
    needsParticleOptions = true
elseif mcMajor == 1 then
    if mcMinor > 21 or (mcMinor == 21 and mcPatch >= 9) then
        needsParticleOptions = true
    end
end

-- 哑元粒子对象：生成失败时返回它，保证链式调用（:setScale 等）不会报错
local dummyParticle = {}
function dummyParticle:setScale()    return self end
function dummyParticle:setLifetime() return self end
function dummyParticle:setColor()    return self end
function dummyParticle:setOpacity()  return self end

-- 粒子名称/选项的版本转换
local function normalizeParticleId(name)
    -- 非字符串（调用方写错）原样返回，让它在外层 pcall 里失败，不在这里抛错
    if type(name) ~= "string" then return name end

    -- flash：新版需要显式颜色
    if name == "minecraft:flash" or name == "flash" then
        if needsParticleOptions then
            return "minecraft:flash{color:[1.0,1.0,1.0,1.0]}"
        end
        return "minecraft:flash"
    end

    -- dust：旧空格格式 -> 新版 SNBT；带不带 minecraft: 前缀都接受
    if needsParticleOptions then
        local body = name:match("^dust%s+(.*)$") or name:match("^minecraft:dust%s+(.*)$")
        if body then
            local r, g, b, a = body:match("^([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)")
            if r then
                r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
                -- 解析失败就原样返回，交给外层 pcall 决定是否降级，避免在兼容层里抛错
                if r and g and b and a then
                    return string.format(
                        "minecraft:dust{color:[%.2f,%.2f,%.2f,%.2f],scale:1.0}",
                        r, g, b, a
                    )
                end
            end
        end
    end

    return name
end

-- 统一粒子生成入口
local particleWarned = false

local function warnParticleFailure(name, err)
    -- 只提示一次：兼容层失效通常是一整类粒子都失效，逐次打印会把日志刷爆
    if particleWarned then return end
    particleWarned = true
    print("[Cocoa] 粒子生成失败（仅提示一次）: " .. tostring(name)
        .. " | " .. tostring(err) .. " | MC " .. tostring(mcVersion))
end

local function spawnParticle(name, pos, ...)
    -- 名字归一化也放进 pcall：坏名字或版本差异不能让 TICK 抛错停掉整个脚本
    local ok, particle = pcall(function(...)
        return particles:newParticle(normalizeParticleId(name), pos, ...)
    end, ...)
    if ok and particle then
        return particle
    end
    warnParticleFailure(name, particle)
    return dummyParticle
end

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
    spawnParticle("minecraft:explosion_emitter", pos):setScale(3)
    spawnParticle("minecraft:flash", pos):setScale(2)
    sounds:playSound("minecraft:entity.generic.explode", pos, 1.0, 1.0)
    for _ = 1, 40 do
        local offset = vectors.vec3(
            (math.random()*2-1), (math.random()*2-1), (math.random()*2-1)
        ):normalize():scale(math.random()*3)
        spawnParticle("minecraft:smoke", pos+offset):setScale(1.5):setLifetime(20)
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
            spawnParticle("minecraft:explosion_emitter", pos):setScale(5)
            spawnParticle("minecraft:flash", pos):setScale(3)
            sounds:playSound("minecraft:entity.generic.explode", pos, 1.2, 1.0)
            for _ = 1, 60 do
                local offset = vectors.vec3(
                    (math.random()*2-1), (math.random()*2-1), (math.random()*2-1)
                ):normalize():scale(math.random()*5)
                spawnParticle("minecraft:smoke", pos+offset):setScale(2):setLifetime(20)
            end
            for _ = 1, 30 do
                local offset = vectors.vec3(
                    (math.random()*2-1), (math.random()*2-1), (math.random()*2-1)
                ):normalize():scale(math.random()*4)
                spawnParticle("minecraft:flame", pos+offset):setScale(1):setLifetime(15)
            end

            local innerTemplate = models.Bomb.World.PillarInner
            local outerTemplate = models.Bomb.World.PillarOuter
            if innerTemplate and outerTemplate then
                -- 两根光柱都配置完再挂到场景：setter 在版本差异下抛错时不会留下
                -- “已添加但没有清理闭包”的孤儿（4096 倍光柱会一直留在世界里）
                local inner = innerTemplate:copy("pillar_inner_" .. math.random(100000,999999))
                    :setParentType("WORLD")
                    :setVisible(true)
                    :setPrimaryRenderType("EMISSIVE_SOLID")
                    :setPos(pos * 16)
                    :setScale(20, 4096, 20)

                local outer = outerTemplate:copy("pillar_outer_" .. math.random(100000,999999))
                    :setParentType("WORLD")
                    :setVisible(true)
                    :setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
                    :setColor(1, 0, 0)
                    :setOpacity(0.4)
                    :setPos(pos * 16)
                    :setScale(25, 4096, 25)

                models.Bomb.World:addChild(inner)
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
            spawnParticle("minecraft:explosion_emitter", pos):setScale(1.5)
            spawnParticle("minecraft:flash", pos):setScale(1)
            sounds:playSound("minecraft:entity.generic.explode", pos, 0.6, 0.7)
            for _ = 1, 15 do
                local offset = vectors.vec3(
                    (math.random()*2-1), (math.random()*2-1), (math.random()*2-1)
                ):normalize():scale(math.random()*1.5)
                spawnParticle("minecraft:smoke", pos+offset):setScale(1):setLifetime(10)
            end
            for _ = 1, 20 do
                local offset = vectors.vec3(
                    (math.random()*2-1), (math.random()*2-1), (math.random()*2-1)
                ):normalize():scale(math.random()*1.5)
                spawnParticle("minecraft:soul_fire_flame", pos+offset):setScale(0.8):setLifetime(10)
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
            spawnParticle("minecraft:explosion_emitter", pos):setScale(4)
            spawnParticle("minecraft:flash", pos):setScale(3)
            sounds:playSound("minecraft:entity.generic.explode", pos, 1.5, 0.8)
            -- 生成 200 个灵魂火粒子，半径 3 格
            for _ = 1, 200 do
                local offset = vectors.vec3(
                    (math.random()*2-1), (math.random()*2-1), (math.random()*2-1)
                ):normalized():scale(math.random() * 3)
                spawnParticle("minecraft:soul_fire_flame", pos + offset)
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
    -- 先配置再挂到场景：setter 抛错时不会留下已添加、未入表的孤儿模型
    copyModel:setVisible(true)
    copyModel:setPos(pos * 16)
    copyModel:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
    self.root:addChild(copyModel)
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
                spawnParticle("minecraft:soul_fire_flame", b.pos):setScale(0.8)
                b.active = false
            elseif b.lifetime <= 0 then
                spawnParticle("minecraft:soul_fire_flame", b.pos):setScale(0.8)
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
            -- 模型缺失时继续取子节点会索引 nil；提前退出，让下面的 if 走警告分支
            if not mdl then break end
            mdl = mdl[part]
        end
        if mdl then
            self.models[i] = mdl
            mdl:setVisible(false)
        else
            print("警告: 未找到模型 " .. table.concat(bt.modelPath, "/") .. "！")
        end
    end

    -- 隐藏光柱模板（Bomb 模型缺失时不能在这里抛错，否则 init 中断、整个脚本都起不来）
    if models.Bomb and models.Bomb.World then
        if models.Bomb.World.PillarInner then
            models.Bomb.World.PillarInner:setVisible(false)
        end
        if models.Bomb.World.PillarOuter then
            models.Bomb.World.PillarOuter:setVisible(false)
        end
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
    -- Fidget 只在 MAX 权限下加载 rigidbodies；非 MAX 观者端这里不判空会报错，
    -- 而 Figura 的未捕获错误会停掉整个脚本，所以直接当作“无法生成”跳过
    if not Fidget.rigidbodies then return nil end

    local preset = self.presets[bombType.physicsPreset] or self.presets.DEFAULT
    local vel = direction:copy():normalize():scale(preset.launchSpeed)

    sounds:playSound("minecraft:entity.firework_rocket.launch", startPos, 0.8, 1.2)
    spawnParticle("minecraft:smoke", startPos):setScale(0.5)

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
-- Bomb4 子弹只有撞方块才会移除；在虚空/未加载区块上空会永远下落。
-- 这里加一个寿命兜底，正常地形仍会提前撞地，不会看到差别。
local BOMB4_BULLET_LIFETIME = 400

function BombManager:createBomb4Bullet(pos)
    local bt = models.Bomb.World.Bullet4
    if not bt then return end
    local m = bt:copy("bullet4_" .. math.random(100000,999999))
    m:setParentType("WORLD"):setVisible(true):setScale(4,4,4):setPrimaryRenderType("EMISSIVE_SOLID")
    models.Bomb.World:addChild(m)
    local b = {
        model = m, pos = pos:copy(), vel = vec(0,-2,0),
        active = true, rotationAngle = 0, particleTimer = 0,
        lifetime = BOMB4_BULLET_LIFETIME
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
            b.lifetime = b.lifetime - 1
            b.particleTimer = b.particleTimer + 1
            if b.particleTimer >= 8 then
                b.particleTimer = 0
                spawnParticle("dust 0.2 0.6 1 1", b.pos):setScale(0.8):setLifetime(15)
            end
            -- 撞方块或寿命耗尽都走同一个爆炸：超时只在永远落不到地面的情况下触发，
            -- 不应该静默消失（视觉上要像一次撞击/爆炸）
            if isSolidBlock(b.pos) or b.lifetime <= 0 then
                for _=1,20 do
                    local t = math.random()*2*math.pi; local p = math.acos(2*math.random()-1)
                    local x,y,z = 0.5*math.sin(p)*math.cos(t), 0.5*math.sin(p)*math.sin(t), 0.5*math.cos(p)
                    spawnParticle("dust 0.2 0.6 1 1", b.pos+vec(x,y,z)):setScale(0.5):setLifetime(20)
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
    local nd = dir:normalized()
    local look = -nd
    local yaw = math.atan2(look.x, look.z)
    local pitch = -math.asin(look.y)
    -- setRot 也是 setter，放在 addChild 之前，失败时不会留下孤儿模型
    m:setRot(math.deg(pitch), math.deg(yaw), 0)
    models.Bomb.World:addChild(m)
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
                spawnParticle("minecraft:soul_fire_flame", b.pos):setScale(0.8)
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
                spawnParticle("minecraft:flame", b.pos):setScale(0.8)
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
                spawnParticle("minecraft:happy_villager", b.pos):setScale(0.8)
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

-- Bomb7 每 tick 的方块查询去重：同一条链的 5 节经常在同一方块里，
-- 缓存上一次查询的方块坐标和结果，避免对同一方块重复调用 getBlockState/hasCollision。
local b7CacheX, b7CacheY, b7CacheZ, b7CacheSolid

local function isSolidBlockBomb7(pos)
    local x, y, z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
    if x == b7CacheX and y == b7CacheY and z == b7CacheZ then
        return b7CacheSolid
    end
    b7CacheSolid = isSolidBlock(pos)
    b7CacheX, b7CacheY, b7CacheZ = x, y, z
    return b7CacheSolid
end

function BombManager:updateBomb7Bullets()
    -- 每 tick 清空：同一 tick 内方块状态不会变，复用结果是安全的
    b7CacheX, b7CacheY, b7CacheZ = nil, nil, nil
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

            if isSolidBlockBomb7(b.pos) or b.lifetime <= 0 then
                spawnParticle("minecraft:flame", b.pos):setScale(0.8)
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
        -- pcall 兜底：单次爆炸效果异常不影响主循环
        local ok, err = pcall(bombType.explosion, pos, { bulletManager = bulletManager })
        if not ok then
            -- print("[Bomb] 爆炸效果异常: " .. tostring(err))
        end
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
