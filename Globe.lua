local Globe = class()

local marslighting
--[[
local Colour = cimport "Colour"
cimport "TouchUtilities"
--]]
function Globe:init(r,t)
    local m = mesh()
    m.texture = t
    m.shader = marslighting()
    m.shader.ambient = 1
    m.shader.light = vec3(0,0,1)
    m:addSphere({
        radius = r,
        colour = Colour.svg.White
    })
    self.mesh = m
    self.radius = r
    self.texture = readImage(t)
    self.tw,self.th = spriteSize(self.texture)
    local tm = mesh()
    tm.shader = lighting()
    tm.shader.ambient = 1
    tm.shader.light = vec3(0,0,1)
    tm:addSphere({
        radius = .1,
        colour = Colour.svg.Yellow
    })
    self.tmesh = tm
end

function Globe:draw()
    self.matrix = modelMatrix()*viewMatrix()*projectionMatrix()
    self.mesh.shader.invModel = modelMatrix():inverse():transpose()
    self.mesh:draw()
    --[[
    if self.spt then
        pushMatrix()
        translate(self.radius*self.spt)
        self.tmesh.shader.invModel = modelMatrix():inverse():transpose()
        self.tmesh:draw()
        popMatrix()
    end
    --]]
end

function Globe:isTouchedBy(t)
    -- Store the matrix in effect at the start of the touch
    self.smatrix = self.matrix
    -- Compute the plane orthogonal to the ray defined by the touch
    local n,u,v = screenframe(t,self.matrix)
    -- Compute the touch point on that plane
    local tc = screentoplane(t,
                   vec3(0,0,0),
                   u,
                   v,
                   self.matrix)
    -- Was it inside the sphere?
    if tc:len() <= self.radius then
        self.plane = {vec3(0,0,0),u,v}
        self.smatrix = self.matrix
        self.starttouch = tc
        self.spt = (tc + math.sqrt(self.radius^2 - tc:lenSqr())*n:normalize()):normalize()
        local phi = math.atan(self.spt.y,self.spt.x)/(2*math.pi) + 1
        phi = phi - math.floor(phi)
        local theta = math.atan(self.spt.z,vec2(self.spt.x,self.spt.y):len())
        self.tcoords = vec2(phi,-theta/math.pi + .5)
        self.tcolour = color(self.texture:get(math.floor(self.tcoords.x * self.tw + .5),math.floor(self.tcoords.y * self.th + .5)))
        -- print(self.tcolour)
        -- print(phi,theta)
        return true
    end
    -- self.spt = nil
    -- self.tcoords = nil
    return false
end

function Globe:processTouches(g)
    local t = g.touchesArr[1].touch
    local n,u,v = screenframe(t,self.matrix)
    -- Compute the touch point on that plane
    local tc = screentoplane(t,
                   vec3(0,0,0),
                   u,
                   v,
                   self.matrix)
    g:noted()
end

function marslighting()
    return shader([[
    //
// A basic vertex shader
//

//This is the current model * view * projection matrix
// Codea sets it automatically
uniform mat4 modelViewProjection;
uniform mat4 invModel;
//This is the current mesh vertex position, color and tex coord
// Set automatically
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;
attribute vec3 normal;

//This is an output variable that will be passed to the fragment shader
varying lowp vec4 vColor;
varying highp vec2 vTexCoord;
varying highp vec3 vNormal;

void main()
{
    //Pass the mesh color to the fragment shader
    vColor = color;
    vTexCoord = texCoord;
    highp vec4 n = invModel * vec4(normal,0.);
    vNormal = n.xyz;
    //Multiply the vertex position by our combined transform
    gl_Position = modelViewProjection * position;
}

]],[[
    //
// A basic fragment shader
//

//Default precision qualifier
precision highp float;

//This represents the current texture on the mesh
uniform lowp sampler2D texture;
uniform highp vec3 light;
uniform lowp float ambient;
//The interpolated vertex color for this fragment
varying lowp vec4 vColor;

//The interpolated texture coordinate for this fragment
varying highp vec2 vTexCoord;
varying highp vec3 vNormal;

void main()
{
    //Sample the texture at the interpolated coordinate
    lowp vec4 col = vColor;//vec4(1.,0.,0.,1.);
    col *= texture2D( texture, vTexCoord );

    lowp float c = ambient + (1.-ambient) * max(0.,dot(light, normalize(vNormal)));
    col.xyz *= c;
    //Set the output color to the texture color
    gl_FragColor = col;
}

    ]]
    )
end

if cmodule then
    return Globe
else
    _G["Globe"] = Globe
end