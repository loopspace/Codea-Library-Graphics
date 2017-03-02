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
uniform vec2 start;
uniform vec2 finish;
uniform float halfangle;
    
vec2 y = finish - start;
vec2 x = vec2(y.y,-y.x);

float sinc(float th) {
    float s;
    if (abs(th) < 0.001) {
        s = 1. - th*th/6. + th*th*th*th/120.;
    } else {
        s = sin(th)/th;
    }
    return s;
}
    
void main()
{
    highp float t = clamp(position.y,0.,1.);
    float l = t*sinc(t*halfangle) / sinc(halfangle);
    vCore = t;
    highp float w = smoothstep(0.,1.,t);
    vWidth = w*ewidth + swidth;
    highp vec2 bpos = start + l*sin((1.-t)*halfangle)*x + l*cos((1.-t)*halfangle)*y;
    highp vec2 bdir = -cos((1.-2.*t)*halfangle)*x + sin((1.-2.*t)*halfangle)*y;
    bdir = vWidth*normalize(bdir);
    bpos = bpos + position.x*bdir;
    highp vec4 bzpos = vec4(bpos.x,bpos.y,0.,1.);
    bzpos.xy += (ecapsw*max(position.y-1.,0.)
                +scapsw*min(position.y,0.))*vec2(bdir.y,-bdir.x);
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
    m.shader.blur = 2
    m.shader.cap = 2
    m.shader.scap = 1
    m.shader.ecap = 1
    return m
end

-- first point, last point, curvature, taper,blur
local function __arc(a,b,c,d,e)
    if type(a) == "table" then
        d = b
        a,b,c = unpack(a)
    end
    if type(a) ~= "userdata" then
        a = a*vec2(1,0)
    end
    if type(b) ~= "userdata" then
        b = b*vec2(0,1)
    end
    --m.shader.blur = 15
    m.shader.taper = d or 1
    m.shader.blur = e or 2/modelMatrix():determinant()^(1/3)
    m.shader.width = strokeWidth()
    m.shader.scolour = color(stroke())
    m.shader.ecolour = color(stroke())
    m.shader.cap = (lineCapMode()-1)%3
    m.shader.start = a
    m.shader.finish = b
    m.shader.halfangle = c
    m:draw()
end

local function arc(...)
    m = m or __makeArc()
    __arc(...)
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
    local a,b,c = unpack(self.params)
    m.shader.start = a
    m.shader.finish = b
    m.shader.halfangle = c
    self.curve = m
    self.draw = function(self) self.curve:draw() end
end

function Arc:draw(t)
    self:makeDrawable(t)
    self.curve:draw()
end

function Arc:setParams(a,b,c)
    if type(a) == "table" then
        a,b,c = unpack(a)
    end
    if type(a) ~= "userdata" then
        a = a*vec2(1,0)
    end
    if type(b) ~= "userdata" then
        b = b*vec2(0,1)
    end
    self.params = {a,b,c}
    if self.curve then
        self.curve.shader.start = a
        self.curve.shader.finish = b
        self.curve.shader.halfangle = c
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

local sinc = function (t)
    if math.abs(t) < 0.001 then
        return 1 - t^2/6 + t^4/120
    else
        return math.sin(t)/t
    end
end

function Arc:point(t)
    local a,b,c = unpack(self.params)
    local y = b - a
    local x = -y:rotate90()
    t = math.max(0,math.min(t,1))
    local r = t*sinc(t*c) / sinc(c);
    local ang = (1-t)*c
    return a + r * math.sin(ang)*x + r * math.cos(ang)*y
end

function Arc:tangent(t)
    local a,b,c = unpack(self.params)
    local y = b - a
    local x = -y:rotate90()
    t = math.max(0,math.min(t,1))
    local r = t*sinc(t*c) / sinc(c);
    local ang = (1-2*t)*c
    return math.sin(ang)*x + math.cos(ang)*y
end

function Arc:normal(t)
    return -self:tangent(t):rotate90()
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



ArcList = class()

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
varying highp float vBlur;
varying lowp vec4 vColour;
varying highp float vCap;
varying highp float vCore;

attribute float cap;
attribute float scap;
attribute float ecap;
attribute float width;
attribute float taper;
attribute float blur;
attribute vec2 start;
attribute vec2 finish;
attribute float halfangle;
    
float sinc(float th) {
    float s;
    if (abs(th) < 0.001) {
        s = 1. - th*th/6. + th*th*th*th/120.;
    } else {
        s = sin(th)/th;
    }
    return s;
}
    
void main()
{

    vec2 y = finish - start;
    vec2 x = vec2(y.y,-y.x);
    highp float t = clamp(position.y,0.,1.);
    vColour = mix(scolour,ecolour,t);
    vCap = cap;
    vCore = t;
    float ecapsw = clamp(cap,0.,1.)*ecap;
    float scapsw = clamp(cap,0.,1.)*scap;
    float l = t*sinc(t*halfangle) / sinc(halfangle);
    highp float w = smoothstep(0.,1.,t);
    vWidth = w*(taper*width - width) + width + blur;
    vBlur = blur;
    highp vec2 bpos = start + l*sin((1.-t)*halfangle)*x + l*cos((1.-t)*halfangle)*y;
    highp vec2 bdir = -cos((1.-2.*t)*halfangle)*x + sin((1.-2.*t)*halfangle)*y;
    bdir = vWidth*normalize(bdir);
    bpos = bpos + position.x*bdir;
    highp vec4 bzpos = vec4(bpos.x,bpos.y,0.,1.);
    bzpos.xy += (ecapsw*max(position.y-1.,0.)
                +scapsw*min(position.y,0.))*vec2(bdir.y,-bdir.x);
    highp float s = clamp(position.y, 
            scapsw*position.y,1.+ecapsw*(position.y-1.));
    vTexCoord = vec2(texCoord.x,s);
    //Multiply the vertex position by our combined transform
    gl_Position = modelViewProjection * bzpos;
}

]],[[
//
// A basic fragment shader
//

//This represents the current texture on the mesh
uniform lowp sampler2D texture;

//The interpolated texture coordinate for this fragment
varying highp vec2 vTexCoord;
varying lowp vec4 vColour;
varying highp float vBlur;
varying highp float vWidth;
varying highp float vCap;
varying highp float vCore;

void main()
{
    //Sample the texture at the interpolated coordinate
    lowp vec4 col = vColour;
    highp float edge = vBlur/vWidth;
    /*
    col.a = mix( 0., col.a,
    smoothstep( 0., edge, min(vTexCoord.x,1. - vTexCoord.x) )
     );
    */
    col.a = mix( 0., col.a, 
            (2.-vCap)*smoothstep( 0., edge, 
                min(vTexCoord.x,1. - vTexCoord.x) )
            * smoothstep( 0., edge, 
                min(1.5-vTexCoord.y, .5+vTexCoord.y) ) 
            + (vCap - 1.)*smoothstep( 0., edge,
             .5-length(vTexCoord - vec2(.5,vCore)))
                );
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
    self.arcpos = {}
    self.narcs = 0
end

function ArcList:draw()
    self.mesh:draw()
end

function ArcList:addArc(t)
    local m = self.mesh
    local sc = m:buffer("scolour")
    local ec = m:buffer("ecolour")
    local w = m:buffer("width")
    local tp = m:buffer("taper")
    local bl = m:buffer("blur")
    local start = m:buffer("start")
    local finish = m:buffer("finish")
    local halfangle = m:buffer("halfangle")
    local scp = m:buffer("scap")
    local ecp = m:buffer("ecap")
    local cp = m:buffer("cap")
    local isc = t.scolour or t.colour or color(stroke())
    local iec = t.ecolour or t.colour or color(stroke())
    local iscp = t.scap or 1
    local iecp = t.ecap or 1
    local icp = t.cap or (lineCapMode()-1)%3
    local iw = t.width or strokeWidth()
    local itp = t.taper or 1
    local ibl = t.blur or 2
    local ist = t.params[1] or t.start
    local ifh = t.params[2] or t.finish
    local iha = t.params[3] or t.halfangle or t.angle/2
    local nsteps = t.nsteps or 150
    local s = self.size
    local bs = s+nsteps*6+12
    local ret = {s,bs}
    sc:resize(bs)
    ec:resize(bs)
    scp:resize(bs)
    ecp:resize(bs)
    cp:resize(bs)
    w:resize(bs)
    tp:resize(bs)
    bl:resize(bs)
    start:resize(bs)
    finish:resize(bs)
    halfangle:resize(bs)
    for n=1,nsteps do
        m:addRect(0,(n-.5)/nsteps,1,1/nsteps)
        for k=1,6 do
            sc[s] = isc/255
            ec[s] = iec/255
            scp[s] = iscp
            ecp[s] = iecp
            cp[s] = icp
            w[s] = iw
            tp[s] = itp
            bl[s] = ibl
            start[s] = ist
            finish[s] = ifh
            halfangle[s] = iha
            s = s + 1
        end
    end
    m:addRect(0,1.25,1,.5)
    m:addRect(0,-.25,1,.5)
    for k=1,12 do
        sc[s] = isc/255
        ec[s] = iec/255
        scp[s] = iscp
        ecp[s] = iecp
        cp[s] = icp
        w[s] = iw
        tp[s] = itp
        bl[s] = ibl
        start[s] = ist
        finish[s] = ifh
        halfangle[s] = iha
        s = s + 1
    end
    self.size = s
    self.narcs = self.narcs + 1
    table.insert(self.arcpos,s)
    m.shader.blur = t.blur or m.shader.blur or 2
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
    if t.scap then
        table.insert(fields,"scap")
        values["scap"] = t.scap
    end
    if t.ecap then
        table.insert(fields,"ecap")
        values["ecap"] = t.ecap
    end
    if t.cap then
        table.insert(fields,"cap")
        values["cap"] = t.cap
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
        table.insert(fields,"start")
        table.insert(fields,"finish")
        table.insert(fields,"halfangle")
        values["start"] = t.params[1]
        values["finish"] = t.params[2]
        values["halfangle"] = t.params[3]
    end
    if t.start then
        table.insert(fields,"start")
        values["start"] = t.start
    end
    if t.start then
        table.insert(fields,"finish")
        values["finish"] = t.finish
    end
    if t.halfangle or t.angle then
        table.insert(fields,"halfangle")
        values["halfangle"] = t.halfangle or t.angle/2
    end
    local buffers = {}
    for k,v in ipairs(fields) do
        buffers[v] = m:buffer(v)
    end
    first = first or 1
    last = last or self.narcs
    first = self.arcpos[first-1] or 0
    first = first + 1
    last = self.arcpos[last] 
    for k=first,last do
        for l,v in pairs(buffers) do
            v[k] = values[l]
        end
    end
end

if cmodule then
    cmodule.export {
        arcangle = arc
    }
    
    return {Arc,ArcList}
else
    _G["arcangle"] = arc
    _G["ArcAngle"] = Arc
    _G["ArcAngleList"] = ArcList
end
