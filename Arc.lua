-- Arc path drawing

local Arc = class()

local m

local __makeArc = function(nsteps)
    -- nsteps doesn't make a huge difference in the range 50,300
    nsteps = nsteps or 50
    local m = mesh()
    m.shader = shader([[
//
// A basic vertex shader
//

//This is the current model * view * projection matrix
// Codea sets it automatically
uniform mat4 modelViewProjection;
uniform lowp vec4 scolour;
uniform lowp vec4 ecolour;
lowp vec4 mcolour = ecolour - scolour;
//This is the current mesh vertex position, color and tex coord
// Set automatically
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

varying highp vec2 vTexCoord;
varying lowp vec4 vColour;
varying highp float vWidth;
varying highp float vCore;

uniform float width;
uniform float taper;
uniform float blur;
uniform float cap;
uniform float scap;
uniform float ecap;
float swidth = width + blur;
float ewidth = taper*width - width;
float ecapsw = clamp(cap,0.,1.)*ecap;
float scapsw = clamp(cap,0.,1.)*scap;
uniform vec2 centre;
uniform vec2 xaxis;
uniform vec2 yaxis;
uniform float startAngle;
uniform float deltaAngle;

void main()
{
    highp float t = clamp(position.y,0.,1.);
    vCore = t;
    highp float w = smoothstep(0.,1.,t);
    vWidth = w*ewidth + swidth;
    highp vec2 bpos = centre + cos(t*deltaAngle + startAngle) * xaxis + sin(t*deltaAngle + startAngle) * yaxis;
    highp vec2 bdir = -sin(t*deltaAngle + startAngle) * xaxis + cos(t*deltaAngle + startAngle) * yaxis;
    bdir = vec2(bdir.y,-bdir.x);
    bdir = vWidth*normalize(bdir);
    bpos = bpos + position.x*bdir;
    highp vec4 bzpos = vec4(bpos.x,bpos.y,0.,1.);
    bzpos.xy += (ecapsw*max(position.y-1.,0.)
                +scapsw*min(position.y,0.))*vec2(-bdir.y,bdir.x);
    highp float s = clamp(position.y, 
            scapsw*position.y,1.+ecapsw*(position.y-1.));
    vTexCoord = vec2(texCoord.x,s);
    vColour = t*mcolour + scolour;
    //Multiply the vertex position by our combined transform
    gl_Position = modelViewProjection * bzpos;
}
]],[[
//
// A basic fragment shader
//

uniform highp float blur;
uniform highp float cap;

varying highp vec2 vTexCoord;
varying highp float vWidth;
varying lowp vec4 vColour;
varying highp float vCore;

void main()
{
    lowp vec4 col = vColour;
    highp float edge = blur/(vWidth+blur);
    col.a = mix( 0., col.a, 
            (2.-cap)*smoothstep( 0., edge, 
                min(vTexCoord.x,1. - vTexCoord.x) )
            * smoothstep( 0., edge, 
                min(1.5-vTexCoord.y, .5+vTexCoord.y) ) 
            + (cap - 1.)*smoothstep( 0., edge,
             .5-length(vTexCoord - vec2(.5,vCore)))
                );

    gl_FragColor = col;
}
]])

    for n=1,nsteps do
        m:addRect(0,(n-.5)/nsteps,1,1/nsteps)
    end
    m:addRect(0,1.25,1,.5)
    m:addRect(0,-.25,1,.5)
    m.shader.blur = 0 --2
    m.shader.cap = 2
    m.shader.scap = 1
    m.shader.ecap = 1
    return m
end

-- centre, xaxis, yaxis, startAngle, deltaAngle, taper
local function __arc(a,b,c,d,e,f,g)
    if type(a) == "table" then
        f = b
        a,b,c,d,e = unpack(a)
    end
    if type(a) ~= "userdata" then
        a = vec2(a,b)
        b,c,d,e,f = c,d,e,f,g
    end
    if type(b) ~= "userdata" then
        b = b*vec2(1,0)
    end
    if type(c) ~= "userdata" then
        c = c*vec2(0,1)
    end
    --m.shader.blur = 15
    m.shader.taper = f or 1
    m.shader.width = strokeWidth()
    m.shader.scolour = color(stroke())
    m.shader.ecolour = color(stroke())
    m.shader.cap = (lineCapMode()-1)%3
    m.shader.centre = a
    m.shader.xaxis = b
    m.shader.yaxis = c
    m.shader.startAngle = d
    m.shader.deltaAngle = e
    m:draw()
end

function arc(...)
    m = __makeArc()
    __arc(...)
    arc = __arc
end

function Arc:init(...)
    self:setParams(...)
end

function Arc:clone()
    return Arc(self.params)
end

function Arc:makeDrawable(t)
    t = t or {}
    local nsteps = t.steps or self.steps
    local m = __makeArc(nsteps)
    m.shader.taper = t.taper or self.taper or 1
    m.shader.blur = t.blur or self.blur or 2
    m.shader.cap = t.cap or self.cap or (lineCapMode()-1)%3
    m.shader.scap = t.scap or self.scap or 1
    m.shader.ecap = t.ecap or self.ecap or 1
    m.shader.width = t.width or self.width or strokeWidth()
    m.shader.scolour = t.scolour or self.scolour or t.colour or color(stroke())
    m.shader.ecolour = t.ecolour or self.ecolour or t.colour or color(stroke())
    local a,b,c,d,e = unpack(self.params)
    m.shader.centre = a
    m.shader.xaxis = b
    m.shader.yaxis = c
    m.shader.startAngle = d
    m.shader.deltaAngle = e
    self.curve = m
    self.draw = function(self) self.curve:draw() end
end

function Arc:draw(t)
    self:makeDrawable(t)
    self.curve:draw()
end

function Arc:setParams(a,b,c,d,e)
    if type(a) == "table" then
        a,b,c,d,e = unpack(a)
    end
    if type(b) ~= "userdata" then
        b = b*vec2(1,0)
    end
    if type(c) ~= "userdata" then
        c = c*vec2(0,1)
    end
    self.params = {a,b,c,d,e}
    if self.curve then
        self.curve.shader.centre = a
        self.curve.shader.xaxis = b
        self.curve.shader.yaxis = c
        self.curve.shader.startAngle = d
        self.curve.shader.deltaAngle = e
    end
end

function Arc:setStyle(t)
    self.scolour = t.scolour or t.colour or self.scolour
    self.ecolour = t.ecolour or t.colour or self.ecolour
    self.width = t.width or self.width
    self.taper = t.taper or self.taper
    self.blur = t.blur or self.blur
    self.cap = t.cap or self.cap
    self.scap = t.scap or self.scap
    self.ecap = t.ecap or self.ecap
    if not self.curve then 
        return
    end
    t = t or {}
    if t.colour then
        self.curve.shader.scolour = t.colour
        self.curve.shader.ecolour = t.colour
    end
    if t.scolour then
        self.curve.shader.scolour = t.scolour
    end
    if t.ecolour then
        self.curve.shader.ecolour = t.ecolour
    end
    if t.width then
        self.curve.shader.width = t.width
    end
    if t.taper then
        self.curve.shader.taper = t.taper
    end
    if t.blur then
        self.curve.shader.blur = t.blur
    end
    if t.cap then
        self.curve.shader.cap = t.cap
    end
    if t.scap then
        self.curve.shader.scap = t.scap
    end
    if t.ecap then
        self.curve.shader.ecap = t.ecap
    end
end

function Arc:point(t)
    local a,b,c,d,e = unpack(self.params)
    return a + math.cos(t*e + d)*b + math.sin(t*e + d)*c
end

function Arc:tangent(t)
    local a,b,c,d,e = unpack(self.params)
    return -math.sin(t*e + d)*b + math.cos(t*e + d)*c
end

function Arc:normal(t)
    return self:tangent(t):rotate90()
end

function Arc:unitNormal(t)
    local pt = self:normal(t)
    local l = pt:len()
    if l == 0 then
        return vec2(0,0)
    else
        return pt/l
    end
end

function Arc:unitTangent(t)
    local pt = self:tangent(t)
    local l = pt:len()
    if l == 0 then
        return vec2(0,0)
    else
        return pt/l
    end
end



local ArcList = class()

local s

local function __makeArcList() 
    s = shader([[
//
// A basic vertex shader
//

//This is the current model * view * projection matrix
// Codea sets it automatically
uniform mat4 modelViewProjection;
attribute vec4 scolour;
attribute vec4 ecolour;

//This is the current mesh vertex position, color and tex coord
// Set automatically
attribute vec4 position;
attribute vec2 texCoord;

//This is an output variable that will be passed to the fragment shader
varying highp vec2 vTexCoord;
varying highp float vWidth;
varying lowp vec4 vColour;

attribute float len;
attribute float width;
attribute float taper;
attribute float blur;
attribute vec2 centre;
attribute vec2 xaxis;
attribute vec2 yaxis;
attribute float startAngle;
attribute float deltaAngle;

void main()
{
    highp float t = position.y/len;
    highp float w = smoothstep(0.,1.,t);
    vWidth = w*(taper*width - width) + width + blur;
    highp vec2 bpos = centre + cos(t*deltaAngle + startAngle) * xaxis + sin(t*deltaAngle + startAngle) * yaxis;
    highp vec2 bdir = -sin(t*deltaAngle + startAngle) * xaxis + cos(t*deltaAngle + startAngle) * yaxis;
    bdir = vec2(bdir.y,-bdir.x);
    bdir = vWidth*position.x*normalize(bdir);
    bpos = bpos + bdir;
    highp vec4 bzpos = vec4(bpos.x,bpos.y,0,1);
    vColour = t*(ecolour - scolour) + scolour;
    vTexCoord = vec2(texCoord.x, t);
    //Multiply the vertex position by our combined transform
    gl_Position = modelViewProjection * bzpos;
}
]],[[
//
// A basic fragment shader
//

//This represents the current texture on the mesh
uniform lowp sampler2D texture;
//uniform highp float width;
uniform highp float blur;

//The interpolated texture coordinate for this fragment
varying highp vec2 vTexCoord;
varying highp float vWidth;
varying lowp vec4 vColour;

void main()
{
    //Sample the texture at the interpolated coordinate
    lowp vec4 col = vColour;
    highp float edge = blur/(vWidth+blur);
    col.a = mix( 0., col.a,
    smoothstep( 0., edge, min(vTexCoord.x,1. - vTexCoord.x) ) );
    gl_FragColor = col;
}
]])
end

function ArcList:init()
    __makeArcList()
    self:__init()
    ArcList.init = ArcList.__init
end

function ArcList:__init()
    self.mesh = mesh()
    self.mesh.shader = s
    self.size = 1
end

function ArcList:draw()
    self.mesh:draw()
end

function ArcList:addArc(t)
    local m = self.mesh
    local sc = m:buffer("scolour")
    local ec = m:buffer("ecolour")
    local len = m:buffer("len")
    local w = m:buffer("width")
    local tp = m:buffer("taper")
    local bl = m:buffer("blur")
    local centre = m:buffer("centre")
    local xaxis = m:buffer("xaxis")
    local yaxis = m:buffer("yaxis")
    local startAngle = m:buffer("startAngle")
    local deltaAngle = m:buffer("deltaAngle")
    local isc = t.scolour or t.colour or color(stroke())
    local iec = t.ecolour or t.colour or color(stroke())
    local iw = t.width or strokeWidth()
    local itp = t.taper or 1
    local ibl = t.blur or 2
    local ipts = t.params
    local nsteps = t.nsteps or 150
    local s = self.size
    local bs = s+nsteps*6
    local ret = {s,bs}
    sc:resize(bs)
    ec:resize(bs)
    len:resize(bs)
    w:resize(bs)
    tp:resize(bs)
    bl:resize(bs)
    centre:resize(bs)
    xaxis:resize(bs)
    yaxis:resize(bs)
    startAngle:resize(bs)
    deltaAngle:resize(bs)
    for n=1,nsteps do
        m:addRect(0,(n-.5),1,1)
        for k=1,6 do
            sc[s] = isc
            ec[s] = iec
            len[s] = nsteps
            w[s] = iw
            tp[s] = itp
            bl[s] = ibl
            centre[s] = ipts[1]
            xaxis[s] = ipts[2]
            yaxis[s] = ipts[3]
            startAngle[s] = ipts[4]
            deltaAngle[s] = ipts[5]
            s = s + 1
        end
    end
    self.size = s
    return ret
end

function ArcList:updateArc(t,first,last)
    local m = self.mesh
    local fields,values = {},{}
    if t.scolour or t.colour then
        table.insert(fields,"scolour")
        values["scolour"] = t.scolour or t.colour
    end
    if t.ecolour or t.colour then
        table.insert(fields,"ecolour")
        values["ecolour"] = t.ecolour or t.colour
    end
    if t.width then
        table.insert(fields,"width")
        values["width"] = t.width
    end
    if t.taper then
        table.insert(fields,"taper")
        values["taper"] = t.taper
    end
    if t.blur then
        table.insert(fields,"blur")
        values["blur"] = t.blur
    end
    if t.params then
        table.insert(fields,"centre")
        table.insert(fields,"xaxis")
        table.insert(fields,"yaxis")
        table.insert(fields,"startAngle")
        table.insert(fields,"deltaAngle")
        values["centre"] = t.params[1]
        values["xaxis"] = t.params[2]
        values["yaxis"] = t.params[3]
        values["startAngle"] = t.params[4]
        values["deltaAngle"] = t.params[5]
    end
    local buffers = {}
    for k,v in ipairs(fields) do
        buffers[v] = m:buffer(v)
    end
    for k=first,last do
        for l,v in pairs(buffers) do
            v[k] = values[l]
        end
    end
end

if cmodule then
    cmodule.export {
        arc = arc
    }
    
    return {Arc,ArcList}
else
    _G["arc"] = arc
    _G["Arc"] = Arc
    _G["ArcList"] = ArcList
end
