-- ALTER UI Library v6.0
-- Full rewrite: scaling, dropdown expansion, scrolling, no emojis, mobile-friendly

local AlterLib = {}
AlterLib.__index = AlterLib

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HTTP    = game:GetService("HttpService")
local LP      = Players.LocalPlayer

local C = {
    BG        = Color3.fromRGB(10,  10,  10),
    PANEL     = Color3.fromRGB(16,  16,  16),
    CARD      = Color3.fromRGB(20,  20,  20),
    ELEM      = Color3.fromRGB(26,  26,  26),
    HOVER     = Color3.fromRGB(34,  34,  34),
    ACTIVE    = Color3.fromRGB(44,  44,  44),
    BORDER    = Color3.fromRGB(40,  40,  40),
    BORDER_LT = Color3.fromRGB(58,  58,  58),
    WHITE     = Color3.fromRGB(240, 240, 240),
    BLACK     = Color3.fromRGB(0,   0,   0),
    T_PRI     = Color3.fromRGB(220, 220, 220),
    T_SEC     = Color3.fromRGB(110, 110, 110),
    T_DIM     = Color3.fromRGB(55,  55,  55),
    ACC_OFF   = Color3.fromRGB(36,  36,  36),
}
AlterLib.Colors = C

local TI = {
    SNAP   = TweenInfo.new(0.04, Enum.EasingStyle.Linear),
    FAST   = TweenInfo.new(0.12, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    MED    = TweenInfo.new(0.20, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    SLOW   = TweenInfo.new(0.32, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    SPRING = TweenInfo.new(0.38, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
    SINE   = TweenInfo.new(0.26, Enum.EasingStyle.Sine,   Enum.EasingDirection.InOut),
}

local TWEENABLE = {
    BackgroundColor3=true, BackgroundTransparency=true,
    Position=true, Size=true, Rotation=true,
    TextColor3=true, TextTransparency=true,
    ImageColor3=true, ImageTransparency=true,
}

local function Tw(obj, ti, props)
    if not obj or not obj.Parent then return end
    local safe = {}
    for k,v in pairs(props) do if TWEENABLE[k] then safe[k]=v end end
    if next(safe) then pcall(function() TS:Create(obj,ti,safe):Play() end) end
end

local function New(class, props, parent)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
    if parent then obj.Parent = parent end
    return obj
end

local function Frame(parent, props)
    local defaults = {
        BackgroundTransparency=1,
        BorderSizePixel=0,
    }
    if props then for k,v in pairs(props) do defaults[k]=v end end
    return New("Frame", defaults, parent)
end

local function Button(parent, props)
    local defaults = {
        BackgroundTransparency=1,
        BorderSizePixel=0,
        AutoButtonColor=false,
        Text="",
        Font=Enum.Font.GothamMedium,
        TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
    }
    if props then for k,v in pairs(props) do defaults[k]=v end end
    return New("TextButton", defaults, parent)
end

local function Label(parent, props)
    local defaults = {
        BackgroundTransparency=1,
        BorderSizePixel=0,
        Font=Enum.Font.GothamMedium,
        TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true,
        RichText=false,
    }
    if props then for k,v in pairs(props) do defaults[k]=v end end
    return New("TextLabel", defaults, parent)
end

local function TextBox(parent, props)
    local defaults = {
        BackgroundTransparency=1,
        BorderSizePixel=0,
        Font=Enum.Font.GothamMedium,
        TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false,
        TextWrapped=false,
    }
    if props then for k,v in pairs(props) do defaults[k]=v end end
    return New("TextBox", defaults, parent)
end

local function Corner(parent, r)
    return New("UICorner", {CornerRadius=UDim.new(0,r or 6)}, parent)
end

local function Stroke(parent, col, thick)
    return New("UIStroke", {
        Color=col or C.BORDER,
        Thickness=thick or 1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function Padding(parent, t, b, l, r)
    return New("UIPadding", {
        PaddingTop=UDim.new(0,t or 0),
        PaddingBottom=UDim.new(0,b or 0),
        PaddingLeft=UDim.new(0,l or 0),
        PaddingRight=UDim.new(0,r or 0),
    }, parent)
end

local function List(parent, dir, gap, halign, valign)
    return New("UIListLayout", {
        FillDirection=dir or Enum.FillDirection.Vertical,
        Padding=UDim.new(0,gap or 0),
        HorizontalAlignment=halign or Enum.HorizontalAlignment.Left,
        VerticalAlignment=valign or Enum.VerticalAlignment.Top,
        SortOrder=Enum.SortOrder.LayoutOrder,
    }, parent)
end

local function Scroll(parent, props)
    local defaults = {
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ScrollBarThickness=3,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarImageColor3=C.BORDER_LT,
        ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,
    }
    if props then for k,v in pairs(props) do defaults[k]=v end end
    return New("ScrollingFrame", defaults, parent)
end

local function MakeSG(id)
    local name = "ALTER_"..id
    pcall(function()
        local e = CoreGui:FindFirstChild(name)
        if e then e:Destroy() end
    end)
    local sg
    pcall(function()
        sg = Instance.new("ScreenGui")
        sg.Name = name
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.IgnoreGuiInset = true
        sg.DisplayOrder = 999
        sg.Parent = CoreGui
    end)
    if not sg or not sg.Parent then
        sg = Instance.new("ScreenGui")
        sg.Name = name
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.IgnoreGuiInset = true
        sg.Parent = LP:WaitForChild("PlayerGui")
    end
    return sg
end

local function Ripple(host)
    if not host or not host.Parent then return end
    local ok1,ap = pcall(function() return host.AbsolutePosition end)
    local ok2,as = pcall(function() return host.AbsoluteSize end)
    if not ok1 or not ok2 then return end
    local mp = UIS:GetMouseLocation()
    local lx = math.clamp(mp.X-ap.X, 0, as.X)
    local ly = math.clamp(mp.Y-ap.Y, 0, as.Y)
    local sz = math.clamp(math.max(as.X,as.Y)*1.4, 20, 80)
    local was = host.ClipsDescendants
    host.ClipsDescendants = true
    local r = New("Frame", {
        Size=UDim2.new(0,0,0,0),
        Position=UDim2.new(0,lx,0,ly),
        AnchorPoint=Vector2.new(0.5,0.5),
        BackgroundColor3=C.WHITE,
        BackgroundTransparency=0.85,
        ZIndex=host.ZIndex+10,
        BorderSizePixel=0,
    }, host)
    Corner(r, 9999)
    Tw(r, TweenInfo.new(0.38,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {
        Size=UDim2.new(0,sz,0,sz),
        BackgroundTransparency=1,
    })
    task.delay(0.4, function()
        if r and r.Parent then r:Destroy() end
        if host and host.Parent then host.ClipsDescendants=was end
    end)
end

local function MakeDraggable(handle, target)
    local down,startM,startP = false,Vector2.new(),Vector2.new()
    handle.InputBegan:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.MouseButton1
        and i.UserInputType~=Enum.UserInputType.Touch then return end
        down=true
        startM=Vector2.new(i.Position.X,i.Position.Y)
        startP=Vector2.new(target.Position.X.Offset,target.Position.Y.Offset)
    end)
    UIS.InputChanged:Connect(function(i)
        if not down then return end
        if i.UserInputType~=Enum.UserInputType.MouseMovement
        and i.UserInputType~=Enum.UserInputType.Touch then return end
        local d=Vector2.new(i.Position.X-startM.X,i.Position.Y-startM.Y)
        local sg=target.Parent
        local mX=sg and math.max(0,sg.AbsoluteSize.X-target.AbsoluteSize.X) or 9999
        local mY=sg and math.max(0,sg.AbsoluteSize.Y-target.AbsoluteSize.Y) or 9999
        target.Position=UDim2.new(0,math.clamp(startP.X+d.X,0,mX),0,math.clamp(startP.Y+d.Y,0,mY))
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then down=false end
    end)
end

-- ─── Config System ─────────────────────────────────────────────────────────
local ConfigSys = {}
ConfigSys.__index = ConfigSys

function ConfigSys.new(folder)
    local s = setmetatable({}, ConfigSys)
    s.folder  = folder or "AlterHub"
    s.entries = {}
    pcall(function()
        if not isfolder(s.folder) then makefolder(s.folder) end
    end)
    return s
end

function ConfigSys:Register(key, getter, setter)
    for _,e in ipairs(self.entries) do
        if e.key==key then e.get=getter; e.set=setter; return end
    end
    table.insert(self.entries,{key=key,get=getter,set=setter})
end

function ConfigSys:Save(name)
    if not name or name=="" then return false,"empty name" end
    local data={}
    for _,e in ipairs(self.entries) do
        local ok,v=pcall(e.get)
        if ok then data[e.key]=v end
    end
    local ok,json=pcall(function() return HTTP:JSONEncode(data) end)
    if not ok then return false,"encode failed" end
    local path=self.folder.."/"..name..".json"
    local wok,werr=pcall(function() writefile(path,json) end)
    return wok,werr
end

function ConfigSys:Load(name)
    local path=self.folder.."/"..name..".json"
    local ok,raw=pcall(function() return readfile(path) end)
    if not ok or not raw then return false end
    local ok2,data=pcall(function() return HTTP:JSONDecode(raw) end)
    if not ok2 or type(data)~="table" then return false end
    for _,e in ipairs(self.entries) do
        if data[e.key]~=nil then pcall(e.set,data[e.key]) end
    end
    return true
end

function ConfigSys:Delete(name)
    return pcall(function() delfile(self.folder.."/"..name..".json") end)
end

function ConfigSys:List()
    local out={}
    pcall(function()
        for _,f in ipairs(listfiles(self.folder)) do
            local n=f:match("[/\\]([^/\\]+)%.json$")
            if n then table.insert(out,n) end
        end
    end)
    return out
end

function ConfigSys:AutoLoadByPlaceId(map)
    task.delay(1.5, function()
        local pid=tostring(game.PlaceId)
        if map and map[pid] then self:Load(map[pid]) else self:Load("default") end
    end)
end

function ConfigSys:AutoLoadByGameId(map)
    task.delay(1.5, function()
        local gid=tostring(game.GameId)
        if map and map[gid] then self:Load(map[gid]) else self:Load("default") end
    end)
end

-- ─── Notifications ─────────────────────────────────────────────────────────
local _nSG, _nHolder

local function EnsureNotif()
    if _nSG and _nSG.Parent then return end
    _nSG = MakeSG("NOTIF")
    _nHolder = Frame(_nSG, {
        Size=UDim2.new(0,280,1,-20),
        Position=UDim2.new(1,-292,0,10),
        ZIndex=200,
    })
    local ll=List(_nHolder,Enum.FillDirection.Vertical,6)
    ll.VerticalAlignment=Enum.VerticalAlignment.Bottom
    Padding(_nHolder,0,10,0,0)
end

function AlterLib:Notify(cfg)
    EnsureNotif()
    cfg=cfg or {}
    local dur=cfg.Duration or 3.5

    local card=Frame(_nHolder,{
        Size=UDim2.new(1,0,0,68),
        BackgroundColor3=C.PANEL,
        BackgroundTransparency=0,
        ZIndex=201,
    })
    Corner(card,8)
    Stroke(card,C.BORDER,1)

    -- left accent bar
    Frame(card,{
        Size=UDim2.new(0,2,1,-16),
        Position=UDim2.new(0,0,0,8),
        BackgroundColor3=C.WHITE,
        BackgroundTransparency=0,
        ZIndex=203,
    })

    -- progress bar at bottom
    local prog=Frame(card,{
        Size=UDim2.new(1,0,0,2),
        Position=UDim2.new(0,0,1,-2),
        BackgroundColor3=C.WHITE,
        BackgroundTransparency=0,
        ZIndex=203,
    })
    Corner(prog,1)

    Label(card,{
        Text=cfg.Title or "Alter",
        TextSize=13,
        Font=Enum.Font.GothamBold,
        TextColor3=C.T_PRI,
        Size=UDim2.new(1,-20,0,22),
        Position=UDim2.new(0,14,0,10),
        ZIndex=202,
        TextWrapped=false,
    })
    Label(card,{
        Text=cfg.Message or "",
        TextSize=11,
        TextColor3=C.T_SEC,
        Size=UDim2.new(1,-20,0,26),
        Position=UDim2.new(0,14,0,34),
        TextWrapped=true,
        ZIndex=202,
    })

    -- slide in
    card.Position=UDim2.new(1,10,1,0)
    Tw(card,TI.SPRING,{Position=UDim2.new(0,0,1,0)})

    -- progress drain
    task.delay(0.1, function()
        Tw(prog, TweenInfo.new(dur-0.1,Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,0,2)})
    end)

    task.delay(dur, function()
        Tw(card,TI.MED,{Position=UDim2.new(1,10,1,0),BackgroundTransparency=1})
        task.delay(0.25, function()
            if card and card.Parent then card:Destroy() end
        end)
    end)
end

function AlterLib:Prompt(cfg)
    cfg=cfg or {}
    local sg=MakeSG("PROMPT")
    local backdrop=Button(sg,{
        Size=UDim2.fromScale(1,1),
        BackgroundColor3=C.BLACK,
        BackgroundTransparency=1,
        ZIndex=100,
    })
    Tw(backdrop,TI.MED,{BackgroundTransparency=0.6})

    local card=Frame(backdrop,{
        Size=UDim2.new(0,360,0,0),
        Position=UDim2.fromScale(0.5,0.5),
        AnchorPoint=Vector2.new(0.5,0.5),
        BackgroundColor3=C.PANEL,
        BackgroundTransparency=0,
        ZIndex=101,
    })
    card.ClipsDescendants=true
    Corner(card,10)
    Stroke(card,C.BORDER_LT,1)

    -- top accent
    Frame(card,{
        Size=UDim2.new(1,0,0,2),
        BackgroundColor3=C.WHITE,
        BackgroundTransparency=0,
        ZIndex=105,
    })

    local hdr=Frame(card,{
        Size=UDim2.new(1,0,0,48),
        BackgroundColor3=C.CARD,
        BackgroundTransparency=0,
        ZIndex=102,
    })
    Corner(hdr,10)
    -- cover bottom corners of hdr
    Frame(hdr,{
        Size=UDim2.new(1,0,0.5,0),
        Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=C.CARD,
        BackgroundTransparency=0,
        ZIndex=102,
    })

    Label(hdr,{
        Text=cfg.Title or "Confirm",
        TextSize=14,
        Font=Enum.Font.GothamBold,
        TextColor3=C.T_PRI,
        Size=UDim2.new(1,-20,1,0),
        Position=UDim2.new(0,16,0,0),
        ZIndex=103,
    })

    Label(card,{
        Text=cfg.Message or "",
        TextSize=12,
        TextColor3=C.T_SEC,
        Size=UDim2.new(1,-32,0,42),
        Position=UDim2.new(0,16,0,56),
        TextWrapped=true,
        ZIndex=103,
    })

    local bRow=Frame(card,{
        Size=UDim2.new(1,-32,0,36),
        Position=UDim2.new(0,16,0,108),
        ZIndex=102,
    })
    List(bRow,Enum.FillDirection.Horizontal,8)

    local function closePrompt(cb)
        Tw(card,TI.MED,{Size=UDim2.new(0,360,0,0)})
        Tw(backdrop,TI.MED,{BackgroundTransparency=1})
        task.delay(0.26, function()
            if cb then pcall(cb) end
            if sg and sg.Parent then sg:Destroy() end
        end)
    end

    local function PBtn(txt, primary, cb)
        local b=Button(bRow,{
            Text=txt,
            TextSize=12,
            Font=Enum.Font.GothamBold,
            TextColor3=primary and C.BLACK or C.T_SEC,
            BackgroundColor3=primary and C.WHITE or C.ELEM,
            BackgroundTransparency=0,
            TextXAlignment=Enum.TextXAlignment.Center,
            Size=UDim2.new(0.5,-4,1,0),
            ZIndex=103,
        })
        Corner(b,7)
        if not primary then Stroke(b,C.BORDER,1) end
        b.MouseButton1Click:Connect(function() closePrompt(cb) end)
        b.MouseEnter:Connect(function()
            Tw(b,TI.FAST,{BackgroundColor3=primary and Color3.fromRGB(210,210,210) or C.HOVER})
        end)
        b.MouseLeave:Connect(function()
            Tw(b,TI.FAST,{BackgroundColor3=primary and C.WHITE or C.ELEM})
        end)
        b.MouseButton1Down:Connect(function() Ripple(b) end)
    end

    PBtn(cfg.NoText or "Cancel", false, cfg.No)
    PBtn(cfg.YesText or "Confirm", true, cfg.Yes)
    backdrop.MouseButton1Click:Connect(function() closePrompt(nil) end)
    Tw(card,TI.SPRING,{Size=UDim2.new(0,360,0,156)})
end

-- ─── Window ────────────────────────────────────────────────────────────────
function AlterLib:Window(cfg)
    cfg=cfg or {}
    local IS_MOB = UIS.TouchEnabled and not UIS.KeyboardEnabled
    local vp     = workspace.CurrentCamera.ViewportSize
    local WIN_W  = IS_MOB and math.min(vp.X-16,460) or 620
    local WIN_H  = IS_MOB and math.min(vp.Y-16,600) or 540
    local SIDE_W = IS_MOB and 108 or 144
    local ROW_H  = IS_MOB and 44  or 36

    local sg     = MakeSG(cfg.Folder or "WIN")
    local cfgSys = ConfigSys.new(cfg.Folder or "AlterHub")

    local root=Frame(sg,{
        Size=UDim2.new(0,WIN_W,0,0),
        Position=UDim2.new(0, IS_MOB and 8 or 60, 0, IS_MOB and 8 or 50),
        BackgroundColor3=C.BG,
        BackgroundTransparency=1,
        ZIndex=1,
    })
    root.ClipsDescendants=false
    Corner(root,10)
    Stroke(root,C.BORDER,1)

    -- title bar
    local titleBar=Frame(root,{
        Size=UDim2.new(1,0,0,48),
        BackgroundColor3=C.PANEL,
        BackgroundTransparency=0,
        ZIndex=4,
    })
    Corner(titleBar,10)
    Frame(titleBar,{
        Size=UDim2.new(1,0,0.5,0),
        Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=C.PANEL,
        BackgroundTransparency=0,
        ZIndex=4,
    })

    local accentLine=Frame(titleBar,{
        Size=UDim2.new(0,0,0,1),
        BackgroundColor3=C.WHITE,
        BackgroundTransparency=0,
        ZIndex=6,
    })
    Corner(accentLine,1)

    local hubLbl=Label(titleBar,{
        Text=cfg.Name or "Alter",
        TextSize=15,
        Font=Enum.Font.GothamBlack,
        TextColor3=C.T_PRI,
        TextTransparency=1,
        Size=UDim2.new(0.6,0,0,28),
        Position=UDim2.new(0,14,0.5,-14),
        ZIndex=5,
        TextWrapped=false,
    })
    Label(titleBar,{
        Text="v6.0  |  "..tostring(game.PlaceId),
        TextSize=9,
        TextColor3=C.T_DIM,
        Size=UDim2.new(0.6,0,0,12),
        Position=UDim2.new(0,14,1,-14),
        ZIndex=5,
        TextWrapped=false,
    })

    -- control buttons
    local ctrlF=Frame(titleBar,{
        Size=UDim2.new(0,62,0,24),
        Position=UDim2.new(1,-70,0.5,-12),
        ZIndex=5,
    })
    List(ctrlF,Enum.FillDirection.Horizontal,6)

    local minimised=false
    local bodyFrame

    local function CtrlBtn(sym,action)
        local b=Button(ctrlF,{
            Text=sym,
            TextSize=14,
            Font=Enum.Font.GothamBold,
            TextColor3=C.T_DIM,
            BackgroundColor3=C.ELEM,
            BackgroundTransparency=0,
            TextXAlignment=Enum.TextXAlignment.Center,
            Size=UDim2.new(0,28,0,24),
            ZIndex=6,
        })
        Corner(b,5)
        Stroke(b,C.BORDER,1)
        b.MouseButton1Click:Connect(function() Ripple(b); action() end)
        b.MouseEnter:Connect(function() Tw(b,TI.FAST,{BackgroundColor3=C.HOVER,TextColor3=C.T_PRI}) end)
        b.MouseLeave:Connect(function() Tw(b,TI.FAST,{BackgroundColor3=C.ELEM,TextColor3=C.T_DIM}) end)
        b.MouseButton1Down:Connect(function() Tw(b,TI.SNAP,{BackgroundColor3=C.ACTIVE}) end)
        return b
    end

    CtrlBtn("-",function()
        minimised=not minimised
        Tw(root,TI.MED,{Size=minimised and UDim2.new(0,WIN_W,0,48) or UDim2.new(0,WIN_W,0,WIN_H)})
    end)
    CtrlBtn("x",function()
        Tw(root,TI.MED,{Size=UDim2.new(0,WIN_W,0,0),BackgroundTransparency=1})
        task.delay(0.28,function()
            if sg and sg.Parent then sg:Destroy() end
        end)
    end)

    MakeDraggable(titleBar,root)

    bodyFrame=Frame(root,{
        Size=UDim2.new(1,0,1,-48),
        Position=UDim2.new(0,0,0,48),
        ZIndex=2,
    })
    bodyFrame.ClipsDescendants=true

    -- sidebar
    local sidebar=Frame(bodyFrame,{
        Size=UDim2.new(0,SIDE_W,1,0),
        BackgroundColor3=C.PANEL,
        BackgroundTransparency=0,
        ZIndex=3,
    })
    Corner(sidebar,10)
    Frame(sidebar,{
        Size=UDim2.new(0,14,1,0),
        Position=UDim2.new(1,-14,0,0),
        BackgroundColor3=C.PANEL,
        BackgroundTransparency=0,
        ZIndex=3,
    })
    Frame(sidebar,{
        Size=UDim2.new(1,0,0,12),
        BackgroundColor3=C.PANEL,
        BackgroundTransparency=0,
        ZIndex=3,
    })
    -- right divider
    Frame(sidebar,{
        Size=UDim2.new(0,1,1,0),
        Position=UDim2.new(1,0,0,0),
        BackgroundColor3=C.BORDER,
        BackgroundTransparency=0,
        ZIndex=4,
    })

    local brandLbl=Label(sidebar,{
        Text="ALTER",
        TextSize=9,
        Font=Enum.Font.GothamBlack,
        TextColor3=C.T_DIM,
        TextTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.new(1,0,0,48),
        ZIndex=4,
    })
    Frame(sidebar,{
        Size=UDim2.new(1,-20,0,1),
        Position=UDim2.new(0,10,0,47),
        BackgroundColor3=C.BORDER,
        BackgroundTransparency=0,
        ZIndex=4,
    })

    local tabScroll=Scroll(sidebar,{
        Size=UDim2.new(1,0,1,-56),
        Position=UDim2.new(0,0,0,54),
        ScrollBarThickness=0,
        ZIndex=4,
    })
    Padding(tabScroll,4,4,6,6)
    List(tabScroll,Enum.FillDirection.Vertical,3)

    local contentArea=Frame(bodyFrame,{
        Size=UDim2.new(1,-SIDE_W,1,0),
        Position=UDim2.new(0,SIDE_W,0,0),
        ZIndex=2,
    })
    contentArea.ClipsDescendants=true

    -- animate open
    task.defer(function()
        Tw(root,TI.SPRING,{Size=UDim2.new(0,WIN_W,0,WIN_H),BackgroundTransparency=0})
        task.delay(0.2,function()
            Tw(accentLine,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                {Size=UDim2.new(1,0,0,1)})
            Tw(hubLbl,TI.SLOW,{TextTransparency=0})
            Tw(brandLbl,TI.SLOW,{TextTransparency=0})
        end)
    end)

    local winObj={_tabs={},Config=cfgSys}

    function winObj:Tab(name)
        local tabObj={_name=name}

        local btn=Button(tabScroll,{
            Size=UDim2.new(1,0,0,ROW_H),
            BackgroundColor3=C.ELEM,
            BackgroundTransparency=1,
            ZIndex=5,
        })
        Corner(btn,6)

        local ind=Frame(btn,{
            Size=UDim2.new(0,2,0,0),
            Position=UDim2.new(0,0,0.5,0),
            AnchorPoint=Vector2.new(0,0.5),
            BackgroundColor3=C.WHITE,
            BackgroundTransparency=0,
            ZIndex=6,
        })
        Corner(ind,1)

        local dot=Frame(btn,{
            Size=UDim2.new(0,4,0,4),
            Position=UDim2.new(0,10,0.5,-2),
            BackgroundColor3=C.T_DIM,
            BackgroundTransparency=0,
            ZIndex=6,
        })
        Corner(dot,2)

        local lbl=Label(btn,{
            Text=name,
            TextSize=IS_MOB and 13 or 12,
            TextColor3=C.T_DIM,
            Size=UDim2.new(1,-22,1,0),
            Position=UDim2.new(0,22,0,0),
            ZIndex=6,
            TextWrapped=false,
        })

        -- content panel (scrolling)
        local panel=Scroll(contentArea,{
            Size=UDim2.new(1,0,1,0),
            ScrollBarThickness=3,
            Visible=false,
            ZIndex=2,
        })
        panel.AutomaticCanvasSize=Enum.AutomaticSize.Y
        Padding(panel,14,14,14,14)
        List(panel,Enum.FillDirection.Vertical,10)

        tabObj._panel=panel; tabObj._btn=btn
        tabObj._ind=ind; tabObj._dot=dot; tabObj._lbl=lbl
        table.insert(self._tabs,tabObj)

        local function activate()
            for _,t in ipairs(self._tabs) do
                if t~=tabObj then
                    t._panel.Visible=false
                    Tw(t._btn,TI.FAST,{BackgroundTransparency=1})
                    Tw(t._ind,TI.FAST,{Size=UDim2.new(0,2,0,0)})
                    Tw(t._dot,TI.FAST,{BackgroundColor3=C.T_DIM})
                    Tw(t._lbl,TI.FAST,{TextColor3=C.T_DIM})
                end
            end
            panel.Visible=true
            Tw(btn,TI.MED,{BackgroundTransparency=0,BackgroundColor3=C.ELEM})
            Tw(ind,TI.SPRING,{Size=UDim2.new(0,2,0,20)})
            Tw(dot,TI.FAST,{BackgroundColor3=C.WHITE})
            Tw(lbl,TI.FAST,{TextColor3=C.T_PRI})
        end

        btn.MouseButton1Click:Connect(function() activate(); Ripple(btn) end)
        btn.MouseEnter:Connect(function()
            if panel.Visible then return end
            Tw(btn,TI.FAST,{BackgroundTransparency=0.88,BackgroundColor3=C.ELEM})
            Tw(lbl,TI.FAST,{TextColor3=C.T_SEC})
        end)
        btn.MouseLeave:Connect(function()
            if panel.Visible then return end
            Tw(btn,TI.FAST,{BackgroundTransparency=1})
            Tw(lbl,TI.FAST,{TextColor3=C.T_DIM})
        end)

        if #self._tabs==1 then activate() end

        -- ─── Section ───────────────────────────────────────────────────────
        function tabObj:Section(secName)
            local secObj={}
            local collapsed=false

            --[[
                The section is a Frame whose height is driven
                by an inner UIListLayout — NO fixed heights.
                AutomaticSize handles everything so dropdowns
                and other expanding elements grow correctly.
            ]]

            local wrap=Frame(panel,{
                BackgroundColor3=C.CARD,
                BackgroundTransparency=0,
                ZIndex=3,
                AutomaticSize=Enum.AutomaticSize.Y,
                Size=UDim2.new(1,0,0,0),
            })
            Corner(wrap,8)
            Stroke(wrap,C.BORDER,1)

            -- header
            local hdr=Frame(wrap,{
                Size=UDim2.new(1,0,0,38),
                BackgroundColor3=C.ELEM,
                BackgroundTransparency=0,
                ZIndex=4,
            })
            Corner(hdr,8)
            -- cover bottom corners
            Frame(hdr,{
                Size=UDim2.new(1,0,0.5,0),
                Position=UDim2.new(0,0,0.5,0),
                BackgroundColor3=C.ELEM,
                BackgroundTransparency=0,
                ZIndex=4,
            })

            local stripe=Frame(hdr,{
                Size=UDim2.new(0,2,0,16),
                Position=UDim2.new(0,10,0.5,-8),
                BackgroundColor3=C.WHITE,
                BackgroundTransparency=0,
                ZIndex=5,
            })
            Corner(stripe,1)

            Label(hdr,{
                Text=string.upper(secName or "Section"),
                TextSize=10,
                Font=Enum.Font.GothamBold,
                TextColor3=C.T_SEC,
                Size=UDim2.new(1,-52,1,0),
                Position=UDim2.new(0,20,0,0),
                ZIndex=5,
                TextWrapped=false,
            })

            local collBtn=Button(hdr,{
                Text="-",
                TextSize=18,
                Font=Enum.Font.GothamBold,
                TextColor3=C.T_DIM,
                TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(0,36,1,0),
                Position=UDim2.new(1,-38,0,0),
                ZIndex=7,
            })

            -- elements container — AutomaticSize grows it
            local elemsWrap=Frame(wrap,{
                Size=UDim2.new(1,0,0,0),
                Position=UDim2.new(0,0,0,38),
                BackgroundColor3=C.CARD,
                BackgroundTransparency=0,
                AutomaticSize=Enum.AutomaticSize.Y,
                ZIndex=4,
                ClipsDescendants=false,
            })

            local elems=Frame(elemsWrap,{
                Size=UDim2.new(1,0,0,0),
                BackgroundTransparency=1,
                AutomaticSize=Enum.AutomaticSize.Y,
                ZIndex=4,
            })
            Padding(elems,10,12,12,12)
            List(elems,Enum.FillDirection.Vertical,8)

            -- collapse/expand
            local function doCollapse()
                collapsed=not collapsed
                elemsWrap.Visible=not collapsed
                if collapsed then
                    Tw(collBtn,TI.FAST,{Rotation=45,TextColor3=C.T_DIM})
                    Tw(stripe,TI.FAST,{BackgroundColor3=C.T_DIM})
                else
                    Tw(collBtn,TI.FAST,{Rotation=0,TextColor3=C.T_DIM})
                    Tw(stripe,TI.FAST,{BackgroundColor3=C.WHITE})
                end
            end

            collBtn.MouseButton1Click:Connect(doCollapse)
            collBtn.MouseEnter:Connect(function() Tw(collBtn,TI.FAST,{TextColor3=C.WHITE}) end)
            collBtn.MouseLeave:Connect(function() Tw(collBtn,TI.FAST,{TextColor3=C.T_DIM}) end)

            local hdrHit=Button(hdr,{Size=UDim2.new(1,-40,1,0),ZIndex=6})
            hdrHit.MouseButton1Click:Connect(doCollapse)
            hdrHit.MouseEnter:Connect(function() Tw(hdr,TI.FAST,{BackgroundColor3=C.HOVER}) end)
            hdrHit.MouseLeave:Connect(function() Tw(hdr,TI.FAST,{BackgroundColor3=C.ELEM}) end)

            -- helper: standard row frame
            local function ElemRow(h)
                local f=Frame(elems,{
                    Size=UDim2.new(1,0,0,h or ROW_H),
                    BackgroundColor3=C.ELEM,
                    BackgroundTransparency=0,
                    ZIndex=5,
                })
                Corner(f,7)
                Stroke(f,C.BORDER,1)
                return f
            end

            -- ── Label ──────────────────────────────────────────────────────
            function secObj:Label(text, col)
                local f=Frame(elems,{
                    Size=UDim2.new(1,0,0,0),
                    AutomaticSize=Enum.AutomaticSize.Y,
                    BackgroundTransparency=1,
                    ZIndex=5,
                })
                Label(f,{
                    Text=text or "",
                    TextSize=12,
                    TextColor3=col or C.T_SEC,
                    Size=UDim2.new(1,0,0,0),
                    AutomaticSize=Enum.AutomaticSize.Y,
                    TextWrapped=true,
                    ZIndex=6,
                })
            end

            -- ── Separator ──────────────────────────────────────────────────
            function secObj:Separator(ltext)
                local f=Frame(elems,{
                    Size=UDim2.new(1,0,0,20),
                    BackgroundTransparency=1,
                    ZIndex=5,
                })
                Frame(f,{
                    Size=UDim2.new(1,0,0,1),
                    Position=UDim2.new(0,0,0.5,0),
                    BackgroundColor3=C.BORDER,
                    BackgroundTransparency=0,
                    ZIndex=5,
                })
                if ltext then
                    local lbl2=Label(f,{
                        Text=" "..ltext.." ",
                        TextSize=10,
                        Font=Enum.Font.GothamBold,
                        TextColor3=C.T_DIM,
                        BackgroundColor3=C.CARD,
                        BackgroundTransparency=0,
                        Size=UDim2.new(0,0,1,0),
                        AutomaticSize=Enum.AutomaticSize.X,
                        Position=UDim2.new(0.5,0,0,0),
                        AnchorPoint=Vector2.new(0.5,0),
                        ZIndex=6,
                        TextWrapped=false,
                    })
                end
            end

            -- ── Button ─────────────────────────────────────────────────────
            function secObj:Button(text, cb)
                local row=Button(elems,{
                    BackgroundColor3=C.ELEM,
                    BackgroundTransparency=0,
                    Size=UDim2.new(1,0,0,ROW_H),
                    ZIndex=5,
                })
                Corner(row,7)
                Stroke(row,C.BORDER,1)

                local glow=Frame(row,{
                    Size=UDim2.new(0,2,0,0),
                    Position=UDim2.new(0,0,0.5,0),
                    AnchorPoint=Vector2.new(0,0.5),
                    BackgroundColor3=C.WHITE,
                    BackgroundTransparency=0,
                    ZIndex=6,
                })
                Corner(glow,1)

                Label(row,{
                    Text=text or "Button",
                    TextSize=12,
                    TextColor3=C.T_SEC,
                    Size=UDim2.new(1,-40,1,0),
                    Position=UDim2.new(0,14,0,0),
                    ZIndex=6,
                    TextWrapped=false,
                })
                Label(row,{
                    Text=">",
                    TextSize=14,
                    Font=Enum.Font.GothamBold,
                    TextColor3=C.T_DIM,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(0,24,1,0),
                    Position=UDim2.new(1,-28,0,0),
                    ZIndex=6,
                })

                row.MouseEnter:Connect(function()
                    Tw(row,TI.FAST,{BackgroundColor3=C.HOVER})
                    Tw(glow,TI.MED,{Size=UDim2.new(0,2,0.55,0)})
                end)
                row.MouseLeave:Connect(function()
                    Tw(row,TI.FAST,{BackgroundColor3=C.ELEM})
                    Tw(glow,TI.FAST,{Size=UDim2.new(0,2,0,0)})
                end)
                row.MouseButton1Down:Connect(function()
                    Tw(row,TI.SNAP,{BackgroundColor3=C.ACTIVE})
                    Ripple(row)
                end)
                row.MouseButton1Up:Connect(function()
                    Tw(row,TI.FAST,{BackgroundColor3=C.HOVER})
                    if cb then task.spawn(cb) end
                end)
            end

            -- ── Toggle ─────────────────────────────────────────────────────
            function secObj:Toggle(text, cb)
                local obj={}; local state=false
                local row=ElemRow(ROW_H)

                local tLbl=Label(row,{
                    Text=text or "Toggle",
                    TextSize=12,
                    TextColor3=C.T_SEC,
                    Size=UDim2.new(1,-62,1,0),
                    Position=UDim2.new(0,14,0,0),
                    ZIndex=6,
                    TextWrapped=false,
                })

                local track=Frame(row,{
                    Size=UDim2.new(0,36,0,20),
                    Position=UDim2.new(1,-48,0.5,-10),
                    BackgroundColor3=C.ACC_OFF,
                    BackgroundTransparency=0,
                    ZIndex=6,
                })
                Corner(track,10)
                Stroke(track,C.BORDER,1)

                local fill=Frame(track,{
                    Size=UDim2.new(0,0,1,0),
                    BackgroundColor3=C.WHITE,
                    BackgroundTransparency=0.5,
                    ZIndex=7,
                })
                Corner(fill,10)

                local thumb=Frame(track,{
                    Size=UDim2.new(0,14,0,14),
                    Position=UDim2.new(0,3,0.5,-7),
                    BackgroundColor3=C.T_DIM,
                    BackgroundTransparency=0,
                    ZIndex=8,
                })
                Corner(thumb,7)

                local function setState(v,silent)
                    state=v
                    if state then
                        Tw(track,TI.MED,{BackgroundColor3=Color3.fromRGB(42,42,42)})
                        Tw(fill,TI.MED,{Size=UDim2.new(1,0,1,0),BackgroundTransparency=0.3})
                        Tw(thumb,TI.SPRING,{Position=UDim2.new(1,-17,0.5,-7),BackgroundColor3=C.WHITE})
                        Tw(tLbl,TI.FAST,{TextColor3=C.T_PRI})
                        Tw(row,TI.FAST,{BackgroundColor3=Color3.fromRGB(30,30,30)})
                    else
                        Tw(track,TI.MED,{BackgroundColor3=C.ACC_OFF})
                        Tw(fill,TI.MED,{Size=UDim2.new(0,0,1,0)})
                        Tw(thumb,TI.SPRING,{Position=UDim2.new(0,3,0.5,-7),BackgroundColor3=C.T_DIM})
                        Tw(tLbl,TI.FAST,{TextColor3=C.T_SEC})
                        Tw(row,TI.FAST,{BackgroundColor3=C.ELEM})
                    end
                    if not silent and cb then task.spawn(cb,state) end
                end

                local hit=Button(row,{Size=UDim2.new(1,0,1,0),ZIndex=9})
                hit.MouseButton1Click:Connect(function()
                    setState(not state)
                    Ripple(row)
                end)
                hit.MouseEnter:Connect(function()
                    if not state then Tw(row,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                hit.MouseLeave:Connect(function()
                    if not state then Tw(row,TI.FAST,{BackgroundColor3=C.ELEM}) end
                end)

                function obj:Set(v) setState(v,true) end
                function obj:Get() return state end
                cfgSys:Register((text or "tog")..#cfgSys.entries,obj.Get,function(v) obj:Set(v) end)
                return obj
            end

            -- ── ToggleBind ─────────────────────────────────────────────────
            function secObj:ToggleBind(text, defaultKey, cb)
                local obj={}; local state=false; local bound=defaultKey; local binding=false
                local row=ElemRow(ROW_H)

                local tLbl=Label(row,{
                    Text=text or "ToggleBind",
                    TextSize=12,
                    TextColor3=C.T_SEC,
                    Size=UDim2.new(1,-138,1,0),
                    Position=UDim2.new(0,14,0,0),
                    ZIndex=6,
                    TextWrapped=false,
                })

                local function kn(k)
                    if not k then return "--" end
                    return tostring(k):gsub("Enum%.KeyCode%.","")
                end

                local pill=Button(row,{
                    Text=kn(bound),
                    TextSize=10,
                    Font=Enum.Font.GothamBold,
                    TextColor3=C.T_SEC,
                    BackgroundColor3=C.CARD,
                    BackgroundTransparency=0,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(0,54,0,22),
                    Position=UDim2.new(1,-110,0.5,-11),
                    ZIndex=7,
                })
                Corner(pill,5)
                Stroke(pill,C.BORDER,1)

                local track=Frame(row,{
                    Size=UDim2.new(0,36,0,20),
                    Position=UDim2.new(1,-48,0.5,-10),
                    BackgroundColor3=C.ACC_OFF,
                    BackgroundTransparency=0,
                    ZIndex=6,
                })
                Corner(track,10)
                Stroke(track,C.BORDER,1)

                local fill=Frame(track,{
                    Size=UDim2.new(0,0,1,0),
                    BackgroundColor3=C.WHITE,
                    BackgroundTransparency=0.5,
                    ZIndex=7,
                })
                Corner(fill,10)

                local thumb=Frame(track,{
                    Size=UDim2.new(0,14,0,14),
                    Position=UDim2.new(0,3,0.5,-7),
                    BackgroundColor3=C.T_DIM,
                    BackgroundTransparency=0,
                    ZIndex=8,
                })
                Corner(thumb,7)

                local function setState(v,silent)
                    state=v
                    if state then
                        Tw(track,TI.MED,{BackgroundColor3=Color3.fromRGB(42,42,42)})
                        Tw(fill,TI.MED,{Size=UDim2.new(1,0,1,0),BackgroundTransparency=0.3})
                        Tw(thumb,TI.SPRING,{Position=UDim2.new(1,-17,0.5,-7),BackgroundColor3=C.WHITE})
                        Tw(tLbl,TI.FAST,{TextColor3=C.T_PRI})
                        Tw(row,TI.FAST,{BackgroundColor3=Color3.fromRGB(30,30,30)})
                    else
                        Tw(track,TI.MED,{BackgroundColor3=C.ACC_OFF})
                        Tw(fill,TI.MED,{Size=UDim2.new(0,0,1,0)})
                        Tw(thumb,TI.SPRING,{Position=UDim2.new(0,3,0.5,-7),BackgroundColor3=C.T_DIM})
                        Tw(tLbl,TI.FAST,{TextColor3=C.T_SEC})
                        Tw(row,TI.FAST,{BackgroundColor3=C.ELEM})
                    end
                    if not silent and cb then task.spawn(cb,state) end
                end

                local function setBind(k)
                    bound=k; binding=false; pill.Text=kn(k)
                    Tw(pill,TI.FAST,{TextColor3=C.T_SEC,BackgroundColor3=C.CARD})
                end

                pill.MouseButton1Click:Connect(function()
                    if binding then return end
                    binding=true; pill.Text="..."
                    Tw(pill,TI.FAST,{TextColor3=C.WHITE,BackgroundColor3=C.ELEM})
                    task.spawn(function()
                        while binding do
                            Tw(pill,TI.SINE,{TextTransparency=0.6}); task.wait(0.33)
                            if not binding then break end
                            Tw(pill,TI.SINE,{TextTransparency=0}); task.wait(0.33)
                        end
                    end)
                end)

                UIS.InputBegan:Connect(function(i,gp)
                    if gp then return end
                    if binding and i.UserInputType==Enum.UserInputType.Keyboard then
                        setBind(i.KeyCode)
                    elseif not binding and bound and i.KeyCode==bound then
                        setState(not state)
                    end
                end)

                local hit=Button(row,{Size=UDim2.new(1,-118,1,0),ZIndex=9})
                hit.MouseButton1Click:Connect(function() setState(not state); Ripple(row) end)
                hit.MouseEnter:Connect(function()
                    if not state then Tw(row,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                hit.MouseLeave:Connect(function()
                    if not state then Tw(row,TI.FAST,{BackgroundColor3=C.ELEM}) end
                end)

                function obj:Set(v) setState(v,true) end
                function obj:SetKey(k) setBind(k) end
                function obj:Get() return state end
                function obj:GetKey() return bound end
                cfgSys:Register((text or "tb")..#cfgSys.entries,obj.Get,function(v) obj:Set(v) end)
                return obj
            end

            -- ── Slider ─────────────────────────────────────────────────────
            function secObj:Slider(text, min, max, default, cb, step)
                local obj={}
                min=min or 0; max=max or 100; step=step or 1
                default=math.clamp(default or min,min,max)
                local val=default

                local wrap=ElemRow(54)
                wrap.Size=UDim2.new(1,0,0,54)
                Padding(wrap,8,8,14,14)

                local topRow=Frame(wrap,{Size=UDim2.new(1,0,0,18),ZIndex=6})

                Label(topRow,{
                    Text=text or "Slider",
                    TextSize=12,
                    TextColor3=C.T_PRI,
                    Size=UDim2.new(0.65,0,1,0),
                    ZIndex=7,
                    TextWrapped=false,
                })

                local valLbl=Label(topRow,{
                    TextSize=11,
                    Font=Enum.Font.GothamBold,
                    TextColor3=C.T_SEC,
                    TextXAlignment=Enum.TextXAlignment.Right,
                    Size=UDim2.new(0.35,0,1,0),
                    Position=UDim2.new(0.65,0,0,0),
                    ZIndex=7,
                    TextWrapped=false,
                })

                local trackBg=Frame(wrap,{
                    Size=UDim2.new(1,0,0,4),
                    Position=UDim2.new(0,0,1,-10),
                    BackgroundColor3=C.BORDER,
                    BackgroundTransparency=0,
                    ZIndex=6,
                })
                Corner(trackBg,2)

                local fill=Frame(trackBg,{
                    Size=UDim2.new(0,0,1,0),
                    BackgroundColor3=C.WHITE,
                    BackgroundTransparency=0,
                    ZIndex=7,
                })
                Corner(fill,2)

                local thumb=Frame(trackBg,{
                    Size=UDim2.new(0,16,0,16),
                    Position=UDim2.new(0,-8,0.5,-8),
                    BackgroundColor3=C.WHITE,
                    BackgroundTransparency=0,
                    ZIndex=9,
                })
                Corner(thumb,8)
                Stroke(thumb,C.BORDER_LT,1)

                local function fmt(n)
                    if step>=1 then return tostring(math.floor(n)) end
                    local d=math.max(0,math.ceil(-math.log10(step+0.000001)))
                    return string.format("%."..d.."f",n)
                end

                local function update(v,silent)
                    local sn=math.floor(v/step+0.5)*step
                    val=math.clamp(sn,min,max)
                    if step<1 then
                        local m=10^math.ceil(-math.log10(step+0.000001))
                        val=math.floor(val*m+0.5)/m
                    end
                    local pct=(val-min)/(max-min)
                    valLbl.Text=fmt(val)
                    Tw(fill,TI.FAST,{Size=UDim2.new(pct,0,1,0)})
                    Tw(thumb,TI.FAST,{Position=UDim2.new(pct,-8,0.5,-8)})
                    if not silent and cb then task.spawn(cb,val) end
                end

                update(default,true)

                local dragging=false
                local function fromInput(i)
                    local sz=trackBg.AbsoluteSize.X
                    if sz<1 then return end
                    local rel=math.clamp((i.Position.X-trackBg.AbsolutePosition.X)/sz,0,1)
                    update(min+rel*(max-min))
                end

                local trackHit=Button(wrap,{
                    Size=UDim2.new(1,0,0,24),
                    Position=UDim2.new(0,0,1,-24),
                    ZIndex=10,
                })
                trackHit.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1
                    or i.UserInputType==Enum.UserInputType.Touch then
                        dragging=true
                        Tw(thumb,TI.FAST,{Size=UDim2.new(0,20,0,20)})
                        Tw(wrap,TI.FAST,{BackgroundColor3=C.HOVER})
                        fromInput(i)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if not dragging then return end
                    if i.UserInputType~=Enum.UserInputType.MouseButton1
                    and i.UserInputType~=Enum.UserInputType.Touch then return end
                    dragging=false
                    Tw(thumb,TI.SPRING,{Size=UDim2.new(0,16,0,16)})
                    Tw(wrap,TI.FAST,{BackgroundColor3=C.ELEM})
                end)
                UIS.InputChanged:Connect(function(i)
                    if not dragging then return end
                    if i.UserInputType==Enum.UserInputType.MouseMovement
                    or i.UserInputType==Enum.UserInputType.Touch then fromInput(i) end
                end)
                wrap.MouseEnter:Connect(function()
                    if not dragging then Tw(wrap,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                wrap.MouseLeave:Connect(function()
                    if not dragging then Tw(wrap,TI.FAST,{BackgroundColor3=C.ELEM}) end
                end)

                function obj:Set(v) update(v,true) end
                function obj:Get() return val end
                cfgSys:Register((text or "sl")..#cfgSys.entries,obj.Get,function(v) obj:Set(v) end)
                return obj
            end

            -- ── Input (TextBox) ────────────────────────────────────────────
            function secObj:Input(text, placeholder, cb)
                local obj={}

                local wrap=ElemRow(ROW_H+10)
                wrap.Size=UDim2.new(1,0,0,ROW_H+10)
                Padding(wrap,0,0,0,0)

                Label(wrap,{
                    Text=text or "Input",
                    TextSize=11,
                    TextColor3=C.T_SEC,
                    Size=UDim2.new(0.42,0,1,0),
                    Position=UDim2.new(0,14,0,0),
                    ZIndex=6,
                    TextWrapped=false,
                })

                local boxBg=Frame(wrap,{
                    Size=UDim2.new(0.54,0,0,ROW_H-8),
                    Position=UDim2.new(0.44,0,0.5,-(ROW_H-8)/2),
                    BackgroundColor3=C.BG,
                    BackgroundTransparency=0,
                    ZIndex=6,
                })
                Corner(boxBg,5)
                Stroke(boxBg,C.BORDER,1)

                local box=TextBox(boxBg,{
                    Size=UDim2.new(1,-12,1,0),
                    Position=UDim2.new(0,6,0,0),
                    Text="",
                    PlaceholderText=placeholder or "...",
                    PlaceholderColor3=C.T_DIM,
                    TextColor3=C.T_PRI,
                    TextSize=12,
                    Font=Enum.Font.GothamMedium,
                    BackgroundTransparency=1,
                    ZIndex=7,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    ClearTextOnFocus=false,
                })

                box.Focused:Connect(function()
                    Tw(boxBg,TI.FAST,{BackgroundColor3=C.ELEM})
                    Stroke(boxBg,C.BORDER_LT,1)
                end)
                box.FocusLost:Connect(function(enter)
                    Tw(boxBg,TI.FAST,{BackgroundColor3=C.BG})
                    if cb then task.spawn(cb,box.Text,enter) end
                end)

                function obj:Set(v) box.Text=tostring(v) end
                function obj:Get() return box.Text end
                cfgSys:Register((text or "inp")..#cfgSys.entries,obj.Get,function(v) obj:Set(v) end)
                return obj
            end

            -- ── ColorPicker (simple BW value picker) ───────────────────────
            function secObj:ColorPicker(text, default, cb)
                local obj={}
                local col=default or C.WHITE
                local open=false

                local wrap=Frame(elems,{
                    Size=UDim2.new(1,0,0,ROW_H),
                    BackgroundColor3=C.ELEM,
                    BackgroundTransparency=0,
                    AutomaticSize=Enum.AutomaticSize.Y,
                    ZIndex=5,
                })
                Corner(wrap,7)
                Stroke(wrap,C.BORDER,1)

                local hdrBtn=Button(wrap,{
                    Size=UDim2.new(1,0,0,ROW_H),
                    ZIndex=7,
                })

                Label(hdrBtn,{
                    Text=text or "Color",
                    TextSize=12,
                    TextColor3=C.T_SEC,
                    Size=UDim2.new(1,-60,1,0),
                    Position=UDim2.new(0,14,0,0),
                    ZIndex=8,
                    TextWrapped=false,
                })

                local preview=Frame(hdrBtn,{
                    Size=UDim2.new(0,24,0,16),
                    Position=UDim2.new(1,-36,0.5,-8),
                    BackgroundColor3=col,
                    BackgroundTransparency=0,
                    ZIndex=8,
                })
                Corner(preview,4)
                Stroke(preview,C.BORDER,1)

                -- simple brightness slider
                local pickerFrame=Frame(wrap,{
                    Size=UDim2.new(1,0,0,0),
                    Position=UDim2.new(0,0,0,ROW_H),
                    BackgroundColor3=C.CARD,
                    BackgroundTransparency=0,
                    AutomaticSize=Enum.AutomaticSize.Y,
                    Visible=false,
                    ZIndex=6,
                })
                Padding(pickerFrame,10,10,12,12)

                Label(pickerFrame,{
                    Text="Brightness",
                    TextSize=10,
                    TextColor3=C.T_DIM,
                    Size=UDim2.new(1,0,0,16),
                    ZIndex=7,
                })

                local slBg=Frame(pickerFrame,{
                    Size=UDim2.new(1,0,0,4),
                    Position=UDim2.new(0,0,0,24),
                    BackgroundColor3=C.BORDER,
                    BackgroundTransparency=0,
                    ZIndex=7,
                })
                Corner(slBg,2)

                -- gradient
                New("UIGradient",{
                    Color=ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
                        ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
                    }),
                    Rotation=0,
                },slBg)

                local slThumb=Frame(slBg,{
                    Size=UDim2.new(0,14,0,14),
                    AnchorPoint=Vector2.new(0.5,0.5),
                    Position=UDim2.new(1,0,0.5,0),
                    BackgroundColor3=C.WHITE,
                    BackgroundTransparency=0,
                    ZIndex=9,
                })
                Corner(slThumb,7)
                Stroke(slThumb,C.BORDER_LT,1)

                local bVal=1 -- brightness 0..1
                local slDragging=false

                local function updateColor(b,silent)
                    bVal=math.clamp(b,0,1)
                    col=Color3.new(bVal,bVal,bVal)
                    preview.BackgroundColor3=col
                    Tw(slThumb,TI.FAST,{Position=UDim2.new(bVal,0,0.5,0),BackgroundColor3=col})
                    if not silent and cb then task.spawn(cb,col) end
                end

                local slHit=Button(pickerFrame,{
                    Size=UDim2.new(1,0,0,22),
                    Position=UDim2.new(0,0,0,16),
                    ZIndex=10,
                })
                slHit.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1
                    or i.UserInputType==Enum.UserInputType.Touch then
                        slDragging=true
                        local rel=math.clamp((i.Position.X-slBg.AbsolutePosition.X)/slBg.AbsoluteSize.X,0,1)
                        updateColor(rel)
                    end
                end)
                UIS.InputChanged:Connect(function(i)
                    if not slDragging then return end
                    if i.UserInputType==Enum.UserInputType.MouseMovement
                    or i.UserInputType==Enum.UserInputType.Touch then
                        local rel=math.clamp((i.Position.X-slBg.AbsolutePosition.X)/slBg.AbsoluteSize.X,0,1)
                        updateColor(rel)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1
                    or i.UserInputType==Enum.UserInputType.Touch then
                        slDragging=false
                    end
                end)

                hdrBtn.MouseButton1Click:Connect(function()
                    open=not open
                    pickerFrame.Visible=open
                end)
                hdrBtn.MouseEnter:Connect(function() Tw(wrap,TI.FAST,{BackgroundColor3=C.HOVER}) end)
                hdrBtn.MouseLeave:Connect(function() Tw(wrap,TI.FAST,{BackgroundColor3=C.ELEM}) end)

                updateColor(1,true)

                function obj:Set(c)
                    local h,s,v=Color3.toHSV(c)
                    updateColor(v,true)
                end
                function obj:Get() return col end
                return obj
            end

            -- ── Bind ───────────────────────────────────────────────────────
            function secObj:Bind(text, default, cb)
                local obj={}; local bound=default; local binding=false
                local row=ElemRow(ROW_H)

                Label(row,{
                    Text=text or "Bind",
                    TextSize=12,
                    TextColor3=C.T_SEC,
                    Size=UDim2.new(1,-88,1,0),
                    Position=UDim2.new(0,14,0,0),
                    ZIndex=6,
                    TextWrapped=false,
                })

                local function kn(k)
                    if not k then return "--" end
                    return tostring(k):gsub("Enum%.KeyCode%.","")
                end

                local pill=Button(row,{
                    Text=kn(bound),
                    TextSize=10,
                    Font=Enum.Font.GothamBold,
                    TextColor3=C.T_SEC,
                    BackgroundColor3=C.CARD,
                    BackgroundTransparency=0,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(0,70,0,24),
                    Position=UDim2.new(1,-80,0.5,-12),
                    ZIndex=7,
                })
                Corner(pill,5)
                Stroke(pill,C.BORDER,1)

                local function setBind(k,silent)
                    bound=k; binding=false; pill.Text=kn(k)
                    Tw(pill,TI.FAST,{TextColor3=C.T_SEC,BackgroundColor3=C.CARD})
                    if not silent and cb then task.spawn(cb,k) end
                end

                pill.MouseButton1Click:Connect(function()
                    if binding then return end
                    binding=true; pill.Text="..."
                    Tw(pill,TI.FAST,{TextColor3=C.WHITE,BackgroundColor3=C.ELEM})
                    task.spawn(function()
                        while binding do
                            Tw(pill,TI.SINE,{TextTransparency=0.6}); task.wait(0.33)
                            if not binding then break end
                            Tw(pill,TI.SINE,{TextTransparency=0}); task.wait(0.33)
                        end
                    end)
                end)

                UIS.InputBegan:Connect(function(i,gp)
                    if gp then return end
                    if binding and i.UserInputType==Enum.UserInputType.Keyboard then
                        setBind(i.KeyCode)
                    elseif not binding and bound and i.KeyCode==bound then
                        if cb then task.spawn(cb,bound) end
                    end
                end)

                row.MouseEnter:Connect(function() Tw(row,TI.FAST,{BackgroundColor3=C.HOVER}) end)
                row.MouseLeave:Connect(function() Tw(row,TI.FAST,{BackgroundColor3=C.ELEM}) end)

                function obj:Set(k) setBind(k,true) end
                function obj:Get() return bound end
                cfgSys:Register((text or "bind")..#cfgSys.entries,
                    function() return kn(bound) end,
                    function(v) pcall(function() setBind(Enum.KeyCode[v],true) end) end)
                return obj
            end

            -- ── Dropdown ───────────────────────────────────────────────────
            --[[
                Key fix: the dropdown panel is parented OUTSIDE the elems/wrap
                hierarchy and absolutely positioned, OR we use AutomaticSize
                on the section so it grows. We use the latter: the dropdown
                inserts a spacer frame that grows when open.
            ]]
            function secObj:Dropdown(text, opts, cb)
                local obj={}; local sel=nil; local open=false
                opts=opts or {}
                local ITEM_H=IS_MOB and 38 or 30

                -- outer container grows with content
                local ddWrap=Frame(elems,{
                    Size=UDim2.new(1,0,0,ROW_H),
                    BackgroundColor3=C.ELEM,
                    BackgroundTransparency=0,
                    AutomaticSize=Enum.AutomaticSize.Y,
                    ZIndex=10,
                    ClipsDescendants=false,
                })
                Corner(ddWrap,7)
                Stroke(ddWrap,C.BORDER,1)

                -- header row (fixed height)
                local ddHdr=Button(ddWrap,{
                    Size=UDim2.new(1,0,0,ROW_H),
                    ZIndex=11,
                })

                Label(ddHdr,{
                    Text=text or "Select",
                    TextSize=12,
                    TextColor3=C.T_SEC,
                    Size=UDim2.new(0.48,0,1,0),
                    Position=UDim2.new(0,14,0,0),
                    ZIndex=12,
                    TextWrapped=false,
                })

                local selLbl=Label(ddHdr,{
                    Text="None",
                    TextSize=12,
                    Font=Enum.Font.GothamBold,
                    TextColor3=C.T_PRI,
                    TextXAlignment=Enum.TextXAlignment.Right,
                    Size=UDim2.new(0.44,0,1,0),
                    Position=UDim2.new(0.48,0,0,0),
                    ZIndex=12,
                    TextWrapped=false,
                })

                local chev=Label(ddHdr,{
                    Text="v",
                    TextSize=11,
                    Font=Enum.Font.GothamBold,
                    TextColor3=C.T_DIM,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(0,22,1,0),
                    Position=UDim2.new(1,-24,0,0),
                    ZIndex=12,
                    TextWrapped=false,
                })

                -- dropdown list (grows via AutomaticSize)
                local ddList=Frame(ddWrap,{
                    Size=UDim2.new(1,0,0,0),
                    Position=UDim2.new(0,0,0,ROW_H+2),
                    BackgroundColor3=C.CARD,
                    BackgroundTransparency=0,
                    AutomaticSize=Enum.AutomaticSize.Y,
                    Visible=false,
                    ZIndex=20,
                    ClipsDescendants=false,
                })
                Corner(ddList,7)
                Stroke(ddList,C.BORDER,1)
                Padding(ddList,4,4,6,6)
                List(ddList,Enum.FillDirection.Vertical,3)

                local function buildOpts()
                    ddList:ClearAllChildren()
                    Padding(ddList,4,4,6,6)
                    List(ddList,Enum.FillDirection.Vertical,3)
                    for _,opt in ipairs(opts) do
                        local isSel=(opt==sel)
                        local ob=Button(ddList,{
                            Text="  "..tostring(opt),
                            TextSize=12,
                            Font=isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                            TextColor3=isSel and C.T_PRI or C.T_SEC,
                            BackgroundColor3=isSel and C.ELEM or C.CARD,
                            BackgroundTransparency=0,
                            TextXAlignment=Enum.TextXAlignment.Left,
                            Size=UDim2.new(1,0,0,ITEM_H),
                            ZIndex=22,
                        })
                        Corner(ob,5)
                        if isSel then
                            Label(ob,{
                                Text="v",
                                TextSize=10,
                                Font=Enum.Font.GothamBold,
                                TextColor3=C.WHITE,
                                TextXAlignment=Enum.TextXAlignment.Center,
                                Size=UDim2.new(0,18,1,0),
                                Position=UDim2.new(1,-20,0,0),
                                ZIndex=23,
                            })
                        end
                        ob.MouseEnter:Connect(function()
                            if not isSel then Tw(ob,TI.FAST,{BackgroundColor3=C.HOVER}) end
                        end)
                        ob.MouseLeave:Connect(function()
                            if not isSel then Tw(ob,TI.FAST,{BackgroundColor3=C.CARD}) end
                        end)
                        ob.MouseButton1Click:Connect(function()
                            sel=opt
                            selLbl.Text=tostring(opt)
                            buildOpts()
                            if cb then task.spawn(cb,opt) end
                        end)
                    end
                end

                buildOpts()

                local function toggleDD()
                    open=not open
                    ddList.Visible=open
                    Tw(chev,TI.MED,{Rotation=open and 180 or 0})
                    Tw(ddWrap,TI.FAST,{BackgroundColor3=open and C.HOVER or C.ELEM})
                end

                ddHdr.MouseButton1Click:Connect(function() toggleDD(); Ripple(ddWrap) end)
                ddHdr.MouseEnter:Connect(function()
                    if not open then Tw(ddWrap,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                ddHdr.MouseLeave:Connect(function()
                    if not open then Tw(ddWrap,TI.FAST,{BackgroundColor3=C.ELEM}) end
                end)

                function obj:Set(v)
                    sel=v; selLbl.Text=tostring(v); buildOpts()
                end
                function obj:Refresh(o,del)
                    opts=o or {}
                    if del then sel=nil; selLbl.Text="None" end
                    buildOpts()
                end
                function obj:Get() return sel end
                cfgSys:Register((text or "dd")..#cfgSys.entries,obj.Get,function(v) obj:Set(v) end)
                return obj
            end

            -- ── MultiDropdown ──────────────────────────────────────────────
            function secObj:MultiDropdown(text, opts, cb)
                local obj={}; local selected={}; local open=false
                opts=opts or {}
                local ITEM_H=IS_MOB and 38 or 30

                local ddWrap=Frame(elems,{
                    Size=UDim2.new(1,0,0,ROW_H),
                    BackgroundColor3=C.ELEM,
                    BackgroundTransparency=0,
                    AutomaticSize=Enum.AutomaticSize.Y,
                    ZIndex=10,
                    ClipsDescendants=false,
                })
                Corner(ddWrap,7)
                Stroke(ddWrap,C.BORDER,1)

                local ddHdr=Button(ddWrap,{Size=UDim2.new(1,0,0,ROW_H),ZIndex=11})

                Label(ddHdr,{
                    Text=text or "Multi Select",
                    TextSize=12,
                    TextColor3=C.T_SEC,
                    Size=UDim2.new(0.52,0,1,0),
                    Position=UDim2.new(0,14,0,0),
                    ZIndex=12,
                    TextWrapped=false,
                })

                local countLbl=Label(ddHdr,{
                    Text="None",
                    TextSize=11,
                    Font=Enum.Font.GothamBold,
                    TextColor3=C.T_DIM,
                    TextXAlignment=Enum.TextXAlignment.Right,
                    Size=UDim2.new(0.40,0,1,0),
                    Position=UDim2.new(0.52,0,0,0),
                    ZIndex=12,
                    TextWrapped=false,
                })

                local chev=Label(ddHdr,{
                    Text="v",
                    TextSize=11,
                    Font=Enum.Font.GothamBold,
                    TextColor3=C.T_DIM,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(0,22,1,0),
                    Position=UDim2.new(1,-24,0,0),
                    ZIndex=12,
                })

                local ddList=Frame(ddWrap,{
                    Size=UDim2.new(1,0,0,0),
                    Position=UDim2.new(0,0,0,ROW_H+2),
                    BackgroundColor3=C.CARD,
                    BackgroundTransparency=0,
                    AutomaticSize=Enum.AutomaticSize.Y,
                    Visible=false,
                    ZIndex=20,
                })
                Corner(ddList,7)
                Stroke(ddList,C.BORDER,1)
                Padding(ddList,4,4,6,6)
                List(ddList,Enum.FillDirection.Vertical,3)

                local function updateCount()
                    local n=0; for _ in pairs(selected) do n=n+1 end
                    countLbl.Text=n==0 and "None" or n.." sel"
                end

                local function buildOpts()
                    ddList:ClearAllChildren()
                    Padding(ddList,4,4,6,6)
                    List(ddList,Enum.FillDirection.Vertical,3)
                    for _,opt in ipairs(opts) do
                        local isSel=selected[opt]==true
                        local ob=Button(ddList,{
                            BackgroundColor3=isSel and C.ELEM or C.CARD,
                            BackgroundTransparency=0,
                            Size=UDim2.new(1,0,0,ITEM_H),
                            ZIndex=22,
                        })
                        Corner(ob,5)

                        local chkBox=Frame(ob,{
                            Size=UDim2.new(0,14,0,14),
                            Position=UDim2.new(0,8,0.5,-7),
                            BackgroundColor3=isSel and C.WHITE or C.BORDER,
                            BackgroundTransparency=0,
                            ZIndex=23,
                        })
                        Corner(chkBox,3)
                        if isSel then
                            Label(chkBox,{
                                Text="v",
                                TextSize=9,
                                Font=Enum.Font.GothamBold,
                                TextColor3=C.BLACK,
                                TextXAlignment=Enum.TextXAlignment.Center,
                                Size=UDim2.new(1,0,1,0),
                                ZIndex=24,
                            })
                        end
                        Label(ob,{
                            Text=tostring(opt),
                            TextSize=12,
                            Font=isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                            TextColor3=isSel and C.T_PRI or C.T_SEC,
                            Size=UDim2.new(1,-32,1,0),
                            Position=UDim2.new(0,30,0,0),
                            ZIndex=23,
                            TextWrapped=false,
                        })
                        ob.MouseEnter:Connect(function() Tw(ob,TI.FAST,{BackgroundColor3=C.HOVER}) end)
                        ob.MouseLeave:Connect(function()
                            Tw(ob,TI.FAST,{BackgroundColor3=isSel and C.ELEM or C.CARD})
                        end)
                        ob.MouseButton1Click:Connect(function()
                            if selected[opt] then selected[opt]=nil else selected[opt]=true end
                            updateCount(); buildOpts()
                            local arr={}; for k in pairs(selected) do table.insert(arr,k) end
                            if cb then task.spawn(cb,arr) end
                        end)
                    end
                end

                buildOpts()

                local function toggleDD()
                    open=not open
                    ddList.Visible=open
                    Tw(chev,TI.MED,{Rotation=open and 180 or 0})
                    Tw(ddWrap,TI.FAST,{BackgroundColor3=open and C.HOVER or C.ELEM})
                end

                ddHdr.MouseButton1Click:Connect(function() toggleDD(); Ripple(ddWrap) end)
                ddHdr.MouseEnter:Connect(function()
                    if not open then Tw(ddWrap,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                ddHdr.MouseLeave:Connect(function()
                    if not open then Tw(ddWrap,TI.FAST,{BackgroundColor3=C.ELEM}) end
                end)

                function obj:Set(arr)
                    selected={}
                    if type(arr)=="table" then
                        for _,v in ipairs(arr) do selected[v]=true end
                    end
                    updateCount(); buildOpts()
                end
                function obj:Get()
                    local arr={}; for k in pairs(selected) do table.insert(arr,k) end; return arr
                end
                function obj:Refresh(o,reset)
                    opts=o or {}; if reset then selected={} end; updateCount(); buildOpts()
                end
                return obj
            end

            return secObj
        end -- Section

        return tabObj
    end -- Tab

    return winObj
end -- Window

return AlterLib
