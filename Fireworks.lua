-- Firework display
-- Authors: Stavrogin (original standalone program)
--          Andrew Stacey (conversion to "celebration" class)
-- Websites: http://pagantongue.posterous.com/fireworks
--           http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: unknown

local NUMSTARS = 50
local COLOURS = {
        color(255, 0, 0, 125),
        color(255, 227, 0, 125),
        color(99, 255, 0, 125),
        color(0, 140, 255, 125),
        color(238, 0, 255, 125),
        color(255, 156, 0, 125),
        color(0, 255, 189, 125),
        color(255, 0, 146, 125)
        }

local Stars = 1
local See_Smoke = 1
local Firework_Parts = 100
local Life = 30
local Life_Variation = 100
local Air_Resistance = 0.1
local PartSize = 35
local PartSize_Variation = 50
local Velocity = 10
local Velocity_Variation = 100
local Color_Variation = 50

local Fireworks = class()

function Fireworks:init()
    self.stars = {}
    self.fireworks = {}
    self.smokes = {}
    for i=0,NUMSTARS do
        self.stars[i] = {x=math.random(WIDTH),y=math.random(HEIGHT)}
    end
    self.active = false
end

function Fireworks:draw()
    pushStyle()
    noSmooth()
        fill(0, 0, 0, 125)
        rect(0,0,WIDTH,HEIGHT)
    
    -- draw stars
    if Stars == 1 then
        for i=0, NUMSTARS do
            fill(255, 255, 255, math.random(255))
            rect(self.stars[i].x,
                self.stars[i].y,
                math.random(3),
                math.random(3))
        end
    end
    local dead = true
    if self.ftimes[self.nfw] then
        if ElapsedTime - self.fstart > self.ftimes[self.nfw] then
            self.nfw = self.nfw + 1
            self.fstart = ElapsedTime
            sound(SOUND_EXPLODE)
        end
        dead = false
    end
    local sm,fw
    for k = 1,self.nfw do
        sm = self.smokes[k]
        fw = self.fireworks[k]
        
        if not sm:isDead() then
            dead = false
            sm:draw()
        end
        if not fw:isDead() then
            dead = false
            fw:draw()
        end
    end
    if dead then
        self.active = false
    end
    popStyle()
    return self.nfw
end

function Fireworks:newshow(p)
    self.fireworks = {}
    self.smokes = {}
    self.ftimes = {}
    if not p then
        local n = math.random(4,8)
        p = {}
        for i = 1,n do
            table.insert(p,{
                math.random(50,WIDTH - 50),
                math.random(HEIGHT/2,HEIGHT - 50)
                })
        end
    end
        local m,t
        for k,v in ipairs(p) do
            m = math.random(#COLOURS)
            
            table.insert(self.fireworks,Firework(v[1],v[2],COLOURS[m]))
            if See_Smoke == 1 then
                table.insert(self.smokes,Smoke(v[1],v[2],3))
            end
            t = math.random() + .5
            table.insert(self.ftimes,t)
            self.fstart = ElapsedTime
            self.nfw = 1
        end
        table.remove(self.ftimes)
        self.active = true
        sound(SOUND_EXPLODE)
end

local Firework = class()

function Firework:init(x,y,colour)
    -- you can accept and set parameters here
    self.p = {}
    self.numParticles = Firework_Parts
    for i=1,self.numParticles do
        local psize = genNumber(PartSize,PartSize_Variation)
        
        local v = vec2(math.random(-100,100),math.random(-100,100))
        v = v:normalize()
        v = v * genNumber(Velocity,Velocity_Variation)
        
        local c = color(genNumber(colour.r,Color_Variation),
                        genNumber(colour.g,Color_Variation),
                        genNumber(colour.b,Color_Variation),
                        colour.a
                        )
        
        self.p[i] = Particle(x,
                        y,
                        psize,
                        genNumber(Life,Life_Variation),
                        c,
                        v)
    end
end

function Firework:draw()
    local resistance = 1/(Air_Resistance + 1)
    local g = vec2(Gravity.x,Gravity.y)
    for i=1,self.numParticles do
        local p = self.p[i]
        
        p.x = p.x + p.v.x
        p.y = p.y + p.v.y
        
        p.v = p.v + g
        p.v = p.v * resistance
        
        local size = math.random(PartSize) * (p.lifeLeft/p.life)
        p.width = size
        p.height = size
        p:draw()
    end
end

function Firework:isDead()
    for i=1,self.numParticles do
        p = self.p[i]
        if p.lifeLeft ~= 0 and
            (p.x>0 and p.x<WIDTH and p.y>0 and p.y<HEIGHT)then
            return false
        end
    end
    return true
end

local Particle = class()

Particle.DEFAULT_OPACITY = 125
Particle.DEFAULT_ANGLE = 0
Particle.DEFAULT_MASS = 1

function Particle:init(posx,posy,size,life,colour,
    velocity,mass,angle,sprite)
    -- position
    self.x = posx
    self.y = posy
    self.ox = 0
    self.oy = 0
    
    -- size
    self.width = size
    self.height = size
    
    -- color
    if colour == nil then
        self.color = color(255, 255, 255, 255)
    else
        self.color = colour
    end
    
    -- velocity
    self.v = velocity
    
    -- life
    self.life = life
    self.lifeLeft= life
    
    -- sprite
    self.sprite = sprite
    
    -- mass
    if mass == nil then
        self.mass = DEFAULT_MASS
    else
        self.mass = mass
    end
    
    -- angle
    if angle == nil then
        self.angle = self.DEFAULT_ANGLE
    else
        self.angle = angle
    end
end

function Particle:draw()
    if self.lifeLeft > 0 then
        self.lifeLeft = self.lifeLeft - 1
    end
    
    if self.lifeLeft ~= 0 then
        if self.sprite == nil then
            fill(self.color)
            ellipse(self.x,self.y,self.width,self.height)
        else
            pushMatrix()
            translate(self.x,self.y)
            rotate(self.angle)
            tint(self.color)
            sprite(self.sprite,0,0,self.width,self.height)
            popMatrix()
        end
    end
end

local function genNumber(number,variation)
    ret = variation*0.01*number
    ret = number + math.random(-ret,ret)
    return ret
end

local Smoke = class()

function Smoke:init(x,y,n)
    self.numparts = n
    -- color used to tint the particle
    local c = color(73, 73, 73, 69)
    -- name of the sprite of each smoke particle
    local s = "Tyrian Remastered:Dark Orb"
    
    self.parts = {}
    for i=0,n do
        -- initial size of the smoke particle
        local sz = genNumber(60,100)
        self.parts[i] = Particle(genNumber(x,20),
                            genNumber(y,20),sz,-7,c,nil,-1,genNumber(180,100),s)
    end
    -- rotation speed
    self.rSpeed = 0.5
    self.windX = 1
    self.windY = 1
end

function Smoke:draw()
    for i=1,self.numparts do
        local p = self.parts[i]
        if p.color.a > 0 then
        p.angle = p.angle + self.rSpeed
        p.width = p.width + 3
        p.height = p.height + 3
        p.color.a = p.color.a - 0.2
        p.x = p.x + self.windX
        p.y = p.y + self.windY
        p:draw()
        end
    end
end

function Smoke:isDead()
    for i=1,self.numparts do
        local p = self.parts[i]
        if p.color.a > 0 then
            return false
        end
    end
    return true
end

if cmodule then
    return Fireworks
else
    _G["Fireworks"] = Fireworks
end
