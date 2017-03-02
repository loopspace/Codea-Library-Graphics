-- Explosion

local expshader
local Explosion = class()

function Explosion:init(t)
    t = t or {}
    self.mesh = mesh()
    local s = shader()
    s.vertexProgram, s.fragmentProgram = expshader()
    self.mesh.shader = s
    self.mesh.texture = t.image
    self.mesh.shader.friction = t.friction or .1
    self.mesh.shader.separation = 0
    local ft = t.factor or 10
    self.mesh.shader.factor = ft
    local vels = self.mesh:buffer("velocity")
    local origin = self.mesh:buffer("origin")
    local angv = self.mesh:buffer("angvel")
    local lvl = self.mesh:buffer("level")
    local m = t.rows or 20
    local n = t.cols or 20
    vels:resize(m*n*6)
    origin:resize(m*n*6)
    angv:resize(m*n*6)
    lvl:resize(m*n*6)
    local c = t.centre
    local w,h
    if type(t.image) == "string" then
        local img = readImage(t.image)
        w,h = img.width,img.height
    else
        w,h = t.image.width,t.image.height
    end
    local w = t.width or w
    local h = t.height or h
    local om = t.angularSpeed or 1/ft
    local xx,y = c.x - w/2,c.y - h/2
    local cl = vec2(w,h):len()/2
    w,h = w/m,h/n
    xx,y = xx+w/2,y+h/2
    local r,th,sf,x,df,tth
    sf = .3
    df = math.random()
    for i=1,m do
        x = xx
        for j = 1,n do
            r = self.mesh:addRect(x,y,w,h)
            self.mesh:setRectTex(r,(j-1)/n,(i-1)/m,1/n,1/m)
            th = 2*noise(i*sf+df,j*sf+df)*math.pi
            tth = 2*om*noise(j*sf+df,i*sf+df)*math.pi
            for k=1,6 do
                vels[6*r-k+1] = 20*(2-(c:dist(vec2(x,y))/cl))^2
                        *vec4(math.cos(th),math.sin(th),0,0)
                origin[6*r-k+1] = vec2(x,y)
                angv[6*r-k+1] = vec2(tth,0)
                lvl[6*r-k+1] = 0
            end
            x = x + w
        end
        y = y + h
    end
    if t.trails then
        local ntr = t.trailLength or 16
        self.trails = mesh()
        self.trails:setColors(255,255,255,255)
        s = shader()
        s.vertexProgram, s.fragmentProgram = expshader()
        self.trails.shader = s
        self.trails.texture = t.image
        self.trails.shader.friction = t.friction or .1
        self.trails.shader.factor = ft
        self.trails.shader.separation = t.trailSeparation or .5
        vels = self.trails:buffer("velocity")
        origin = self.trails:buffer("origin")
        angv = self.trails:buffer("angvel")
        lvl = self.trails:buffer("level")
        vels:resize(ntr*m*n*6)
        origin:resize(ntr*m*n*6)
        angv:resize(ntr*m*n*6)
        lvl:resize(ntr*m*n*6)
        local yy
        xx,yy = c.x - (m-1)*w/2,c.y - (n-1)*h/2
        for l=1,ntr do
            y = yy
            for i=1,m do
                x = xx
                for j = 1,n do
                    r = self.trails:addRect(x,y,w,h)
                    self.trails:setRectTex(r,(j-1)/n,(i-1)/m,1/n,1/m)
                    self.trails:setRectColor(r,255,255,255,l*127/ntr)
                    th = 2*noise(i*sf+df,j*sf+df)*math.pi
                    tth = 2*om*noise(j*sf+df,i*sf+df)*math.pi
                    for k=1,6 do
                        vels[6*r-k+1] = 20*(2-(c:dist(vec2(x,y))/cl))^2
                                *vec4(math.cos(th),math.sin(th),0,0)
                        origin[6*r-k+1] = vec2(x,y)
                        angv[6*r-k+1] = vec2(tth,0)
                        lvl[6*r-k+1] = l - ntr - 1
                    end
                    x = x + w
                end
                y = y + h
            end
        end
    end
    self.start = ElapsedTime
end

function Explosion:draw()
    if not self.active then
        return
    end
    pushStyle()
    local time = ElapsedTime - self.start
    if not self.paused then
        if self.trails then
            blendMode(SRC_ALPHA,ONE)
            self.trails.shader.time = time
            self.trails:draw()
        end
        self.mesh.shader.time = time
    end
    blendMode(NORMAL)
    self.mesh:draw()
    if not self.paused then
        if self.stop and ElapsedTime > self.start + self.stop then
            self:deactivate()
        end
    end
    popStyle()
end

function Explosion:activate(t,s)
    t = t or 0
    self.start = ElapsedTime + t
    self.stop = s
    self.active = true
    self.paused = false
end

function Explosion:deactivate()
    self.active = false
end

function Explosion:pause()
    if self.paused then
        self.start = ElapsedTime - self.pausetime
        self.paused = false
    else
        self.paused = true
        self.pausetime = ElapsedTime - self.start
    end
end

expshader = function()
    return [[
//
// The explosion vertex shader
//
precision highp float;
//This is the current model * view * projection matrix
// Codea sets it automatically
uniform mat4 modelViewProjection;
uniform float time;
uniform float friction;
uniform float factor;
uniform float separation;

lowp vec4 gravity = vec4(0.,-1.,0.,0.);
mediump float mtime = max(0.,time)*factor;
//This is the current mesh vertex position, color and tex coord
// Set automatically
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;
// These are vertex buffers: initial velocity of the square,
// angular velocity,
// centre of square
attribute vec4 velocity;
attribute vec2 angvel;
attribute vec2 origin;
attribute float level;

//This is an output variable that will be passed to the fragment shader
varying lowp vec4 vColor;
varying highp vec2 vTexCoord;
//varying mediump float vLevel;

// ODE: x'' = -friction x' + gravity
// Solution: A exp(- friction * time) + B + time*gravity/friction
// Initial conditions:
// A = gravity/(friction*friction) - x'(0)/friction
// B = x(0) -A

void main()
{
    //Pass the mesh color to the fragment shader
    vColor = color;
    vTexCoord = texCoord;
    //vLevel = level;
    lowp vec4 pos;
    mediump float t = mtime + level * separation;

    lowp float angle = t*angvel.x;
    highp vec4 A = gravity/(friction*friction) - velocity/friction;
    highp vec4 B = vec4(origin,0.,0.) - A;
    lowp mat2 rot = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));

    pos = (position - vec4(origin,0.,0.));
    pos.xy = rot * pos.xy;
    pos += exp(-t*friction)*A + B + t * gravity/friction;
    if (level != 0. && t < 1.) pos = vec4(0.,0.,0.,1.);
    //Multiply the vertex position by our combined transform
    gl_Position = modelViewProjection * pos;
}
]],[[
//
// A basic fragment shader
//

//This represents the current texture on the mesh
uniform lowp sampler2D texture;

//The interpolated vertex color for this fragment
varying lowp vec4 vColor;

//The interpolated texture coordinate for this fragment
varying highp vec2 vTexCoord;

void main()
{
    //Sample the texture at the interpolated coordinate
    lowp vec4 col = texture2D( texture, vTexCoord );
    col *= vColor;
    //Set the output color to the texture color
    gl_FragColor = col;
}
]]
end

if cmodule then
    return Explosion
else
    _G["Explosion"] = Explosion
end

