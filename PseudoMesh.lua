local PseudoMesh = class()

function PseudoMesh:init()
    self.vertices = {}
    self.texCoords = {}
    self.normals = {}
    self.colors = {}
    self.size = 0
end

function PseudoMesh:vertex(k,v)
    if v then
        self.vertices[k] = v
    else
        return self.vertices[k]
    end
end

function PseudoMesh:normal(k,v)
    if v then
        self.normals[k] = v
    else
        return self.normals[k]
    end
end

function PseudoMesh:texCoord(k,v)
    if v then
        self.texCoords[k] = v
    else
        return self.texCoords[k]
    end
end

function PseudoMesh:color(k,v)
    if v then
        self.colors[k] = v
    else
        return self.colors[k]
    end
end

function PseudoMesh:resize(k)
    self.size = k
end

local mm = getmetatable(mesh())

function PseudoMesh:addJewel(t)
    return mm.addJewel(self,t)
end

function PseudoMesh:addPyramid(t)
    return mm.addPyramid(self,t)
end

function PseudoMesh:addPolygon(t)
    return mm.addPolygon(self,t)
end

function PseudoMesh:addBlock(t)
    return mm.addBlock(self,t)
end

function PseudoMesh:addCylinder(t)
    return mm.addCylinder(self,t)
end

function PseudoMesh:addSphere(t)
    return mm.addSphere(self,t)
end

function PseudoMesh:addSphereSegment(t)
    return mm.addSphereSegment(self,t)
end

function PseudoMesh:invertNormals()
    for k,v in ipairs(self.normals) do
        self.normals[k] = -v
    end
end


function PseudoMesh:toModel()
    local m = craft.model()
    local i = {}
    local n = #self.vertices
    for k=1,n,3 do
        if (self.vertices[k+1] - self.vertices[k]):cross(self.vertices[k+2] - self.vertices[k]):dot(self.normals[k+1] + self.normals[k+2] + self.normals[k]) < 0 then
            table.insert(i,k)
            table.insert(i,k+1)
            table.insert(i,k+2)
        else
            table.insert(i,k)
            table.insert(i,k+2)
            table.insert(i,k+1)
        end
    end
    m.positions = self.vertices
    m.normals = self.normals
    m.uvs = self.texCoords
    m.colors = self.colors
    m.indices = i
    return m
end

function extendModel()

    local mt = getmetatable(craft.model)
    if mt.__extended then
        return true
    end

    local mm = getmetatable(mesh())
    if not mm.__extended then
        return false
    end

    rawset(mt,"jewel", function(t)
        local m = PseudoMesh()
        mm.addJewel(m,t)
        return m:toModel()
    end)
    
    rawset(mt,"pyramid", function(t)
        local m = PseudoMesh()
        mm.addPyramid(m,t)
        return m:toModel()
    end)
    
    rawset(mt,"polygon", function(t)
        local m = PseudoMesh()
        mm.addPolygon(m,t)
        return m:toModel()
    end)
    
    rawset(mt,"block", function(t)
        local m = PseudoMesh()
        mm.addBlock(m,t)
        return m:toModel()
    end)

    rawset(mt,"cylinder", function(t)
        local m = PseudoMesh()
        mm.addCylinder(m,t)
        return m:toModel()
    end)

    rawset(mt,"sphere", function(t)
        local m = PseudoMesh()
        mm.addSphere(m,t)
        return m:toModel()
    end)

    rawset(mt,"sphereSegment", function(t)
        local m = PseudoMesh()
        mm.addSphereSegment(m,t)
        return m:toModel()
    end)

    rawset(mt,"__extended",true)
    return true
end

local exports = {
    extendModel = extendModel
}

if craft.model then
    if extendModel() then
        exports = {}
    end
end

if cmodule then
    cmodule.export(exports)
    return PseudoMesh
else
    _G["PseudoMesh"] = PseudoMesh
    for k,v in pairs(exports) do
        _G[k] = v
    end
end
