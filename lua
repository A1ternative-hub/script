-- ALTER UI Library v5.2
-- Fix: C table referenced only at call-time, never at definition-time

local AlterLib = {}
AlterLib.__index = AlterLib

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local RS      = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HTTP    = game:GetService("HttpService")
local LP      = Players.LocalPlayer

-- Palette
local C = {
    BG        = Color3.fromRGB(12,  12,  12),
    PANEL     = Color3.fromRGB(18,  18,  18),
    CARD      = Color3.fromRGB(22,  22,  22),
    ELEM      = Color3.fromRGB(28,  28,  28),
    HOVER     = Color3.fromRGB(36,  36,  36),
    ACTIVE    = Color3.fromRGB(46,  46,  46),
    BORDER    = Color3.fromRGB(42,  42,  42),
    BORDER_LT = Color3.fromRGB(60,  60,  60),
    WHITE     = Color3.fromRGB(255, 255, 255),
    BLACK     = Color3.fromRGB(0,   0,   0),
    T_PRI     = Color3.fromRGB(225, 225, 225),
    T_SEC     = Color3.fromRGB(100, 100, 100),
    T_DIM     = Color3.fromRGB(52,  52,  52),
    ACC_OFF   = Color3.fromRGB(38,  38,  38),
}

-- Tween presets
local TI = {
    SNAP   = TweenInfo.new(0.04, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
    FAST   = TweenInfo.new(0.12, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    MED    = TweenInfo.new(0.20, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    SLOW   = TweenInfo.new(0.32, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    SPRING = TweenInfo.new(0.42, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
    SINE   = TweenInfo.new(0.26, Enum.EasingStyle.Sine,   Enum.EasingDirection.InOut),
}

local TWEENABLE = {
    BackgroundColor3       = true,
    BackgroundTransparency = true,
    Position               = true,
    Size                   = true,
    Rotation               = true,
    TextColor3             = true,
    TextTransparency       = true,
    ImageColor3            = true,
    ImageTransparency      = true,
    CanvasPosition         = true,
}

local function Tw(obj, ti, props)
    if not obj or not obj.Parent then return end
    local safe = {}
    for k, v in pairs(props) do
        if TWEENABLE[k] then safe[k] = v end
    end
    if next(safe) then
        pcall(function() TS:Create(obj, ti, safe):Play() end)
    end
end

-- NO C references at definition time in any of these functions
-- C is only used inside function bodies which run AFTER C is defined

local function MakeFrame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    if props then
        for k, v in pairs(props) do
            pcall(function() f[k] = v end)
        end
    end
    f.Parent = parent
    return f
end

local function MakeButton(parent, props)
    local b = Instance.new("TextButton")
    b.BackgroundTransparency = 1
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Text = ""
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    if props then
        for k, v in pairs(props) do
            pcall(function() b[k] = v end)
        end
    end
    b.Parent = parent
    return b
end

local function MakeLabel(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = false
    if props then
        for k, v in pairs(props) do
            pcall(function() l[k] = v end)
        end
    end
    l.Parent = parent
    return l
end

local function MakeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function MakeStroke(parent, color, thickness)
    -- color param passed at call site, not from C at definition time
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(42, 42, 42)
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function MakePadding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.Parent = parent
    return p
end

local function MakeList(parent, direction, gap)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = direction or Enum.FillDirection.Vertical
    l.Padding             = UDim.new(0, gap or 0)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = Enum.VerticalAlignment.Top
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

-- ScrollFrame: NO default color references here
-- scrollbar color is set by caller
local function MakeScrollFrame(parent, props)
    local s = Instance.new("ScrollingFrame")
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.ScrollBarThickness = 3
    s.ScrollingDirection = Enum.ScrollingDirection.Y
    s.CanvasSize = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    -- NO C reference here — set after construction
    if props then
        for k, v in pairs(props) do
            pcall(function() s[k] = v end)
        end
    end
    s.Parent = parent
    return s
end

local function MakeSG(id)
    local name = "ALTER_" .. id
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
    local ok1, ap = pcall(function() return host.AbsolutePosition end)
    local ok2, as = pcall(function() return host.AbsoluteSize end)
    if not ok1 or not ok2 then return end
    local mp = UIS:GetMouseLocation()
    local lx = math.clamp(mp.X - ap.X, 0, as.X)
    local ly = math.clamp(mp.Y - ap.Y, 0, as.Y)
    local sz = math.clamp(math.max(as.X, as.Y) * 1.2, 20, 70)
    local wasClip = host.ClipsDescendants
    host.ClipsDescendants = true
    local r = Instance.new("Frame")
    r.Size = UDim2.new(0, 0, 0, 0)
    r.Position = UDim2.new(0, lx, 0, ly)
    r.AnchorPoint = Vector2.new(0.5, 0.5)
    r.BackgroundColor3 = C.WHITE
    r.BackgroundTransparency = 0.82
    r.ZIndex = host.ZIndex + 8
    r.BorderSizePixel = 0
    r.Parent = host
    MakeCorner(r, 9999)
    Tw(r, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, sz, 0, sz),
        BackgroundTransparency = 1,
    })
    task.delay(0.42, function()
        if r and r.Parent then r:Destroy() end
        if host and host.Parent then
            host.ClipsDescendants = wasClip
        end
    end)
end

local function MakeDraggable(handle, target)
    local down   = false
    local startM = Vector2.new()
    local startP = Vector2.new()
    handle.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
        down   = true
        startM = Vector2.new(i.Position.X, i.Position.Y)
        startP = Vector2.new(target.Position.X.Offset, target.Position.Y.Offset)
    end)
    UIS.InputChanged:Connect(function(i)
        if not down then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local d  = Vector2.new(i.Position.X - startM.X, i.Position.Y - startM.Y)
        local sg = target.Parent
        local mX = sg and math.max(0, sg.AbsoluteSize.X - target.AbsoluteSize.X) or 9999
        local mY = sg and math.max(0, sg.AbsoluteSize.Y - target.AbsoluteSize.Y) or 9999
        target.Position = UDim2.new(
            0, math.clamp(startP.X + d.X, 0, mX),
            0, math.clamp(startP.Y + d.Y, 0, mY)
        )
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            down = false
        end
    end)
end

-- Config system
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
    for _, e in ipairs(self.entries) do
        if e.key == key then
            e.get = getter
            e.set = setter
            return
        end
    end
    table.insert(self.entries, {key=key, get=getter, set=setter})
end

function ConfigSys:Save(name)
    if not name or name == "" then return false, "empty name" end
    local data = {}
    for _, e in ipairs(self.entries) do
        local ok, v = pcall(e.get)
        if ok then data[e.key] = v end
    end
    local ok, json = pcall(function() return HTTP:JSONEncode(data) end)
    if not ok then return false, "encode failed" end
    local path = self.folder.."/"..name..".json"
    local wok, werr = pcall(function() writefile(path, json) end)
    return wok, werr
end

function ConfigSys:Load(name)
    local path = self.folder.."/"..name..".json"
    local ok, raw = pcall(function() return readfile(path) end)
    if not ok or not raw then return false end
    local ok2, data = pcall(function() return HTTP:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return false end
    for _, e in ipairs(self.entries) do
        if data[e.key] ~= nil then pcall(e.set, data[e.key]) end
    end
    return true
end

function ConfigSys:Delete(name)
    local path = self.folder.."/"..name..".json"
    return pcall(function() delfile(path) end)
end

function ConfigSys:List()
    local out = {}
    pcall(function()
        for _, f in ipairs(listfiles(self.folder)) do
            local n = f:match("[/\\]([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end)
    return out
end

function ConfigSys:AutoLoadByPlaceId(map)
    task.delay(1.5, function()
        local pid = tostring(game.PlaceId)
        if map and map[pid] and self:Load(map[pid]) then
            print("[Alter] PlaceId autoload:", map[pid])
        else
            self:Load("default")
        end
    end)
end

function ConfigSys:AutoLoadByGameId(map)
    task.delay(1.5, function()
        local gid = tostring(game.GameId)
        if map and map[gid] and self:Load(map[gid]) then
            print("[Alter] GameId autoload:", map[gid])
        else
            self:Load("default")
        end
    end)
end

-- Notifications
local _nSG, _nHolder

local function EnsureNotif()
    if _nSG and _nSG.Parent then return end
    _nSG = MakeSG("NOTIF")
    _nHolder = MakeFrame(_nSG, {
        Size     = UDim2.new(0, 270, 1, -20),
        Position = UDim2.new(1, -282, 0, 10),
        ZIndex   = 200,
    })
    local ll = Instance.new("UIListLayout")
    ll.FillDirection       = Enum.FillDirection.Vertical
    ll.VerticalAlignment   = Enum.VerticalAlignment.Bottom
    ll.HorizontalAlignment = Enum.HorizontalAlignment.Left
    ll.Padding             = UDim.new(0, 6)
    ll.SortOrder           = Enum.SortOrder.LayoutOrder
    ll.Parent              = _nHolder
    MakePadding(_nHolder, 0, 10, 0, 0)
end

function AlterLib:Notify(cfg)
    EnsureNotif()
    cfg = cfg or {}
    local card = MakeFrame(_nHolder, {
        Size                   = UDim2.new(1, 0, 0, 62),
        BackgroundColor3       = C.PANEL,
        BackgroundTransparency = 0,
        ZIndex                 = 201,
    })
    MakeCorner(card, 8)
    MakeStroke(card, C.BORDER, 1)
    local bar = MakeFrame(card, {
        Size                   = UDim2.new(0, 0, 0, 2),
        BackgroundColor3       = C.WHITE,
        BackgroundTransparency = 0,
        ZIndex                 = 203,
    })
    MakeCorner(bar, 1)
    MakeLabel(card, {
        Text       = cfg.Title or "Alter",
        TextSize   = 13,
        Font       = Enum.Font.GothamBold,
        TextColor3 = C.T_PRI,
        Size       = UDim2.new(1, -14, 0, 20),
        Position   = UDim2.new(0, 10, 0, 9),
        ZIndex     = 202,
    })
    MakeLabel(card, {
        Text        = cfg.Message or "",
        TextSize    = 11,
        TextColor3  = C.T_SEC,
        Size        = UDim2.new(1, -14, 0, 24),
        Position    = UDim2.new(0, 10, 0, 31),
        TextWrapped = true,
        ZIndex      = 202,
    })
    card.Position = UDim2.new(1, 10, 1, 0)
    Tw(card, TI.SPRING, {Position = UDim2.new(0, 0, 1, 0)})
    task.delay(0.06, function()
        Tw(bar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(1, 0, 0, 2)})
    end)
    task.delay(cfg.Duration or 3.5, function()
        Tw(card, TI.MED, {
            Position               = UDim2.new(1, 10, 1, 0),
            BackgroundTransparency = 1,
        })
        task.delay(0.25, function()
            if card and card.Parent then card:Destroy() end
        end)
    end)
end

function AlterLib:Prompt(cfg)
    cfg = cfg or {}
    local sg = MakeSG("PROMPT")
    local backdrop = MakeButton(sg, {
        Size                   = UDim2.fromScale(1, 1),
        BackgroundColor3       = C.BLACK,
        BackgroundTransparency = 1,
        ZIndex                 = 100,
    })
    Tw(backdrop, TI.MED, {BackgroundTransparency = 0.55})
    local card = MakeFrame(backdrop, {
        Size                   = UDim2.new(0, 340, 0, 0),
        Position               = UDim2.fromScale(0.5, 0.5),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = C.PANEL,
        BackgroundTransparency = 0,
        ZIndex                 = 101,
    })
    card.ClipsDescendants = true
    MakeCorner(card, 9)
    MakeStroke(card, C.BORDER_LT, 1)
    MakeFrame(card, {
        Size=UDim2.new(1,0,0,2), BackgroundColor3=C.WHITE,
        BackgroundTransparency=0, ZIndex=105,
    })
    local hdr = MakeFrame(card, {
        Size=UDim2.new(1,0,0,44), BackgroundColor3=C.CARD,
        BackgroundTransparency=0, ZIndex=102,
    })
    MakeCorner(hdr, 9)
    MakeFrame(hdr, {
        Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=C.CARD, BackgroundTransparency=0, ZIndex=102,
    })
    MakeLabel(hdr, {
        Text=cfg.Title or "Confirm", TextSize=13, Font=Enum.Font.GothamBold,
        TextColor3=C.T_PRI, Size=UDim2.new(1,-20,1,0),
        Position=UDim2.new(0,14,0,0), ZIndex=103,
    })
    MakeLabel(card, {
        Text=cfg.Message or "", TextSize=12, TextColor3=C.T_SEC,
        Size=UDim2.new(1,-28,0,38), Position=UDim2.new(0,14,0,52),
        TextWrapped=true, ZIndex=103,
    })
    local bRow = MakeFrame(card, {
        Size=UDim2.new(1,-28,0,32), Position=UDim2.new(0,14,0,100), ZIndex=102,
    })
    MakeList(bRow, Enum.FillDirection.Horizontal, 8)
    local function closePrompt(cb)
        Tw(card,     TI.MED, {Size=UDim2.new(0,340,0,0)})
        Tw(backdrop, TI.MED, {BackgroundTransparency=1})
        task.delay(0.26, function()
            if cb then pcall(cb) end
            if sg and sg.Parent then sg:Destroy() end
        end)
    end
    local function PBtn(txt, primary, cb)
        local b = MakeButton(bRow, {
            Text=txt, TextSize=12, Font=Enum.Font.GothamBold,
            TextColor3=primary and C.BLACK or C.T_SEC,
            BackgroundColor3=primary and C.WHITE or C.ELEM,
            BackgroundTransparency=0,
            TextXAlignment=Enum.TextXAlignment.Center,
            Size=UDim2.new(0.5,-4,1,0), ZIndex=103,
        })
        MakeCorner(b, 6)
        if not primary then MakeStroke(b, C.BORDER, 1) end
        b.MouseButton1Click:Connect(function() closePrompt(cb) end)
        b.MouseEnter:Connect(function()
            Tw(b, TI.FAST, {BackgroundColor3=primary and Color3.fromRGB(210,210,210) or C.HOVER})
        end)
        b.MouseLeave:Connect(function()
            Tw(b, TI.FAST, {BackgroundColor3=primary and C.WHITE or C.ELEM})
        end)
        b.MouseButton1Down:Connect(function() Ripple(b) end)
    end
    PBtn(cfg.NoText  or "Cancel",  false, cfg.No)
    PBtn(cfg.YesText or "Confirm", true,  cfg.Yes)
    backdrop.MouseButton1Click:Connect(function() closePrompt(nil) end)
    Tw(card, TI.SPRING, {Size=UDim2.new(0,340,0,142)})
end

function AlterLib:Window(cfg)
    cfg = cfg or {}
    local IS_MOB = UIS.TouchEnabled and not UIS.KeyboardEnabled
    local vp     = workspace.CurrentCamera.ViewportSize
    local WIN_W  = IS_MOB and math.min(vp.X - 16, 440) or 600
    local WIN_H  = IS_MOB and math.min(vp.Y - 16, 580) or 520
    local SIDE_W = IS_MOB and 100 or 138
    local ROW_H  = IS_MOB and 42  or 34

    local sg     = MakeSG(cfg.Folder or "WIN")
    local cfgSys = ConfigSys.new(cfg.Folder or "AlterHub")

    local root = MakeFrame(sg, {
        Size                   = UDim2.new(0, WIN_W, 0, 0),
        Position               = UDim2.new(0, IS_MOB and 8 or 70, 0, IS_MOB and 8 or 55),
        BackgroundColor3       = C.BG,
        BackgroundTransparency = 1,
        ZIndex                 = 1,
    })
    root.ClipsDescendants = false
    MakeCorner(root, 10)
    MakeStroke(root, C.BORDER, 1)

    local titleBar = MakeFrame(root, {
        Size=UDim2.new(1,0,0,46), BackgroundColor3=C.PANEL,
        BackgroundTransparency=0, ZIndex=4,
    })
    MakeCorner(titleBar, 10)
    MakeFrame(titleBar, {
        Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=C.PANEL, BackgroundTransparency=0, ZIndex=4,
    })

    local accentLine = MakeFrame(titleBar, {
        Size=UDim2.new(0,0,0,1), BackgroundColor3=C.WHITE,
        BackgroundTransparency=0, ZIndex=6,
    })
    MakeCorner(accentLine, 1)

    local hubLbl = MakeLabel(titleBar, {
        Text=cfg.Name or "Alter", TextSize=14, Font=Enum.Font.GothamBlack,
        TextColor3=C.T_PRI, TextTransparency=1, RichText=true,
        Size=UDim2.new(0.55,0,0,26), Position=UDim2.new(0,14,0.5,-13), ZIndex=5,
    })
    MakeLabel(titleBar, {
        Text="PlaceId "..tostring(game.PlaceId), TextSize=9, TextColor3=C.T_DIM,
        Size=UDim2.new(0.55,0,0,12), Position=UDim2.new(0,14,1,-14), ZIndex=5,
    })

    local ctrlF = MakeFrame(titleBar, {
        Size=UDim2.new(0,58,0,22), Position=UDim2.new(1,-66,0.5,-11), ZIndex=5,
    })
    MakeList(ctrlF, Enum.FillDirection.Horizontal, 6)

    local minimised = false
    local bodyFrame

    local function CtrlBtn(sym, action)
        local b = MakeButton(ctrlF, {
            Text=sym, TextSize=13, Font=Enum.Font.GothamBold,
            TextColor3=C.T_DIM, BackgroundColor3=C.ELEM,
            BackgroundTransparency=0, TextXAlignment=Enum.TextXAlignment.Center,
            Size=UDim2.new(0,26,0,22), ZIndex=6,
        })
        MakeCorner(b, 5)
        MakeStroke(b, C.BORDER, 1)
        b.MouseButton1Click:Connect(function() Ripple(b); action() end)
        b.MouseEnter:Connect(function()
            Tw(b, TI.FAST, {BackgroundColor3=C.HOVER, TextColor3=C.T_PRI})
        end)
        b.MouseLeave:Connect(function()
            Tw(b, TI.FAST, {BackgroundColor3=C.ELEM, TextColor3=C.T_DIM})
        end)
        b.MouseButton1Down:Connect(function()
            Tw(b, TI.SNAP, {BackgroundColor3=C.ACTIVE})
        end)
        return b
    end

    CtrlBtn("−", function()
        minimised = not minimised
        Tw(root, TI.MED, {
            Size = minimised
                and UDim2.new(0,WIN_W,0,46)
                or  UDim2.new(0,WIN_W,0,WIN_H)
        })
    end)
    CtrlBtn("×", function()
        Tw(root, TI.MED, {Size=UDim2.new(0,WIN_W,0,0), BackgroundTransparency=1})
        task.delay(0.28, function()
            if sg and sg.Parent then sg:Destroy() end
        end)
    end)

    MakeDraggable(titleBar, root)

    bodyFrame = MakeFrame(root, {
        Size=UDim2.new(1,0,1,-46), Position=UDim2.new(0,0,0,46), ZIndex=2,
    })
    bodyFrame.ClipsDescendants = true

    local sidebar = MakeFrame(bodyFrame, {
        Size=UDim2.new(0,SIDE_W,1,0), BackgroundColor3=C.PANEL,
        BackgroundTransparency=0, ZIndex=3,
    })
    MakeCorner(sidebar, 10)
    MakeFrame(sidebar, {
        Size=UDim2.new(0,10,1,0), Position=UDim2.new(1,-10,0,0),
        BackgroundColor3=C.PANEL, BackgroundTransparency=0, ZIndex=3,
    })
    MakeFrame(sidebar, {
        Size=UDim2.new(1,0,0,10), BackgroundColor3=C.PANEL,
        BackgroundTransparency=0, ZIndex=3,
    })
    MakeFrame(sidebar, {
        Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,0,0,0),
        BackgroundColor3=C.BORDER, BackgroundTransparency=0, ZIndex=4,
    })

    local brandLbl = MakeLabel(sidebar, {
        Text="ALTER", TextSize=10, Font=Enum.Font.GothamBlack,
        TextColor3=C.T_DIM, TextTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.new(1,0,0,46), ZIndex=4,
    })
    MakeFrame(sidebar, {
        Size=UDim2.new(1,-18,0,1), Position=UDim2.new(0,9,0,45),
        BackgroundColor3=C.BORDER, BackgroundTransparency=0, ZIndex=4,
    })

    local tabScroll = MakeScrollFrame(sidebar, {
        Size=UDim2.new(1,0,1,-54), Position=UDim2.new(0,0,0,52),
        ScrollBarThickness=0, ZIndex=4,
    })
    tabScroll.ScrollBarImageColor3 = C.BORDER_LT
    MakePadding(tabScroll, 4, 4, 6, 6)
    MakeList(tabScroll, Enum.FillDirection.Vertical, 3)

    local contentArea = MakeFrame(bodyFrame, {
        Size=UDim2.new(1,-SIDE_W,1,0), Position=UDim2.new(0,SIDE_W,0,0), ZIndex=2,
    })
    contentArea.ClipsDescendants = true

    task.defer(function()
        Tw(root, TI.SPRING, {
            Size=UDim2.new(0,WIN_W,0,WIN_H), BackgroundTransparency=0,
        })
        task.delay(0.18, function()
            Tw(accentLine,
                TweenInfo.new(0.55,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                {Size=UDim2.new(1,0,0,1)})
            Tw(hubLbl,   TI.SLOW, {TextTransparency=0})
            Tw(brandLbl, TI.SLOW, {TextTransparency=0})
        end)
    end)

    local winObj = {_tabs={}, Config=cfgSys}

    function winObj:Tab(name)
        local tabObj = {_name=name}

        local btn = MakeButton(tabScroll, {
            Size=UDim2.new(1,0,0,ROW_H), BackgroundColor3=C.ELEM,
            BackgroundTransparency=1, ZIndex=5,
        })
        MakeCorner(btn, 6)

        local ind = MakeFrame(btn, {
            Size=UDim2.new(0,2,0,0), Position=UDim2.new(0,0,0.5,0),
            AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=C.WHITE,
            BackgroundTransparency=0, ZIndex=6,
        })
        MakeCorner(ind, 1)

        local dot = MakeFrame(btn, {
            Size=UDim2.new(0,4,0,4), Position=UDim2.new(0,10,0.5,-2),
            BackgroundColor3=C.T_DIM, BackgroundTransparency=0, ZIndex=6,
        })
        MakeCorner(dot, 2)

        local lbl = MakeLabel(btn, {
            Text=name, TextSize=12, TextColor3=C.T_DIM,
            Size=UDim2.new(1,-22,1,0), Position=UDim2.new(0,22,0,0), ZIndex=6,
        })

        local panel = MakeScrollFrame(contentArea, {
            Size=UDim2.new(1,0,1,0), ScrollBarThickness=3, Visible=false, ZIndex=2,
        })
        panel.ScrollBarImageColor3 = C.BORDER_LT
        panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
        MakePadding(panel, 12, 12, 12, 12)
        MakeList(panel, Enum.FillDirection.Vertical, 8)

        tabObj._panel = panel
        tabObj._btn   = btn
        tabObj._ind   = ind
        tabObj._dot   = dot
        tabObj._lbl   = lbl
        table.insert(self._tabs, tabObj)

        local function activate()
            for _, t in ipairs(self._tabs) do
                if t ~= tabObj then
                    t._panel.Visible = false
                    Tw(t._btn, TI.FAST, {BackgroundTransparency=1})
                    Tw(t._ind, TI.FAST, {Size=UDim2.new(0,2,0,0)})
                    Tw(t._dot, TI.FAST, {BackgroundColor3=C.T_DIM})
                    Tw(t._lbl, TI.FAST, {TextColor3=C.T_DIM})
                end
            end
            panel.Visible  = true
            panel.Position = UDim2.new(0,4,0,0)
            Tw(panel, TI.MED,    {Position=UDim2.new(0,0,0,0)})
            Tw(btn,   TI.MED,    {BackgroundTransparency=0, BackgroundColor3=C.ELEM})
            Tw(ind,   TI.SPRING, {Size=UDim2.new(0,2,0,18)})
            Tw(dot,   TI.FAST,   {BackgroundColor3=C.WHITE})
            Tw(lbl,   TI.FAST,   {TextColor3=C.T_PRI})
        end

        btn.MouseButton1Click:Connect(function() activate(); Ripple(btn) end)
        btn.MouseEnter:Connect(function()
            if panel.Visible then return end
            Tw(btn, TI.FAST, {BackgroundTransparency=0.88, BackgroundColor3=C.ELEM})
            Tw(lbl, TI.FAST, {TextColor3=C.T_SEC})
        end)
        btn.MouseLeave:Connect(function()
            if panel.Visible then return end
            Tw(btn, TI.FAST, {BackgroundTransparency=1})
            Tw(lbl, TI.FAST, {TextColor3=C.T_DIM})
        end)

        if #self._tabs == 1 then activate() end

        function tabObj:Section(secName)
            local secObj    = {}
            local collapsed = false
            local fullH     = 36

            local wrap = MakeFrame(panel, {
                Size=UDim2.new(1,0,0,36), BackgroundColor3=C.CARD,
                BackgroundTransparency=1, ZIndex=3,
            })
            wrap.ClipsDescendants = true
            MakeCorner(wrap, 8)
            MakeStroke(wrap, C.BORDER, 1)

            local hdr = MakeFrame(wrap, {
                Size=UDim2.new(1,0,0,36), BackgroundColor3=C.ELEM,
                BackgroundTransparency=0, ZIndex=4,
            })
            MakeCorner(hdr, 8)
            MakeFrame(hdr, {
                Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0.5,0),
                BackgroundColor3=C.ELEM, BackgroundTransparency=0, ZIndex=4,
            })

            local stripe = MakeFrame(hdr, {
                Size=UDim2.new(0,2,0,14), Position=UDim2.new(0,8,0.5,-7),
                BackgroundColor3=C.WHITE, BackgroundTransparency=0, ZIndex=5,
            })
            MakeCorner(stripe, 1)

            MakeLabel(hdr, {
                Text=string.upper(secName or "Section"), TextSize=10,
                Font=Enum.Font.GothamBold, TextColor3=C.T_SEC,
                Size=UDim2.new(1,-46,1,0), Position=UDim2.new(0,18,0,0), ZIndex=5,
            })

            local collBtn = MakeButton(hdr, {
                Text="−", TextSize=16, Font=Enum.Font.GothamBold,
                TextColor3=C.T_DIM, TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(0,32,1,0), Position=UDim2.new(1,-34,0,0), ZIndex=7,
            })

            local elems = MakeFrame(wrap, {
                Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,36), ZIndex=4,
            })
            MakePadding(elems, 8, 10, 10, 10)
            local elemsLL = MakeList(elems, Enum.FillDirection.Vertical, 6)

            local function syncHeight()
                if collapsed then return end
                local newH = 36 + elemsLL.AbsoluteContentSize.Y + 18
                fullH      = newH
                wrap.Size  = UDim2.new(1, 0, 0, newH)
            end

            elemsLL.Changed:Connect(function() task.defer(syncHeight) end)
            task.defer(function()
                Tw(wrap, TI.SPRING, {BackgroundTransparency=0})
                task.defer(syncHeight)
            end)

            local function doCollapse()
                collapsed = not collapsed
                if collapsed then
                    fullH = wrap.AbsoluteSize.Y
                    Tw(wrap,    TI.MED,  {Size=UDim2.new(1,0,0,36)})
                    Tw(collBtn, TI.FAST, {Rotation=45})
                    Tw(stripe,  TI.FAST, {BackgroundColor3=C.T_DIM})
                else
                    Tw(wrap,    TI.MED,  {Size=UDim2.new(1,0,0,fullH)})
                    Tw(collBtn, TI.FAST, {Rotation=0})
                    Tw(stripe,  TI.FAST, {BackgroundColor3=C.WHITE})
                end
            end

            collBtn.MouseButton1Click:Connect(doCollapse)
            collBtn.MouseEnter:Connect(function()
                Tw(collBtn, TI.FAST, {TextColor3=C.WHITE})
            end)
            collBtn.MouseLeave:Connect(function()
                Tw(collBtn, TI.FAST, {TextColor3=C.T_DIM})
            end)

            local hdrHit = MakeButton(hdr, {
                Size=UDim2.new(1,-36,1,0), ZIndex=6,
            })
            hdrHit.MouseButton1Click:Connect(doCollapse)
            hdrHit.MouseEnter:Connect(function()
                Tw(hdr, TI.FAST, {BackgroundColor3=C.HOVER})
            end)
            hdrHit.MouseLeave:Connect(function()
                Tw(hdr, TI.FAST, {BackgroundColor3=C.ELEM})
            end)

            local function ElemRow(h)
                local f = MakeFrame(elems, {
                    Size=UDim2.new(1,0,0,h or ROW_H),
                    BackgroundColor3=C.ELEM, BackgroundTransparency=0, ZIndex=5,
                })
                MakeCorner(f, 7)
                MakeStroke(f, C.BORDER, 1)
                return f
            end

            function secObj:Label(text, col)
                local f = MakeFrame(elems, {Size=UDim2.new(1,0,0,24), ZIndex=5})
                MakeLabel(f, {
                    Text=text or "", TextSize=11,
                    TextColor3=col or C.T_SEC,
                    Size=UDim2.new(1,0,1,0), TextWrapped=true, ZIndex=6,
                })
            end

            function secObj:Button(text, cb)
                local row = MakeButton(elems, {
                    BackgroundColor3=C.ELEM, BackgroundTransparency=0,
                    Size=UDim2.new(1,0,0,ROW_H), ZIndex=5,
                })
                MakeCorner(row, 7)
                MakeStroke(row, C.BORDER, 1)
                local glow = MakeFrame(row, {
                    Size=UDim2.new(0,2,0,0), Position=UDim2.new(0,0,0.5,0),
                    AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=C.WHITE,
                    BackgroundTransparency=0, ZIndex=6,
                })
                MakeCorner(glow, 1)
                MakeLabel(row, {
                    Text=text or "Button", TextSize=12, TextColor3=C.T_SEC,
                    Size=UDim2.new(1,-36,1,0), Position=UDim2.new(0,12,0,0), ZIndex=6,
                })
                MakeLabel(row, {
                    Text="›", TextSize=16, Font=Enum.Font.GothamBold,
                    TextColor3=C.T_DIM, TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(0,22,1,0), Position=UDim2.new(1,-26,0,0), ZIndex=6,
                })
                row.MouseEnter:Connect(function()
                    Tw(row,  TI.FAST, {BackgroundColor3=C.HOVER})
                    Tw(glow, TI.MED,  {Size=UDim2.new(0,2,0.5,0)})
                end)
                row.MouseLeave:Connect(function()
                    Tw(row,  TI.FAST, {BackgroundColor3=C.ELEM})
                    Tw(glow, TI.FAST, {Size=UDim2.new(0,2,0,0)})
                end)
                row.MouseButton1Down:Connect(function()
                    Tw(row, TI.SNAP, {BackgroundColor3=C.ACTIVE})
                    Ripple(row)
                end)
                row.MouseButton1Up:Connect(function()
                    Tw(row, TI.FAST, {BackgroundColor3=C.HOVER})
                    if cb then task.spawn(cb) end
                end)
            end

            function secObj:Toggle(text, cb)
                local obj={} ; local state=false
                local row=ElemRow(ROW_H)
                local tLbl=MakeLabel(row, {
                    Text=text or "Toggle", TextSize=12, TextColor3=C.T_SEC,
                    Size=UDim2.new(1,-58,1,0), Position=UDim2.new(0,12,0,0), ZIndex=6,
                })
                local track=MakeFrame(row, {
                    Size=UDim2.new(0,34,0,18), Position=UDim2.new(1,-46,0.5,-9),
                    BackgroundColor3=C.ACC_OFF, BackgroundTransparency=0, ZIndex=6,
                })
                MakeCorner(track,9); MakeStroke(track,C.BORDER,1)
                local fill=MakeFrame(track, {
                    Size=UDim2.new(0,0,1,0), BackgroundColor3=C.WHITE,
                    BackgroundTransparency=0.4, ZIndex=7,
                })
                MakeCorner(fill,9)
                local thumb=MakeFrame(track, {
                    Size=UDim2.new(0,12,0,12), Position=UDim2.new(0,3,0.5,-6),
                    BackgroundColor3=C.T_DIM, BackgroundTransparency=0, ZIndex=8,
                })
                MakeCorner(thumb,6)
                local function setState(v,silent)
                    state=v
                    if state then
                        Tw(track,TI.MED,   {BackgroundColor3=Color3.fromRGB(46,46,46)})
                        Tw(fill, TI.MED,   {Size=UDim2.new(1,0,1,0)})
                        Tw(thumb,TI.SPRING,{Position=UDim2.new(0,19,0.5,-6),BackgroundColor3=C.WHITE})
                        Tw(tLbl, TI.FAST,  {TextColor3=C.T_PRI})
                        Tw(row,  TI.FAST,  {BackgroundColor3=Color3.fromRGB(30,30,30)})
                    else
                        Tw(track,TI.MED,   {BackgroundColor3=C.ACC_OFF})
                        Tw(fill, TI.MED,   {Size=UDim2.new(0,0,1,0)})
                        Tw(thumb,TI.SPRING,{Position=UDim2.new(0,3,0.5,-6),BackgroundColor3=C.T_DIM})
                        Tw(tLbl, TI.FAST,  {TextColor3=C.T_SEC})
                        Tw(row,  TI.FAST,  {BackgroundColor3=C.ELEM})
                    end
                    if not silent and cb then task.spawn(cb,state) end
                end
                local hit=MakeButton(row,{Size=UDim2.new(1,0,1,0),ZIndex=9})
                hit.MouseButton1Click:Connect(function()
                    Tw(thumb,TI.SNAP,{Size=UDim2.new(0,16,0,10)})
                    task.delay(0.07,function()
                        Tw(thumb,TI.SPRING,{Size=UDim2.new(0,12,0,12)})
                        setState(not state)
                    end)
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
                cfgSys:Register((text or "tog")..#cfgSys.entries, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            function secObj:ToggleBind(text, defaultKey, cb)
                local obj={};local state=false;local bound=defaultKey;local binding=false
                local row=ElemRow(ROW_H)
                local tLbl=MakeLabel(row,{
                    Text=text or "ToggleBind",TextSize=12,TextColor3=C.T_SEC,
                    Size=UDim2.new(1,-130,1,0),Position=UDim2.new(0,12,0,0),ZIndex=6,
                })
                local function kn(k)
                    if not k then return "—" end
                    return tostring(k):gsub("Enum.KeyCode.","")
                end
                local pill=MakeButton(row,{
                    Text=kn(bound),TextSize=10,Font=Enum.Font.GothamBold,
                    TextColor3=C.T_SEC,BackgroundColor3=C.CARD,BackgroundTransparency=0,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(0,52,0,20),Position=UDim2.new(1,-104,0.5,-10),ZIndex=7,
                })
                MakeCorner(pill,5);MakeStroke(pill,C.BORDER,1)
                local track=MakeFrame(row,{
                    Size=UDim2.new(0,34,0,18),Position=UDim2.new(1,-46,0.5,-9),
                    BackgroundColor3=C.ACC_OFF,BackgroundTransparency=0,ZIndex=6,
                })
                MakeCorner(track,9);MakeStroke(track,C.BORDER,1)
                local fill=MakeFrame(track,{
                    Size=UDim2.new(0,0,1,0),BackgroundColor3=C.WHITE,
                    BackgroundTransparency=0.4,ZIndex=7,
                })
                MakeCorner(fill,9)
                local thumb=MakeFrame(track,{
                    Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,3,0.5,-6),
                    BackgroundColor3=C.T_DIM,BackgroundTransparency=0,ZIndex=8,
                })
                MakeCorner(thumb,6)
                local function setState(v,silent)
                    state=v
                    if state then
                        Tw(track,TI.MED,{BackgroundColor3=Color3.fromRGB(46,46,46)})
                        Tw(fill,TI.MED,{Size=UDim2.new(1,0,1,0)})
                        Tw(thumb,TI.SPRING,{Position=UDim2.new(0,19,0.5,-6),BackgroundColor3=C.WHITE})
                        Tw(tLbl,TI.FAST,{TextColor3=C.T_PRI})
                        Tw(row,TI.FAST,{BackgroundColor3=Color3.fromRGB(30,30,30)})
                    else
                        Tw(track,TI.MED,{BackgroundColor3=C.ACC_OFF})
                        Tw(fill,TI.MED,{Size=UDim2.new(0,0,1,0)})
                        Tw(thumb,TI.SPRING,{Position=UDim2.new(0,3,0.5,-6),BackgroundColor3=C.T_DIM})
                        Tw(tLbl,TI.FAST,{TextColor3=C.T_SEC})
                        Tw(row,TI.FAST,{BackgroundColor3=C.ELEM})
                    end
                    if not silent and cb then task.spawn(cb,state) end
                end
                local function setBind(k,silent)
                    bound=k;binding=false;pill.Text=kn(k)
                    Tw(pill,TI.FAST,{TextColor3=C.T_SEC,BackgroundColor3=C.CARD})
                end
                pill.MouseButton1Click:Connect(function()
                    if binding then return end
                    binding=true;pill.Text="···"
                    Tw(pill,TI.FAST,{TextColor3=C.WHITE,BackgroundColor3=C.ELEM})
                    task.spawn(function()
                        while binding do
                            Tw(pill,TI.SINE,{TextTransparency=0.6});task.wait(0.33)
                            if not binding then break end
                            Tw(pill,TI.SINE,{TextTransparency=0});task.wait(0.33)
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
                local hit=MakeButton(row,{Size=UDim2.new(1,-112,1,0),ZIndex=8})
                hit.MouseButton1Click:Connect(function() setState(not state);Ripple(row) end)
                hit.MouseEnter:Connect(function()
                    if not state then Tw(row,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                hit.MouseLeave:Connect(function()
                    if not state then Tw(row,TI.FAST,{BackgroundColor3=C.ELEM}) end
                end)
                function obj:Set(v) setState(v,true) end
                function obj:SetKey(k) setBind(k,true) end
                function obj:Get() return state end
                function obj:GetKey() return bound end
                cfgSys:Register((text or "togbind")..#cfgSys.entries,obj.Get,function(v) obj:Set(v) end)
                return obj
            end

            function secObj:Slider(text, min, max, default, cb, step)
                local obj={}
                min=min or 0;max=max or 100;step=step or 1
                default=math.clamp(default or min,min,max)
                local val=default
                local wrap=ElemRow(50)
                wrap.Size=UDim2.new(1,0,0,50)
                MakePadding(wrap,8,8,12,12)
                local topRow=MakeFrame(wrap,{Size=UDim2.new(1,0,0,16),ZIndex=6})
                MakeLabel(topRow,{
                    Text=text or "Slider",TextSize=12,TextColor3=C.T_PRI,
                    Size=UDim2.new(0.65,0,1,0),ZIndex=7,
                })
                local valLbl=MakeLabel(topRow,{
                    TextSize=11,Font=Enum.Font.GothamBold,TextColor3=C.T_DIM,
                    TextXAlignment=Enum.TextXAlignment.Right,
                    Size=UDim2.new(0.35,0,1,0),Position=UDim2.new(0.65,0,0,0),ZIndex=7,
                })
                local trackBg=MakeFrame(wrap,{
                    Size=UDim2.new(1,0,0,4),Position=UDim2.new(0,0,1,-12),
                    BackgroundColor3=C.BORDER,BackgroundTransparency=0,ZIndex=6,
                })
                MakeCorner(trackBg,2)
                local fill=MakeFrame(trackBg,{
                    Size=UDim2.new(0,0,1,0),BackgroundColor3=C.WHITE,
                    BackgroundTransparency=0,ZIndex=7,
                })
                MakeCorner(fill,2)
                local thumb=MakeFrame(trackBg,{
                    Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,-7,0.5,-7),
                    BackgroundColor3=C.WHITE,BackgroundTransparency=0,ZIndex=9,
                })
                MakeCorner(thumb,7);MakeStroke(thumb,C.BORDER_LT,1)
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
                    Tw(fill, TI.FAST,{Size=UDim2.new(pct,0,1,0)})
                    Tw(thumb,TI.FAST,{Position=UDim2.new(pct,-7,0.5,-7)})
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
                local trackHit=MakeButton(wrap,{
                    Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,1,-20),ZIndex=10,
                })
                trackHit.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1
                    or i.UserInputType==Enum.UserInputType.Touch then
                        dragging=true
                        local pct=(val-min)/(max-min)
                        Tw(thumb,TI.FAST,{Size=UDim2.new(0,18,0,18),Position=UDim2.new(pct,-9,0.5,-9)})
                        Tw(wrap,TI.FAST,{BackgroundColor3=C.HOVER})
                        fromInput(i)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if not dragging then return end
                    if i.UserInputType~=Enum.UserInputType.MouseButton1
                    and i.UserInputType~=Enum.UserInputType.Touch then return end
                    dragging=false
                    local pct=(val-min)/(max-min)
                    Tw(thumb,TI.SPRING,{Size=UDim2.new(0,14,0,14),Position=UDim2.new(pct,-7,0.5,-7)})
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

            function secObj:Dropdown(text, opts, cb)
                local obj={};local sel=nil;local open=false
                opts=opts or {}
                local ITEM_H=ROW_H-4
                local ddWrap=MakeFrame(elems,{
                    Size=UDim2.new(1,0,0,ROW_H),BackgroundColor3=C.ELEM,
                    BackgroundTransparency=0,ZIndex=10,
                })
                ddWrap.ClipsDescendants=false
                MakeCorner(ddWrap,7);MakeStroke(ddWrap,C.BORDER,1)
                local ddHdr=MakeButton(ddWrap,{Size=UDim2.new(1,0,0,ROW_H),ZIndex=11})
                MakeLabel(ddHdr,{
                    Text=text or "Dropdown",TextSize=12,TextColor3=C.T_SEC,
                    Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0,12,0,0),ZIndex=12,
                })
                local selLbl=MakeLabel(ddHdr,{
                    Text="None",TextSize=12,Font=Enum.Font.GothamBold,TextColor3=C.T_PRI,
                    TextXAlignment=Enum.TextXAlignment.Right,
                    Size=UDim2.new(0.42,0,1,0),Position=UDim2.new(0.5,0,0,0),ZIndex=12,
                })
                local chev=MakeLabel(ddHdr,{
                    Text="⌄",TextSize=13,Font=Enum.Font.GothamBold,TextColor3=C.T_DIM,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-22,0,0),ZIndex=12,
                })
                local ddPanel=MakeScrollFrame(ddWrap,{
                    Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,ROW_H+4),
                    ScrollBarThickness=2,ZIndex=20,
                })
                ddPanel.ScrollBarImageColor3=C.BORDER_LT
                ddPanel.Visible=false
                ddPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y
                MakeCorner(ddPanel,7);MakeStroke(ddPanel,C.BORDER,1)
                local ddInner=MakeFrame(ddPanel,{Size=UDim2.new(1,0,0,0),ZIndex=21})
                ddInner.AutomaticSize=Enum.AutomaticSize.Y
                MakePadding(ddInner,4,4,5,5)
                MakeList(ddInner,Enum.FillDirection.Vertical,2)
                local function buildOpts()
                    ddInner:ClearAllChildren()
                    MakePadding(ddInner,4,4,5,5)
                    MakeList(ddInner,Enum.FillDirection.Vertical,2)
                    for _,opt in ipairs(opts) do
                        local isSel=(opt==sel)
                        local ob=MakeButton(ddInner,{
                            Text=tostring(opt),TextSize=12,
                            Font=isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                            TextColor3=isSel and C.T_PRI or C.T_SEC,
                            BackgroundColor3=isSel and C.ELEM or C.CARD,
                            BackgroundTransparency=0,TextXAlignment=Enum.TextXAlignment.Left,
                            Size=UDim2.new(1,0,0,ITEM_H),ZIndex=22,
                        })
                        MakePadding(ob,0,0,8,0);MakeCorner(ob,5)
                        if isSel then
                            MakeLabel(ob,{
                                Text="✓",TextSize=10,Font=Enum.Font.GothamBold,
                                TextColor3=C.WHITE,TextXAlignment=Enum.TextXAlignment.Center,
                                Size=UDim2.new(0,16,1,0),Position=UDim2.new(1,-18,0,0),ZIndex=23,
                            })
                        end
                        ob.MouseEnter:Connect(function()
                            if not isSel then Tw(ob,TI.FAST,{BackgroundColor3=C.HOVER}) end
                        end)
                        ob.MouseLeave:Connect(function()
                            if not isSel then Tw(ob,TI.FAST,{BackgroundColor3=C.CARD}) end
                        end)
                        ob.MouseButton1Click:Connect(function()
                            sel=opt;selLbl.Text=tostring(opt);buildOpts()
                            if cb then task.spawn(cb,opt) end
                        end)
                    end
                end
                buildOpts()
                local function toggleDD()
                    open=not open
                    if open then
                        local h=math.min(#opts,5)*(ITEM_H+2)+8
                        ddPanel.Visible=true
                        Tw(ddPanel,TI.MED,{Size=UDim2.new(1,0,0,h)})
                        Tw(chev,TI.MED,{Rotation=180})
                        Tw(ddWrap,TI.FAST,{BackgroundColor3=C.HOVER})
                    else
                        Tw(ddPanel,TI.MED,{Size=UDim2.new(1,0,0,0)})
                        Tw(chev,TI.MED,{Rotation=0})
                        Tw(ddWrap,TI.FAST,{BackgroundColor3=C.ELEM})
                        task.delay(0.22,function()
                            if not open then ddPanel.Visible=false end
                        end)
                    end
                end
                ddHdr.MouseButton1Click:Connect(function() toggleDD();Ripple(ddWrap) end)
                ddHdr.MouseEnter:Connect(function()
                    if not open then Tw(ddWrap,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                ddHdr.MouseLeave:Connect(function()
                    if not open then Tw(ddWrap,TI.FAST,{BackgroundColor3=C.ELEM}) end
                end)
                function obj:Set(v) sel=v;selLbl.Text=tostring(v);buildOpts() end
                function obj:Refresh(o,del)
                    opts=o or {};if del then sel=nil;selLbl.Text="None" end;buildOpts()
                end
                function obj:Get() return sel end
                cfgSys:Register((text or "dd")..#cfgSys.entries,obj.Get,function(v) obj:Set(v) end)
                return obj
            end

            function secObj:MultiDropdown(text, opts, cb)
                local obj={};local selected={};local open=false
                opts=opts or {}
                local ITEM_H=ROW_H-4
                local ddWrap=MakeFrame(elems,{
                    Size=UDim2.new(1,0,0,ROW_H),BackgroundColor3=C.ELEM,
                    BackgroundTransparency=0,ZIndex=10,
                })
                ddWrap.ClipsDescendants=false
                MakeCorner(ddWrap,7);MakeStroke(ddWrap,C.BORDER,1)
                local ddHdr=MakeButton(ddWrap,{Size=UDim2.new(1,0,0,ROW_H),ZIndex=11})
                MakeLabel(ddHdr,{
                    Text="▣ "..(text or "Multi Select"),TextSize=12,TextColor3=C.T_SEC,
                    Size=UDim2.new(0.55,0,1,0),Position=UDim2.new(0,12,0,0),ZIndex=12,
                })
                local countLbl=MakeLabel(ddHdr,{
                    Text="None",TextSize=11,Font=Enum.Font.GothamBold,TextColor3=C.T_DIM,
                    TextXAlignment=Enum.TextXAlignment.Right,
                    Size=UDim2.new(0.38,0,1,0),Position=UDim2.new(0.55,0,0,0),ZIndex=12,
                })
                local chev=MakeLabel(ddHdr,{
                    Text="⌄",TextSize=13,Font=Enum.Font.GothamBold,TextColor3=C.T_DIM,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-22,0,0),ZIndex=12,
                })
                local ddPanel=MakeScrollFrame(ddWrap,{
                    Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,ROW_H+4),
                    ScrollBarThickness=2,ZIndex=20,
                })
                ddPanel.ScrollBarImageColor3=C.BORDER_LT
                ddPanel.Visible=false
                ddPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y
                MakeCorner(ddPanel,7);MakeStroke(ddPanel,C.BORDER,1)
                local ddInner=MakeFrame(ddPanel,{Size=UDim2.new(1,0,0,0),ZIndex=21})
                ddInner.AutomaticSize=Enum.AutomaticSize.Y
                MakePadding(ddInner,4,4,5,5)
                MakeList(ddInner,Enum.FillDirection.Vertical,2)
                local function updateCount()
                    local n=0;for _ in pairs(selected) do n=n+1 end
                    countLbl.Text=n==0 and "None" or (n.." sel")
                end
                local function buildOpts()
                    ddInner:ClearAllChildren()
                    MakePadding(ddInner,4,4,5,5)
                    MakeList(ddInner,Enum.FillDirection.Vertical,2)
                    for _,opt in ipairs(opts) do
                        local isSel=selected[opt]==true
                        local ob=MakeButton(ddInner,{
                            BackgroundColor3=isSel and C.ELEM or C.CARD,
                            BackgroundTransparency=0,Size=UDim2.new(1,0,0,ITEM_H),ZIndex=22,
                        })
                        MakeCorner(ob,5)
                        local chkBox=MakeFrame(ob,{
                            Size=UDim2.new(0,13,0,13),Position=UDim2.new(0,6,0.5,-6.5),
                            BackgroundColor3=isSel and C.WHITE or C.BORDER,
                            BackgroundTransparency=0,ZIndex=23,
                        })
                        MakeCorner(chkBox,3)
                        if isSel then
                            MakeLabel(chkBox,{
                                Text="✓",TextSize=9,Font=Enum.Font.GothamBold,
                                TextColor3=C.BLACK,TextXAlignment=Enum.TextXAlignment.Center,
                                Size=UDim2.new(1,0,1,0),ZIndex=24,
                            })
                        end
                        MakeLabel(ob,{
                            Text=tostring(opt),TextSize=12,
                            Font=isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                            TextColor3=isSel and C.T_PRI or C.T_SEC,
                            Size=UDim2.new(1,-28,1,0),Position=UDim2.new(0,26,0,0),ZIndex=23,
                        })
                        ob.MouseEnter:Connect(function()
                            Tw(ob,TI.FAST,{BackgroundColor3=C.HOVER})
                        end)
                        ob.MouseLeave:Connect(function()
                            Tw(ob,TI.FAST,{BackgroundColor3=isSel and C.ELEM or C.CARD})
                        end)
                        ob.MouseButton1Click:Connect(function()
                            if selected[opt] then selected[opt]=nil else selected[opt]=true end
                            updateCount();buildOpts()
                            local arr={};for k in pairs(selected) do table.insert(arr,k) end
                            if cb then task.spawn(cb,arr) end
                        end)
                    end
                end
                buildOpts()
                local function toggleDD()
                    open=not open
                    if open then
                        local h=math.min(#opts,5)*(ITEM_H+2)+8
                        ddPanel.Visible=true
                        Tw(ddPanel,TI.MED,{Size=UDim2.new(1,0,0,h)})
                        Tw(chev,TI.MED,{Rotation=180})
                        Tw(ddWrap,TI.FAST,{BackgroundColor3=C.HOVER})
                    else
                        Tw(ddPanel,TI.MED,{Size=UDim2.new(1,0,0,0)})
                        Tw(chev,TI.MED,{Rotation=0})
                        Tw(ddWrap,TI.FAST,{BackgroundColor3=C.ELEM})
                        task.delay(0.22,function()
                            if not open then ddPanel.Visible=false end
                        end)
                    end
                end
                ddHdr.MouseButton1Click:Connect(function() toggleDD();Ripple(ddWrap) end)
                ddHdr.MouseEnter:Connect(function()
                    if not open then Tw(ddWrap,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                ddHdr.MouseLeave:Connect(function()
                    if not open then Tw(ddWrap,TI.FAST,{BackgroundColor3=C.ELEM}) end
                end)
                function obj:Set(arr)
                    selected={}
                    if type(arr)=="table" then for _,v in ipairs(arr) do selected[v]=true end end
                    updateCount();buildOpts()
                end
                function obj:Get()
                    local arr={};for k in pairs(selected) do table.insert(arr,k) end;return arr
                end
                function obj:Refresh(o,reset)
                    opts=o or {};if reset then selected={} end;updateCount();buildOpts()
                end
                return obj
            end

            function secObj:Bind(text, default, cb)
                local obj={};local bound=default;local binding=false
                local row=ElemRow(ROW_H)
                MakeLabel(row,{
                    Text=text or "Bind",TextSize=12,TextColor3=C.T_SEC,
                    Size=UDim2.new(0.55,0,1,0),Position=UDim2.new(0,12,0,0),ZIndex=6,
                })
                local function kn(k)
                    if not k then return "—" end
                    return tostring(k):gsub("Enum.KeyCode.","")
                end
                local pill=MakeButton(row,{
                    Text=kn(bound),TextSize=10,Font=Enum.Font.GothamBold,
                    TextColor3=C.T_SEC,BackgroundColor3=C.CARD,BackgroundTransparency=0,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(0,66,0,20),Position=UDim2.new(1,-76,0.5,-10),ZIndex=6,
                })
                MakeCorner(pill,5);MakeStroke(pill,C.BORDER,1)
                local function setBind(k,silent)
                    bound=k;binding=false;pill.Text=kn(k)
                    Tw(pill,TI.FAST,{TextColor3=C.T_SEC,BackgroundColor3=C.CARD})
                    if not silent and cb then task.spawn(cb,k) end
                end
                pill.MouseButton1Click:Connect(function()
                    if binding then return end
                    binding=true;pill.Text="···"
                    Tw(pill,TI.FAST,{TextColor3=C.WHITE,BackgroundColor3=C.ELEM})
                    task.spawn(function()
                        while binding do
                            Tw(pill,TI.SINE,{TextTransparency=0.6});task.wait(0.33)
                            if not binding then break end
                            Tw(pill,TI.SINE,{TextTransparency=0});task.wait(0.33)
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

            return secObj
        end -- Section

        return tabObj
    end -- Tab

    return winObj
end -- Window

return AlterLib
