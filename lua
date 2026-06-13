--[[
    A L T E R  UI Library — v3.1
    Fixed: All TweenService errors, EasingStyle.Expo removed,
           invalid tween properties removed
--]]

local AlterLib = {}
AlterLib.__index = AlterLib

--> Services
local Players          = game:GetService("Players")
local UIS              = game:GetService("UserInputService")
local TS               = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LP = Players.LocalPlayer

--> Palette
local C = {
    BG         = Color3.fromRGB(12,  12,  12),
    PANEL      = Color3.fromRGB(18,  18,  18),
    CARD       = Color3.fromRGB(22,  22,  22),
    ELEM       = Color3.fromRGB(28,  28,  28),
    HOVER      = Color3.fromRGB(36,  36,  36),
    ACTIVE     = Color3.fromRGB(48,  48,  48),
    BORDER     = Color3.fromRGB(42,  42,  42),
    BORDER_LT  = Color3.fromRGB(58,  58,  58),
    WHITE      = Color3.fromRGB(255, 255, 255),
    BLACK      = Color3.fromRGB(0,   0,   0),
    T_PRI      = Color3.fromRGB(230, 230, 230),
    T_SEC      = Color3.fromRGB(110, 110, 110),
    T_DIM      = Color3.fromRGB(55,  55,  55),
    ACC_OFF    = Color3.fromRGB(38,  38,  38),
}

--> Tween presets — only valid EasingStyles
local TI = {
    SNAP   = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
    FAST   = TweenInfo.new(0.13, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    MED    = TweenInfo.new(0.22, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    SLOW   = TweenInfo.new(0.35, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    SPRING = TweenInfo.new(0.45, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
    SINE   = TweenInfo.new(0.28, Enum.EasingStyle.Sine,   Enum.EasingDirection.InOut),
    CIRC   = TweenInfo.new(0.4,  Enum.EasingStyle.Circular, Enum.EasingDirection.Out),
    BOUNCE = TweenInfo.new(0.5,  Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
}

--> Safe tween — skips invalid properties instead of erroring
local TWEENABLE = {
    -- Frame / UI properties
    BackgroundColor3     = true,
    BackgroundTransparency = true,
    BorderColor3         = true,
    Position             = true,
    Size                 = true,
    Rotation             = true,
    -- Text
    TextColor3           = true,
    TextTransparency     = true,
    TextSize             = true,
    -- Image
    ImageColor3          = true,
    ImageTransparency    = true,
    -- Scroll
    CanvasPosition       = true,
    -- UIStroke
    Color                = true,
    Thickness            = true,
    Transparency         = true,
}

local function Tween(obj, ti, props)
    if not obj or not obj.Parent then return end
    local clean = {}
    for k, v in pairs(props) do
        if TWEENABLE[k] then
            clean[k] = v
        end
    end
    if next(clean) then
        local ok, err = pcall(function()
            TS:Create(obj, ti, clean):Play()
        end)
        if not ok then
            -- silently skip bad tweens
        end
    end
end

--> Instance factory
local function New(cls, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props or {}) do
        if k ~= "Children" then
            local ok, err = pcall(function() inst[k] = v end)
            if not ok then
                warn("[Alter] Property '" .. tostring(k) .. "' failed on " .. cls .. ": " .. tostring(err))
            end
        end
    end
    if props and props.Children then
        for _, c in ipairs(props.Children) do
            c.Parent = inst
        end
    end
    return inst
end

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
    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, t or 0)
    pad.PaddingBottom = UDim.new(0, b or 0)
    pad.PaddingLeft   = UDim.new(0, l or 0)
    pad.PaddingRight  = UDim.new(0, r or 0)
    pad.Parent = p
    return pad
end

local function List(p, dir, gap)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = dir or Enum.FillDirection.Vertical
    l.Padding             = UDim.new(0, gap or 0)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = Enum.VerticalAlignment.Top
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Parent = p
    return l
end

local function Label(p, props)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextColor3 = C.T_PRI
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    for k, v in pairs(props or {}) do
        pcall(function() lbl[k] = v end)
    end
    lbl.Parent = p
    return lbl
end

--> Ripple effect
local function Ripple(host, mx, my)
    if not host or not host.Parent then return end
    local ok, ap = pcall(function() return host.AbsolutePosition end)
    local ok2, as = pcall(function() return host.AbsoluteSize end)
    if not ok or not ok2 then return end

    local lx = (mx or 0) - ap.X
    local ly = (my or 0) - ap.Y
    local sz = math.max(as.X, as.Y) * 2.5

    local r = Instance.new("Frame")
    r.Size = UDim2.new(0, 0, 0, 0)
    r.Position = UDim2.new(0, lx, 0, ly)
    r.AnchorPoint = Vector2.new(0.5, 0.5)
    r.BackgroundColor3 = C.WHITE
    r.BackgroundTransparency = 0.88
    r.ZIndex = 50
    r.BorderSizePixel = 0
    r.Parent = host

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 9999)
    c.Parent = r

    Tween(r, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, sz, 0, sz),
        BackgroundTransparency = 1,
    })
    task.delay(0.55, function()
        if r and r.Parent then r:Destroy() end
    end)
end

--> Fixed drag — pure offset delta, no momentum, no drift
local function MakeDraggable(handle, target)
    local dragging   = false
    local startMouse = Vector2.new()
    local startPos   = Vector2.new()

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging   = true
        startMouse = Vector2.new(inp.Position.X, inp.Position.Y)
        startPos   = Vector2.new(
            target.Position.X.Offset,
            target.Position.Y.Offset
        )
    end)

    UIS.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end

        local cur   = Vector2.new(inp.Position.X, inp.Position.Y)
        local delta = cur - startMouse
        local sg    = target.Parent
        local maxX  = sg and math.max(0, sg.AbsoluteSize.X - target.AbsoluteSize.X) or 9999
        local maxY  = sg and math.max(0, sg.AbsoluteSize.Y - target.AbsoluteSize.Y) or 9999

        target.Position = UDim2.new(
            0, math.clamp(startPos.X + delta.X, 0, maxX),
            0, math.clamp(startPos.Y + delta.Y, 0, maxY)
        )
    end)

    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

--> ScreenGui factory
local function MakeSG(name)
    local id = "ALTER_" .. tostring(name)
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

-->═══════════════════════════════════════════╗
-->  CONFIG SYSTEM                            ║
-->═══════════════════════════════════════════╝
local ConfigSystem = {}
ConfigSystem.__index = ConfigSystem

function ConfigSystem.new(folder)
    local self  = setmetatable({}, ConfigSystem)
    self._folder  = folder or "AlterHub"
    self._entries = {}
    pcall(function()
        if not isfolder(self._folder) then
            makefolder(self._folder)
        end
    end)
    return self
end

function ConfigSystem:Register(key, getter, setter)
    -- avoid duplicate keys
    for _, e in ipairs(self._entries) do
        if e.key == key then
            e.get = getter
            e.set = setter
            return
        end
    end
    table.insert(self._entries, {key = key, get = getter, set = setter})
end

function ConfigSystem:Save(name)
    local data = {}
    for _, e in ipairs(self._entries) do
        local ok, v = pcall(e.get)
        if ok then data[e.key] = v end
    end
    local ok, json = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if not ok then return false end
    local path = self._folder .. "/" .. (name or "default") .. ".json"
    local wok = pcall(function() writefile(path, json) end)
    return wok
end

function ConfigSystem:Load(name)
    local path = self._folder .. "/" .. (name or "default") .. ".json"
    local ok, raw = pcall(function() return readfile(path) end)
    if not ok or not raw then return false end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not ok2 or type(data) ~= "table" then return false end
    for _, e in ipairs(self._entries) do
        if data[e.key] ~= nil then
            pcall(e.set, data[e.key])
        end
    end
    return true
end

function ConfigSystem:List()
    local files = {}
    pcall(function()
        for _, f in ipairs(listfiles(self._folder)) do
            if f:sub(-5) == ".json" then
                local n = f:gsub(self._folder .. "/", ""):gsub(self._folder .. "\\", ""):gsub(".json", "")
                table.insert(files, n)
            end
        end
    end)
    return files
end

function ConfigSystem:AutoLoad(placeMap)
    local pid = tostring(game.PlaceId)
    task.delay(1.5, function()
        if placeMap and placeMap[pid] then
            local ok = self:Load(placeMap[pid])
            print("[Alter] AutoLoad:", placeMap[pid], "→", ok and "OK" or "not found")
        else
            self:Load("default")
        end
    end)
end

-->═══════════════════════════════════════════╗
-->  RICHTEXT                                 ║
-->═══════════════════════════════════════════╝
function AlterLib:RichText(color)
    local hex = string.format("#%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
    return setmetatable({}, {
        __index = function(_, word)
            return string.format('<font color="%s">%s</font>', hex, word)
        end
    })
end

-->═══════════════════════════════════════════╗
-->  NOTIFICATION                             ║
-->═══════════════════════════════════════════╝
local _nSG, _nHolder

local function EnsureNotif()
    if _nSG and _nSG.Parent then return end
    _nSG = MakeSG("NOTIF")
    _nHolder = Instance.new("Frame")
    _nHolder.Size = UDim2.new(0, 280, 1, -20)
    _nHolder.Position = UDim2.new(1, -292, 0, 10)
    _nHolder.BackgroundTransparency = 1
    _nHolder.ZIndex = 200
    _nHolder.Parent = _nSG

    local ll = Instance.new("UIListLayout")
    ll.FillDirection = Enum.FillDirection.Vertical
    ll.VerticalAlignment = Enum.VerticalAlignment.Bottom
    ll.HorizontalAlignment = Enum.HorizontalAlignment.Left
    ll.Padding = UDim.new(0, 6)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = _nHolder

    Pad(_nHolder, 0, 10, 0, 0)
end

function AlterLib:Notify(cfg)
    EnsureNotif()
    cfg = cfg or {}

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 66)
    card.BackgroundColor3 = C.PANEL
    card.ZIndex = 201
    card.ClipsDescendants = false
    card.Parent = _nHolder
    Corner(card, 8)
    Stroke(card, C.BORDER, 1)

    -- accent line animates width
    local acc = Instance.new("Frame")
    acc.Size = UDim2.new(0, 0, 0, 2)
    acc.Position = UDim2.new(0, 0, 0, 0)
    acc.BackgroundColor3 = C.WHITE
    acc.BorderSizePixel = 0
    acc.ZIndex = 203
    acc.Parent = card
    Corner(acc, 1)

    Label(card, {
        Text = cfg.Title or "Alter",
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextColor3 = C.T_PRI,
        Size = UDim2.new(1, -16, 0, 20),
        Position = UDim2.new(0, 12, 0, 10),
        ZIndex = 202,
    })
    Label(card, {
        Text = cfg.Message or "",
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextColor3 = C.T_SEC,
        Size = UDim2.new(1, -16, 0, 26),
        Position = UDim2.new(0, 12, 0, 32),
        TextWrapped = true,
        ZIndex = 202,
    })

    -- slide in from right
    card.Position = UDim2.new(0, 20, 1, 0)
    Tween(card, TI.SPRING, {Position = UDim2.new(0, 0, 1, 0)})
    task.delay(0.1, function()
        Tween(acc, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 2)
        })
    end)

    local dur = cfg.Duration or 3.5
    task.delay(dur, function()
        Tween(card, TI.MED, {
            Position = UDim2.new(0, 20, 1, 0),
            BackgroundTransparency = 1,
        })
        task.delay(0.25, function()
            if card and card.Parent then card:Destroy() end
        end)
    end)
end

-->═══════════════════════════════════════════╗
-->  PROMPT                                   ║
-->═══════════════════════════════════════════╝
function AlterLib:Prompt(cfg)
    cfg = cfg or {}
    local sg = MakeSG("PROMPT")

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = C.BLACK
    bg.BackgroundTransparency = 1
    bg.ZIndex = 100
    bg.Parent = sg
    Tween(bg, TI.MED, {BackgroundTransparency = 0.55})

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 360, 0, 0)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = C.PANEL
    card.ZIndex = 101
    card.ClipsDescendants = true
    card.Parent = bg
    Corner(card, 10)
    Stroke(card, C.BORDER_LT, 1)

    -- top accent
    local topAcc = Instance.new("Frame")
    topAcc.Size = UDim2.new(1, 0, 0, 2)
    topAcc.BackgroundColor3 = C.WHITE
    topAcc.BorderSizePixel = 0
    topAcc.ZIndex = 105
    topAcc.Parent = card

    -- header
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 48)
    hdr.BackgroundColor3 = C.CARD
    hdr.ZIndex = 102
    hdr.Parent = card
    Corner(hdr, 10)

    local hdrSq = Instance.new("Frame")
    hdrSq.Size = UDim2.new(1, 0, 0.5, 0)
    hdrSq.Position = UDim2.new(0, 0, 0.5, 0)
    hdrSq.BackgroundColor3 = C.CARD
    hdrSq.BorderSizePixel = 0
    hdrSq.ZIndex = 102
    hdrSq.Parent = hdr

    Label(hdr, {
        Text = cfg.Title or "Confirm",
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextColor3 = C.T_PRI,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        ZIndex = 103,
    })

    Label(card, {
        Text = cfg.Message or "",
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextColor3 = C.T_SEC,
        Size = UDim2.new(1, -36, 0, 42),
        Position = UDim2.new(0, 18, 0, 56),
        TextWrapped = true,
        ZIndex = 103,
    })

    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, -36, 0, 36)
    btnRow.Position = UDim2.new(0, 18, 0, 108)
    btnRow.BackgroundTransparency = 1
    btnRow.ZIndex = 102
    btnRow.Parent = card
    List(btnRow, Enum.FillDirection.Horizontal, 8)

    local function closePrompt(cb)
        Tween(card, TI.MED, {Size = UDim2.new(0, 360, 0, 0)})
        Tween(bg,   TI.MED, {BackgroundTransparency = 1})
        task.delay(0.28, function()
            if cb then pcall(cb) end
            if sg and sg.Parent then sg:Destroy() end
        end)
    end

    local function PBtn(txt, primary, cb)
        local b = Instance.new("TextButton")
        b.Text = txt
        b.TextSize = 12
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = primary and C.BLACK or C.T_SEC
        b.BackgroundColor3 = primary and C.WHITE or C.ELEM
        b.Size = UDim2.new(0.5, -4, 1, 0)
        b.AutoButtonColor = false
        b.ZIndex = 103
        b.Parent = btnRow
        Corner(b, 7)
        if not primary then Stroke(b, C.BORDER, 1) end

        b.MouseButton1Click:Connect(function()
            closePrompt(cb)
        end)
        b.MouseEnter:Connect(function()
            Tween(b, TI.FAST, {
                BackgroundColor3 = primary and Color3.fromRGB(215, 215, 215) or C.HOVER
            })
        end)
        b.MouseLeave:Connect(function()
            Tween(b, TI.FAST, {
                BackgroundColor3 = primary and C.WHITE or C.ELEM
            })
        end)
        b.MouseButton1Down:Connect(function()
            local mp = UIS:GetMouseLocation()
            Ripple(b, mp.X, mp.Y)
        end)
    end

    PBtn(cfg.NoText  or "Cancel",  false, cfg.No)
    PBtn(cfg.YesText or "Confirm", true,  cfg.Yes)

    bg.MouseButton1Click:Connect(function()
        closePrompt(nil)
    end)

    Tween(card, TI.SPRING, {Size = UDim2.new(0, 360, 0, 156)})
end

-->═══════════════════════════════════════════╗
-->  WINDOW                                   ║
-->═══════════════════════════════════════════╝
function AlterLib:Window(cfg)
    cfg = cfg or {}

    local WIN_W  = 600
    local WIN_H  = 520
    local SIDE_W = 145

    local sg = MakeSG(cfg.Folder or "WIN")
    local configSys = ConfigSystem.new(cfg.Folder or "AlterHub")

    --> Root frame — offset only positioning
    local root = Instance.new("Frame")
    root.Size = UDim2.new(0, WIN_W, 0, 0)
    root.Position = UDim2.new(0, 80, 0, 60)
    root.BackgroundColor3 = C.BG
    root.BackgroundTransparency = 1
    root.ClipsDescendants = false
    root.ZIndex = 1
    root.Parent = sg
    Corner(root, 10)
    Stroke(root, C.BORDER, 1)

    --> Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundColor3 = C.PANEL
    titleBar.ZIndex = 4
    titleBar.Parent = root
    Corner(titleBar, 10)

    -- square off bottom of title bar
    local tbSq = Instance.new("Frame")
    tbSq.Size = UDim2.new(1, 0, 0.5, 0)
    tbSq.Position = UDim2.new(0, 0, 0.5, 0)
    tbSq.BackgroundColor3 = C.PANEL
    tbSq.BorderSizePixel = 0
    tbSq.ZIndex = 4
    tbSq.Parent = titleBar

    -- accent line
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(0, 0, 0, 1)
    accentLine.BackgroundColor3 = C.WHITE
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 6
    accentLine.Parent = titleBar
    Corner(accentLine, 1)

    -- Hub label
    local hubLbl = Instance.new("TextLabel")
    hubLbl.Text = cfg.Name or "Alter"
    hubLbl.TextSize = 15
    hubLbl.Font = Enum.Font.GothamBlack
    hubLbl.TextColor3 = C.T_PRI
    hubLbl.BackgroundTransparency = 1
    hubLbl.Size = UDim2.new(0.5, 0, 1, 0)
    hubLbl.Position = UDim2.new(0, 18, 0, 0)
    hubLbl.TextXAlignment = Enum.TextXAlignment.Left
    hubLbl.RichText = true
    hubLbl.ZIndex = 5
    hubLbl.TextTransparency = 1
    hubLbl.Parent = titleBar

    -- Sub label
    local subLbl = Instance.new("TextLabel")
    subLbl.Text = cfg.SubName or ("PlaceId " .. tostring(game.PlaceId))
    subLbl.TextSize = 10
    subLbl.Font = Enum.Font.Gotham
    subLbl.TextColor3 = C.T_DIM
    subLbl.BackgroundTransparency = 1
    subLbl.Size = UDim2.new(0.5, 0, 0, 14)
    subLbl.Position = UDim2.new(0, 18, 1, -16)
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.ZIndex = 5
    subLbl.Parent = titleBar

    -- Controls row
    local ctrlRow = Instance.new("Frame")
    ctrlRow.Size = UDim2.new(0, 58, 0, 24)
    ctrlRow.Position = UDim2.new(1, -68, 0.5, -12)
    ctrlRow.BackgroundTransparency = 1
    ctrlRow.ZIndex = 5
    ctrlRow.Parent = titleBar
    List(ctrlRow, Enum.FillDirection.Horizontal, 6)

    local minimised = false
    local bodyFrame

    local function CtrlBtn(sym, action)
        local b = Instance.new("TextButton")
        b.Text = sym
        b.TextSize = 13
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = C.T_DIM
        b.BackgroundColor3 = C.ELEM
        b.Size = UDim2.new(0, 26, 0, 24)
        b.AutoButtonColor = false
        b.ZIndex = 6
        b.Parent = ctrlRow
        Corner(b, 5)
        Stroke(b, C.BORDER, 1)

        b.MouseButton1Click:Connect(function()
            local mp = UIS:GetMouseLocation()
            Ripple(b, mp.X, mp.Y)
            action()
        end)
        b.MouseEnter:Connect(function()
            Tween(b, TI.FAST, {BackgroundColor3 = C.HOVER, TextColor3 = C.T_PRI})
        end)
        b.MouseLeave:Connect(function()
            Tween(b, TI.FAST, {BackgroundColor3 = C.ELEM,  TextColor3 = C.T_DIM})
        end)
        b.MouseButton1Down:Connect(function()
            Tween(b, TI.SNAP, {BackgroundColor3 = C.ACTIVE})
        end)
        return b
    end

    CtrlBtn("−", function()
        minimised = not minimised
        Tween(root, TI.MED, {
            Size = minimised
                and UDim2.new(0, WIN_W, 0, 48)
                or  UDim2.new(0, WIN_W, 0, WIN_H)
        })
    end)

    CtrlBtn("×", function()
        Tween(root, TI.MED, {
            Size = UDim2.new(0, WIN_W, 0, 0),
            BackgroundTransparency = 1,
        })
        task.delay(0.3, function()
            if sg and sg.Parent then sg:Destroy() end
        end)
    end)

    MakeDraggable(titleBar, root)

    --> Body
    bodyFrame = Instance.new("Frame")
    bodyFrame.Size = UDim2.new(1, 0, 1, -48)
    bodyFrame.Position = UDim2.new(0, 0, 0, 48)
    bodyFrame.BackgroundTransparency = 1
    bodyFrame.ClipsDescendants = true
    bodyFrame.ZIndex = 2
    bodyFrame.Parent = root

    --> Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, SIDE_W, 1, 0)
    sidebar.Position = UDim2.new(0, 0, 0, 0)
    sidebar.BackgroundColor3 = C.PANEL
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 3
    sidebar.Parent = bodyFrame
    Corner(sidebar, 10)

    -- square off top-right and right side
    local sbSq1 = Instance.new("Frame")
    sbSq1.Size = UDim2.new(0, 10, 1, 0)
    sbSq1.Position = UDim2.new(1, -10, 0, 0)
    sbSq1.BackgroundColor3 = C.PANEL
    sbSq1.BorderSizePixel = 0
    sbSq1.ZIndex = 3
    sbSq1.Parent = sidebar

    local sbSq2 = Instance.new("Frame")
    sbSq2.Size = UDim2.new(1, 0, 0, 10)
    sbSq2.Position = UDim2.new(0, 0, 0, 0)
    sbSq2.BackgroundColor3 = C.PANEL
    sbSq2.BorderSizePixel = 0
    sbSq2.ZIndex = 3
    sbSq2.Parent = sidebar

    -- separator
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(0, 1, 1, 0)
    sep.Position = UDim2.new(1, 0, 0, 0)
    sep.BackgroundColor3 = C.BORDER
    sep.BorderSizePixel = 0
    sep.ZIndex = 4
    sep.Parent = sidebar

    -- brand
    local brandLbl = Instance.new("TextLabel")
    brandLbl.Text = "ALTER"
    brandLbl.TextSize = 11
    brandLbl.Font = Enum.Font.GothamBlack
    brandLbl.TextColor3 = C.T_DIM
    brandLbl.BackgroundTransparency = 1
    brandLbl.Size = UDim2.new(1, 0, 0, 48)
    brandLbl.Position = UDim2.new(0, 0, 0, 0)
    brandLbl.TextXAlignment = Enum.TextXAlignment.Center
    brandLbl.ZIndex = 4
    brandLbl.TextTransparency = 1
    brandLbl.Parent = sidebar

    -- divider under brand
    local brandDiv = Instance.new("Frame")
    brandDiv.Size = UDim2.new(1, -24, 0, 1)
    brandDiv.Position = UDim2.new(0, 12, 0, 47)
    brandDiv.BackgroundColor3 = C.BORDER
    brandDiv.BorderSizePixel = 0
    brandDiv.ZIndex = 4
    brandDiv.Parent = sidebar

    -- Tab scroll
    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Size = UDim2.new(1, 0, 1, -56)
    tabScroll.Position = UDim2.new(0, 0, 0, 54)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 0
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.ZIndex = 4
    tabScroll.ClipsDescendants = true
    tabScroll.Parent = sidebar
    Pad(tabScroll, 4, 4, 8, 8)

    local tabLL = List(tabScroll, Enum.FillDirection.Vertical, 3)
    tabLL.Changed:Connect(function()
        tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabLL.AbsoluteContentSize.Y + 8)
    end)

    --> Content area
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -SIDE_W, 1, 0)
    content.Position = UDim2.new(0, SIDE_W, 0, 0)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.ZIndex = 2
    content.Parent = bodyFrame

    --> Open animation
    task.defer(function()
        Tween(root, TI.SPRING, {
            Size = UDim2.new(0, WIN_W, 0, WIN_H),
            BackgroundTransparency = 0,
        })
        task.delay(0.2, function()
            Tween(accentLine, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, 1)
            })
            Tween(hubLbl,   TI.SLOW, {TextTransparency = 0})
            Tween(brandLbl, TI.SLOW, {TextTransparency = 0})
        end)
    end)

    --> Window object
    local winObj = {
        _tabs  = {},
        Config = configSys,
    }

    -->══════════════════════════════════════════
    --> :Tab()
    -->══════════════════════════════════════════
    function winObj:Tab(name)
        local tabObj = {_name = name}

        local btn = Instance.new("TextButton")
        btn.Text = ""
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = C.ELEM
        btn.BackgroundTransparency = 1
        btn.AutoButtonColor = false
        btn.ZIndex = 5
        btn.Parent = tabScroll
        Corner(btn, 7)

        local ind = Instance.new("Frame")
        ind.Size = UDim2.new(0, 2, 0, 0)
        ind.Position = UDim2.new(0, 0, 0.5, 0)
        ind.AnchorPoint = Vector2.new(0, 0.5)
        ind.BackgroundColor3 = C.WHITE
        ind.BorderSizePixel = 0
        ind.ZIndex = 6
        ind.Parent = btn
        Corner(ind, 1)

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 4, 0, 4)
        dot.Position = UDim2.new(0, 12, 0.5, -2)
        dot.BackgroundColor3 = C.T_DIM
        dot.BorderSizePixel = 0
        dot.ZIndex = 6
        dot.Parent = btn
        Corner(dot, 2)

        local lbl = Instance.new("TextLabel")
        lbl.Text = name
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextColor3 = C.T_DIM
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, -28, 1, 0)
        lbl.Position = UDim2.new(0, 24, 0, 0)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 6
        lbl.Parent = btn

        -- panel
        local panel = Instance.new("ScrollingFrame")
        panel.Size = UDim2.new(1, 0, 1, 0)
        panel.Position = UDim2.new(0, 0, 0, 0)
        panel.BackgroundTransparency = 1
        panel.BorderSizePixel = 0
        panel.ScrollBarThickness = 2
        panel.ScrollBarImageColor3 = C.BORDER
        panel.CanvasSize = UDim2.new(0, 0, 0, 0)
        panel.Visible = false
        panel.ZIndex = 2
        panel.Parent = content
        Pad(panel, 14, 14, 14, 14)

        local panelLL = List(panel, Enum.FillDirection.Vertical, 10)
        panelLL.Changed:Connect(function()
            panel.CanvasSize = UDim2.new(0, 0, 0, panelLL.AbsoluteContentSize.Y + 28)
        end)

        tabObj._panel  = panel
        tabObj._btn    = btn
        tabObj._ind    = ind
        tabObj._dot    = dot
        tabObj._lbl    = lbl
        table.insert(self._tabs, tabObj)

        local function activate()
            for _, t in ipairs(self._tabs) do
                if t ~= tabObj then
                    t._panel.Visible = false
                    Tween(t._btn, TI.FAST, {BackgroundTransparency = 1})
                    Tween(t._ind, TI.FAST, {Size = UDim2.new(0, 2, 0, 0)})
                    Tween(t._dot, TI.FAST, {BackgroundColor3 = C.T_DIM})
                    Tween(t._lbl, TI.FAST, {TextColor3 = C.T_DIM})
                end
            end
            panel.Visible = true
            panel.Position = UDim2.new(0, 6, 0, 0)
            Tween(panel, TI.MED, {Position = UDim2.new(0, 0, 0, 0)})
            Tween(btn,   TI.MED, {BackgroundTransparency = 0, BackgroundColor3 = C.ELEM})
            Tween(ind,   TI.SPRING, {Size = UDim2.new(0, 2, 0, 20)})
            Tween(dot,   TI.FAST,   {BackgroundColor3 = C.WHITE})
            Tween(lbl,   TI.FAST,   {TextColor3 = C.T_PRI})
        end

        btn.MouseButton1Click:Connect(function()
            activate()
            local mp = UIS:GetMouseLocation()
            Ripple(btn, mp.X, mp.Y)
        end)
        btn.MouseEnter:Connect(function()
            if panel.Visible then return end
            Tween(btn, TI.FAST, {BackgroundTransparency = 0.85, BackgroundColor3 = C.ELEM})
            Tween(lbl, TI.FAST, {TextColor3 = C.T_SEC})
        end)
        btn.MouseLeave:Connect(function()
            if panel.Visible then return end
            Tween(btn, TI.FAST, {BackgroundTransparency = 1})
            Tween(lbl, TI.FAST, {TextColor3 = C.T_DIM})
        end)

        if #self._tabs == 1 then activate() end

        -->══════════════════════════════════════
        --> :Section()
        -->══════════════════════════════════════
        function tabObj:Section(secName)
            local secObj    = {}
            local collapsed = false
            local savedH    = 0

            local wrap = Instance.new("Frame")
            wrap.Size = UDim2.new(1, 0, 0, 36)
            wrap.BackgroundColor3 = C.CARD
            wrap.BackgroundTransparency = 1
            wrap.AutomaticSize = Enum.AutomaticSize.Y
            wrap.ClipsDescendants = true
            wrap.ZIndex = 3
            wrap.Parent = panel
            Corner(wrap, 8)
            Stroke(wrap, C.BORDER, 1)

            task.defer(function()
                Tween(wrap, TI.SPRING, {BackgroundTransparency = 0})
            end)

            -- header
            local hdr = Instance.new("Frame")
            hdr.Size = UDim2.new(1, 0, 0, 36)
            hdr.BackgroundColor3 = C.ELEM
            hdr.ZIndex = 4
            hdr.Parent = wrap
            Corner(hdr, 8)

            local hdrSq = Instance.new("Frame")
            hdrSq.Size = UDim2.new(1, 0, 0.5, 0)
            hdrSq.Position = UDim2.new(0, 0, 0.5, 0)
            hdrSq.BackgroundColor3 = C.ELEM
            hdrSq.BorderSizePixel = 0
            hdrSq.ZIndex = 4
            hdrSq.Parent = hdr

            local stripe = Instance.new("Frame")
            stripe.Size = UDim2.new(0, 2, 0, 16)
            stripe.Position = UDim2.new(0, 8, 0.5, -8)
            stripe.BackgroundColor3 = C.WHITE
            stripe.BorderSizePixel = 0
            stripe.ZIndex = 5
            stripe.Parent = hdr
            Corner(stripe, 1)

            local secLbl = Instance.new("TextLabel")
            secLbl.Text = string.upper(secName or "Section")
            secLbl.TextSize = 10
            secLbl.Font = Enum.Font.GothamBold
            secLbl.TextColor3 = C.T_SEC
            secLbl.BackgroundTransparency = 1
            secLbl.Size = UDim2.new(1, -48, 1, 0)
            secLbl.Position = UDim2.new(0, 18, 0, 0)
            secLbl.TextXAlignment = Enum.TextXAlignment.Left
            secLbl.ZIndex = 5
            secLbl.Parent = hdr

            local collBtn = Instance.new("TextButton")
            collBtn.Text = "−"
            collBtn.TextSize = 16
            collBtn.Font = Enum.Font.GothamBold
            collBtn.TextColor3 = C.T_DIM
            collBtn.BackgroundTransparency = 1
            collBtn.Size = UDim2.new(0, 32, 1, 0)
            collBtn.Position = UDim2.new(1, -34, 0, 0)
            collBtn.AutoButtonColor = false
            collBtn.ZIndex = 7
            collBtn.Parent = hdr

            -- element container
            local elems = Instance.new("Frame")
            elems.Size = UDim2.new(1, 0, 0, 0)
            elems.Position = UDim2.new(0, 0, 0, 36)
            elems.BackgroundTransparency = 1
            elems.AutomaticSize = Enum.AutomaticSize.Y
            elems.ZIndex = 4
            elems.Parent = wrap
            Pad(elems, 8, 10, 10, 10)
            List(elems, Enum.FillDirection.Vertical, 6)

            local function doCollapse()
                collapsed = not collapsed
                if collapsed then
                    savedH = wrap.AbsoluteSize.Y
                    wrap.AutomaticSize = Enum.AutomaticSize.None
                    Tween(wrap,    TI.MED,  {Size = UDim2.new(1, 0, 0, 36)})
                    Tween(collBtn, TI.FAST, {Rotation = 45, TextColor3 = C.T_DIM})
                    Tween(stripe,  TI.FAST, {BackgroundColor3 = C.T_DIM})
                    Tween(secLbl,  TI.FAST, {TextColor3 = C.T_DIM})
                else
                    Tween(wrap,    TI.MED,  {Size = UDim2.new(1, 0, 0, savedH)})
                    Tween(collBtn, TI.FAST, {Rotation = 0, TextColor3 = C.T_DIM})
                    Tween(stripe,  TI.FAST, {BackgroundColor3 = C.WHITE})
                    Tween(secLbl,  TI.FAST, {TextColor3 = C.T_SEC})
                    task.delay(0.25, function()
                        if not collapsed then
                            wrap.AutomaticSize = Enum.AutomaticSize.Y
                        end
                    end)
                end
            end

            collBtn.MouseButton1Click:Connect(doCollapse)
            collBtn.MouseEnter:Connect(function()
                Tween(collBtn, TI.FAST, {TextColor3 = C.WHITE})
            end)
            collBtn.MouseLeave:Connect(function()
                Tween(collBtn, TI.FAST, {TextColor3 = C.T_DIM})
            end)

            local hdrHit = Instance.new("TextButton")
            hdrHit.Text = ""
            hdrHit.Size = UDim2.new(1, -36, 1, 0)
            hdrHit.BackgroundTransparency = 1
            hdrHit.ZIndex = 6
            hdrHit.Parent = hdr
            hdrHit.MouseButton1Click:Connect(doCollapse)
            hdrHit.MouseEnter:Connect(function()
                Tween(hdr, TI.FAST, {BackgroundColor3 = C.HOVER})
            end)
            hdrHit.MouseLeave:Connect(function()
                Tween(hdr, TI.FAST, {BackgroundColor3 = C.ELEM})
            end)

            -->══════════════════════════════
            --> BUTTON
            -->══════════════════════════════
            function secObj:Button(lbl, cb)
                local btn = Instance.new("TextButton")
                btn.Text = ""
                btn.Size = UDim2.new(1, 0, 0, 36)
                btn.BackgroundColor3 = C.ELEM
                btn.AutoButtonColor = false
                btn.ZIndex = 5
                btn.Parent = elems
                Corner(btn, 7)
                Stroke(btn, C.BORDER, 1)

                local glow = Instance.new("Frame")
                glow.Size = UDim2.new(0, 2, 0, 0)
                glow.Position = UDim2.new(0, 0, 0.5, 0)
                glow.AnchorPoint = Vector2.new(0, 0.5)
                glow.BackgroundColor3 = C.WHITE
                glow.BorderSizePixel = 0
                glow.ZIndex = 6
                glow.Parent = btn
                Corner(glow, 1)

                local bLbl = Instance.new("TextLabel")
                bLbl.Text = lbl or "Button"
                bLbl.TextSize = 12
                bLbl.Font = Enum.Font.GothamMedium
                bLbl.TextColor3 = C.T_SEC
                bLbl.BackgroundTransparency = 1
                bLbl.Size = UDim2.new(1, -44, 1, 0)
                bLbl.Position = UDim2.new(0, 14, 0, 0)
                bLbl.TextXAlignment = Enum.TextXAlignment.Left
                bLbl.ZIndex = 6
                bLbl.Parent = btn

                local arr = Instance.new("TextLabel")
                arr.Text = "›"
                arr.TextSize = 16
                arr.Font = Enum.Font.GothamBold
                arr.TextColor3 = C.T_DIM
                arr.BackgroundTransparency = 1
                arr.Size = UDim2.new(0, 26, 1, 0)
                arr.Position = UDim2.new(1, -30, 0, 0)
                arr.TextXAlignment = Enum.TextXAlignment.Center
                arr.ZIndex = 6
                arr.Parent = btn

                btn.MouseEnter:Connect(function()
                    Tween(btn,  TI.FAST, {BackgroundColor3 = C.HOVER})
                    Tween(bLbl, TI.FAST, {TextColor3 = C.T_PRI})
                    Tween(arr,  TI.MED,  {TextColor3 = C.WHITE, Position = UDim2.new(1, -24, 0, 0)})
                    Tween(glow, TI.MED,  {Size = UDim2.new(0, 2, 0.6, 0)})
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn,  TI.FAST, {BackgroundColor3 = C.ELEM})
                    Tween(bLbl, TI.FAST, {TextColor3 = C.T_SEC})
                    Tween(arr,  TI.FAST, {TextColor3 = C.T_DIM, Position = UDim2.new(1, -30, 0, 0)})
                    Tween(glow, TI.FAST, {Size = UDim2.new(0, 2, 0, 0)})
                end)
                btn.MouseButton1Down:Connect(function()
                    Tween(btn, TI.SNAP, {BackgroundColor3 = C.ACTIVE})
                    local mp = UIS:GetMouseLocation()
                    Ripple(btn, mp.X, mp.Y)
                end)
                btn.MouseButton1Up:Connect(function()
                    Tween(btn, TI.FAST, {BackgroundColor3 = C.HOVER})
                    if cb then task.spawn(cb) end
                end)
            end

            -->══════════════════════════════
            --> TOGGLE
            -->══════════════════════════════
            function secObj:Toggle(lbl, cb)
                local obj   = {}
                local state = false

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 36)
                row.BackgroundColor3 = C.ELEM
                row.ZIndex = 5
                row.Parent = elems
                Corner(row, 7)
                Stroke(row, C.BORDER, 1)

                local tLbl = Instance.new("TextLabel")
                tLbl.Text = lbl or "Toggle"
                tLbl.TextSize = 12
                tLbl.Font = Enum.Font.GothamMedium
                tLbl.TextColor3 = C.T_SEC
                tLbl.BackgroundTransparency = 1
                tLbl.Size = UDim2.new(1, -62, 1, 0)
                tLbl.Position = UDim2.new(0, 12, 0, 0)
                tLbl.TextXAlignment = Enum.TextXAlignment.Left
                tLbl.ZIndex = 6
                tLbl.Parent = row

                local track = Instance.new("Frame")
                track.Size = UDim2.new(0, 38, 0, 20)
                track.Position = UDim2.new(1, -50, 0.5, -10)
                track.BackgroundColor3 = C.ACC_OFF
                track.ZIndex = 6
                track.Parent = row
                Corner(track, 10)
                Stroke(track, C.BORDER, 1)

                local trackFill = Instance.new("Frame")
                trackFill.Size = UDim2.new(0, 0, 1, 0)
                trackFill.BackgroundColor3 = C.WHITE
                trackFill.BackgroundTransparency = 0.35
                trackFill.ZIndex = 7
                trackFill.Parent = track
                Corner(trackFill, 10)

                local thumb = Instance.new("Frame")
                thumb.Size = UDim2.new(0, 14, 0, 14)
                thumb.Position = UDim2.new(0, 3, 0.5, -7)
                thumb.BackgroundColor3 = C.T_DIM
                thumb.ZIndex = 8
                thumb.Parent = track
                Corner(thumb, 7)

                local function setToggle(v, silent)
                    state = v
                    if state then
                        Tween(track,     TI.MED,    {BackgroundColor3 = Color3.fromRGB(50, 50, 50)})
                        Tween(trackFill, TI.MED,    {Size = UDim2.new(1, 0, 1, 0)})
                        Tween(thumb,     TI.SPRING, {
                            Position         = UDim2.new(0, 21, 0.5, -7),
                            BackgroundColor3 = C.WHITE,
                        })
                        Tween(tLbl, TI.FAST, {TextColor3 = C.T_PRI})
                        Tween(row,  TI.FAST, {BackgroundColor3 = Color3.fromRGB(32, 32, 32)})
                    else
                        Tween(track,     TI.MED,    {BackgroundColor3 = C.ACC_OFF})
                        Tween(trackFill, TI.MED,    {Size = UDim2.new(0, 0, 1, 0)})
                        Tween(thumb,     TI.SPRING, {
                            Position         = UDim2.new(0, 3, 0.5, -7),
                            BackgroundColor3 = C.T_DIM,
                        })
                        Tween(tLbl, TI.FAST, {TextColor3 = C.T_SEC})
                        Tween(row,  TI.FAST, {BackgroundColor3 = C.ELEM})
                    end
                    if not silent and cb then task.spawn(cb, state) end
                end

                local hit = Instance.new("TextButton")
                hit.Text = ""
                hit.Size = UDim2.new(1, 0, 1, 0)
                hit.BackgroundTransparency = 1
                hit.ZIndex = 9
                hit.Parent = row

                hit.MouseButton1Click:Connect(function()
                    -- quick squeeze then spring
                    Tween(thumb, TI.SNAP, {Size = UDim2.new(0, 18, 0, 12)})
                    task.delay(0.08, function()
                        Tween(thumb, TI.SPRING, {Size = UDim2.new(0, 14, 0, 14)})
                        setToggle(not state)
                    end)
                    local mp = UIS:GetMouseLocation()
                    Ripple(row, mp.X, mp.Y)
                end)
                hit.MouseEnter:Connect(function()
                    if not state then
                        Tween(row, TI.FAST, {BackgroundColor3 = C.HOVER})
                    end
                end)
                hit.MouseLeave:Connect(function()
                    if not state then
                        Tween(row, TI.FAST, {BackgroundColor3 = C.ELEM})
                    end
                end)

                function obj:Set(v) setToggle(v, true) end
                function obj:Get() return state end

                configSys:Register(lbl or "toggle_"..tostring(#configSys._entries), obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            -->══════════════════════════════
            --> SLIDER
            -->══════════════════════════════
            function secObj:Slider(lbl, min, max, default, cb)
                local obj = {}
                min     = min or 0
                max     = max or 100
                default = math.clamp(default or min, min, max)
                local val = default

                local wrap = Instance.new("Frame")
                wrap.Size = UDim2.new(1, 0, 0, 54)
                wrap.BackgroundColor3 = C.ELEM
                wrap.ZIndex = 5
                wrap.Parent = elems
                Corner(wrap, 7)
                Stroke(wrap, C.BORDER, 1)
                Pad(wrap, 8, 10, 12, 12)

                local topRow = Instance.new("Frame")
                topRow.Size = UDim2.new(1, 0, 0, 16)
                topRow.BackgroundTransparency = 1
                topRow.ZIndex = 6
                topRow.Parent = wrap

                local sLbl = Instance.new("TextLabel")
                sLbl.Text = lbl or "Slider"
                sLbl.TextSize = 12
                sLbl.Font = Enum.Font.GothamMedium
                sLbl.TextColor3 = C.T_PRI
                sLbl.BackgroundTransparency = 1
                sLbl.Size = UDim2.new(0.65, 0, 1, 0)
                sLbl.TextXAlignment = Enum.TextXAlignment.Left
                sLbl.ZIndex = 7
                sLbl.Parent = topRow

                local valLbl = Instance.new("TextLabel")
                valLbl.Text = tostring(val)
                valLbl.TextSize = 11
                valLbl.Font = Enum.Font.GothamBold
                valLbl.TextColor3 = C.T_DIM
                valLbl.BackgroundTransparency = 1
                valLbl.Size = UDim2.new(0.35, 0, 1, 0)
                valLbl.Position = UDim2.new(0.65, 0, 0, 0)
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.ZIndex = 7
                valLbl.Parent = topRow

                local trackBg = Instance.new("Frame")
                trackBg.Size = UDim2.new(1, 0, 0, 4)
                trackBg.Position = UDim2.new(0, 0, 1, -14)
                trackBg.BackgroundColor3 = C.BORDER
                trackBg.ZIndex = 6
                trackBg.Parent = wrap
                Corner(trackBg, 2)

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.BackgroundColor3 = C.WHITE
                fill.ZIndex = 7
                fill.Parent = trackBg
                Corner(fill, 2)

                local thumb = Instance.new("Frame")
                thumb.Size = UDim2.new(0, 14, 0, 14)
                thumb.Position = UDim2.new(0, -7, 0.5, -7)
                thumb.BackgroundColor3 = C.WHITE
                thumb.ZIndex = 9
                thumb.Parent = trackBg
                Corner(thumb, 7)
                Stroke(thumb, C.BORDER_LT, 1)

                local function update(v, silent)
                    val = math.clamp(math.floor(v + 0.5), min, max)
                    local pct = (val - min) / (max - min)
                    valLbl.Text = tostring(val)
                    Tween(fill,  TI.FAST, {Size     = UDim2.new(pct, 0, 1, 0)})
                    Tween(thumb, TI.FAST, {Position = UDim2.new(pct, -7, 0.5, -7)})
                    if not silent and cb then task.spawn(cb, val) end
                end
                update(default, true)

                local dragging = false
                local function fromInput(inp)
                    local rel = math.clamp(
                        (inp.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X,
                        0, 1
                    )
                    update(min + rel * (max - min))
                end

                trackBg.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        local pct = (val - min) / (max - min)
                        Tween(thumb, TI.FAST, {
                            Size     = UDim2.new(0, 18, 0, 18),
                            Position = UDim2.new(pct, -9, 0.5, -9),
                        })
                        Tween(wrap, TI.FAST, {BackgroundColor3 = C.HOVER})
                        fromInput(i)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if dragging and (
                        i.UserInputType == Enum.UserInputType.MouseButton1 or
                        i.UserInputType == Enum.UserInputType.Touch
                    ) then
                        dragging = false
                        local pct = (val - min) / (max - min)
                        Tween(thumb, TI.SPRING, {
                            Size     = UDim2.new(0, 14, 0, 14),
                            Position = UDim2.new(pct, -7, 0.5, -7),
                        })
                        Tween(wrap, TI.FAST, {BackgroundColor3 = C.ELEM})
                    end
                end)
                UIS.InputChanged:Connect(function(i)
                    if dragging and (
                        i.UserInputType == Enum.UserInputType.MouseMovement or
                        i.UserInputType == Enum.UserInputType.Touch
                    ) then
                        fromInput(i)
                    end
                end)

                wrap.MouseEnter:Connect(function()
                    if not dragging then Tween(wrap, TI.FAST, {BackgroundColor3 = C.HOVER}) end
                end)
                wrap.MouseLeave:Connect(function()
                    if not dragging then Tween(wrap, TI.FAST, {BackgroundColor3 = C.ELEM}) end
                end)

                function obj:Set(v) update(v, true) end
                function obj:Get() return val end

                configSys:Register(lbl or "slider_"..tostring(#configSys._entries), obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            -->══════════════════════════════
            --> DROPDOWN
            -->══════════════════════════════
            function secObj:Dropdown(lbl, opts, cb)
                local obj  = {}
                local sel  = nil
                local open = false
                opts = opts or {}

                local ddWrap = Instance.new("Frame")
                ddWrap.Size = UDim2.new(1, 0, 0, 36)
                ddWrap.BackgroundColor3 = C.ELEM
                ddWrap.ClipsDescendants = false
                ddWrap.ZIndex = 10
                ddWrap.Parent = elems
                Corner(ddWrap, 7)
                Stroke(ddWrap, C.BORDER, 1)

                local ddHdr = Instance.new("TextButton")
                ddHdr.Text = ""
                ddHdr.Size = UDim2.new(1, 0, 0, 36)
                ddHdr.BackgroundTransparency = 1
                ddHdr.AutoButtonColor = false
                ddHdr.ZIndex = 11
                ddHdr.Parent = ddWrap

                local ddLbl = Instance.new("TextLabel")
                ddLbl.Text = lbl or "Dropdown"
                ddLbl.TextSize = 12
                ddLbl.Font = Enum.Font.GothamMedium
                ddLbl.TextColor3 = C.T_SEC
                ddLbl.BackgroundTransparency = 1
                ddLbl.Size = UDim2.new(0.5, 0, 1, 0)
                ddLbl.Position = UDim2.new(0, 12, 0, 0)
                ddLbl.TextXAlignment = Enum.TextXAlignment.Left
                ddLbl.ZIndex = 12
                ddLbl.Parent = ddHdr

                local selLbl = Instance.new("TextLabel")
                selLbl.Text = "None"
                selLbl.TextSize = 12
                selLbl.Font = Enum.Font.GothamBold
                selLbl.TextColor3 = C.T_PRI
                selLbl.BackgroundTransparency = 1
                selLbl.Size = UDim2.new(0.42, 0, 1, 0)
                selLbl.Position = UDim2.new(0.5, 0, 0, 0)
                selLbl.TextXAlignment = Enum.TextXAlignment.Right
                selLbl.ZIndex = 12
                selLbl.Parent = ddHdr

                local chev = Instance.new("TextLabel")
                chev.Text = "⌄"
                chev.TextSize = 14
                chev.Font = Enum.Font.GothamBold
                chev.TextColor3 = C.T_DIM
                chev.BackgroundTransparency = 1
                chev.Size = UDim2.new(0, 22, 1, 0)
                chev.Position = UDim2.new(1, -24, 0, 0)
                chev.TextXAlignment = Enum.TextXAlignment.Center
                chev.ZIndex = 12
                chev.Parent = ddHdr

                local ddPanel = Instance.new("Frame")
                ddPanel.Size = UDim2.new(1, 0, 0, 0)
                ddPanel.Position = UDim2.new(0, 0, 0, 40)
                ddPanel.BackgroundColor3 = C.CARD
                ddPanel.ClipsDescendants = true
                ddPanel.ZIndex = 20
                ddPanel.Visible = false
                ddPanel.Parent = ddWrap
                Corner(ddPanel, 7)
                Stroke(ddPanel, C.BORDER, 1)

                local ddScroll = Instance.new("ScrollingFrame")
                ddScroll.Size = UDim2.new(1, 0, 1, 0)
                ddScroll.BackgroundTransparency = 1
                ddScroll.BorderSizePixel = 0
                ddScroll.ScrollBarThickness = 2
                ddScroll.ScrollBarImageColor3 = C.BORDER
                ddScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                ddScroll.ZIndex = 21
                ddScroll.Parent = ddPanel
                Pad(ddScroll, 4, 4, 6, 6)

                local ddLL = List(ddScroll, Enum.FillDirection.Vertical, 2)
                ddLL.Changed:Connect(function()
                    ddScroll.CanvasSize = UDim2.new(0, 0, 0, ddLL.AbsoluteContentSize.Y + 8)
                end)

                local function build()
                    for _, c in ipairs(ddScroll:GetChildren()) do
                        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
                            c:Destroy()
                        end
                    end
                    for _, opt in ipairs(opts) do
                        local isSel = (opt == sel)
                        local ob = Instance.new("TextButton")
                        ob.Text = tostring(opt)
                        ob.TextSize = 12
                        ob.Font = isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium
                        ob.TextColor3 = isSel and C.T_PRI or C.T_SEC
                        ob.BackgroundColor3 = isSel and C.ELEM or C.CARD
                        ob.Size = UDim2.new(1, 0, 0, 28)
                        ob.AutoButtonColor = false
                        ob.TextXAlignment = Enum.TextXAlignment.Left
                        ob.ZIndex = 22
                        ob.Parent = ddScroll
                        Pad(ob, 0, 0, 8, 0)
                        Corner(ob, 5)

                        if isSel then
                            local chk = Instance.new("TextLabel")
                            chk.Text = "✓"
                            chk.TextSize = 10
                            chk.Font = Enum.Font.GothamBold
                            chk.TextColor3 = C.WHITE
                            chk.BackgroundTransparency = 1
                            chk.Size = UDim2.new(0, 18, 1, 0)
                            chk.Position = UDim2.new(1, -20, 0, 0)
                            chk.TextXAlignment = Enum.TextXAlignment.Center
                            chk.ZIndex = 23
                            chk.Parent = ob
                        end

                        ob.MouseEnter:Connect(function()
                            if not isSel then Tween(ob, TI.FAST, {BackgroundColor3 = C.HOVER}) end
                        end)
                        ob.MouseLeave:Connect(function()
                            if not isSel then Tween(ob, TI.FAST, {BackgroundColor3 = C.CARD}) end
                        end)
                        ob.MouseButton1Click:Connect(function()
                            sel = opt
                            selLbl.Text = tostring(opt)
                            build()
                            if cb then task.spawn(cb, opt) end
                        end)
                    end
                end
                build()

                local function toggleDD()
                    open = not open
                    if open then
                        local h = math.min(#opts * 30 + 8, 5 * 30 + 8)
                        ddPanel.Visible = true
                        Tween(ddPanel, TI.MED,  {Size = UDim2.new(1, 0, 0, h)})
                        Tween(chev,    TI.MED,  {Rotation = 180})
                        Tween(ddWrap,  TI.FAST, {BackgroundColor3 = C.HOVER})
                    else
                        Tween(ddPanel, TI.MED,  {Size = UDim2.new(1, 0, 0, 0)})
                        Tween(chev,    TI.MED,  {Rotation = 0})
                        Tween(ddWrap,  TI.FAST, {BackgroundColor3 = C.ELEM})
                        task.delay(0.25, function()
                            if not open then ddPanel.Visible = false end
                        end)
                    end
                end

                ddHdr.MouseButton1Click:Connect(function()
                    toggleDD()
                    local mp = UIS:GetMouseLocation()
                    Ripple(ddWrap, mp.X, mp.Y)
                end)
                ddHdr.MouseEnter:Connect(function()
                    if not open then Tween(ddWrap, TI.FAST, {BackgroundColor3 = C.HOVER}) end
                end)
                ddHdr.MouseLeave:Connect(function()
                    if not open then Tween(ddWrap, TI.FAST, {BackgroundColor3 = C.ELEM}) end
                end)

                function obj:Set(v)
                    sel = v
                    selLbl.Text = tostring(v)
                    build()
                end
                function obj:Refresh(o, del)
                    opts = o or {}
                    if del then sel = nil; selLbl.Text = "None" end
                    build()
                end
                function obj:Get() return sel end

                configSys:Register(lbl or "dd_"..tostring(#configSys._entries), obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            -->══════════════════════════════
            --> BIND
            -->══════════════════════════════
            function secObj:Bind(lbl, default, cb)
                local obj     = {}
                local bound   = default
                local binding = false

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 36)
                row.BackgroundColor3 = C.ELEM
                row.ZIndex = 5
                row.Parent = elems
                Corner(row, 7)
                Stroke(row, C.BORDER, 1)

                local bLbl = Instance.new("TextLabel")
                bLbl.Text = lbl or "Bind"
                bLbl.TextSize = 12
                bLbl.Font = Enum.Font.GothamMedium
                bLbl.TextColor3 = C.T_SEC
                bLbl.BackgroundTransparency = 1
                bLbl.Size = UDim2.new(0.55, 0, 1, 0)
                bLbl.Position = UDim2.new(0, 12, 0, 0)
                bLbl.TextXAlignment = Enum.TextXAlignment.Left
                bLbl.ZIndex = 6
                bLbl.Parent = row

                local function kn(k)
                    if not k then return "—" end
                    return tostring(k):gsub("Enum.KeyCode.", "")
                end

                local pill = Instance.new("TextButton")
                pill.Text = kn(bound)
                pill.TextSize = 10
                pill.Font = Enum.Font.GothamBold
                pill.TextColor3 = C.T_SEC
                pill.BackgroundColor3 = C.CARD
                pill.Size = UDim2.new(0, 72, 0, 22)
                pill.Position = UDim2.new(1, -82, 0.5, -11)
                pill.AutoButtonColor = false
                pill.ZIndex = 6
                pill.Parent = row
                Corner(pill, 5)
                Stroke(pill, C.BORDER, 1)

                local function setBind(k, silent)
                    bound   = k
                    binding = false
                    pill.Text = kn(k)
                    pill.TextTransparency = 0
                    Tween(pill, TI.FAST, {
                        TextColor3       = C.T_SEC,
                        BackgroundColor3 = C.CARD,
                    })
                    if not silent and cb then task.spawn(cb, k) end
                end

                pill.MouseButton1Click:Connect(function()
                    if binding then return end
                    binding = true
                    pill.Text = "···"
                    Tween(pill, TI.FAST, {
                        TextColor3       = C.WHITE,
                        BackgroundColor3 = C.ELEM,
                    })
                    task.spawn(function()
                        while binding do
                            Tween(pill, TI.SINE, {TextTransparency = 0.6})
                            task.wait(0.35)
                            if not binding then break end
                            Tween(pill, TI.SINE, {TextTransparency = 0})
                            task.wait(0.35)
                        end
                    end)
                end)

                UIS.InputBegan:Connect(function(i, gp)
                    if gp then return end
                    if binding then
                        if i.UserInputType == Enum.UserInputType.Keyboard then
                            setBind(i.KeyCode)
                        end
                    else
                        if bound and i.KeyCode == bound then
                            if cb then task.spawn(cb, bound) end
                        end
                    end
                end)

                row.MouseEnter:Connect(function()
                    Tween(row, TI.FAST, {BackgroundColor3 = C.HOVER})
                end)
                row.MouseLeave:Connect(function()
                    Tween(row, TI.FAST, {BackgroundColor3 = C.ELEM})
                end)

                function obj:Set(k) setBind(k, true) end
                function obj:Get() return bound end

                configSys:Register(lbl or "bind_"..tostring(#configSys._entries),
                    function() return bound and tostring(bound):gsub("Enum.KeyCode.", "") or "None" end,
                    function(v) pcall(function() setBind(Enum.KeyCode[v], true) end) end
                )

                return obj
            end

            return secObj
        end -- Section

        return tabObj
    end -- Tab

    return winObj
end -- Window

return AlterLib
