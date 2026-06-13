--[[
    ╔═══════════════════════════════════════════════════════╗
    ║   A L T E R  UI Library — v3                         ║
    ║   Fixed drag · Section collapse · Config system      ║
    ║   PlaceId auto-load · Full animation suite           ║
    ╚═══════════════════════════════════════════════════════╝
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
    BG         = Color3.fromRGB(12,  12,  12 ),
    PANEL      = Color3.fromRGB(18,  18,  18 ),
    CARD       = Color3.fromRGB(22,  22,  22 ),
    ELEM       = Color3.fromRGB(28,  28,  28 ),
    HOVER      = Color3.fromRGB(36,  36,  36 ),
    ACTIVE     = Color3.fromRGB(48,  48,  48 ),
    BORDER     = Color3.fromRGB(42,  42,  42 ),
    BORDER_LT  = Color3.fromRGB(58,  58,  58 ),
    WHITE      = Color3.fromRGB(255, 255, 255),
    BLACK      = Color3.fromRGB(0,   0,   0  ),
    T_PRI      = Color3.fromRGB(230, 230, 230),
    T_SEC      = Color3.fromRGB(110, 110, 110),
    T_DIM      = Color3.fromRGB(55,  55,  55 ),
    ACC_OFF    = Color3.fromRGB(38,  38,  38 ),
}

--> Easing
local TI = {
    SNAP   = TweenInfo.new(0.05, Enum.EasingStyle.Linear),
    FAST   = TweenInfo.new(0.13, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    MED    = TweenInfo.new(0.22, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    SLOW   = TweenInfo.new(0.35, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    SPRING = TweenInfo.new(0.5,  Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
    SINE   = TweenInfo.new(0.28, Enum.EasingStyle.Sine,   Enum.EasingDirection.InOut),
    EXPO   = TweenInfo.new(0.4,  Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
}

local function Tw(o, ti, p) return TS:Create(o, ti, p) end
local function Tween(o, ti, p) TS:Create(o, ti, p):Play() end

local function New(cls, props)
    local i = Instance.new(cls)
    for k, v in pairs(props or {}) do
        if k ~= "Children" then i[k] = v end
    end
    if props and props.Children then
        for _, c in ipairs(props.Children) do c.Parent = i end
    end
    return i
end

local function Corner(p, r)
    return New("UICorner", {Parent = p, CornerRadius = UDim.new(0, r or 6)})
end

local function Stroke(p, col, th)
    return New("UIStroke", {Parent = p, Color = col or C.BORDER, Thickness = th or 1})
end

local function Pad(p, t, b, l, r)
    return New("UIPadding", {
        Parent = p,
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or 0),
    })
end

local function List(p, dir, gap)
    return New("UIListLayout", {
        Parent              = p,
        FillDirection       = dir or Enum.FillDirection.Vertical,
        Padding             = UDim.new(0, gap or 0),
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment   = Enum.VerticalAlignment.Top,
        SortOrder           = Enum.SortOrder.LayoutOrder,
    })
end

--> Ripple
local function Ripple(host, mx, my)
    local ap  = host.AbsolutePosition
    local as  = host.AbsoluteSize
    local lx  = mx - ap.X
    local ly  = my - ap.Y
    local sz  = math.max(as.X, as.Y) * 2.5
    local r   = New("Frame", {
        Parent               = host,
        Size                 = UDim2.new(0, 0, 0, 0),
        Position             = UDim2.new(0, lx, 0, ly),
        AnchorPoint          = Vector2.new(0.5, 0.5),
        BackgroundColor3     = C.WHITE,
        BackgroundTransparency = 0.88,
        ZIndex               = host.ZIndex + 20,
        ClipsDescendants     = false,
    })
    Corner(r, 9999)
    Tween(r, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size                   = UDim2.new(0, sz, 0, sz),
        BackgroundTransparency = 1,
    })
    task.delay(0.51, function() r:Destroy() end)
end

--> FIXED Dragging — no momentum, no drift
local function MakeDraggable(handle, target)
    local dragging  = false
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
        local delta = Vector2.new(inp.Position.X, inp.Position.Y) - startMouse
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

--> ScreenGui
local function MakeSG(name)
    local id = "ALTER_" .. tostring(name)
    pcall(function()
        local e = CoreGui:FindFirstChild(id)
        if e then e:Destroy() end
    end)
    local sg
    pcall(function()
        sg = New("ScreenGui", {
            Name           = id,
            Parent         = CoreGui,
            ResetOnSpawn   = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true,
            DisplayOrder   = 999,
        })
    end)
    if not sg then
        sg = New("ScreenGui", {
            Name           = id,
            Parent         = LP:WaitForChild("PlayerGui"),
            ResetOnSpawn   = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true,
        })
    end
    return sg
end

-->═══════════════════════════════════════════╗
-->  CONFIG SYSTEM                            ║
-->═══════════════════════════════════════════╝
local ConfigSystem = {}
ConfigSystem.__index = ConfigSystem

function ConfigSystem.new(folder)
    local self = setmetatable({}, ConfigSystem)
    self._folder  = folder or "AlterHub"
    self._entries = {}   -- { key, getter, setter }
    -- ensure folder
    pcall(function()
        if not isfolder(self._folder) then
            makefolder(self._folder)
        end
    end)
    return self
end

function ConfigSystem:Register(key, getter, setter)
    table.insert(self._entries, {key=key, get=getter, set=setter})
end

function ConfigSystem:Save(name)
    local data = {}
    for _, e in ipairs(self._entries) do
        local ok, v = pcall(e.get)
        if ok then data[e.key] = v end
    end
    local json = HttpService:JSONEncode(data)
    local path = self._folder .. "/" .. (name or "default") .. ".json"
    pcall(function() writefile(path, json) end)
    return path
end

function ConfigSystem:Load(name)
    local path = self._folder .. "/" .. (name or "default") .. ".json"
    local ok, raw = pcall(function() return readfile(path) end)
    if not ok or not raw then return false end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
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
                local name = f:gsub(self._folder.."/",""):gsub(".json","")
                table.insert(files, name)
            end
        end
    end)
    return files
end

function ConfigSystem:AutoLoad(placeMap)
    -- placeMap = { [placeId] = "configName", ... }
    local pid = tostring(game.PlaceId)
    if placeMap and placeMap[pid] then
        task.delay(1, function()
            self:Load(placeMap[pid])
            print("[Alter] Auto-loaded config:", placeMap[pid], "for PlaceId:", pid)
        end)
    else
        task.delay(1, function()
            self:Load("default")
        end)
    end
end

-->═══════════════════════════════════════════╗
-->  RICHTEXT                                 ║
-->═══════════════════════════════════════════╝
function AlterLib:RichText(color)
    local hex = string.format("#%02X%02X%02X",
        math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
    return setmetatable({}, {
        __index = function(_, word)
            return string.format('<font color="%s">%s</font>', hex, word)
        end
    })
end

-->═══════════════════════════════════════════╗
-->  NOTIFICATION                             ║
-->═══════════════════════════════════════════╝
local _notifSG
local _notifList
local _notifLayout

local function EnsureNotifSG()
    if _notifSG and _notifSG.Parent then return end
    _notifSG = MakeSG("NOTIF")
    _notifList = New("Frame", {
        Parent               = _notifSG,
        Size                 = UDim2.new(0, 280, 1, 0),
        Position             = UDim2.new(1, -295, 0, 0),
        BackgroundTransparency = 1,
        ZIndex               = 200,
    })
    _notifLayout = List(_notifList, Enum.FillDirection.Vertical, 8)
    Pad(_notifList, 16, 16, 0, 0)
end

function AlterLib:Notify(cfg)
    EnsureNotifSG()
    cfg = cfg or {}

    local card = New("Frame", {
        Parent               = _notifList,
        Size                 = UDim2.new(1, 0, 0, 70),
        BackgroundColor3     = C.PANEL,
        BackgroundTransparency = 0,
        ZIndex               = 201,
        ClipsDescendants     = true,
    })
    Corner(card, 8)
    Stroke(card, C.BORDER, 1)

    -- top accent
    local acc = New("Frame", {
        Parent           = card,
        Size             = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = C.WHITE,
        BorderSizePixel  = 0,
        ZIndex           = 203,
    })
    Corner(acc, 1)

    New("TextLabel", {
        Parent               = card,
        Text                 = cfg.Title or "Alter",
        TextSize             = 13,
        Font                 = Enum.Font.GothamBold,
        TextColor3           = C.T_PRI,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, -16, 0, 22),
        Position             = UDim2.new(0, 12, 0, 10),
        TextXAlignment       = Enum.TextXAlignment.Left,
        ZIndex               = 202,
    })
    New("TextLabel", {
        Parent               = card,
        Text                 = cfg.Message or "",
        TextSize             = 11,
        Font                 = Enum.Font.Gotham,
        TextColor3           = C.T_SEC,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, -16, 0, 28),
        Position             = UDim2.new(0, 12, 0, 32),
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextWrapped          = true,
        ZIndex               = 202,
    })

    -- slide in
    card.Position = UDim2.new(1, 10, 0, 0)
    Tween(acc,  TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {Size = UDim2.new(1, 0, 0, 2)})
    Tween(card, TI.SPRING, {Position = UDim2.new(0, 0, 0, 0)})

    -- auto dismiss
    local dur = cfg.Duration or 3.5
    task.delay(dur, function()
        Tween(card, TI.MED, {
            Position             = UDim2.new(1, 20, 0, 0),
            BackgroundTransparency = 1,
        })
        task.delay(0.25, function() card:Destroy() end)
    end)
end

-->═══════════════════════════════════════════╗
-->  PROMPT                                   ║
-->═══════════════════════════════════════════╝
function AlterLib:Prompt(cfg)
    cfg = cfg or {}
    local sg = MakeSG("PROMPT")

    local bg = New("Frame", {
        Parent               = sg,
        Size                 = UDim2.fromScale(1, 1),
        BackgroundColor3     = C.BLACK,
        BackgroundTransparency = 1,
        ZIndex               = 100,
    })
    Tween(bg, TI.MED, {BackgroundTransparency = 0.55})

    local card = New("Frame", {
        Parent               = bg,
        Size                 = UDim2.new(0, 370, 0, 0),
        Position             = UDim2.fromScale(0.5, 0.5),
        AnchorPoint          = Vector2.new(0.5, 0.5),
        BackgroundColor3     = C.PANEL,
        BackgroundTransparency = 0,
        ZIndex               = 101,
        ClipsDescendants     = true,
    })
    Corner(card, 10)
    Stroke(card, C.BORDER_LT, 1)

    -- top accent bar
    local topBar = New("Frame", {
        Parent           = card,
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = C.WHITE,
        BorderSizePixel  = 0,
        ZIndex           = 104,
    })

    local hdr = New("Frame", {
        Parent           = card,
        Size             = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = C.CARD,
        ZIndex           = 102,
    })
    Corner(hdr, 10)
    New("Frame", {
        Parent           = hdr,
        Size             = UDim2.new(1, 0, 0, 10),
        Position         = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = C.CARD,
        BorderSizePixel  = 0,
        ZIndex           = 102,
    })
    New("TextLabel", {
        Parent               = hdr,
        Text                 = cfg.Title or "Confirm",
        TextSize             = 13,
        Font                 = Enum.Font.GothamBold,
        TextColor3           = C.T_PRI,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, -20, 1, 0),
        Position             = UDim2.new(0, 18, 0, 0),
        TextXAlignment       = Enum.TextXAlignment.Left,
        ZIndex               = 103,
    })

    New("TextLabel", {
        Parent               = card,
        Text                 = cfg.Message or "",
        TextSize             = 12,
        Font                 = Enum.Font.Gotham,
        TextColor3           = C.T_SEC,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, -36, 0, 44),
        Position             = UDim2.new(0, 18, 0, 58),
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextWrapped          = true,
        ZIndex               = 103,
    })

    local btnRow = New("Frame", {
        Parent               = card,
        Size                 = UDim2.new(1, -36, 0, 38),
        Position             = UDim2.new(0, 18, 0, 112),
        BackgroundTransparency = 1,
        ZIndex               = 102,
    })
    List(btnRow, Enum.FillDirection.Horizontal, 10)

    local function close(cb)
        Tween(card, TI.MED, {Size = UDim2.new(0, 370, 0, 0)})
        Tween(bg,   TI.MED, {BackgroundTransparency = 1})
        task.delay(0.25, function()
            if cb then cb() end
            sg:Destroy()
        end)
    end

    local function PBtn(txt, primary, cb)
        local b = New("TextButton", {
            Parent           = btnRow,
            Text             = txt,
            TextSize         = 12,
            Font             = Enum.Font.GothamBold,
            TextColor3       = primary and C.BLACK or C.T_SEC,
            BackgroundColor3 = primary and C.WHITE  or C.ELEM,
            Size             = UDim2.new(0.5, -5, 1, 0),
            AutoButtonColor  = false,
            ZIndex           = 103,
        })
        Corner(b, 7)
        if not primary then Stroke(b, C.BORDER, 1) end
        b.MouseButton1Click:Connect(function() close(cb) end)
        b.MouseEnter:Connect(function()
            Tween(b, TI.FAST, {
                BackgroundColor3 = primary and Color3.fromRGB(215,215,215) or C.HOVER
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

    -- open animation
    Tween(card, TI.SPRING, {Size = UDim2.new(0, 370, 0, 162)})
    bg.MouseButton1Click:Connect(function() close() end)
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

    -- Config system
    local configSys = ConfigSystem.new(cfg.Folder or "AlterHub")

    --> Root — use OFFSET position only, never Scale for dragging
    local root = New("Frame", {
        Parent               = sg,
        Size                 = UDim2.new(0, WIN_W, 0, WIN_H),
        Position             = UDim2.new(0, 80, 0, 60),
        BackgroundColor3     = C.BG,
        BackgroundTransparency = 1,
        ClipsDescendants     = false,
        ZIndex               = 1,
    })
    Corner(root, 10)
    Stroke(root, C.BORDER, 1)

    --> Title bar
    local titleBar = New("Frame", {
        Parent           = root,
        Size             = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = C.PANEL,
        ZIndex           = 4,
    })
    Corner(titleBar, 10)
    -- square off bottom corners
    New("Frame", {
        Parent           = titleBar,
        Size             = UDim2.new(1, 0, 0.5, 0),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = C.PANEL,
        BorderSizePixel  = 0,
        ZIndex           = 4,
    })

    -- animated top accent line
    local accentLine = New("Frame", {
        Parent           = titleBar,
        Size             = UDim2.new(0, 0, 0, 1),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = C.WHITE,
        BorderSizePixel  = 0,
        ZIndex           = 6,
    })
    Corner(accentLine, 1)

    -- Hub name
    local hubLbl = New("TextLabel", {
        Parent               = titleBar,
        Text                 = cfg.Name or "Alter",
        TextSize             = 15,
        Font                 = Enum.Font.GothamBlack,
        TextColor3           = C.T_PRI,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(0.5, 0, 1, 0),
        Position             = UDim2.new(0, 18, 0, 0),
        TextXAlignment       = Enum.TextXAlignment.Left,
        RichText             = true,
        ZIndex               = 5,
        TextTransparency     = 1,
    })

    -- Sub-label / game name
    New("TextLabel", {
        Parent               = titleBar,
        Text                 = cfg.SubName or ("PlaceId: "..tostring(game.PlaceId)),
        TextSize             = 10,
        Font                 = Enum.Font.Gotham,
        TextColor3           = C.T_DIM,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(0.5, 0, 0, 14),
        Position             = UDim2.new(0, 18, 1, -16),
        TextXAlignment       = Enum.TextXAlignment.Left,
        ZIndex               = 5,
    })

    -- Controls
    local ctrlRow = New("Frame", {
        Parent               = titleBar,
        Size                 = UDim2.new(0, 64, 0, 24),
        Position             = UDim2.new(1, -76, 0.5, -12),
        BackgroundTransparency = 1,
        ZIndex               = 5,
    })
    List(ctrlRow, Enum.FillDirection.Horizontal, 6)

    local minimised = false
    local bodyFrame

    local function CtrlBtn(sym, action)
        local b = New("TextButton", {
            Parent           = ctrlRow,
            Text             = sym,
            TextSize         = 12,
            Font             = Enum.Font.GothamBold,
            TextColor3       = C.T_DIM,
            BackgroundColor3 = C.ELEM,
            Size             = UDim2.new(0, 24, 0, 24),
            AutoButtonColor  = false,
            ZIndex           = 6,
        })
        Corner(b, 6)
        Stroke(b, C.BORDER, 1)
        b.MouseButton1Click:Connect(function()
            local mp = UIS:GetMouseLocation()
            Ripple(b, mp.X, mp.Y)
            action()
        end)
        b.MouseEnter:Connect(function()
            Tween(b, TI.FAST, {BackgroundColor3=C.HOVER, TextColor3=C.T_PRI})
        end)
        b.MouseLeave:Connect(function()
            Tween(b, TI.FAST, {BackgroundColor3=C.ELEM,  TextColor3=C.T_DIM})
        end)
        b.MouseButton1Down:Connect(function()
            Tween(b, TI.SNAP, {BackgroundColor3=C.ACTIVE})
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
            Size                 = UDim2.new(0, WIN_W, 0, 0),
            BackgroundTransparency = 1,
        })
        task.delay(0.28, function() sg:Destroy() end)
    end)

    MakeDraggable(titleBar, root)

    --> Body
    bodyFrame = New("Frame", {
        Parent               = root,
        Size                 = UDim2.new(1, 0, 1, -48),
        Position             = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        ClipsDescendants     = true,
        ZIndex               = 2,
    })

    --> Sidebar
    local sidebar = New("Frame", {
        Parent           = bodyFrame,
        Size             = UDim2.new(0, SIDE_W, 1, 0),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = C.PANEL,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    })
    -- square off right side corners
    New("Frame", {
        Parent           = sidebar,
        Size             = UDim2.new(0, 10, 1, 0),
        Position         = UDim2.new(1, -10, 0, 0),
        BackgroundColor3 = C.PANEL,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    })
    Corner(sidebar, 10)
    -- right separator
    New("Frame", {
        Parent           = sidebar,
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.BORDER,
        BorderSizePixel  = 0,
        ZIndex           = 4,
    })

    -- Brand
    local brandLbl = New("TextLabel", {
        Parent               = sidebar,
        Text                 = "ALTER",
        TextSize             = 11,
        Font                 = Enum.Font.GothamBlack,
        TextColor3           = C.T_DIM,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, 0, 0, 48),
        Position             = UDim2.new(0, 0, 0, 0),
        TextXAlignment       = Enum.TextXAlignment.Center,
        ZIndex               = 4,
        TextTransparency     = 1,
    })

    -- divider
    New("Frame", {
        Parent           = sidebar,
        Size             = UDim2.new(1, -24, 0, 1),
        Position         = UDim2.new(0, 12, 0, 48),
        BackgroundColor3 = C.BORDER,
        BorderSizePixel  = 0,
        ZIndex           = 4,
    })

    local tabScroll = New("ScrollingFrame", {
        Parent                 = sidebar,
        Size                   = UDim2.new(1, 0, 1, -58),
        Position               = UDim2.new(0, 0, 0, 56),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 0,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        ZIndex                 = 4,
        ClipsDescendants       = true,
    })
    Pad(tabScroll, 6, 6, 8, 8)
    local tabLL = List(tabScroll, Enum.FillDirection.Vertical, 3)
    tabLL.Changed:Connect(function()
        tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabLL.AbsoluteContentSize.Y + 12)
    end)

    --> Content
    local content = New("Frame", {
        Parent               = bodyFrame,
        Size                 = UDim2.new(1, -SIDE_W, 1, 0),
        Position             = UDim2.new(0, SIDE_W, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants     = true,
        ZIndex               = 2,
    })

    -- Open animation
    task.defer(function()
        Tween(root, TI.SPRING, {
            Size                 = UDim2.new(0, WIN_W, 0, WIN_H),
            BackgroundTransparency = 0,
        })
        task.delay(0.15, function()
            Tween(accentLine, TweenInfo.new(0.7, Enum.EasingStyle.Expo, Enum.EasingDirection.Out),
                {Size = UDim2.new(1, 0, 0, 1)})
            Tween(hubLbl,    TI.SLOW, {TextTransparency = 0})
            Tween(brandLbl,  TI.SLOW, {TextTransparency = 0})
        end)
    end)

    --> Window object
    local winObj = {
        _tabs    = {},
        _cfg     = configSys,
    }

    -- Expose config system
    winObj.Config = configSys

    -->══════════════════════════════════════
    --> :Tab()
    -->══════════════════════════════════════
    function winObj:Tab(name)
        local tabObj = { _name = name, _sections = {} }

        local btn = New("TextButton", {
            Parent               = tabScroll,
            Text                 = "",
            Size                 = UDim2.new(1, 0, 0, 36),
            BackgroundColor3     = C.ELEM,
            BackgroundTransparency = 1,
            AutoButtonColor      = false,
            ZIndex               = 5,
        })
        Corner(btn, 7)

        -- active indicator
        local ind = New("Frame", {
            Parent           = btn,
            Size             = UDim2.new(0, 2, 0, 0),
            Position         = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint      = Vector2.new(0, 0.5),
            BackgroundColor3 = C.WHITE,
            BorderSizePixel  = 0,
            ZIndex           = 6,
        })
        Corner(ind, 1)

        -- dot
        local dot = New("Frame", {
            Parent           = btn,
            Size             = UDim2.new(0, 4, 0, 4),
            Position         = UDim2.new(0, 12, 0.5, -2),
            BackgroundColor3 = C.T_DIM,
            BorderSizePixel  = 0,
            ZIndex           = 6,
        })
        Corner(dot, 2)

        local lbl = New("TextLabel", {
            Parent               = btn,
            Text                 = name,
            TextSize             = 12,
            Font                 = Enum.Font.GothamMedium,
            TextColor3           = C.T_DIM,
            BackgroundTransparency = 1,
            Size                 = UDim2.new(1, -28, 1, 0),
            Position             = UDim2.new(0, 24, 0, 0),
            TextXAlignment       = Enum.TextXAlignment.Left,
            ZIndex               = 6,
        })

        -- panel
        local panel = New("ScrollingFrame", {
            Parent                 = content,
            Size                   = UDim2.new(1, 0, 1, 0),
            Position               = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ScrollBarThickness     = 2,
            ScrollBarImageColor3   = C.BORDER,
            CanvasSize             = UDim2.new(0, 0, 0, 0),
            Visible                = false,
            ZIndex                 = 2,
        })
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
                    Tween(t._btn, TI.FAST, {BackgroundTransparency=1})
                    Tween(t._ind, TI.FAST, {Size=UDim2.new(0,2,0,0)})
                    Tween(t._dot, TI.FAST, {BackgroundColor3=C.T_DIM})
                    Tween(t._lbl, TI.FAST, {TextColor3=C.T_DIM, Font=Enum.Font.GothamMedium})
                end
            end
            panel.Visible    = true
            panel.Position   = UDim2.new(0, 8, 0, 0)
            Tween(panel, TI.MED, {Position = UDim2.new(0, 0, 0, 0)})
            Tween(btn,   TI.MED, {BackgroundTransparency=0, BackgroundColor3=C.ELEM})
            Tween(ind,   TI.SPRING, {Size=UDim2.new(0,2,0,20)})
            Tween(dot,   TI.FAST,   {BackgroundColor3=C.WHITE})
            Tween(lbl,   TI.FAST,   {TextColor3=C.T_PRI, Font=Enum.Font.GothamBold})
        end

        btn.MouseButton1Click:Connect(function()
            activate()
            local mp = UIS:GetMouseLocation()
            Ripple(btn, mp.X, mp.Y)
        end)
        btn.MouseEnter:Connect(function()
            if panel.Visible then return end
            Tween(btn, TI.FAST, {BackgroundTransparency=0.85, BackgroundColor3=C.ELEM})
            Tween(lbl, TI.FAST, {TextColor3=C.T_SEC})
        end)
        btn.MouseLeave:Connect(function()
            if panel.Visible then return end
            Tween(btn, TI.FAST, {BackgroundTransparency=1})
            Tween(lbl, TI.FAST, {TextColor3=C.T_DIM})
        end)

        if #self._tabs == 1 then activate() end

        -->══════════════════════════════════
        --> :Section()
        -->══════════════════════════════════
        function tabObj:Section(secName)
            local secObj      = {}
            local collapsed   = false
            local naturalH    = 0

            local wrap = New("Frame", {
                Parent               = panel,
                Size                 = UDim2.new(1, 0, 0, 36),
                BackgroundColor3     = C.CARD,
                BackgroundTransparency = 1,
                AutomaticSize        = Enum.AutomaticSize.Y,
                ClipsDescendants     = true,
                ZIndex               = 3,
            })
            Corner(wrap, 8)
            Stroke(wrap, C.BORDER, 1)

            -- slide in
            task.defer(function()
                Tween(wrap, TI.SPRING, {BackgroundTransparency = 0})
            end)

            -- Header
            local hdr = New("Frame", {
                Parent           = wrap,
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = C.ELEM,
                ZIndex           = 4,
            })
            Corner(hdr, 8)
            New("Frame", {
                Parent           = hdr,
                Size             = UDim2.new(1, 0, 0.5, 0),
                Position         = UDim2.new(0, 0, 0.5, 0),
                BackgroundColor3 = C.ELEM,
                BorderSizePixel  = 0,
                ZIndex           = 4,
            })

            -- left stripe
            local stripe = New("Frame", {
                Parent           = hdr,
                Size             = UDim2.new(0, 2, 0, 16),
                Position         = UDim2.new(0, 8, 0.5, -8),
                BackgroundColor3 = C.WHITE,
                BorderSizePixel  = 0,
                ZIndex           = 5,
            })
            Corner(stripe, 1)

            local secLbl = New("TextLabel", {
                Parent               = hdr,
                Text                 = string.upper(secName or "Section"),
                TextSize             = 10,
                Font                 = Enum.Font.GothamBold,
                TextColor3           = C.T_SEC,
                BackgroundTransparency = 1,
                Size                 = UDim2.new(1, -48, 1, 0),
                Position             = UDim2.new(0, 18, 0, 0),
                TextXAlignment       = Enum.TextXAlignment.Left,
                ZIndex               = 5,
            })

            -- Collapse btn
            local collBtn = New("TextButton", {
                Parent               = hdr,
                Text                 = "−",
                TextSize             = 14,
                Font                 = Enum.Font.GothamBold,
                TextColor3           = C.T_DIM,
                BackgroundTransparency = 1,
                Size                 = UDim2.new(0, 32, 1, 0),
                Position             = UDim2.new(1, -34, 0, 0),
                AutoButtonColor      = false,
                ZIndex               = 6,
            })

            -- Element container
            local elems = New("Frame", {
                Parent               = wrap,
                Size                 = UDim2.new(1, 0, 0, 0),
                Position             = UDim2.new(0, 0, 0, 36),
                BackgroundTransparency = 1,
                AutomaticSize        = Enum.AutomaticSize.Y,
                ZIndex               = 4,
            })
            Pad(elems, 8, 10, 10, 10)
            List(elems, Enum.FillDirection.Vertical, 6)

            -- Collapse logic
            local function doCollapse()
                collapsed = not collapsed
                if collapsed then
                    naturalH = wrap.AbsoluteSize.Y
                    wrap.AutomaticSize = Enum.AutomaticSize.None
                    Tween(wrap,    TI.MED, {Size = UDim2.new(1, 0, 0, 36)})
                    Tween(collBtn, TI.MED, {Rotation = 45, TextColor3 = C.T_DIM})
                    Tween(stripe,  TI.FAST, {BackgroundColor3 = C.T_DIM})
                    Tween(secLbl,  TI.FAST, {TextColor3 = C.T_DIM})
                else
                    Tween(wrap,    TI.MED, {Size = UDim2.new(1, 0, 0, naturalH)})
                    Tween(collBtn, TI.MED, {Rotation = 0,  TextColor3 = C.T_DIM})
                    Tween(stripe,  TI.FAST, {BackgroundColor3 = C.WHITE})
                    Tween(secLbl,  TI.FAST, {TextColor3 = C.T_SEC})
                    task.delay(0.25, function()
                        wrap.AutomaticSize = Enum.AutomaticSize.Y
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

            -- click header to collapse
            local hdrHit = New("TextButton", {
                Parent               = hdr,
                Text                 = "",
                Size                 = UDim2.new(1, -36, 1, 0),
                BackgroundTransparency = 1,
                ZIndex               = 7,
            })
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
                local btn = New("TextButton", {
                    Parent           = elems,
                    Text             = "",
                    Size             = UDim2.new(1, 0, 0, 36),
                    BackgroundColor3 = C.ELEM,
                    AutoButtonColor  = false,
                    ZIndex           = 5,
                })
                Corner(btn, 7)
                Stroke(btn, C.BORDER, 1)

                -- left glow
                local glow = New("Frame", {
                    Parent           = btn,
                    Size             = UDim2.new(0, 2, 0, 0),
                    Position         = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint      = Vector2.new(0, 0.5),
                    BackgroundColor3 = C.WHITE,
                    BorderSizePixel  = 0,
                    ZIndex           = 6,
                })
                Corner(glow, 1)

                local bLbl = New("TextLabel", {
                    Parent               = btn,
                    Text                 = lbl or "Button",
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamMedium,
                    TextColor3           = C.T_SEC,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(1, -44, 1, 0),
                    Position             = UDim2.new(0, 14, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    ZIndex               = 6,
                })

                local arr = New("TextLabel", {
                    Parent               = btn,
                    Text                 = "›",
                    TextSize             = 16,
                    Font                 = Enum.Font.GothamBold,
                    TextColor3           = C.T_DIM,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0, 26, 1, 0),
                    Position             = UDim2.new(1, -30, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Center,
                    ZIndex               = 6,
                })

                btn.MouseEnter:Connect(function()
                    Tween(btn,  TI.FAST, {BackgroundColor3 = C.HOVER})
                    Tween(bLbl, TI.FAST, {TextColor3 = C.T_PRI})
                    Tween(arr,  TI.MED,  {TextColor3 = C.WHITE, Position=UDim2.new(1,-24,0,0)})
                    Tween(glow, TI.MED,  {Size=UDim2.new(0,2,0.65,0)})
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn,  TI.FAST, {BackgroundColor3 = C.ELEM})
                    Tween(bLbl, TI.FAST, {TextColor3 = C.T_SEC})
                    Tween(arr,  TI.FAST, {TextColor3 = C.T_DIM, Position=UDim2.new(1,-30,0,0)})
                    Tween(glow, TI.FAST, {Size=UDim2.new(0,2,0,0)})
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
            --> TOGGLE  (fully animated)
            -->══════════════════════════════
            function secObj:Toggle(lbl, cb)
                local obj   = {}
                local state = false

                local row = New("Frame", {
                    Parent           = elems,
                    Size             = UDim2.new(1, 0, 0, 36),
                    BackgroundColor3 = C.ELEM,
                    ZIndex           = 5,
                })
                Corner(row, 7)
                Stroke(row, C.BORDER, 1)

                local tLbl = New("TextLabel", {
                    Parent               = row,
                    Text                 = lbl or "Toggle",
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamMedium,
                    TextColor3           = C.T_SEC,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(1, -62, 1, 0),
                    Position             = UDim2.new(0, 12, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    ZIndex               = 6,
                })

                -- Track
                local track = New("Frame", {
                    Parent           = row,
                    Size             = UDim2.new(0, 38, 0, 20),
                    Position         = UDim2.new(1, -50, 0.5, -10),
                    BackgroundColor3 = C.ACC_OFF,
                    ZIndex           = 6,
                })
                Corner(track, 10)
                Stroke(track, C.BORDER, 1)

                -- inner fill (grows left→right when on)
                local trackFill = New("Frame", {
                    Parent               = track,
                    Size                 = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3     = C.WHITE,
                    BackgroundTransparency = 0.3,
                    ZIndex               = 7,
                })
                Corner(trackFill, 10)

                -- Thumb
                local thumb = New("Frame", {
                    Parent           = track,
                    Size             = UDim2.new(0, 14, 0, 14),
                    Position         = UDim2.new(0, 3, 0.5, -7),
                    BackgroundColor3 = C.T_DIM,
                    ZIndex           = 8,
                })
                Corner(thumb, 7)

                -- thumb inner shine
                local shine = New("Frame", {
                    Parent               = thumb,
                    Size                 = UDim2.new(0, 4, 0, 4),
                    Position             = UDim2.new(0, 2, 0, 2),
                    BackgroundColor3     = C.WHITE,
                    BackgroundTransparency = 0.6,
                    ZIndex               = 9,
                })
                Corner(shine, 2)

                local function setToggle(v, silent)
                    state = v
                    if state then
                        -- ON
                        Tween(track,     TI.MED,    {BackgroundColor3 = Color3.fromRGB(50,50,50)})
                        Tween(trackFill, TI.MED,    {Size = UDim2.new(1, 0, 1, 0)})
                        Tween(thumb,     TI.SPRING, {
                            Position         = UDim2.new(0, 21, 0.5, -7),
                            BackgroundColor3 = C.WHITE,
                            Size             = UDim2.new(0, 14, 0, 14),
                        })
                        Tween(shine,     TI.MED,    {BackgroundTransparency = 0.7, BackgroundColor3 = C.WHITE})
                        Tween(tLbl,      TI.FAST,   {TextColor3 = C.T_PRI, Font = Enum.Font.GothamBold})
                        Tween(row,       TI.FAST,   {BackgroundColor3 = Color3.fromRGB(32,32,32)})
                    else
                        -- OFF
                        Tween(track,     TI.MED,    {BackgroundColor3 = C.ACC_OFF})
                        Tween(trackFill, TI.MED,    {Size = UDim2.new(0, 0, 1, 0)})
                        Tween(thumb,     TI.SPRING, {
                            Position         = UDim2.new(0, 3, 0.5, -7),
                            BackgroundColor3 = C.T_DIM,
                            Size             = UDim2.new(0, 14, 0, 14),
                        })
                        Tween(shine,     TI.FAST,   {BackgroundTransparency = 0.8})
                        Tween(tLbl,      TI.FAST,   {TextColor3 = C.T_SEC, Font = Enum.Font.GothamMedium})
                        Tween(row,       TI.FAST,   {BackgroundColor3 = C.ELEM})
                    end
                    if not silent and cb then task.spawn(cb, state) end
                end

                local hit = New("TextButton", {
                    Parent               = row,
                    Text                 = "",
                    Size                 = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ZIndex               = 9,
                })
                hit.MouseButton1Click:Connect(function()
                    -- squeeze thumb on click
                    Tween(thumb, TI.SNAP, {Size = UDim2.new(0, 18, 0, 12)})
                    task.delay(0.1, function()
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

                -- Register with config
                configSys:Register(lbl or "toggle", obj.Get, function(v) obj:Set(v) end)

                return obj
            end

            -->══════════════════════════════
            --> SLIDER
            -->══════════════════════════════
            function secObj:Slider(lbl, min, max, default, cb)
                local obj = {}
                min     = min     or 0
                max     = max     or 100
                default = math.clamp(default or min, min, max)
                local val = default

                local wrap = New("Frame", {
                    Parent           = elems,
                    Size             = UDim2.new(1, 0, 0, 54),
                    BackgroundColor3 = C.ELEM,
                    ZIndex           = 5,
                })
                Corner(wrap, 7)
                Stroke(wrap, C.BORDER, 1)
                Pad(wrap, 8, 10, 12, 12)

                local topRow = New("Frame", {
                    Parent               = wrap,
                    Size                 = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    ZIndex               = 6,
                })

                New("TextLabel", {
                    Parent               = topRow,
                    Text                 = lbl or "Slider",
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamMedium,
                    TextColor3           = C.T_PRI,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0.65, 0, 1, 0),
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    ZIndex               = 7,
                })

                local valBox = New("TextLabel", {
                    Parent               = topRow,
                    Text                 = tostring(val),
                    TextSize             = 11,
                    Font                 = Enum.Font.GothamBold,
                    TextColor3           = C.T_DIM,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0.35, 0, 1, 0),
                    Position             = UDim2.new(0.65, 0, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Right,
                    ZIndex               = 7,
                })

                local trackBg = New("Frame", {
                    Parent           = wrap,
                    Size             = UDim2.new(1, 0, 0, 4),
                    Position         = UDim2.new(0, 0, 1, -14),
                    BackgroundColor3 = C.BORDER,
                    ZIndex           = 6,
                })
                Corner(trackBg, 2)

                local fill = New("Frame", {
                    Parent           = trackBg,
                    Size             = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = C.WHITE,
                    ZIndex           = 7,
                })
                Corner(fill, 2)

                -- tick marks
                local tickCount = 5
                for i = 0, tickCount do
                    New("Frame", {
                        Parent           = trackBg,
                        Size             = UDim2.new(0, 1, 0, 6),
                        Position         = UDim2.new(i/tickCount, 0, 0.5, -3),
                        AnchorPoint      = Vector2.new(0.5, 0),
                        BackgroundColor3 = C.BORDER,
                        BorderSizePixel  = 0,
                        ZIndex           = 7,
                    })
                end

                local thumb = New("Frame", {
                    Parent           = trackBg,
                    Size             = UDim2.new(0, 14, 0, 14),
                    Position         = UDim2.new(0, -7, 0.5, -7),
                    BackgroundColor3 = C.WHITE,
                    ZIndex           = 9,
                })
                Corner(thumb, 7)
                Stroke(thumb, C.BORDER_LT, 1)

                local function update(v, silent)
                    val = math.clamp(math.floor(v + 0.5), min, max)
                    local pct = (val - min) / (max - min)
                    valBox.Text = tostring(val)
                    Tween(fill,  TI.FAST, {Size = UDim2.new(pct, 0, 1, 0)})
                    Tween(thumb, TI.FAST, {Position = UDim2.new(pct, -7, 0.5, -7)})
                    if not silent and cb then task.spawn(cb, val) end
                end
                update(default, true)

                local dragging = false
                local function fromInput(inp)
                    local rel = math.clamp(
                        (inp.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X,
                        0, 1)
                    update(min + rel * (max - min))
                end

                trackBg.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        Tween(thumb, TI.FAST, {Size=UDim2.new(0,18,0,18), Position=UDim2.new((val-min)/(max-min),-9,0.5,-9)})
                        Tween(wrap,  TI.FAST, {BackgroundColor3=C.HOVER})
                        fromInput(i)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch) then
                        dragging = false
                        Tween(thumb, TI.SPRING, {
                            Size     = UDim2.new(0,14,0,14),
                            Position = UDim2.new((val-min)/(max-min),-7,0.5,-7),
                        })
                        Tween(wrap, TI.FAST, {BackgroundColor3=C.ELEM})
                    end
                end)
                UIS.InputChanged:Connect(function(i)
                    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch) then
                        fromInput(i)
                    end
                end)

                wrap.MouseEnter:Connect(function()
                    if not dragging then
                        Tween(wrap, TI.FAST, {BackgroundColor3=C.HOVER})
                    end
                end)
                wrap.MouseLeave:Connect(function()
                    if not dragging then
                        Tween(wrap, TI.FAST, {BackgroundColor3=C.ELEM})
                    end
                end)

                function obj:Set(v) update(v, true) end
                function obj:Get() return val end

                configSys:Register(lbl or "slider", obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            -->══════════════════════════════
            --> DROPDOWN
            -->══════════════════════════════
            function secObj:Dropdown(lbl, opts, cb)
                local obj = {} ; local sel = nil ; local open = false
                opts = opts or {}

                local ddWrap = New("Frame", {
                    Parent           = elems,
                    Size             = UDim2.new(1, 0, 0, 36),
                    BackgroundColor3 = C.ELEM,
                    ClipsDescendants = false,
                    ZIndex           = 10,
                })
                Corner(ddWrap, 7)
                Stroke(ddWrap, C.BORDER, 1)

                local ddHdr = New("TextButton", {
                    Parent               = ddWrap,
                    Text                 = "",
                    Size                 = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    AutoButtonColor      = false,
                    ZIndex               = 11,
                })

                New("TextLabel", {
                    Parent               = ddHdr,
                    Text                 = lbl or "Dropdown",
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamMedium,
                    TextColor3           = C.T_SEC,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0.5, 0, 1, 0),
                    Position             = UDim2.new(0, 12, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    ZIndex               = 12,
                })

                local selLbl = New("TextLabel", {
                    Parent               = ddHdr,
                    Text                 = "None",
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamBold,
                    TextColor3           = C.T_PRI,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0.42, 0, 1, 0),
                    Position             = UDim2.new(0.5, 0, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Right,
                    ZIndex               = 12,
                })

                local chev = New("TextLabel", {
                    Parent               = ddHdr,
                    Text                 = "⌄",
                    TextSize             = 14,
                    Font                 = Enum.Font.GothamBold,
                    TextColor3           = C.T_DIM,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0, 22, 1, 0),
                    Position             = UDim2.new(1, -24, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Center,
                    ZIndex               = 12,
                })

                local ddPanel = New("Frame", {
                    Parent           = ddWrap,
                    Size             = UDim2.new(1, 0, 0, 0),
                    Position         = UDim2.new(0, 0, 0, 40),
                    BackgroundColor3 = C.CARD,
                    ClipsDescendants = true,
                    ZIndex           = 20,
                    Visible          = false,
                })
                Corner(ddPanel, 7)
                Stroke(ddPanel, C.BORDER, 1)

                local ddScroll = New("ScrollingFrame", {
                    Parent                 = ddPanel,
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    ScrollBarThickness     = 2,
                    ScrollBarImageColor3   = C.BORDER,
                    CanvasSize             = UDim2.new(0, 0, 0, 0),
                    ZIndex                 = 21,
                })
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
                        local isSelected = (opt == sel)
                        local ob = New("TextButton", {
                            Parent           = ddScroll,
                            Text             = tostring(opt),
                            TextSize         = 12,
                            Font             = isSelected and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                            TextColor3       = isSelected and C.T_PRI or C.T_SEC,
                            BackgroundColor3 = isSelected and C.ELEM  or C.CARD,
                            Size             = UDim2.new(1, 0, 0, 28),
                            AutoButtonColor  = false,
                            TextXAlignment   = Enum.TextXAlignment.Left,
                            ZIndex           = 22,
                        })
                        Pad(ob, 0, 0, 8, 0)
                        Corner(ob, 5)

                        if isSelected then
                            New("TextLabel", {
                                Parent               = ob,
                                Text                 = "✓",
                                TextSize             = 10,
                                Font                 = Enum.Font.GothamBold,
                                TextColor3           = C.WHITE,
                                BackgroundTransparency = 1,
                                Size                 = UDim2.new(0, 20, 1, 0),
                                Position             = UDim2.new(1, -22, 0, 0),
                                TextXAlignment       = Enum.TextXAlignment.Center,
                                ZIndex               = 23,
                            })
                        end

                        ob.MouseEnter:Connect(function()
                            if not isSelected then
                                Tween(ob, TI.FAST, {BackgroundColor3 = C.HOVER})
                            end
                        end)
                        ob.MouseLeave:Connect(function()
                            if not isSelected then
                                Tween(ob, TI.FAST, {BackgroundColor3 = C.CARD})
                            end
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
                        Tween(ddPanel,  TI.MED, {Size = UDim2.new(1, 0, 0, h)})
                        Tween(chev,     TI.MED, {Rotation = 180})
                        Tween(ddWrap,   TI.FAST, {BackgroundColor3 = C.HOVER})
                    else
                        Tween(ddPanel,  TI.MED, {Size = UDim2.new(1, 0, 0, 0)})
                        Tween(chev,     TI.MED, {Rotation = 0})
                        Tween(ddWrap,   TI.FAST, {BackgroundColor3 = C.ELEM})
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
                    if not open then Tween(ddWrap, TI.FAST, {BackgroundColor3=C.HOVER}) end
                end)
                ddHdr.MouseLeave:Connect(function()
                    if not open then Tween(ddWrap, TI.FAST, {BackgroundColor3=C.ELEM}) end
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

                configSys:Register(lbl or "dropdown", obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            -->══════════════════════════════
            --> BIND
            -->══════════════════════════════
            function secObj:Bind(lbl, default, cb)
                local obj = {} ; local bound = default ; local binding = false

                local row = New("Frame", {
                    Parent           = elems,
                    Size             = UDim2.new(1, 0, 0, 36),
                    BackgroundColor3 = C.ELEM,
                    ZIndex           = 5,
                })
                Corner(row, 7)
                Stroke(row, C.BORDER, 1)

                New("TextLabel", {
                    Parent               = row,
                    Text                 = lbl or "Bind",
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamMedium,
                    TextColor3           = C.T_SEC,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0.55, 0, 1, 0),
                    Position             = UDim2.new(0, 12, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    ZIndex               = 6,
                })

                local function kn(k)
                    if not k then return "—" end
                    return tostring(k):gsub("Enum.KeyCode.", "")
                end

                local pill = New("TextButton", {
                    Parent           = row,
                    Text             = kn(bound),
                    TextSize         = 10,
                    Font             = Enum.Font.GothamBold,
                    TextColor3       = C.T_SEC,
                    BackgroundColor3 = C.CARD,
                    Size             = UDim2.new(0, 72, 0, 22),
                    Position         = UDim2.new(1, -82, 0.5, -11),
                    AutoButtonColor  = false,
                    ZIndex           = 6,
                })
                Corner(pill, 5)
                Stroke(pill, C.BORDER, 1)

                local function setBind(k, silent)
                    bound   = k
                    binding = false
                    pill.Text       = kn(k)
                    Tween(pill, TI.FAST, {
                        TextColor3       = C.T_SEC,
                        BackgroundColor3 = C.CARD,
                        TextTransparency = 0,
                    })
                    if not silent and cb then task.spawn(cb, k) end
                end

                local pulseConn
                pill.MouseButton1Click:Connect(function()
                    if binding then return end
                    binding = true
                    pill.Text = "···"
                    Tween(pill, TI.FAST, {
                        TextColor3       = C.WHITE,
                        BackgroundColor3 = C.ELEM,
                    })
                    if pulseConn then pulseConn:Disconnect() end
                    pulseConn = RunService.Heartbeat:Connect(function(dt)
                        if not binding then
                            pulseConn:Disconnect(); return
                        end
                    end)
                    -- pulse opacity
                    task.spawn(function()
                        while binding do
                            Tween(pill, TI.SINE, {TextTransparency = 0.6})
                            task.wait(0.3)
                            if not binding then break end
                            Tween(pill, TI.SINE, {TextTransparency = 0})
                            task.wait(0.3)
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
                    Tween(row, TI.FAST, {BackgroundColor3=C.HOVER})
                end)
                row.MouseLeave:Connect(function()
                    Tween(row, TI.FAST, {BackgroundColor3=C.ELEM})
                end)

                function obj:Set(k) setBind(k, true) end
                function obj:Get() return bound end

                configSys:Register(lbl or "bind", function()
                    return bound and tostring(bound):gsub("Enum.KeyCode.","") or "None"
                end, function(v)
                    pcall(function()
                        setBind(Enum.KeyCode[v], true)
                    end)
                end)

                return obj
            end

            return secObj
        end -- :Section

        return tabObj
    end -- :Tab

    return winObj
end -- :Window

return AlterLib
