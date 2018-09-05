local Augmented = class()

local Plane

if cmodule then
    Plane = cimport "ARPlane"
end

function Augmented:init(t,s,a)
    self.scene = s
    self.action = a
    if t then
        t:pushHandler(self)
    end
    self.placed = false
end

function Augmented:start()
    if not self.active or not craft.ar.isSupported then
        return
    end
    local grid = readImage("Documents:GridWhite")
    local planes={}
    self.scene.ar:run()
    
    self.scene.ar.didAddAnchors = function(anchors)
        for k,v in pairs(anchors) do
            local p = scene:entity():add(Plane, v, grid)
            planes[v.identifier] = p
        end
    end
    
    self.scene.ar.didUpdateAnchors = function(anchors)
        for k,v in pairs(anchors) do
            local p = planes[v.identifier]
            p:updateWithAnchor(v)
        end
    end
    
    self.scene.ar.didRemoveAnchors = function(anchors)
        for k,v in pairs(anchors) do
            local p = planes[v.identifier]
            p.entity:destroy()
            planes[v.identifier] = nil
        end
    end
end

function Augmented:isTouchedBy(t)
    if not self.active or not craft.ar.isSupported then
        return false
    end
    if not self.placed then
        local results = self.scene.ar:hitTest(vec2(t.x, t.y),AR_EXISTING_PLANE_CLIPPED)
        local c = self.scene.camera:get(craft.camera)
        for k,v in pairs(results) do
            self.hit = v
            c.mask = 1
            if self.action then
                self.action(v)
            end
            if self.entity then
                self.entity.position = v.position
                self.entity.rotation = v.rotation
                self.entity.active = true
-- self.entity.scale = v.extent
            end
            self.placed = true
            return true
        end
        c.mask = ~0
        return false
    else
        return false
    end
end

function Augmented:processTouches(g)
    g:noted()
    if g.type.ended then
        g:reset()
    end
end

local exports = {}

if cmodule then
    cmodule.export(exports)
    return Augmented
else
    _G["Augmented"] = Augmented
    for k,v in pairs(exports) do
        _G[k] = v
    end
end