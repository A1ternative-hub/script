--[[
    A L T E R  UI Library — v4
    Fixed: Section scaling, ripple size, shadows removed,
    Added: TextLabel, MultiDropdown, ToggleBind, 0.1 Sliders,
           Config system with name/save/load/delete/autoload,
           Mobile support improvements
--]]

local AlterLib = {}
AlterLib.__index = AlterLib

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TS       = game:GetService("TweenService")
local RS       = game:GetService("RunService")
local CoreGui  = game:GetService("CoreGui")
local HTTP     = game:GetService("HttpService")
local LP       = Players.LocalPlayer

--> Palette
local C = {
    BG        = Color3.fromRGB(11,  11,  11),
    PANEL     = Color3.fromRGB(17,  17,  17),
    CARD      = Color3.fromRGB(21,  21,  21),
    ELEM      = Color3.fromRGB(27,  27,  27),
    HOVER     = Color3.fromRGB(34,  34,  34),
    ACTIVE    = Color3.fromRGB(44,  44,  44),
    BORDER    = Color3.fromRGB(40,  40,  40),
    BORDER_LT = Color3.fromRGB(55,  55,  55),
    WHITE     = Color3.fromRGB(255, 255, 255),
    BLACK     = Color3.fromRGB(0,   0,   0),
    T_PRI     = Color3.fromRGB(228, 228, 228),
    T_SEC     = Color3.fromRGB(105, 105, 105),
    T_DIM     = Color3.fromRGB(52,  52,  52),
    ACC_OFF   = Color3.fromRGB(36,  36,  36),
}

--> TweenInfos — only valid EasingStyles
local TI = {
    SNAP   = TweenInfo.new(0.04, Enum.EasingStyle.Linear,   Enum.EasingDirection.Out),
    FAST   = TweenInfo.new(0.12, Enum.EasingStyle.Quad,     Enum.EasingDirection.Out),
    MED    = TweenInfo.new(0.20, Enum.EasingStyle.Quad,     Enum.EasingDirection.Out),
    SLOW   = TweenInfo.new(0.32, Enum.EasingStyle.Quad,     Enum.EasingDirection.Out),
    SPRING = TweenInfo.new(0.42, Enum.EasingStyle.Back,     Enum.EasingDirection.Out),
    SINE   = TweenInfo.new(0.26, Enum.EasingStyle.Sine,     Enum.EasingDirection.InOut),
    CIRC   = TweenInfo.new(0.35, Enum.EasingStyle.Circular, Enum.EasingDirection.Out),
}

--> Safe whitelist — only tweenable GUI properties
local SAFE = {
    BackgroundColor3       = true, BackgroundTransparency = true,
    Position               = true, Size                   = true,
    Rotation               = true, TextColor3             = true,
    TextTransparency       = true, ImageColor3            = true,
    ImageTransparency      = true, CanvasPosition         = true,
    Color                  = true, Thickness              = true,
}

local function Tw(obj, ti, props)
    if not obj or not obj.Parent then return end
    local p = {}
    for k, v in pairs(props) do
        if SAFE[k] then p[k] = v end
    end
    if not next(p) then return end
    pcall(function() TS:Create(obj, ti, p):Play() end)
end

--> Helpers
local function Corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
    return c
end

local function Stroke(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or C.BORDER
    s.Thickness = th or 1
    s.Parent = p
    return s
end

local function Pad(p, t, b, l, r)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
    u.PaddingLeft   = UDim.new(0, l or 0)
    u.PaddingRight  = UDim.new(0, r or 0)
    u.Parent = p
    return u
end

local function VList(p, gap)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = Enum.FillDirection.Vertical
    l.Padding             = UDim.new(0, gap or 0)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = Enum.VerticalAlignment.Top
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Parent = p
    return l
end

local function HList(p, gap)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = Enum.FillDirection.Horizontal
    l.Padding             = UDim.new(0, gap or 0)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = Enum.VerticalAlignment.Center
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Parent = p
    return l
end

local function Frame(props)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    for k, v in pairs(props or {}) do pcall(function() f[k] = v end) end
    return f
end

local function Lbl(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 12
    l.TextColor3 = C.T_PRI
    for k, v in pairs(props or {}) do pcall(function() l[k] = v end) end
    return l
end

local function Btn(props)
    local b = Instance.new("TextButton")
    b.BackgroundTransparency = 1
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Text = ""
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.TextColor3 = C.T_PRI
    for k, v in pairs(props or {}) do pcall(function() b[k] = v end) end
    return b
end

--> Ripple — small, clipped, proportional
local function Ripple(host)
    if not host or not host.Parent then return end
    local mp = UIS:GetMouseLocation()
    local ok1, ap = pcall(function() return host.AbsolutePosition end)
    local ok2, as = pcall(function() return host.AbsoluteSize end)
    if not ok1 or not ok2 then return end

    -- clamp ripple max size to the element itself
    local sz = math.min(math.max(as.X, as.Y), 80)
    local lx = math.clamp(mp.X - ap.X, 0, as.X)
    local ly = math.clamp(mp.Y - ap.Y, 0, as.Y)

    local old = host.ClipsDescendants
    host.ClipsDescendants = true

    local r = Instance.new("Frame")
    r.Size = UDim2.new(0, 0, 0, 0)
    r.Position = UDim2.new(0, lx, 0, ly)
    r.AnchorPoint = Vector2.new(0.5, 0.5)
    r.BackgroundColor3 = C.WHITE
    r.BackgroundTransparency = 0.82
    r.ZIndex = host.ZIndex + 5
    r.BorderSizePixel = 0
    r.Parent = host
    Corner(r, 9999)

    Tw(r, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, sz, 0, sz),
        BackgroundTransparency = 1,
    })
    task.delay(0.4, function()
        if r and r.Parent then r:Destroy() end
        host.ClipsDescendants = old
    end)
end

--> Drag — pure delta, no momentum
local function MakeDraggable(handle, target)
    local down = false
    local sm = Vector2.new()
    local sp = Vector2.new()

    local function beginDrag(pos)
        down = true
        sm = Vector2.new(pos.X, pos.Y)
        sp = Vector2.new(target.Position.X.Offset, target.Position.Y.Offset)
    end

    local function moveDrag(pos)
        if not down then return end
        local d  = Vector2.new(pos.X, pos.Y) - sm
        local sg = target.Parent
        local mX = sg and math.max(0, sg.AbsoluteSize.X - target.AbsoluteSize.X) or 4000
        local mY = sg and math.max(0, sg.AbsoluteSize.Y - target.AbsoluteSize.Y) or 4000
        target.Position = UDim2.new(0, math.clamp(sp.X + d.X, 0, mX),
                                     0, math.clamp(sp.Y + d.Y, 0, mY))
    end

    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            beginDrag(i.Position)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            moveDrag(i.Position)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            down = false
        end
    end)
end

--> ScreenGui
local function MakeSG(name)
    local id = "ALTER4_" .. name
    pcall(function()
        local e = CoreGui:FindFirstChild(id)
        if e then e:Destroy() end
    end)
    local sg
    pcall(function()
        sg = Instance.new("ScreenGui")
        sg.Name = id
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.IgnoreGuiInset = true
        sg.DisplayOrder = 999
        sg.Parent = CoreGui
    end)
    if not sg or not sg.Parent then
        sg = Instance.new("ScreenGui")
        sg.Name = id
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.IgnoreGuiInset = true
        sg.Parent = LP:WaitForChild("PlayerGui")
    end
    return sg
end

-->════════════════════════════════════════════
-->  CONFIG SYSTEM
-->════════════════════════════════════════════
local Config = {}
Config.__index = Config

function Config.new(folder)
    local s = setmetatable({}, Config)
    s.folder  = folder or "AlterHub"
    s.entries = {}
    pcall(function()
        if not isfolder(s.folder) then makefolder(s.folder) end
    end)
    return s
end

function Config:Register(key, get, set)
    for _, e in ipairs(self.entries) do
        if e.key == key then e.get = get; e.set = set; return end
    end
    table.insert(self.entries, {key=key, get=get, set=set})
end

function Config:Save(name)
    if not name or name == "" then return false, "No name" end
    local data = {}
    for _, e in ipairs(self.entries) do
        local ok, v = pcall(e.get)
        if ok then data[e.key] = v end
    end
    local ok, json = pcall(function() return HTTP:JSONEncode(data) end)
    if not ok then return false, "Encode error" end
    local path = self.folder .. "/" .. name .. ".json"
    local wok, werr = pcall(function() writefile(path, json) end)
    return wok, werr
end

function Config:Load(name)
    local path = self.folder .. "/" .. name .. ".json"
    local ok, raw = pcall(function() return readfile(path) end)
    if not ok or not raw then return false end
    local ok2, data = pcall(function() return HTTP:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return false end
    for _, e in ipairs(self.entries) do
        if data[e.key] ~= nil then
            pcall(e.set, data[e.key])
        end
    end
    return true
end

function Config:Delete(name)
    local path = self.folder .. "/" .. name .. ".json"
    local ok, err = pcall(function() delfile(path) end)
    return ok
end

function Config:List()
    local out = {}
    pcall(function()
        for _, f in ipairs(listfiles(self.folder)) do
            local n = f:match("[/\\]([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end)
    return out
end

function Config:AutoLoadByPlaceId(map)
    -- map = { ["placeId"] = "configName" }
    task.delay(1.5, function()
        local pid = tostring(game.PlaceId)
        local name = map and map[pid]
        if name and self:Load(name) then
            print("[Alter] AutoLoad PlaceId", pid, "→", name)
        else
            self:Load("default")
        end
    end)
end

function Config:AutoLoadByGameId(map)
    -- map = { ["gameId/universeId"] = "configName" }
    task.delay(1.5, function()
        local gid = tostring(game.GameId)
        local name = map and map[gid]
        if name and self:Load(name) then
            print("[Alter] AutoLoad GameId", gid, "→", name)
        else
            self:Load("default")
        end
    end)
end

-->════════════════════════════════════════════
-->  NOTIFICATIONS
-->════════════════════════════════════════════
local _nSG, _nFrame

local function EnsureNotif()
    if _nSG and _nSG.Parent then return end
    _nSG = MakeSG("NOTIF")
    _nFrame = Frame({
        Size     = UDim2.new(0, 270, 1, -20),
        Position = UDim2.new(1, -282, 0, 10),
        ZIndex   = 200,
        Parent   = _nSG,
    })
    local ll = Instance.new("UIListLayout")
    ll.FillDirection       = Enum.FillDirection.Vertical
    ll.VerticalAlignment   = Enum.VerticalAlignment.Bottom
    ll.HorizontalAlignment = Enum.HorizontalAlignment.Left
    ll.Padding  = UDim.new(0, 6)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = _nFrame
end

function AlterLib:Notify(cfg)
    EnsureNotif()
    cfg = cfg or {}

    local card = Frame({
        Size             = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = C.PANEL,
        BackgroundTransparency = 0,
        ZIndex           = 201,
        Parent           = _nFrame,
    })
    Corner(card, 8)
    Stroke(card, C.BORDER, 1)

    local bar = Frame({
        Size             = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = C.WHITE,
        BackgroundTransparency = 0,
        ZIndex           = 203,
        Parent           = card,
    })
    Corner(bar, 1)

    Lbl({
        Text       = cfg.Title or "Alter",
        TextSize   = 13,
        Font       = Enum.Font.GothamBold,
        TextColor3 = C.T_PRI,
        Size       = UDim2.new(1, -14, 0, 20),
        Position   = UDim2.new(0, 10, 0, 9),
        ZIndex     = 202,
        Parent     = card,
    })
    Lbl({
        Text        = cfg.Message or "",
        TextSize    = 11,
        TextColor3  = C.T_SEC,
        Size        = UDim2.new(1, -14, 0, 24),
        Position    = UDim2.new(0, 10, 0, 30),
        TextWrapped = true,
        ZIndex      = 202,
        Parent      = card,
    })

    card.Position = UDim2.new(1, 10, 1, 0)
    Tw(card, TI.SPRING, {Position = UDim2.new(0, 0, 1, 0)})
    task.delay(0.05, function()
        Tw(bar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(1, 0, 0, 2)})
    end)

    task.delay(cfg.Duration or 3.5, function()
        Tw(card, TI.MED, {
            Position = UDim2.new(1, 10, 1, 0),
            BackgroundTransparency = 1,
        })
        task.delay(0.25, function()
            if card and card.Parent then card:Destroy() end
        end)
    end)
end

-->════════════════════════════════════════════
-->  PROMPT
-->════════════════════════════════════════════
function AlterLib:Prompt(cfg)
    cfg = cfg or {}
    local sg = MakeSG("PROMPT")

    local bg = Frame({
        Size             = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.BLACK,
        BackgroundTransparency = 1,
        ZIndex           = 100,
        Parent           = sg,
    })
    Tw(bg, TI.MED, {BackgroundTransparency = 0.55})

    local card = Frame({
        Size             = UDim2.new(0, 350, 0, 0),
        Position         = UDim2.fromScale(0.5, 0.5),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.PANEL,
        BackgroundTransparency = 0,
        ZIndex           = 101,
        Parent           = bg,
    })
    card.ClipsDescendants = true
    Corner(card, 9)
    Stroke(card, C.BORDER_LT, 1)

    local topBar = Frame({
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = C.WHITE,
        BackgroundTransparency = 0,
        ZIndex           = 105,
        Parent           = card,
    })

    local hdr = Frame({
        Size             = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = C.CARD,
        BackgroundTransparency = 0,
        ZIndex           = 102,
        Parent           = card,
    })
    Corner(hdr, 9)
    local hdrSq = Frame({
        Size             = UDim2.new(1, 0, 0.5, 0),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = C.CARD,
        BackgroundTransparency = 0,
        ZIndex           = 102,
        Parent           = hdr,
    })
    Lbl({
        Text       = cfg.Title or "Confirm",
        TextSize   = 13,
        Font       = Enum.Font.GothamBold,
        TextColor3 = C.T_PRI,
        Size       = UDim2.new(1, -20, 1, 0),
        Position   = UDim2.new(0, 16, 0, 0),
        ZIndex     = 103,
        Parent     = hdr,
    })

    Lbl({
        Text        = cfg.Message or "",
        TextSize    = 12,
        TextColor3  = C.T_SEC,
        Size        = UDim2.new(1, -32, 0, 40),
        Position    = UDim2.new(0, 16, 0, 54),
        TextWrapped = true,
        ZIndex      = 103,
        Parent      = card,
    })

    local bRow = Frame({
        Size     = UDim2.new(1, -32, 0, 34),
        Position = UDim2.new(0, 16, 0, 104),
        ZIndex   = 102,
        Parent   = card,
    })
    HList(bRow, 8)

    local function closePrompt(cb)
        Tw(card, TI.MED, {Size = UDim2.new(0, 350, 0, 0)})
        Tw(bg,   TI.MED, {BackgroundTransparency = 1})
        task.delay(0.25, function()
            if cb then pcall(cb) end
            if sg and sg.Parent then sg:Destroy() end
        end)
    end

    local function PBtn(txt, primary, cb)
        local b = Btn({
            Text             = txt,
            TextSize         = 12,
            Font             = Enum.Font.GothamBold,
            TextColor3       = primary and C.BLACK or C.T_SEC,
            BackgroundColor3 = primary and C.WHITE  or C.ELEM,
            BackgroundTransparency = 0,
            Size             = UDim2.new(0.5, -4, 1, 0),
            ZIndex           = 103,
            Parent           = bRow,
        })
        Corner(b, 7)
        if not primary then Stroke(b, C.BORDER, 1) end
        b.MouseButton1Click:Connect(function() closePrompt(cb) end)
        b.MouseEnter:Connect(function()
            Tw(b, TI.FAST, {BackgroundColor3 = primary and Color3.fromRGB(210,210,210) or C.HOVER})
        end)
        b.MouseLeave:Connect(function()
            Tw(b, TI.FAST, {BackgroundColor3 = primary and C.WHITE or C.ELEM})
        end)
        b.MouseButton1Down:Connect(function() Ripple(b) end)
    end

    PBtn(cfg.NoText  or "Cancel",  false, cfg.No)
    PBtn(cfg.YesText or "Confirm", true,  cfg.Yes)

    bg.MouseButton1Click:Connect(function() closePrompt() end)
    Tw(card, TI.SPRING, {Size = UDim2.new(0, 350, 0, 148)})
end

-->════════════════════════════════════════════
-->  WINDOW
-->════════════════════════════════════════════
function AlterLib:Window(cfg)
    cfg = cfg or {}
    local WIN_W  = 620
    local WIN_H  = 540
    local SIDE_W = 148
    local IS_MOB = UIS.TouchEnabled and not UIS.KeyboardEnabled

    -- mobile: full screen ish
    if IS_MOB then
        WIN_W = math.min(workspace.CurrentCamera.ViewportSize.X - 20, 500)
        WIN_H = math.min(workspace.CurrentCamera.ViewportSize.Y - 20, 620)
        SIDE_W = 110
    end

    local sg  = MakeSG(cfg.Folder or "WIN")
    local cfg_ = Config.new(cfg.Folder or "AlterHub")

    -- root
    local root = Frame({
        Size             = UDim2.new(0, WIN_W, 0, 0),
        Position         = UDim2.new(0, IS_MOB and 10 or 80, 0, IS_MOB and 10 or 60),
        BackgroundColor3 = C.BG,
        BackgroundTransparency = 1,
        ZIndex           = 1,
        Parent           = sg,
    })
    root.ClipsDescendants = false
    Corner(root, 10)
    Stroke(root, C.BORDER, 1)

    -- title bar
    local titleBar = Frame({
        Size             = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = C.PANEL,
        BackgroundTransparency = 0,
        ZIndex           = 4,
        Parent           = root,
    })
    Corner(titleBar, 10)
    Frame({  -- square bottom half
        Size             = UDim2.new(1, 0, 0.5, 0),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = C.PANEL,
        BackgroundTransparency = 0,
        ZIndex           = 4,
        Parent           = titleBar,
    })

    -- animated accent
    local accent = Frame({
        Size             = UDim2.new(0, 0, 0, 1),
        BackgroundColor3 = C.WHITE,
        BackgroundTransparency = 0,
        ZIndex           = 6,
        Parent           = titleBar,
    })
    Corner(accent, 1)

    local hubLbl = Lbl({
        Text         = cfg.Name or "Alter",
        TextSize     = 14,
        Font         = Enum.Font.GothamBlack,
        TextColor3   = C.T_PRI,
        TextTransparency = 1,
        Size         = UDim2.new(0.5, 0, 0, 28),
        Position     = UDim2.new(0, 16, 0.5, -14),
        ZIndex       = 5,
        RichText     = true,
        Parent       = titleBar,
    })
    local subLbl = Lbl({
        Text         = cfg.SubName or ("PlaceId: "..game.PlaceId),
        TextSize     = 9,
        Font         = Enum.Font.Gotham,
        TextColor3   = C.T_DIM,
        Size         = UDim2.new(0.5, 0, 0, 12),
        Position     = UDim2.new(0, 16, 1, -14),
        ZIndex       = 5,
        Parent       = titleBar,
    })

    -- ctrl buttons
    local ctrlF = Frame({
        Size     = UDim2.new(0, 58, 0, 22),
        Position = UDim2.new(1, -66, 0.5, -11),
        ZIndex   = 5,
        Parent   = titleBar,
    })
    HList(ctrlF, 6)

    local minimised = false
    local bodyFrame

    local function CBtn(sym, action)
        local b = Btn({
            Text             = sym,
            TextSize         = 13,
            Font             = Enum.Font.GothamBold,
            TextColor3       = C.T_DIM,
            BackgroundColor3 = C.ELEM,
            BackgroundTransparency = 0,
            Size             = UDim2.new(0, 26, 0, 22),
            ZIndex           = 6,
            Parent           = ctrlF,
        })
        Corner(b, 5)
        Stroke(b, C.BORDER, 1)
        b.MouseButton1Click:Connect(function() Ripple(b); action() end)
        b.MouseEnter:Connect(function() Tw(b, TI.FAST, {BackgroundColor3=C.HOVER, TextColor3=C.T_PRI}) end)
        b.MouseLeave:Connect(function() Tw(b, TI.FAST, {BackgroundColor3=C.ELEM,  TextColor3=C.T_DIM}) end)
        b.MouseButton1Down:Connect(function() Tw(b, TI.SNAP, {BackgroundColor3=C.ACTIVE}) end)
        return b
    end

    CBtn("−", function()
        minimised = not minimised
        Tw(root, TI.MED, {
            Size = minimised
                and UDim2.new(0, WIN_W, 0, 46)
                or  UDim2.new(0, WIN_W, 0, WIN_H)
        })
    end)
    CBtn("×", function()
        Tw(root, TI.MED, {Size=UDim2.new(0,WIN_W,0,0), BackgroundTransparency=1})
        task.delay(0.25, function() if sg and sg.Parent then sg:Destroy() end end)
    end)

    MakeDraggable(titleBar, root)

    -- body
    bodyFrame = Frame({
        Size             = UDim2.new(1, 0, 1, -46),
        Position         = UDim2.new(0, 0, 0, 46),
        BackgroundTransparency = 1,
        ZIndex           = 2,
        Parent           = root,
    })
    bodyFrame.ClipsDescendants = true

    -- sidebar
    local sidebar = Frame({
        Size             = UDim2.new(0, SIDE_W, 1, 0),
        BackgroundColor3 = C.PANEL,
        BackgroundTransparency = 0,
        ZIndex           = 3,
        Parent           = bodyFrame,
    })
    sidebar.ClipsDescendants = false
    Corner(sidebar, 10)
    Frame({  -- square right side
        Size             = UDim2.new(0, 10, 1, 0),
        Position         = UDim2.new(1, -10, 0, 0),
        BackgroundColor3 = C.PANEL,
        BackgroundTransparency = 0,
        ZIndex           = 3,
        Parent           = sidebar,
    })
    Frame({  -- square top
        Size             = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = C.PANEL,
        BackgroundTransparency = 0,
        ZIndex           = 3,
        Parent           = sidebar,
    })
    Frame({  -- right separator
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.BORDER,
        BackgroundTransparency = 0,
        ZIndex           = 4,
        Parent           = sidebar,
    })

    local brandLbl = Lbl({
        Text             = "ALTER",
        TextSize         = 10,
        Font             = Enum.Font.GothamBlack,
        TextColor3       = C.T_DIM,
        TextTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 46),
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = 4,
        Parent           = sidebar,
    })
    Frame({  -- divider
        Size             = UDim2.new(1, -20, 0, 1),
        Position         = UDim2.new(0, 10, 0, 45),
        BackgroundColor3 = C.BORDER,
        BackgroundTransparency = 0,
        ZIndex           = 4,
        Parent           = sidebar,
    })

    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Size = UDim2.new(1, 0, 1, -54)
    tabScroll.Position = UDim2.new(0, 0, 0, 52)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 0
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.ZIndex = 4
    tabScroll.ClipsDescendants = true
    tabScroll.Parent = sidebar
    Pad(tabScroll, 4, 4, 6, 6)
    local tabLL = VList(tabScroll, 3)
    tabLL.Changed:Connect(function()
        tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabLL.AbsoluteContentSize.Y + 8)
    end)

    -- content
    local content = Frame({
        Size             = UDim2.new(1, -SIDE_W, 1, 0),
        Position         = UDim2.new(0, SIDE_W, 0, 0),
        BackgroundTransparency = 1,
        ZIndex           = 2,
        Parent           = bodyFrame,
    })
    content.ClipsDescendants = true

    -- open anim
    task.defer(function()
        Tw(root, TI.SPRING, {Size=UDim2.new(0,WIN_W,0,WIN_H), BackgroundTransparency=0})
        task.delay(0.18, function()
            Tw(accent,   TweenInfo.new(0.55,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {Size=UDim2.new(1,0,0,1)})
            Tw(hubLbl,   TI.SLOW,   {TextTransparency=0})
            Tw(brandLbl, TI.SLOW,   {TextTransparency=0})
        end)
    end)

    local winObj = {_tabs={}, Config=cfg_}

    -->════════════════════════════════════════
    --> :Tab()
    -->════════════════════════════════════════
    function winObj:Tab(name)
        local tabObj = {_name=name}

        local btn = Btn({
            Size             = UDim2.new(1, 0, 0, IS_MOB and 40 or 34),
            BackgroundColor3 = C.ELEM,
            BackgroundTransparency = 1,
            ZIndex           = 5,
            Parent           = tabScroll,
        })
        Corner(btn, 6)

        local ind = Frame({
            Size             = UDim2.new(0, 2, 0, 0),
            Position         = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint      = Vector2.new(0, 0.5),
            BackgroundColor3 = C.WHITE,
            BackgroundTransparency = 0,
            ZIndex           = 6,
            Parent           = btn,
        })
        Corner(ind, 1)

        local dot = Frame({
            Size             = UDim2.new(0, 4, 0, 4),
            Position         = UDim2.new(0, 10, 0.5, -2),
            BackgroundColor3 = C.T_DIM,
            BackgroundTransparency = 0,
            ZIndex           = 6,
            Parent           = btn,
        })
        Corner(dot, 2)

        local lbl = Lbl({
            Text       = name,
            TextSize   = IS_MOB and 13 or 12,
            TextColor3 = C.T_DIM,
            Size       = UDim2.new(1, -22, 1, 0),
            Position   = UDim2.new(0, 22, 0, 0),
            ZIndex     = 6,
            Parent     = btn,
        })

        local panel = Instance.new("ScrollingFrame")
        panel.Size = UDim2.new(1, 0, 1, 0)
        panel.BackgroundTransparency = 1
        panel.BorderSizePixel = 0
        panel.ScrollBarThickness = IS_MOB and 3 or 2
        panel.ScrollBarImageColor3 = C.BORDER
        panel.CanvasSize = UDim2.new(0, 0, 0, 0)
        panel.Visible = false
        panel.ZIndex = 2
        panel.Parent = content
        Pad(panel, 12, 12, 12, 12)
        local panelLL = VList(panel, 8)
        panelLL.Changed:Connect(function()
            panel.CanvasSize = UDim2.new(0, 0, 0, panelLL.AbsoluteContentSize.Y + 24)
        end)

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
            panel.Position = UDim2.new(0, 5, 0, 0)
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

        -->════════════════════════════════════
        --> :Section()
        -->════════════════════════════════════
        function tabObj:Section(secName)
            local secObj    = {}
            local collapsed = false
            local savedH    = 0

            -- outer wrap — NO AutomaticSize initially to avoid sizing bugs
            local wrap = Frame({
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = C.CARD,
                BackgroundTransparency = 1,
                ZIndex           = 3,
                Parent           = panel,
            })
            wrap.ClipsDescendants = true
            Corner(wrap, 8)
            Stroke(wrap, C.BORDER, 1)

            -- header
            local hdr = Frame({
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = C.ELEM,
                BackgroundTransparency = 0,
                ZIndex           = 4,
                Parent           = wrap,
            })
            Corner(hdr, 8)
            Frame({  -- square bottom
                Size             = UDim2.new(1, 0, 0.5, 0),
                Position         = UDim2.new(0, 0, 0.5, 0),
                BackgroundColor3 = C.ELEM,
                BackgroundTransparency = 0,
                ZIndex           = 4,
                Parent           = hdr,
            })

            local stripe = Frame({
                Size             = UDim2.new(0, 2, 0, 14),
                Position         = UDim2.new(0, 8, 0.5, -7),
                BackgroundColor3 = C.WHITE,
                BackgroundTransparency = 0,
                ZIndex           = 5,
                Parent           = hdr,
            })
            Corner(stripe, 1)

            local secLbl = Lbl({
                Text       = string.upper(secName or "Section"),
                TextSize   = 10,
                Font       = Enum.Font.GothamBold,
                TextColor3 = C.T_SEC,
                Size       = UDim2.new(1, -46, 1, 0),
                Position   = UDim2.new(0, 18, 0, 0),
                ZIndex     = 5,
                Parent     = hdr,
            })

            local collBtn = Btn({
                Text      = "−",
                TextSize  = 15,
                Font      = Enum.Font.GothamBold,
                TextColor3= C.T_DIM,
                Size      = UDim2.new(0, 32, 1, 0),
                Position  = UDim2.new(1, -34, 0, 0),
                ZIndex    = 7,
                Parent    = hdr,
            })

            -- element container
            local elems = Frame({
                Size     = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 36),
                ZIndex   = 4,
                Parent   = wrap,
            })
            Pad(elems, 8, 10, 10, 10)
            local elemsLL = VList(elems, 6)

            -- auto-update wrap height from elems content
            local function refreshHeight()
                if collapsed then return end
                local h = 36 + elemsLL.AbsoluteContentSize.Y + 18
                wrap.Size = UDim2.new(1, 0, 0, h)
                savedH    = h
            end

            elemsLL.Changed:Connect(function()
                task.defer(refreshHeight)
            end)

            -- fade in
            task.defer(function()
                Tw(wrap, TI.SPRING, {BackgroundTransparency=0})
                task.defer(refreshHeight)
            end)

            local function doCollapse()
                collapsed = not collapsed
                if collapsed then
                    savedH = wrap.AbsoluteSize.Y
                    Tw(wrap,    TI.MED,  {Size=UDim2.new(1,0,0,36)})
                    Tw(collBtn, TI.FAST, {Rotation=45, TextColor3=C.T_DIM})
                    Tw(stripe,  TI.FAST, {BackgroundColor3=C.T_DIM})
                    Tw(secLbl,  TI.FAST, {TextColor3=C.T_DIM})
                else
                    Tw(wrap,    TI.MED,  {Size=UDim2.new(1,0,0,savedH)})
                    Tw(collBtn, TI.FAST, {Rotation=0, TextColor3=C.T_DIM})
                    Tw(stripe,  TI.FAST, {BackgroundColor3=C.WHITE})
                    Tw(secLbl,  TI.FAST, {TextColor3=C.T_SEC})
                end
            end

            collBtn.MouseButton1Click:Connect(doCollapse)
            collBtn.MouseEnter:Connect(function() Tw(collBtn,TI.FAST,{TextColor3=C.WHITE}) end)
            collBtn.MouseLeave:Connect(function() Tw(collBtn,TI.FAST,{TextColor3=C.T_DIM}) end)

            local hHit = Btn({
                Size   = UDim2.new(1,-36,1,0),
                ZIndex = 6,
                Parent = hdr,
            })
            hHit.MouseButton1Click:Connect(doCollapse)
            hHit.MouseEnter:Connect(function() Tw(hdr,TI.FAST,{BackgroundColor3=C.HOVER}) end)
            hHit.MouseLeave:Connect(function() Tw(hdr,TI.FAST,{BackgroundColor3=C.ELEM}) end)

            -->══════════════════════════
            --> TEXT LABEL
            -->══════════════════════════
            function secObj:Label(text, color)
                local lf = Frame({
                    Size   = UDim2.new(1, 0, 0, 28),
                    ZIndex = 5,
                    Parent = elems,
                })
                Lbl({
                    Text       = text or "",
                    TextSize   = 12,
                    TextColor3 = color or C.T_SEC,
                    Size       = UDim2.new(1, -8, 1, 0),
                    Position   = UDim2.new(0, 4, 0, 0),
                    TextWrapped = true,
                    ZIndex     = 6,
                    Parent     = lf,
                })
            end

            -->══════════════════════════
            --> BUTTON
            -->══════════════════════════
            function secObj:Button(lbl, cb)
                local b = Btn({
                    BackgroundColor3     = C.ELEM,
                    BackgroundTransparency = 0,
                    Size                 = UDim2.new(1, 0, 0, IS_MOB and 42 or 34),
                    ZIndex               = 5,
                    Parent               = elems,
                })
                Corner(b, 7)
                Stroke(b, C.BORDER, 1)

                local glow = Frame({
                    Size             = UDim2.new(0, 2, 0, 0),
                    Position         = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint      = Vector2.new(0, 0.5),
                    BackgroundColor3 = C.WHITE,
                    BackgroundTransparency = 0,
                    ZIndex           = 6,
                    Parent           = b,
                })
                Corner(glow, 1)

                local bTxt = Lbl({
                    Text       = lbl or "Button",
                    TextSize   = 12,
                    TextColor3 = C.T_SEC,
                    Size       = UDim2.new(1, -40, 1, 0),
                    Position   = UDim2.new(0, 12, 0, 0),
                    ZIndex     = 6,
                    Parent     = b,
                })

                local arr = Lbl({
                    Text             = "›",
                    TextSize         = 16,
                    Font             = Enum.Font.GothamBold,
                    TextColor3       = C.T_DIM,
                    TextXAlignment   = Enum.TextXAlignment.Center,
                    Size             = UDim2.new(0, 24, 1, 0),
                    Position         = UDim2.new(1, -28, 0, 0),
                    ZIndex           = 6,
                    Parent           = b,
                })

                b.MouseEnter:Connect(function()
                    Tw(b,    TI.FAST, {BackgroundColor3=C.HOVER})
                    Tw(bTxt, TI.FAST, {TextColor3=C.T_PRI})
                    Tw(arr,  TI.MED,  {TextColor3=C.WHITE, Position=UDim2.new(1,-22,0,0)})
                    Tw(glow, TI.MED,  {Size=UDim2.new(0,2,0.55,0)})
                end)
                b.MouseLeave:Connect(function()
                    Tw(b,    TI.FAST, {BackgroundColor3=C.ELEM})
                    Tw(bTxt, TI.FAST, {TextColor3=C.T_SEC})
                    Tw(arr,  TI.FAST, {TextColor3=C.T_DIM, Position=UDim2.new(1,-28,0,0)})
                    Tw(glow, TI.FAST, {Size=UDim2.new(0,2,0,0)})
                end)
                b.MouseButton1Down:Connect(function()
                    Tw(b, TI.SNAP, {BackgroundColor3=C.ACTIVE})
                    Ripple(b)
                end)
                b.MouseButton1Up:Connect(function()
                    Tw(b, TI.FAST, {BackgroundColor3=C.HOVER})
                    if cb then task.spawn(cb) end
                end)
            end

            -->══════════════════════════
            --> TOGGLE
            -->══════════════════════════
            function secObj:Toggle(lbl, cb)
                local obj   = {}
                local state = false

                local row = Frame({
                    Size             = UDim2.new(1, 0, 0, IS_MOB and 42 or 34),
                    BackgroundColor3 = C.ELEM,
                    BackgroundTransparency = 0,
                    ZIndex           = 5,
                    Parent           = elems,
                })
                Corner(row, 7)
                Stroke(row, C.BORDER, 1)

                local tLbl = Lbl({
                    Text       = lbl or "Toggle",
                    TextSize   = 12,
                    TextColor3 = C.T_SEC,
                    Size       = UDim2.new(1, -60, 1, 0),
                    Position   = UDim2.new(0, 12, 0, 0),
                    ZIndex     = 6,
                    Parent     = row,
                })

                local track = Frame({
                    Size             = UDim2.new(0, 36, 0, 19),
                    Position         = UDim2.new(1, -48, 0.5, -9.5),
                    BackgroundColor3 = C.ACC_OFF,
                    BackgroundTransparency = 0,
                    ZIndex           = 6,
                    Parent           = row,
                })
                Corner(track, 10)
                Stroke(track, C.BORDER, 1)

                local fill = Frame({
                    Size             = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = C.WHITE,
                    BackgroundTransparency = 0.4,
                    ZIndex           = 7,
                    Parent           = track,
                })
                Corner(fill, 10)

                local thumb = Frame({
                    Size             = UDim2.new(0, 13, 0, 13),
                    Position         = UDim2.new(0, 3, 0.5, -6.5),
                    BackgroundColor3 = C.T_DIM,
                    BackgroundTransparency = 0,
                    ZIndex           = 8,
                    Parent           = track,
                })
                Corner(thumb, 7)

                local function setToggle(v, silent)
                    state = v
                    if state then
                        Tw(track, TI.MED,    {BackgroundColor3=Color3.fromRGB(48,48,48)})
                        Tw(fill,  TI.MED,    {Size=UDim2.new(1,0,1,0), BackgroundTransparency=0.35})
                        Tw(thumb, TI.SPRING, {Position=UDim2.new(0,20,0.5,-6.5), BackgroundColor3=C.WHITE})
                        Tw(tLbl,  TI.FAST,   {TextColor3=C.T_PRI})
                        Tw(row,   TI.FAST,   {BackgroundColor3=Color3.fromRGB(31,31,31)})
                    else
                        Tw(track, TI.MED,    {BackgroundColor3=C.ACC_OFF})
                        Tw(fill,  TI.MED,    {Size=UDim2.new(0,0,1,0), BackgroundTransparency=0.4})
                        Tw(thumb, TI.SPRING, {Position=UDim2.new(0,3,0.5,-6.5), BackgroundColor3=C.T_DIM})
                        Tw(tLbl,  TI.FAST,   {TextColor3=C.T_SEC})
                        Tw(row,   TI.FAST,   {BackgroundColor3=C.ELEM})
                    end
                    if not silent and cb then task.spawn(cb, state) end
                end

                local hit = Btn({Size=UDim2.new(1,0,1,0), ZIndex=9, Parent=row})
                hit.MouseButton1Click:Connect(function()
                    Tw(thumb, TI.SNAP, {Size=UDim2.new(0,17,0,11)})
                    task.delay(0.07, function()
                        Tw(thumb, TI.SPRING, {Size=UDim2.new(0,13,0,13)})
                        setToggle(not state)
                    end)
                    Ripple(row)
                end)
                hit.MouseEnter:Connect(function()
                    if not state then Tw(row,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                hit.MouseLeave:Connect(function()
                    if not state then Tw(row,TI.FAST,{BackgroundColor3=C.ELEM}) end
                end)

                function obj:Set(v) setToggle(v, true) end
                function obj:Get() return state end
                cfg_:Register(lbl or "tog_"..#cfg_.entries, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            -->══════════════════════════
            --> TOGGLE BIND
            --> Toggle that also has a keybind
            -->══════════════════════════
            function secObj:ToggleBind(lbl, defaultKey, cb)
                local obj     = {}
                local state   = false
                local bound   = defaultKey
                local binding = false

                local row = Frame({
                    Size             = UDim2.new(1, 0, 0, IS_MOB and 42 or 34),
                    BackgroundColor3 = C.ELEM,
                    BackgroundTransparency = 0,
                    ZIndex           = 5,
                    Parent           = elems,
                })
                Corner(row, 7)
                Stroke(row, C.BORDER, 1)

                local tLbl = Lbl({
                    Text       = lbl or "ToggleBind",
                    TextSize   = 12,
                    TextColor3 = C.T_SEC,
                    Size       = UDim2.new(1, -140, 1, 0),
                    Position   = UDim2.new(0, 12, 0, 0),
                    ZIndex     = 6,
                    Parent     = row,
                })

                -- pill for bind
                local function kn(k)
                    if not k then return "—" end
                    return tostring(k):gsub("Enum.KeyCode.","")
                end

                local pill = Btn({
                    Text             = kn(bound),
                    TextSize         = 10,
                    Font             = Enum.Font.GothamBold,
                    TextColor3       = C.T_SEC,
                    BackgroundColor3 = C.CARD,
                    BackgroundTransparency = 0,
                    Size             = UDim2.new(0, 60, 0, 20),
                    Position         = UDim2.new(1, -118, 0.5, -10),
                    ZIndex           = 6,
                    Parent           = row,
                })
                Corner(pill, 5)
                Stroke(pill, C.BORDER, 1)

                local track = Frame({
                    Size             = UDim2.new(0, 36, 0, 19),
                    Position         = UDim2.new(1, -48, 0.5, -9.5),
                    BackgroundColor3 = C.ACC_OFF,
                    BackgroundTransparency = 0,
                    ZIndex           = 6,
                    Parent           = row,
                })
                Corner(track, 10)
                Stroke(track, C.BORDER, 1)

                local fill = Frame({
                    Size             = UDim2.new(0,0,1,0),
                    BackgroundColor3 = C.WHITE,
                    BackgroundTransparency = 0.4,
                    ZIndex           = 7, Parent = track,
                })
                Corner(fill, 10)

                local thumb = Frame({
                    Size             = UDim2.new(0,13,0,13),
                    Position         = UDim2.new(0,3,0.5,-6.5),
                    BackgroundColor3 = C.T_DIM,
                    BackgroundTransparency = 0,
                    ZIndex           = 8, Parent = track,
                })
                Corner(thumb, 7)

                local function setToggle(v, silent)
                    state = v
                    if state then
                        Tw(track, TI.MED,    {BackgroundColor3=Color3.fromRGB(48,48,48)})
                        Tw(fill,  TI.MED,    {Size=UDim2.new(1,0,1,0)})
                        Tw(thumb, TI.SPRING, {Position=UDim2.new(0,20,0.5,-6.5), BackgroundColor3=C.WHITE})
                        Tw(tLbl,  TI.FAST,   {TextColor3=C.T_PRI})
                        Tw(row,   TI.FAST,   {BackgroundColor3=Color3.fromRGB(31,31,31)})
                    else
                        Tw(track, TI.MED,    {BackgroundColor3=C.ACC_OFF})
                        Tw(fill,  TI.MED,    {Size=UDim2.new(0,0,1,0)})
                        Tw(thumb, TI.SPRING, {Position=UDim2.new(0,3,0.5,-6.5), BackgroundColor3=C.T_DIM})
                        Tw(tLbl,  TI.FAST,   {TextColor3=C.T_SEC})
                        Tw(row,   TI.FAST,   {BackgroundColor3=C.ELEM})
                    end
                    if not silent and cb then task.spawn(cb, state) end
                end

                local function setBind(k, silent)
                    bound   = k
                    binding = false
                    pill.Text = kn(k)
                    Tw(pill, TI.FAST, {TextColor3=C.T_SEC, BackgroundColor3=C.CARD})
                end

                pill.MouseButton1Click:Connect(function()
                    if binding then return end
                    binding = true
                    pill.Text = "···"
                    Tw(pill, TI.FAST, {TextColor3=C.WHITE, BackgroundColor3=C.ELEM})
                    task.spawn(function()
                        while binding do
                            Tw(pill, TI.SINE, {TextTransparency=0.6})
                            task.wait(0.35)
                            if not binding then break end
                            Tw(pill, TI.SINE, {TextTransparency=0})
                            task.wait(0.35)
                        end
                    end)
                end)

                UIS.InputBegan:Connect(function(i, gp)
                    if gp then return end
                    if binding and i.UserInputType==Enum.UserInputType.Keyboard then
                        setBind(i.KeyCode)
                    elseif not binding and bound and i.KeyCode==bound then
                        setToggle(not state)
                    end
                end)

                local hit = Btn({Size=UDim2.new(1,-130,1,0), ZIndex=9, Parent=row})
                hit.MouseButton1Click:Connect(function()
                    setToggle(not state); Ripple(row)
                end)
                hit.MouseEnter:Connect(function()
                    if not state then Tw(row,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                hit.MouseLeave:Connect(function()
                    if not state then Tw(row,TI.FAST,{BackgroundColor3=C.ELEM}) end
                end)

                function obj:Set(v) setToggle(v,true) end
                function obj:SetKey(k) setBind(k,true) end
                function obj:Get() return state end
                function obj:GetKey() return bound end
                cfg_:Register(lbl or "togbind_"..#cfg_.entries, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            -->══════════════════════════
            --> SLIDER  (supports 0.1 step)
            -->══════════════════════════
            function secObj:Slider(lbl, min, max, default, cb, step)
                local obj  = {}
                min     = min     or 0
                max     = max     or 100
                step    = step    or 1   -- pass 0.1 for decimal
                default = math.clamp(default or min, min, max)
                local val = default

                local wrap = Frame({
                    Size             = UDim2.new(1, 0, 0, IS_MOB and 58 or 52),
                    BackgroundColor3 = C.ELEM,
                    BackgroundTransparency = 0,
                    ZIndex           = 5,
                    Parent           = elems,
                })
                Corner(wrap, 7)
                Stroke(wrap, C.BORDER, 1)
                Pad(wrap, 8, 10, 12, 12)

                local topRow = Frame({
                    Size   = UDim2.new(1,0,0,16),
                    ZIndex = 6, Parent = wrap,
                })
                Lbl({
                    Text       = lbl or "Slider",
                    TextSize   = 12,
                    TextColor3 = C.T_PRI,
                    Size       = UDim2.new(0.65,0,1,0),
                    ZIndex     = 7, Parent = topRow,
                })
                local valLbl = Lbl({
                    Text             = tostring(val),
                    TextSize         = 11,
                    Font             = Enum.Font.GothamBold,
                    TextColor3       = C.T_DIM,
                    TextXAlignment   = Enum.TextXAlignment.Right,
                    Size             = UDim2.new(0.35,0,1,0),
                    Position         = UDim2.new(0.65,0,0,0),
                    ZIndex           = 7, Parent = topRow,
                })

                local trackBg = Frame({
                    Size             = UDim2.new(1,0,0,4),
                    Position         = UDim2.new(0,0,1,-13),
                    BackgroundColor3 = C.BORDER,
                    BackgroundTransparency = 0,
                    ZIndex           = 6, Parent = wrap,
                })
                Corner(trackBg, 2)

                local fill = Frame({
                    Size             = UDim2.new(0,0,1,0),
                    BackgroundColor3 = C.WHITE,
                    BackgroundTransparency = 0,
                    ZIndex           = 7, Parent = trackBg,
                })
                Corner(fill, 2)

                local thumb = Frame({
                    Size             = UDim2.new(0,14,0,14),
                    Position         = UDim2.new(0,-7,0.5,-7),
                    BackgroundColor3 = C.WHITE,
                    BackgroundTransparency = 0,
                    ZIndex           = 9, Parent = trackBg,
                })
                Corner(thumb, 7)
                Stroke(thumb, C.BORDER_LT, 1)

                local function fmt(n)
                    if step >= 1 then
                        return tostring(math.floor(n))
                    else
                        -- figure out decimal places from step
                        local dec = math.ceil(-math.log10(step))
                        return string.format("%."..dec.."f", n)
                    end
                end

                local function update(v, silent)
                    -- snap to step
                    local snapped = math.floor(v / step + 0.5) * step
                    val = math.clamp(snapped, min, max)
                    -- clamp float precision
                    local mult = 10^math.ceil(-math.log10(step+0.0001))
                    val = math.floor(val * mult + 0.5) / mult

                    local pct = (val - min) / (max - min)
                    valLbl.Text = fmt(val)
                    Tw(fill,  TI.FAST, {Size=UDim2.new(pct,0,1,0)})
                    Tw(thumb, TI.FAST, {Position=UDim2.new(pct,-7,0.5,-7)})
                    if not silent and cb then task.spawn(cb, val) end
                end
                update(default, true)

                local dragging = false
                local function fromInp(i)
                    local rel = math.clamp(
                        (i.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X,
                        0, 1)
                    update(min + rel*(max-min))
                end

                trackBg.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1
                    or i.UserInputType==Enum.UserInputType.Touch then
                        dragging = true
                        local pct = (val-min)/(max-min)
                        Tw(thumb, TI.FAST, {Size=UDim2.new(0,18,0,18), Position=UDim2.new(pct,-9,0.5,-9)})
                        Tw(wrap,  TI.FAST, {BackgroundColor3=C.HOVER})
                        fromInp(i)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if dragging and (i.UserInputType==Enum.UserInputType.MouseButton1
                    or i.UserInputType==Enum.UserInputType.Touch) then
                        dragging = false
                        local pct = (val-min)/(max-min)
                        Tw(thumb, TI.SPRING, {Size=UDim2.new(0,14,0,14), Position=UDim2.new(pct,-7,0.5,-7)})
                        Tw(wrap,  TI.FAST,   {BackgroundColor3=C.ELEM})
                    end
                end)
                UIS.InputChanged:Connect(function(i)
                    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement
                    or i.UserInputType==Enum.UserInputType.Touch) then
                        fromInp(i)
                    end
                end)
                wrap.MouseEnter:Connect(function()
                    if not dragging then Tw(wrap,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                wrap.MouseLeave:Connect(function()
                    if not dragging then Tw(wrap,TI.FAST,{BackgroundColor3=C.ELEM}) end
                end)

                function obj:Set(v) update(v, true) end
                function obj:Get() return val end
                cfg_:Register(lbl or "sl_"..#cfg_.entries, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            -->══════════════════════════
            --> DROPDOWN (single)
            -->══════════════════════════
            function secObj:Dropdown(lbl, opts, cb)
                local obj  = {}
                local sel  = nil
                local open = false
                opts = opts or {}

                local ddWrap = Frame({
                    Size             = UDim2.new(1,0,0,IS_MOB and 42 or 34),
                    BackgroundColor3 = C.ELEM,
                    BackgroundTransparency = 0,
                    ZIndex           = 10, Parent = elems,
                })
                ddWrap.ClipsDescendants = false
                Corner(ddWrap, 7)
                Stroke(ddWrap, C.BORDER, 1)

                local ddHdr = Btn({
                    Size   = UDim2.new(1,0,1,0),
                    ZIndex = 11, Parent = ddWrap,
                })
                Lbl({
                    Text       = lbl or "Dropdown",
                    TextSize   = 12,
                    TextColor3 = C.T_SEC,
                    Size       = UDim2.new(0.5,0,1,0),
                    Position   = UDim2.new(0,12,0,0),
                    ZIndex     = 12, Parent = ddHdr,
                })
                local selLbl = Lbl({
                    Text             = "None",
                    TextSize         = 12,
                    Font             = Enum.Font.GothamBold,
                    TextColor3       = C.T_PRI,
                    TextXAlignment   = Enum.TextXAlignment.Right,
                    Size             = UDim2.new(0.42,0,1,0),
                    Position         = UDim2.new(0.5,0,0,0),
                    ZIndex           = 12, Parent = ddHdr,
                })
                local chev = Lbl({
                    Text             = "⌄",
                    TextSize         = 14,
                    Font             = Enum.Font.GothamBold,
                    TextColor3       = C.T_DIM,
                    TextXAlignment   = Enum.TextXAlignment.Center,
                    Size             = UDim2.new(0,22,1,0),
                    Position         = UDim2.new(1,-24,0,0),
                    ZIndex           = 12, Parent = ddHdr,
                })

                local ddPanel = Frame({
                    Size             = UDim2.new(1,0,0,0),
                    Position         = UDim2.new(0,0,0, IS_MOB and 46 or 38),
                    BackgroundColor3 = C.CARD,
                    BackgroundTransparency = 0,
                    ZIndex           = 20, Parent = ddWrap,
                })
                ddPanel.Visible = false
                ddPanel.ClipsDescendants = true
                Corner(ddPanel, 7)
                Stroke(ddPanel, C.BORDER, 1)

                local ddScroll = Instance.new("ScrollingFrame")
                ddScroll.Size = UDim2.new(1,0,1,0)
                ddScroll.BackgroundTransparency = 1
                ddScroll.BorderSizePixel = 0
                ddScroll.ScrollBarThickness = IS_MOB and 3 or 2
                ddScroll.ScrollBarImageColor3 = C.BORDER
                ddScroll.CanvasSize = UDim2.new(0,0,0,0)
                ddScroll.ZIndex = 21
                ddScroll.Parent = ddPanel
                Pad(ddScroll,4,4,6,6)
                local ddLL = VList(ddScroll, 2)
                ddLL.Changed:Connect(function()
                    ddScroll.CanvasSize = UDim2.new(0,0,0,ddLL.AbsoluteContentSize.Y+8)
                end)

                local function build()
                    for _, c in ipairs(ddScroll:GetChildren()) do
                        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
                    end
                    for _, opt in ipairs(opts) do
                        local isSel = (opt==sel)
                        local ob = Btn({
                            Text             = tostring(opt),
                            TextSize         = 12,
                            Font             = isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                            TextColor3       = isSel and C.T_PRI or C.T_SEC,
                            BackgroundColor3 = isSel and C.ELEM  or C.CARD,
                            BackgroundTransparency = 0,
                            Size             = UDim2.new(1,0,0, IS_MOB and 34 or 28),
                            ZIndex           = 22, Parent = ddScroll,
                        })
                        ob.TextXAlignment = Enum.TextXAlignment.Left
                        Pad(ob,0,0,8,0)
                        Corner(ob,5)
                        if isSel then
                            Lbl({
                                Text="✓",TextSize=10,Font=Enum.Font.GothamBold,
                                TextColor3=C.WHITE,TextXAlignment=Enum.TextXAlignment.Center,
                                BackgroundTransparency=1,
                                Size=UDim2.new(0,18,1,0), Position=UDim2.new(1,-20,0,0),
                                ZIndex=23, Parent=ob,
                            })
                        end
                        ob.MouseEnter:Connect(function()
                            if not isSel then Tw(ob,TI.FAST,{BackgroundColor3=C.HOVER}) end
                        end)
                        ob.MouseLeave:Connect(function()
                            if not isSel then Tw(ob,TI.FAST,{BackgroundColor3=C.CARD}) end
                        end)
                        ob.MouseButton1Click:Connect(function()
                            sel=opt; selLbl.Text=tostring(opt); build()
                            if cb then task.spawn(cb,opt) end
                        end)
                    end
                end
                build()

                local function toggleDD()
                    open = not open
                    if open then
                        local ih = IS_MOB and 36 or 30
                        local h  = math.min(#opts * ih + 8, 5 * ih + 8)
                        ddPanel.Visible = true
                        Tw(ddPanel, TI.MED,  {Size=UDim2.new(1,0,0,h)})
                        Tw(chev,    TI.MED,  {Rotation=180})
                        Tw(ddWrap,  TI.FAST, {BackgroundColor3=C.HOVER})
                    else
                        Tw(ddPanel, TI.MED,  {Size=UDim2.new(1,0,0,0)})
                        Tw(chev,    TI.MED,  {Rotation=0})
                        Tw(ddWrap,  TI.FAST, {BackgroundColor3=C.ELEM})
                        task.delay(0.22, function()
                            if not open then ddPanel.Visible=false end
                        end)
                    end
                end

                ddHdr.MouseButton1Click:Connect(function() toggleDD(); Ripple(ddWrap) end)
                ddHdr.MouseEnter:Connect(function()
                    if not open then Tw(ddWrap,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                ddHdr.MouseLeave:Connect(function()
                    if not open then Tw(ddWrap,TI.FAST,{BackgroundColor3=C.ELEM}) end
                end)

                function obj:Set(v) sel=v; selLbl.Text=tostring(v); build() end
                function obj:Refresh(o,del) opts=o or {}; if del then sel=nil; selLbl.Text="None" end build() end
                function obj:Get() return sel end
                cfg_:Register(lbl or "dd_"..#cfg_.entries, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            -->══════════════════════════
            --> MULTI-SELECT DROPDOWN
            -->══════════════════════════
            function secObj:MultiDropdown(lbl, opts, cb)
                local obj      = {}
                local selected = {}  -- set of selected options
                local open     = false
                opts = opts or {}

                local ddWrap = Frame({
                    Size             = UDim2.new(1,0,0,IS_MOB and 42 or 34),
                    BackgroundColor3 = C.ELEM,
                    BackgroundTransparency = 0,
                    ZIndex           = 10, Parent = elems,
                })
                ddWrap.ClipsDescendants = false
                Corner(ddWrap, 7)
                Stroke(ddWrap, C.BORDER, 1)

                local ddHdr = Btn({Size=UDim2.new(1,0,1,0), ZIndex=11, Parent=ddWrap})

                Lbl({
                    Text="▣ "..(lbl or "Multi Select"),
                    TextSize=12, TextColor3=C.T_SEC,
                    Size=UDim2.new(0.55,0,1,0),
                    Position=UDim2.new(0,12,0,0),
                    ZIndex=12, Parent=ddHdr,
                })
                local countLbl = Lbl({
                    Text="0 selected",
                    TextSize=11, Font=Enum.Font.GothamBold,
                    TextColor3=C.T_DIM,
                    TextXAlignment=Enum.TextXAlignment.Right,
                    Size=UDim2.new(0.38,0,1,0),
                    Position=UDim2.new(0.55,0,0,0),
                    ZIndex=12, Parent=ddHdr,
                })
                local chev = Lbl({
                    Text="⌄",TextSize=14,Font=Enum.Font.GothamBold,
                    TextColor3=C.T_DIM,TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(0,22,1,0),Position=UDim2.new(1,-24,0,0),
                    ZIndex=12, Parent=ddHdr,
                })

                local ddPanel = Frame({
                    Size=UDim2.new(1,0,0,0),
                    Position=UDim2.new(0,0,0,IS_MOB and 46 or 38),
                    BackgroundColor3=C.CARD, BackgroundTransparency=0,
                    ZIndex=20, Parent=ddWrap,
                })
                ddPanel.Visible = false
                ddPanel.ClipsDescendants = true
                Corner(ddPanel,7)
                Stroke(ddPanel,C.BORDER,1)

                local ddScroll = Instance.new("ScrollingFrame")
                ddScroll.Size=UDim2.new(1,0,1,0)
                ddScroll.BackgroundTransparency=1
                ddScroll.BorderSizePixel=0
                ddScroll.ScrollBarThickness=IS_MOB and 3 or 2
                ddScroll.ScrollBarImageColor3=C.BORDER
                ddScroll.CanvasSize=UDim2.new(0,0,0,0)
                ddScroll.ZIndex=21
                ddScroll.Parent=ddPanel
                Pad(ddScroll,4,4,6,6)
                local ddLL=VList(ddScroll,2)
                ddLL.Changed:Connect(function()
                    ddScroll.CanvasSize=UDim2.new(0,0,0,ddLL.AbsoluteContentSize.Y+8)
                end)

                local function updateCount()
                    local n = 0
                    for _ in pairs(selected) do n=n+1 end
                    countLbl.Text = n==0 and "None" or (n.." selected")
                end

                local function build()
                    for _, c in ipairs(ddScroll:GetChildren()) do
                        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
                    end
                    for _, opt in ipairs(opts) do
                        local isSel = selected[opt] == true
                        local ob = Btn({
                            BackgroundColor3 = isSel and C.ELEM or C.CARD,
                            BackgroundTransparency = 0,
                            Size=UDim2.new(1,0,0,IS_MOB and 34 or 28),
                            ZIndex=22, Parent=ddScroll,
                        })
                        Corner(ob,5)

                        -- checkbox
                        local chkBox = Frame({
                            Size=UDim2.new(0,14,0,14),
                            Position=UDim2.new(0,6,0.5,-7),
                            BackgroundColor3 = isSel and C.WHITE or C.BORDER,
                            BackgroundTransparency=0,
                            ZIndex=23, Parent=ob,
                        })
                        Corner(chkBox,3)
                        if isSel then
                            Lbl({
                                Text="✓",TextSize=9,Font=Enum.Font.GothamBold,
                                TextColor3=C.BLACK,TextXAlignment=Enum.TextXAlignment.Center,
                                BackgroundTransparency=1,
                                Size=UDim2.new(1,0,1,0),ZIndex=24,Parent=chkBox,
                            })
                        end

                        Lbl({
                            Text=tostring(opt),TextSize=12,
                            Font=isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                            TextColor3=isSel and C.T_PRI or C.T_SEC,
                            Size=UDim2.new(1,-30,1,0),
                            Position=UDim2.new(0,28,0,0),
                            ZIndex=23, Parent=ob,
                        })

                        ob.MouseEnter:Connect(function()
                            Tw(ob,TI.FAST,{BackgroundColor3=C.HOVER})
                        end)
                        ob.MouseLeave:Connect(function()
                            Tw(ob,TI.FAST,{BackgroundColor3=isSel and C.ELEM or C.CARD})
                        end)
                        ob.MouseButton1Click:Connect(function()
                            if selected[opt] then
                                selected[opt] = nil
                            else
                                selected[opt] = true
                            end
                            updateCount()
                            build()
                            -- return array of selected
                            local arr={}
                            for k in pairs(selected) do table.insert(arr,k) end
                            if cb then task.spawn(cb,arr) end
                        end)
                    end
                end
                build()

                local function toggleDD()
                    open=not open
                    if open then
                        local ih=IS_MOB and 36 or 30
                        local h=math.min(#opts*ih+8, 5*ih+8)
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
                    updateCount(); build()
                end
                function obj:Get()
                    local arr={}
                    for k in pairs(selected) do table.insert(arr,k) end
                    return arr
                end
                function obj:Refresh(o,reset)
                    opts=o or {}
                    if reset then selected={} end
                    updateCount(); build()
                end
                return obj
            end

            -->══════════════════════════
            --> BIND
            -->══════════════════════════
            function secObj:Bind(lbl, default, cb)
                local obj     = {}
                local bound   = default
                local binding = false

                local row = Frame({
                    Size=UDim2.new(1,0,0,IS_MOB and 42 or 34),
                    BackgroundColor3=C.ELEM, BackgroundTransparency=0,
                    ZIndex=5, Parent=elems,
                })
                Corner(row,7)
                Stroke(row,C.BORDER,1)
                Lbl({
                    Text=lbl or "Bind",TextSize=12,TextColor3=C.T_SEC,
                    Size=UDim2.new(0.55,0,1,0),Position=UDim2.new(0,12,0,0),
                    ZIndex=6,Parent=row,
                })

                local function kn(k)
                    if not k then return "—" end
                    return tostring(k):gsub("Enum.KeyCode.","")
                end

                local pill = Btn({
                    Text=kn(bound),TextSize=10,Font=Enum.Font.GothamBold,
                    TextColor3=C.T_SEC,BackgroundColor3=C.CARD,BackgroundTransparency=0,
                    Size=UDim2.new(0,72,0,22),Position=UDim2.new(1,-82,0.5,-11),
                    ZIndex=6,Parent=row,
                })
                Corner(pill,5)
                Stroke(pill,C.BORDER,1)

                local function setBind(k,silent)
                    bound=k; binding=false
                    pill.Text=kn(k)
                    Tw(pill,TI.FAST,{TextColor3=C.T_SEC,BackgroundColor3=C.CARD})
                    if not silent and cb then task.spawn(cb,k) end
                end

                pill.MouseButton1Click:Connect(function()
                    if binding then return end
                    binding=true
                    pill.Text="···"
                    Tw(pill,TI.FAST,{TextColor3=C.WHITE,BackgroundColor3=C.ELEM})
                    task.spawn(function()
                        while binding do
                            Tw(pill,TI.SINE,{TextTransparency=0.6})
                            task.wait(0.35)
                            if not binding then break end
                            Tw(pill,TI.SINE,{TextTransparency=0})
                            task.wait(0.35)
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
                cfg_:Register(lbl or "bind_"..#cfg_.entries,
                    function() return kn(bound) end,
                    function(v) pcall(function() setBind(Enum.KeyCode[v],true) end) end
                )
                return obj
            end

            return secObj
        end -- :Section

        return tabObj
    end -- :Tab

    return winObj
end -- :Window

return AlterLib
