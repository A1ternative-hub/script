--============================================================================
-- ALTER UI Library v7.0
-- Drop-in replacement for v6.9. Public API is unchanged.
--
-- Fixed in this version:
--  * Tw() no longer silently dropped properties (UIStroke.Color, UIScale.Scale,
--    Rotation on non-tween types, CanvasPosition...). Half the hover/press
--    animations in v6.9 never actually ran because of the hardcoded whitelist.
--  * Tweens on the same property now cancel each other instead of fighting,
--    which is what caused toggles/sections to "stick" mid-animation.
--  * UIScale moved off the ScreenGui and onto the window root, so the scale
--    slider scales the window in place instead of throwing it off screen and
--    desyncing dragging. Window is clamped on screen after any scale/drag/rotate.
--  * Floating toggle button is always visible, draggable, edge-snapping.
--  * All labels default to single-line + truncate (v6.9 wrapped every label,
--    which is why rows looked broken on narrow phones).
--  * Every metric (row height, font size, switch size, paddings) derives from a
--    single metrics table that adapts to phone vs desktop.
--  * Sliders/dropdowns disable panel scrolling while dragging on touch.
--  * Notifications use a layout-safe holder so the slide-in actually plays.
--  * Global input connections replaced with one shared dispatcher (v6.9 leaked
--    a new UserInputService connection per slider/bind/window, forever).
--  * Window reacts to viewport resize / device rotation.
--============================================================================

local AlterLib = {}
AlterLib.__index = AlterLib
AlterLib.Version = "7.0"

--=========================== Services =======================================
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HTTP    = game:GetService("HttpService")
local LP      = Players.LocalPlayer

local startTime = os.time()

--=========================== Palette ========================================
local C = {
    BG = Color3.fromRGB(10, 10, 10), PANEL = Color3.fromRGB(18, 18, 18), CARD = Color3.fromRGB(26, 26, 26),
    ELEM = Color3.fromRGB(32, 32, 32), HOVER = Color3.fromRGB(45, 45, 45), ACTIVE = Color3.fromRGB(60, 60, 60),
    BORDER = Color3.fromRGB(40, 40, 40), BORDER_LT = Color3.fromRGB(80, 80, 80), WHITE = Color3.fromRGB(255, 255, 255),
    BLACK = Color3.fromRGB(0, 0, 0), T_PRI = Color3.fromRGB(255, 255, 255), T_SEC = Color3.fromRGB(170, 170, 170),
    T_DIM = Color3.fromRGB(100, 100, 100), ACC_OFF = Color3.fromRGB(30, 30, 30),
    ON = Color3.fromRGB(70, 70, 70), ON_ROW = Color3.fromRGB(40, 40, 40),
}
AlterLib.Colors = C

--=========================== Tween presets ==================================
local TI = {
    SNAP   = TweenInfo.new(0.02, Enum.EasingStyle.Linear),
    FAST   = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    HOVER  = TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    MED    = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    SLOW   = TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    SPRING = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    FOLD   = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    SINE   = TweenInfo.new(0.30, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
}

--=========================== Viewport / device ==============================
local function Viewport()
    local cam = workspace.CurrentCamera
    if cam then return cam.ViewportSize end
    return Vector2.new(1280, 720)
end

local IS_MOB do
    local touch = UIS.TouchEnabled
    local mouse = UIS.MouseEnabled
    local kb    = UIS.KeyboardEnabled
    IS_MOB = touch and not (mouse and kb)
    if (not IS_MOB) and touch and Viewport().X < 720 then IS_MOB = true end
end
AlterLib.IsMobile = IS_MOB

-- Single source of truth for every size in the library.
local MET = {
    TITLE_H   = IS_MOB and 48 or 44,
    ROW_H     = IS_MOB and 40 or 32,
    TAB_H     = IS_MOB and 44 or 34,
    SEC_HDR_H = IS_MOB and 40 or 36,
    SIDE_W    = IS_MOB and 168 or 148,
    SIDE_FOOT = IS_MOB and 88 or 78,

    F_TITLE = IS_MOB and 15 or 14,
    F_ROW   = IS_MOB and 13 or 11,
    F_SUB   = IS_MOB and 12 or 10,
    F_TINY  = IS_MOB and 10 or 9,

    SW_W  = IS_MOB and 42 or 34,
    SW_H  = IS_MOB and 24 or 18,
    PILL_W = IS_MOB and 62 or 56,
    PILL_H = IS_MOB and 24 or 20,

    PAD    = IS_MOB and 10 or 12,
    GAP    = IS_MOB and 7 or 8,
    DD_MAX = IS_MOB and 200 or 160,
    FAB    = IS_MOB and 46 or 38,
}

--=========================== Filesystem shims ===============================
-- These only exist in some environments; guard every call so the library
-- still loads (config just becomes a no-op) when they're missing.
local FS = {
    isfolder = isfolder, makefolder = makefolder, isfile = isfile,
    writefile = writefile, readfile = readfile, delfile = delfile, listfiles = listfiles,
}
local FS_OK = (FS.isfolder and FS.makefolder and FS.writefile and FS.readfile) and true or false

--=========================== Shared input dispatcher ========================
-- v6.9 created a fresh UIS connection for every slider, bind and window and
-- never disconnected them. One dispatcher, handlers can unregister.
local Hub = {Began = {}, Changed = {}, Ended = {}}

local function hubAdd(list, fn)
    table.insert(list, fn)
    return function()
        for i = #list, 1, -1 do
            if list[i] == fn then table.remove(list, i) break end
        end
    end
end

local function hubFire(list, input, gp)
    for i = #list, 1, -1 do
        local fn = list[i]
        if fn then
            local ok, err = pcall(fn, input, gp)
            if not ok then warn("[Alter] input handler error: " .. tostring(err)) end
        end
    end
end

UIS.InputBegan:Connect(function(i, gp)   hubFire(Hub.Began, i, gp)   end)
UIS.InputChanged:Connect(function(i, gp) hubFire(Hub.Changed, i, gp) end)
UIS.InputEnded:Connect(function(i, gp)   hubFire(Hub.Ended, i, gp)   end)

local function OnBegan(fn)   return hubAdd(Hub.Began, fn)   end
local function OnChanged(fn) return hubAdd(Hub.Changed, fn) end
local function OnEnded(fn)   return hubAdd(Hub.Ended, fn)   end

local function isPointer(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end
local function isDrag(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

--=========================== Tween helper ===================================
local TweenReg = setmetatable({}, {__mode = "k"})

local function Tw(obj, ti, props)
    if typeof(obj) ~= "Instance" or not obj.Parent then return end

    -- Keep only properties this instance actually has.
    local safe = {}
    for k, v in pairs(props) do
        if pcall(function() return obj[k] end) then safe[k] = v end
    end
    if not next(safe) then return end

    local reg = TweenReg[obj]
    if not reg then reg = {}; TweenReg[obj] = reg end

    -- Cancel whatever is currently animating these same properties.
    for k in pairs(safe) do
        local prev = reg[k]
        if prev then pcall(function() prev:Cancel() end); reg[k] = nil end
    end

    local ok, tween = pcall(function() return TS:Create(obj, ti, safe) end)
    if not ok or not tween then
        -- Not tweenable (Visible, Text, ...) - apply instantly instead of dropping it.
        for k, v in pairs(safe) do pcall(function() obj[k] = v end) end
        return
    end

    for k in pairs(safe) do reg[k] = tween end
    tween.Completed:Connect(function()
        for k, t in pairs(reg) do if t == tween then reg[k] = nil end end
    end)
    tween:Play()
    return tween
end

-- Instant set, same shape as Tw.
local function Set(obj, props)
    if typeof(obj) ~= "Instance" then return end
    for k, v in pairs(props) do pcall(function() obj[k] = v end) end
end

--=========================== Instance builders ==============================
local function MakeFrame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    if props then for k, v in pairs(props) do pcall(function() f[k] = v end) end end
    f.Parent = parent
    return f
end

local function MakeButton(parent, props)
    local b = Instance.new("TextButton")
    b.BackgroundTransparency = 1
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Active = true
    b.Text = ""
    b.Font = Enum.Font.GothamMedium
    b.TextSize = MET.F_ROW
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextTruncate = Enum.TextTruncate.AtEnd
    if props then for k, v in pairs(props) do pcall(function() b[k] = v end) end end
    b.Parent = parent
    return b
end

-- NOTE: TextWrapped defaults to FALSE now. v6.9 wrapped every label, so any
-- row label that didn't fit turned into two clipped lines on mobile.
local function MakeLabel(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font = Enum.Font.GothamMedium
    l.TextSize = MET.F_ROW
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = false
    l.TextTruncate = Enum.TextTruncate.AtEnd
    if props then for k, v in pairs(props) do pcall(function() l[k] = v end) end end
    l.Parent = parent
    return l
end

local function MakeTextBox(parent, props)
    local t = Instance.new("TextBox")
    t.BackgroundTransparency = 1
    t.BorderSizePixel = 0
    t.Font = Enum.Font.GothamMedium
    t.TextSize = MET.F_SUB
    t.TextColor3 = C.T_PRI
    t.PlaceholderColor3 = C.T_DIM
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ClearTextOnFocus = false
    t.TextTruncate = Enum.TextTruncate.AtEnd
    if props then for k, v in pairs(props) do pcall(function() t[k] = v end) end end
    t.Parent = parent
    return t
end

local function MakeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function MakeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.BORDER
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
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

local function MakeScrollFrame(parent, props)
    local s = Instance.new("ScrollingFrame")
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.ScrollBarThickness = IS_MOB and 3 or 2
    s.ScrollingDirection = Enum.ScrollingDirection.Y
    s.CanvasSize = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.ScrollBarImageColor3 = C.BORDER_LT
    s.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    if props then for k, v in pairs(props) do pcall(function() s[k] = v end) end end
    s.Parent = parent
    return s
end

local function MakeSG(id)
    local name = "ALTER_" .. id
    pcall(function() if CoreGui:FindFirstChild(name) then CoreGui:FindFirstChild(name):Destroy() end end)
    pcall(function() if LP.PlayerGui and LP.PlayerGui:FindFirstChild(name) then LP.PlayerGui:FindFirstChild(name):Destroy() end end)

    local function build()
        local s = Instance.new("ScreenGui")
        s.Name = name
        s.ResetOnSpawn = false
        s.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        s.IgnoreGuiInset = true
        s.DisplayOrder = 999
        return s
    end

    local sg
    pcall(function()
        local s = build()
        s.Parent = CoreGui
        if s.Parent == CoreGui then sg = s end
    end)
    if not sg then
        pcall(function()
            local s = build()
            s.Parent = gethui()
            if s.Parent then sg = s end
        end)
    end
    if not sg then
        pcall(function()
            local s = build()
            s.Parent = LP:WaitForChild("PlayerGui")
            sg = s
        end)
    end
    return sg
end

--=========================== Interaction helpers ============================
-- Mobile has no hover, so on touch we drive the same visuals from press/release.
local function Hover(btn, onEnter, onLeave)
    if not btn then return end
    if IS_MOB then
        btn.MouseButton1Down:Connect(function() if onEnter then onEnter() end end)
        btn.MouseButton1Up:Connect(function()
            task.delay(0.14, function() if onLeave then onLeave() end end)
        end)
        btn.MouseLeave:Connect(function() if onLeave then onLeave() end end)
    else
        btn.MouseEnter:Connect(function() if onEnter then onEnter() end end)
        btn.MouseLeave:Connect(function() if onLeave then onLeave() end end)
    end
end

-- iOS-style press: scale dip + light flash. Now actually works, because Tw
-- no longer drops UIScale.Scale.
local function Ripple(host)
    if not host or not host.Parent then return end

    local scale = host:FindFirstChildOfClass("UIScale")
    if not scale then
        scale = Instance.new("UIScale")
        scale.Scale = 1
        scale.Parent = host
    end
    Tw(scale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.965})
    task.delay(0.10, function()
        Tw(scale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
    end)

    local radius = 8
    local corner = host:FindFirstChildOfClass("UICorner")
    if corner then radius = corner.CornerRadius.Offset end

    local flash = Instance.new("Frame")
    flash.Size = UDim2.fromScale(1, 1)
    flash.BackgroundColor3 = C.WHITE
    flash.BackgroundTransparency = 0.9
    flash.ZIndex = host.ZIndex + 12
    flash.BorderSizePixel = 0
    flash.Active = false
    flash.Parent = host
    MakeCorner(flash, radius)

    Tw(flash, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
    task.delay(0.28, function() pcall(function() flash:Destroy() end) end)
end

-- Generic pointer drag bound to the shared dispatcher.
-- onMove(delta, input), returns a disconnect function.
local function BindDrag(handle, onBegin, onMove, onEnd)
    local active, startPos = false, Vector2.zero
    local dcChanged, dcEnded

    handle.InputBegan:Connect(function(i)
        if not isPointer(i) then return end
        active = true
        startPos = Vector2.new(i.Position.X, i.Position.Y)
        if onBegin then onBegin(i) end
    end)

    dcChanged = OnChanged(function(i)
        if not active or not isDrag(i) then return end
        local now = Vector2.new(i.Position.X, i.Position.Y)
        if onMove then onMove(now - startPos, i) end
    end)

    dcEnded = OnEnded(function(i)
        if not active or not isPointer(i) then return end
        active = false
        if onEnd then onEnd(i) end
    end)

    return function()
        if dcChanged then dcChanged() end
        if dcEnded then dcEnded() end
    end
end

-- Track-based value scrubbing (sliders). Works with UIScale because both
-- AbsolutePosition and input.Position are in real screen pixels.
local function BindTrack(hit, track, apply, onStart, onStop)
    local dragging = false
    local dcChanged, dcEnded

    local function fromInput(i)
        local w = track.AbsoluteSize.X
        if w < 1 then return end
        local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / w, 0, 1)
        apply(rel)
    end

    hit.InputBegan:Connect(function(i)
        if not isPointer(i) then return end
        dragging = true
        if onStart then onStart() end
        fromInput(i)
    end)

    dcChanged = OnChanged(function(i)
        if not dragging or not isDrag(i) then return end
        fromInput(i)
    end)

    dcEnded = OnEnded(function(i)
        if not dragging or not isPointer(i) then return end
        dragging = false
        if onStop then onStop() end
    end)

    return function()
        if dcChanged then dcChanged() end
        if dcEnded then dcEnded() end
    end
end

--=========================== Config system ==================================
local ConfigSys = {}
ConfigSys.__index = ConfigSys

function ConfigSys.new(folder)
    local s = setmetatable({}, ConfigSys)
    s.folder  = folder or "AlterHub"
    s.entries = {}
    s._ready  = false
    if FS_OK then
        pcall(function()
            if not FS.isfolder(s.folder) then FS.makefolder(s.folder) end
        end)
    end
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
    table.insert(self.entries, {key = key, get = getter, set = setter})
end

function ConfigSys:MarkReady() self._ready = true end

function ConfigSys:WaitForReady(timeout)
    timeout = timeout or 10
    local elapsed = 0
    while not self._ready and elapsed < timeout do
        task.wait(0.1)
        elapsed += 0.1
    end
end

function ConfigSys:Save(name)
    if not FS_OK then return false, "no filesystem" end
    if not name or name == "" then return false, "empty name" end
    local data = {}
    for _, e in ipairs(self.entries) do
        local ok, v = pcall(e.get)
        if ok then data[e.key] = v end
    end
    local ok, json = pcall(function() return HTTP:JSONEncode(data) end)
    if not ok then return false, "encode failed" end
    local path = self.folder .. "/" .. name .. ".json"
    pcall(function() if FS.isfile and FS.isfile(path) and FS.delfile then FS.delfile(path) end end)
    local wok, werr = pcall(function() FS.writefile(path, json) end)
    return wok, werr
end

function ConfigSys:Load(name)
    if not FS_OK then return false end
    local path = self.folder .. "/" .. name .. ".json"
    local ok, raw = pcall(function() return FS.readfile(path) end)
    if not ok or not raw then return false end
    local ok2, data = pcall(function() return HTTP:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return false end
    for _, e in ipairs(self.entries) do
        if data[e.key] ~= nil then pcall(e.set, data[e.key]) end
    end
    return true
end

function ConfigSys:AutoLoadByPlaceId(map)
    task.spawn(function()
        self:WaitForReady(10)
        task.wait(0.5)
        local pid = tostring(game.PlaceId)
        if map and map[pid] and self:Load(map[pid]) then
            print("[Alter] PlaceId autoloaded:", map[pid])
        else
            self:Load("default")
        end
    end)
end

function ConfigSys:AutoLoadByGameId(map)
    task.spawn(function()
        self:WaitForReady(10)
        task.wait(0.5)
        local gid = tostring(game.GameId)
        if map and map[gid] and self:Load(map[gid]) then
            print("[Alter] GameId autoloaded:", map[gid])
        else
            self:Load("default")
        end
    end)
end

function ConfigSys:Delete(name)
    if not FS_OK or not FS.delfile then return false end
    local path = self.folder .. "/" .. name .. ".json"
    return pcall(function() FS.delfile(path) end)
end

function ConfigSys:List()
    local out = {}
    if not FS_OK or not FS.listfiles then return out end
    pcall(function()
        for _, f in ipairs(FS.listfiles(self.folder)) do
            local n = f:match("[/\\]([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end)
    return out
end

--=========================== Notifications ==================================
local _nSG, _nHolder
local _nCards = {}

local function NotifWidth()
    return math.clamp(Viewport().X - 24, 200, IS_MOB and 300 or 290)
end

local function EnsureNotif()
    if _nSG and _nSG.Parent then
        local w = NotifWidth()
        _nHolder.Size = UDim2.new(0, w, 1, -20)
        _nHolder.Position = UDim2.new(1, -(w + 12), 0, 10)
        return
    end
    _nSG = MakeSG("NOTIF")
    local w = NotifWidth()
    _nHolder = MakeFrame(_nSG, {
        Size     = UDim2.new(0, w, 1, -20),
        Position = UDim2.new(1, -(w + 12), 0, 10),
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
    local duration = tonumber(cfg.Duration) or 3.5

    -- The list layout owns the holder's position; the card inside it is free
    -- to animate. v6.9 tweened the layout-controlled frame, so the slide-in
    -- was immediately overwritten by the layout.
    local holder = MakeFrame(_nHolder, {
        Size         = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex       = 201,
        LayoutOrder  = math.floor(os.clock() * 100),
    })

    local card = MakeFrame(holder, {
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundColor3       = C.PANEL,
        BackgroundTransparency = 0,
        Position               = UDim2.new(1, 24, 0, 0),
        ZIndex                 = 202,
    })
    MakeCorner(card, 8)
    MakeStroke(card, C.BORDER, 1)
    MakePadding(card, 10, 12, 12, 12)
    local cl = MakeList(card, Enum.FillDirection.Vertical, 3)
    cl.SortOrder = Enum.SortOrder.LayoutOrder

    local title = MakeLabel(card, {
        Text = cfg.Title or "Notification",
        TextSize = MET.F_ROW + 1,
        Font = Enum.Font.GothamBold,
        TextColor3 = C.T_PRI,
        Size = UDim2.new(1, 0, 0, MET.F_ROW + 8),
        LayoutOrder = 1,
        ZIndex = 203,
    })

    local msgText = tostring(cfg.Message or "")
    if msgText ~= "" then
        MakeLabel(card, {
            Text = msgText,
            TextSize = MET.F_SUB + 1,
            TextColor3 = C.T_SEC,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            LayoutOrder = 2,
            ZIndex = 203,
        })
    end

    local barHolder = MakeFrame(card, {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = C.BORDER,
        BackgroundTransparency = 0,
        LayoutOrder = 3,
        ZIndex = 203,
    })
    MakeCorner(barHolder, 1)
    local bar = MakeFrame(barHolder, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.WHITE,
        BackgroundTransparency = 0,
        ZIndex = 204,
    })
    MakeCorner(bar, 1)

    table.insert(_nCards, holder)
    if #_nCards > 5 then
        local old = table.remove(_nCards, 1)
        pcall(function() old:Destroy() end)
    end

    Tw(card, TI.SPRING, {Position = UDim2.new(0, 0, 0, 0)})
    task.delay(0.06, function()
        Tw(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)})
    end)

    local function dismiss()
        Tw(card, TI.MED, {Position = UDim2.new(1, 24, 0, 0), BackgroundTransparency = 1})
        for _, d in ipairs(card:GetDescendants()) do
            if d:IsA("TextLabel") then Tw(d, TI.MED, {TextTransparency = 1})
            elseif d:IsA("Frame") then Tw(d, TI.MED, {BackgroundTransparency = 1})
            elseif d:IsA("UIStroke") then Tw(d, TI.MED, {Transparency = 1}) end
        end
        task.delay(0.24, function()
            for i, v in ipairs(_nCards) do if v == holder then table.remove(_nCards, i) break end end
            pcall(function() holder:Destroy() end)
        end)
    end

    -- Tap to dismiss early. Lives on the holder, not the card: the card has a
    -- UIListLayout and would treat a hitbox child as another row.
    local hit = MakeButton(holder, {Size = UDim2.new(1, 0, 1, 0), ZIndex = 210, BackgroundTransparency = 1})
    hit.MouseButton1Click:Connect(dismiss)

    task.delay(duration, dismiss)
end

--=========================== Prompt =========================================
function AlterLib:Prompt(cfg)
    cfg = cfg or {}
    local sg = MakeSG("PROMPT")
    local vp = Viewport()
    local W  = math.min(340, vp.X - 32)
    local H  = IS_MOB and 156 or 142
    local BTN_H = IS_MOB and 38 or 32

    local backdrop = MakeButton(sg, {
        Size                   = UDim2.fromScale(1, 1),
        BackgroundColor3       = C.BLACK,
        BackgroundTransparency = 1,
        ZIndex                 = 100,
    })
    Tw(backdrop, TI.MED, {BackgroundTransparency = 0.6})

    local card = MakeFrame(backdrop, {
        Size                   = UDim2.new(0, W, 0, 0),
        Position               = UDim2.fromScale(0.5, 0.5),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = C.PANEL,
        BackgroundTransparency = 0,
        ZIndex                 = 101,
    })
    card.ClipsDescendants = true
    MakeCorner(card, 8)
    MakeStroke(card, C.BORDER_LT, 1)

    local hdr = MakeFrame(card, {
        Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = C.CARD,
        BackgroundTransparency = 0, ZIndex = 102,
    })
    MakeCorner(hdr, 8)
    MakeFrame(hdr, {
        Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = C.CARD, BackgroundTransparency = 0, ZIndex = 102,
    })
    MakeLabel(hdr, {
        Text = cfg.Title or "Prompt", TextSize = MET.F_ROW + 2, Font = Enum.Font.GothamBold,
        TextColor3 = C.T_PRI, Size = UDim2.new(1, -28, 1, 0),
        Position = UDim2.new(0, 14, 0, 0), ZIndex = 103,
    })
    MakeLabel(card, {
        Text = cfg.Message or "", TextSize = MET.F_ROW, TextColor3 = C.T_SEC,
        Size = UDim2.new(1, -28, 0, H - 44 - BTN_H - 24), Position = UDim2.new(0, 14, 0, 52),
        TextWrapped = true, TextTruncate = Enum.TextTruncate.None,
        TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 103,
    })

    local bRow = MakeFrame(card, {
        Size = UDim2.new(1, -28, 0, BTN_H), Position = UDim2.new(0, 14, 1, -(BTN_H + 12)), ZIndex = 102,
    })
    MakeList(bRow, Enum.FillDirection.Horizontal, 8)

    local closing = false
    local function closePrompt(cb)
        if closing then return end
        closing = true
        Tw(card, TI.MED, {Size = UDim2.new(0, W, 0, 0)})
        Tw(backdrop, TI.MED, {BackgroundTransparency = 1})
        task.delay(0.22, function()
            if cb then pcall(cb) end
            pcall(function() sg:Destroy() end)
        end)
    end

    local function PBtn(txt, primary, cb)
        local b = MakeButton(bRow, {
            Text = txt, TextSize = MET.F_ROW, Font = Enum.Font.GothamBold,
            TextColor3 = primary and C.BLACK or C.T_SEC,
            BackgroundColor3 = primary and C.WHITE or C.ELEM,
            BackgroundTransparency = 0,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.new(0.5, -4, 1, 0), ZIndex = 103,
        })
        MakeCorner(b, 6)
        if not primary then MakeStroke(b, C.BORDER, 1) end
        b.MouseButton1Click:Connect(function() Ripple(b); closePrompt(cb) end)
        Hover(b,
            function() Tw(b, TI.HOVER, {BackgroundColor3 = primary and Color3.fromRGB(220, 220, 220) or C.HOVER}) end,
            function() Tw(b, TI.HOVER, {BackgroundColor3 = primary and C.WHITE or C.ELEM}) end)
    end

    PBtn(cfg.NoText  or "Cancel",  false, cfg.No)
    PBtn(cfg.YesText or "Confirm", true,  cfg.Yes)
    backdrop.MouseButton1Click:Connect(function() closePrompt(nil) end)
    Tw(card, TI.SPRING, {Size = UDim2.new(0, W, 0, H)})
end

--=========================== Window =========================================
function AlterLib:Window(cfg)
    cfg = cfg or {}

    local cfgSys = ConfigSys.new(cfg.Folder or "AlterHub")
    local sg     = MakeSG(cfg.Folder or "WIN")

    --== Sizing, recomputed on viewport change
    local WIN_W, WIN_H, SIDE_W
    local function computeSize()
        local vp = Viewport()
        if IS_MOB then
            WIN_W = math.floor(math.min(vp.X - 16, 380))
            WIN_H = math.floor(math.min(vp.Y - 90, 460))
        else
            WIN_W = math.floor(math.min(vp.X - 40, 620))
            WIN_H = math.floor(math.min(vp.Y - 80, 490))
        end
        SIDE_W = math.floor(math.min(MET.SIDE_W, WIN_W * 0.46))
    end
    computeSize()

    local TITLE_H = MET.TITLE_H
    local ROW_H   = MET.ROW_H

    local currentScale = 1
    local scaleMin, scaleMax = 0.6, 1.6
    local function CurScale() return currentScale end

    --== Root
    local root = MakeFrame(sg, {
        Size                   = UDim2.new(0, WIN_W, 0, 0),
        Position               = UDim2.new(0, IS_MOB and 8 or 70, 0, IS_MOB and 8 or 55),
        BackgroundColor3       = C.BG,
        BackgroundTransparency = 1,
        ZIndex                 = 1,
        Active                 = true,
    })
    root.ClipsDescendants = true            -- was false: content spilled during fold
    MakeCorner(root, 10)
    MakeStroke(root, C.BORDER, 1)

    -- UIScale lives on the window, not the ScreenGui. On the ScreenGui it
    -- scaled from the screen origin, which pushed the window off-screen and
    -- broke drag math.
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1
    uiScale.Parent = root

    local minimised = false
    local visible   = true
    local uiToggleKey = Enum.KeyCode.RightShift
    local destroyed = false
    local cleanup = {}

    local function targetHeight()
        return minimised and TITLE_H or WIN_H
    end

    local function clampToScreen()
        local vp = Viewport()
        local w  = WIN_W * currentScale
        local h  = TITLE_H * currentScale
        local x  = math.clamp(root.Position.X.Offset, -(w - 70), vp.X - 70)
        local y  = math.clamp(root.Position.Y.Offset, 0, math.max(0, vp.Y - h))
        root.Position = UDim2.fromOffset(x, y)
    end

    --== Title bar
    local titleBar = MakeFrame(root, {
        Size = UDim2.new(1, 0, 0, TITLE_H), BackgroundColor3 = C.PANEL,
        BackgroundTransparency = 0, ZIndex = 4, Active = true,
    })
    MakeCorner(titleBar, 10)
    MakeFrame(titleBar, {
        Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = C.PANEL, BackgroundTransparency = 0, ZIndex = 4,
    })

    local titleLeft = IS_MOB and (MET.TAB_H + 12) or 14
    local ctrlW     = IS_MOB and 76 or 62

    MakeLabel(titleBar, {
        Text = cfg.Name or "ALTER", TextSize = MET.F_TITLE, Font = Enum.Font.GothamBlack,
        TextColor3 = C.T_PRI, RichText = true,
        Size = UDim2.new(1, -(titleLeft + ctrlW + 14), 0, MET.F_TITLE + 10),
        Position = UDim2.new(0, titleLeft, 0, IS_MOB and 7 or 6), ZIndex = 5,
    })
    MakeLabel(titleBar, {
        Text = "PlaceId: " .. tostring(game.PlaceId), TextSize = MET.F_TINY, TextColor3 = C.T_DIM,
        Size = UDim2.new(1, -(titleLeft + ctrlW + 14), 0, 12),
        Position = UDim2.new(0, titleLeft, 1, -16), ZIndex = 5,
    })

    local ctrlF = MakeFrame(titleBar, {
        Size = UDim2.new(0, ctrlW, 0, IS_MOB and 28 or 22),
        Position = UDim2.new(1, -(ctrlW + 8), 0.5, IS_MOB and -14 or -11), ZIndex = 5,
    })
    local ctrlList = MakeList(ctrlF, Enum.FillDirection.Horizontal, 6)
    ctrlList.HorizontalAlignment = Enum.HorizontalAlignment.Right

    --== Window body containers (declared before the functions that use them)
    local bodyFrame = MakeFrame(root, {
        Size = UDim2.new(1, 0, 1, -TITLE_H), Position = UDim2.new(0, 0, 0, TITLE_H), ZIndex = 2,
    })
    bodyFrame.ClipsDescendants = true

    --== Show / hide
    local function setVisible(state, instant)
        visible = state
        if visible then
            root.Visible = true
            if instant then
                root.Size = UDim2.new(0, WIN_W, 0, targetHeight())
                root.BackgroundTransparency = 0
            else
                Tw(root, TI.SPRING, {Size = UDim2.new(0, WIN_W, 0, targetHeight()), BackgroundTransparency = 0})
            end
            clampToScreen()
        else
            Tw(root, TI.MED, {Size = UDim2.new(0, WIN_W, 0, 0), BackgroundTransparency = 1})
            task.delay(0.22, function()
                if not visible then root.Visible = false end
            end)
        end
    end

    local function toggleUIVisibility() setVisible(not visible) end

    --== Floating toggle button: always on screen, draggable, snaps to an edge
    local fabSG = MakeSG("FLOATBTN")
    local fab = MakeButton(fabSG, {
        Text = "A",
        TextSize = MET.F_TITLE,
        Font = Enum.Font.GothamBlack,
        TextColor3 = C.T_PRI,
        BackgroundColor3 = C.PANEL,
        BackgroundTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromOffset(MET.FAB, MET.FAB),
        Position = UDim2.new(0, 12, 0.5, -MET.FAB / 2),
        ZIndex = 300,
    })
    MakeCorner(fab, MET.FAB / 2)
    local fabStroke = MakeStroke(fab, C.BORDER_LT, 1)
    local fabDot = MakeFrame(fab, {
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.new(1, -9, 0, 3),
        BackgroundColor3 = C.WHITE,
        BackgroundTransparency = 0,
        ZIndex = 301,
    })
    MakeCorner(fabDot, 3)

    local fabMoved = false
    local function snapFab()
        local vp = Viewport()
        local x  = fab.Position.X.Offset
        local y  = math.clamp(fab.Position.Y.Offset, 6, math.max(6, vp.Y - MET.FAB - 6))
        local snapLeft = (x + MET.FAB / 2) < vp.X / 2
        local targetX  = snapLeft and 12 or (vp.X - MET.FAB - 12)
        Tw(fab, TI.SPRING, {Position = UDim2.fromOffset(targetX, y)})
    end

    do
        local startOffset = Vector2.zero
        table.insert(cleanup, BindDrag(fab,
            function()
                fabMoved = false
                startOffset = Vector2.new(fab.Position.X.Offset, fab.Position.Y.Offset)
            end,
            function(delta)
                if delta.Magnitude > 6 then fabMoved = true end
                if not fabMoved then return end
                fab.Position = UDim2.fromOffset(startOffset.X + delta.X, startOffset.Y + delta.Y)
            end,
            function()
                if fabMoved then snapFab() end
            end))
    end

    fab.MouseButton1Click:Connect(function()
        if fabMoved then fabMoved = false return end
        Ripple(fab)
        toggleUIVisibility()
    end)
    Hover(fab,
        function() Tw(fab, TI.HOVER, {BackgroundColor3 = C.HOVER}) end,
        function() Tw(fab, TI.HOVER, {BackgroundColor3 = C.PANEL}) end)

    -- Dot reflects open/closed state.
    local function syncFab()
        Tw(fabDot, TI.HOVER, {BackgroundTransparency = visible and 0 or 0.75})
        Tw(fabStroke, TI.HOVER, {Color = visible and C.BORDER_LT or C.BORDER})
    end

    local _setVisible = setVisible
    setVisible = function(state, instant)
        _setVisible(state, instant)
        syncFab()
    end
    toggleUIVisibility = function() setVisible(not visible) end
    syncFab()

    --== Keyboard toggle
    table.insert(cleanup, OnBegan(function(input, gp)
        if gp or destroyed then return end
        if input.KeyCode == uiToggleKey then toggleUIVisibility() end
    end))

    --== Title bar controls
    local function performClose()
        destroyed = true
        Tw(root, TI.MED, {Size = UDim2.new(0, WIN_W, 0, 0), BackgroundTransparency = 1})
        Tw(fab, TI.MED, {BackgroundTransparency = 1, TextTransparency = 1})
        task.delay(0.26, function()
            for _, dc in ipairs(cleanup) do pcall(dc) end
            pcall(function() sg:Destroy() end)
            pcall(function() fabSG:Destroy() end)
        end)
    end

    local function CtrlBtn(sym, action)
        local b = MakeButton(ctrlF, {
            Text = sym, TextSize = MET.F_SUB + 1, Font = Enum.Font.GothamBold,
            TextColor3 = C.T_DIM, BackgroundColor3 = C.ELEM,
            BackgroundTransparency = 0, TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromOffset(IS_MOB and 32 or 26, IS_MOB and 26 or 22), ZIndex = 6,
        })
        MakeCorner(b, 5)
        MakeStroke(b, C.BORDER, 1)
        b.MouseButton1Click:Connect(function() Ripple(b); action() end)
        Hover(b,
            function() Tw(b, TI.HOVER, {BackgroundColor3 = C.HOVER, TextColor3 = C.T_PRI}) end,
            function() Tw(b, TI.HOVER, {BackgroundColor3 = C.ELEM, TextColor3 = C.T_DIM}) end)
        return b
    end

    local minBtn
    minBtn = CtrlBtn("-", function()
        minimised = not minimised
        bodyFrame.Visible = true
        Tw(root, TI.FOLD, {Size = UDim2.new(0, WIN_W, 0, targetHeight())})
        Tw(minBtn, TI.FOLD, {Rotation = minimised and 90 or 0})
        task.delay(TI.FOLD.Time, function()
            if minimised then bodyFrame.Visible = false end
            clampToScreen()
        end)
    end)
    CtrlBtn("x", performClose)

    --== Window dragging (clamped, scale-aware)
    do
        local startOffset = Vector2.zero
        table.insert(cleanup, BindDrag(titleBar,
            function() startOffset = Vector2.new(root.Position.X.Offset, root.Position.Y.Offset) end,
            function(delta)
                root.Position = UDim2.fromOffset(startOffset.X + delta.X, startOffset.Y + delta.Y)
            end,
            function() clampToScreen() end))
    end

    --== Sidebar
    local sidebar = MakeFrame(bodyFrame, {
        Size = UDim2.new(0, SIDE_W, 1, 0), BackgroundColor3 = C.PANEL,
        BackgroundTransparency = 0, ZIndex = 30,
    })
    sidebar.ClipsDescendants = true
    MakeCorner(sidebar, 10)
    MakeFrame(sidebar, {
        Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0),
        BackgroundColor3 = C.PANEL, BackgroundTransparency = 0, ZIndex = 30,
    })
    MakeFrame(sidebar, {
        Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = C.PANEL,
        BackgroundTransparency = 0, ZIndex = 30,
    })
    MakeFrame(sidebar, {
        Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = C.BORDER, BackgroundTransparency = 0, ZIndex = 31,
    })

    MakeLabel(sidebar, {
        Text = "ALTER", TextSize = MET.F_SUB, Font = Enum.Font.GothamBlack,
        TextColor3 = C.T_DIM, TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, 0, 0, 44), ZIndex = 31,
    })
    MakeFrame(sidebar, {
        Size = UDim2.new(1, -18, 0, 1), Position = UDim2.new(0, 9, 0, 44),
        BackgroundColor3 = C.BORDER, BackgroundTransparency = 0, ZIndex = 31,
    })

    local tabScroll = MakeScrollFrame(sidebar, {
        Size = UDim2.new(1, 0, 1, -(52 + MET.SIDE_FOOT)), Position = UDim2.new(0, 0, 0, 52),
        ScrollBarThickness = 0, ZIndex = 31,
    })
    MakePadding(tabScroll, 4, 8, 8, 8)
    MakeList(tabScroll, Enum.FillDirection.Vertical, 4)

    --== Sidebar footer: scale slider + timer + discord
    local sideBottom = MakeFrame(sidebar, {
        Size = UDim2.new(1, 0, 0, MET.SIDE_FOOT),
        Position = UDim2.new(0, 0, 1, -MET.SIDE_FOOT),
        ZIndex = 31,
    })
    MakePadding(sideBottom, 4, 8, 12, 14)

    local scaleRow = MakeFrame(sideBottom, {
        Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 0), ZIndex = 32,
    })
    local scaleLbl = MakeLabel(scaleRow, {
        Text = "Scale: 100%", TextSize = MET.F_TINY, TextColor3 = C.T_DIM,
        Size = UDim2.new(1, 0, 0, 12), ZIndex = 33,
    })
    local scaleTrack = MakeFrame(scaleRow, {
        Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = C.BORDER, BackgroundTransparency = 0, ZIndex = 33,
    })
    MakeCorner(scaleTrack, 2)
    local scaleFill = MakeFrame(scaleTrack, {
        Size = UDim2.new(0.5, 0, 1, 0), BackgroundColor3 = C.WHITE,
        BackgroundTransparency = 0, ZIndex = 34,
    })
    MakeCorner(scaleFill, 2)
    local thSz = IS_MOB and 14 or 11
    local scaleThumb = MakeFrame(scaleTrack, {
        Size = UDim2.fromOffset(thSz, thSz),
        Position = UDim2.new(0.5, -thSz / 2, 0.5, -thSz / 2),
        BackgroundColor3 = C.WHITE, BackgroundTransparency = 0, ZIndex = 36,
    })
    MakeCorner(scaleThumb, thSz / 2)
    MakeStroke(scaleThumb, C.BORDER_LT, 1)

    local function applyScale(v, instant)
        currentScale = math.clamp(v, scaleMin, scaleMax)
        local pct = (currentScale - scaleMin) / (scaleMax - scaleMin)
        scaleLbl.Text = "Scale: " .. math.floor(currentScale * 100 + 0.5) .. "%"
        if instant then
            scaleFill.Size = UDim2.new(pct, 0, 1, 0)
            scaleThumb.Position = UDim2.new(pct, -thSz / 2, 0.5, -thSz / 2)
        else
            Tw(scaleFill, TI.FAST, {Size = UDim2.new(pct, 0, 1, 0)})
            Tw(scaleThumb, TI.FAST, {Position = UDim2.new(pct, -thSz / 2, 0.5, -thSz / 2)})
        end
        uiScale.Scale = currentScale
        clampToScreen()
    end
    applyScale(1, true)

    local scaleHit = MakeButton(scaleRow, {
        Size = UDim2.new(1, 0, 0, IS_MOB and 30 or 24), Position = UDim2.new(0, 0, 0, 10), ZIndex = 37,
    })
    table.insert(cleanup, BindTrack(scaleHit, scaleTrack,
        function(rel) applyScale(scaleMin + rel * (scaleMax - scaleMin)) end,
        function() Tw(scaleThumb, TI.FAST, {Size = UDim2.fromOffset(thSz + 3, thSz + 3)}) end,
        function() Tw(scaleThumb, TI.SPRING, {Size = UDim2.fromOffset(thSz, thSz)}) end))

    -- Double-tap the label to reset to 100%.
    local resetHit = MakeButton(scaleRow, {Size = UDim2.new(1, 0, 0, 12), ZIndex = 38})
    local lastTap = 0
    resetHit.MouseButton1Click:Connect(function()
        local now = os.clock()
        if now - lastTap < 0.4 then applyScale(1) end
        lastTap = now
    end)

    local bottomRow = MakeFrame(sideBottom, {
        Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 1, -26), ZIndex = 32,
    })
    local timerLbl = MakeLabel(bottomRow, {
        Text = "00:00:00", TextSize = MET.F_TINY + 1, TextColor3 = C.T_DIM,
        Size = UDim2.new(0.5, -2, 1, 0), ZIndex = 32,
    })

    task.spawn(function()
        while task.wait(1) do
            if destroyed or not timerLbl.Parent then break end
            local elapsed = os.time() - startTime
            timerLbl.Text = string.format("%02d:%02d:%02d",
                math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), elapsed % 60)
        end
    end)

    local dscBtn = MakeButton(bottomRow, {
        Text = "DISCORD", TextSize = MET.F_TINY, Font = Enum.Font.GothamBold,
        TextColor3 = C.T_SEC, BackgroundColor3 = C.ELEM, BackgroundTransparency = 0,
        Size = UDim2.new(0.5, 0, 0, IS_MOB and 24 or 20),
        Position = UDim2.new(0.5, 0, 0.5, IS_MOB and -12 or -10),
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 32,
    })
    MakeCorner(dscBtn, 4)
    MakeStroke(dscBtn, C.BORDER, 1)
    Hover(dscBtn,
        function() Tw(dscBtn, TI.HOVER, {BackgroundColor3 = C.HOVER}) end,
        function() Tw(dscBtn, TI.HOVER, {BackgroundColor3 = C.ELEM}) end)
    dscBtn.MouseButton1Click:Connect(function()
        Ripple(dscBtn)
        local link = cfg.Discord or "https://discord.gg/5xcttz2uvH"
        local clip = setclipboard or toclipboard
        if clip then
            local ok = pcall(clip, link)
            if ok then
                AlterLib:Notify({Title = "Discord", Message = "Invite copied to clipboard.", Duration = 3})
                return
            end
        end
        AlterLib:Notify({Title = "Discord", Message = link, Duration = 6})
    end)

    --== Content area
    local contentArea = MakeFrame(bodyFrame, {
        Size = UDim2.new(1, IS_MOB and 0 or -SIDE_W, 1, 0),
        Position = UDim2.new(0, IS_MOB and 0 or SIDE_W, 0, 0), ZIndex = 2,
    })
    contentArea.ClipsDescendants = true

    --== Mobile drawer
    local sidebarOpen = not IS_MOB
    local scrim
    local function setSidebarState(state)
        if not IS_MOB then return end
        sidebarOpen = state
        if sidebarOpen then
            sidebar.Visible = true
            scrim.Visible = true
            Tw(scrim, TI.FOLD, {BackgroundTransparency = 0.45})
            Tw(sidebar, TI.FOLD, {Size = UDim2.new(0, SIDE_W, 1, 0)})
        else
            Tw(scrim, TI.FOLD, {BackgroundTransparency = 1})
            Tw(sidebar, TI.FOLD, {Size = UDim2.new(0, 0, 1, 0)})
            task.delay(TI.FOLD.Time, function()
                if not sidebarOpen then
                    sidebar.Visible = false
                    scrim.Visible = false
                end
            end)
        end
    end

    if IS_MOB then
        sidebar.Size = UDim2.new(0, 0, 1, 0)
        sidebar.Visible = false

        scrim = MakeButton(bodyFrame, {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.BLACK,
            BackgroundTransparency = 1, ZIndex = 29,
        })
        scrim.Visible = false
        scrim.MouseButton1Click:Connect(function() setSidebarState(false) end)
        sidebar.ZIndex = 30

        local navBtn = MakeButton(titleBar, {
            Text = "=", TextSize = 18, Font = Enum.Font.GothamBold,
            TextColor3 = C.T_PRI, BackgroundColor3 = C.ELEM, BackgroundTransparency = 0,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromOffset(MET.TAB_H - 8, MET.TAB_H - 8),
            Position = UDim2.new(0, 8, 0.5, -(MET.TAB_H - 8) / 2), ZIndex = 6,
        })
        MakeCorner(navBtn, 6)
        MakeStroke(navBtn, C.BORDER, 1)
        Hover(navBtn,
            function() Tw(navBtn, TI.HOVER, {BackgroundColor3 = C.HOVER}) end,
            function() Tw(navBtn, TI.HOVER, {BackgroundColor3 = C.ELEM}) end)
        navBtn.MouseButton1Click:Connect(function()
            Ripple(navBtn)
            setSidebarState(not sidebarOpen)
        end)
    end

    --== Viewport / rotation handling
    do
        local function onResize()
            if destroyed then return end
            computeSize()
            if not IS_MOB then
                contentArea.Size = UDim2.new(1, -SIDE_W, 1, 0)
                contentArea.Position = UDim2.new(0, SIDE_W, 0, 0)
                sidebar.Size = UDim2.new(0, SIDE_W, 1, 0)
            elseif sidebarOpen then
                sidebar.Size = UDim2.new(0, SIDE_W, 1, 0)
            end
            if visible then
                root.Size = UDim2.new(0, WIN_W, 0, targetHeight())
            end
            clampToScreen()
            snapFab()
            EnsureNotif()
        end

        local cam = workspace.CurrentCamera
        if cam then
            local conn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(onResize)
            table.insert(cleanup, function() conn:Disconnect() end)
        end
        local camConn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            local c = workspace.CurrentCamera
            if c then c:GetPropertyChangedSignal("ViewportSize"):Connect(onResize) end
            onResize()
        end)
        table.insert(cleanup, function() camConn:Disconnect() end)
    end

    --== Open animation
    task.defer(function()
        Tw(root, TI.SPRING, {Size = UDim2.new(0, WIN_W, 0, WIN_H), BackgroundTransparency = 0})
        clampToScreen()
    end)

    --========================= Window object ================================
    local winObj = {_tabs = {}, Config = cfgSys}

    function winObj:SetKeybind(key)
        if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
            uiToggleKey = key
        end
    end

    -- Extras (additive, nothing removed)
    function winObj:Toggle() toggleUIVisibility() end
    function winObj:Show() setVisible(true) end
    function winObj:Hide() setVisible(false) end
    function winObj:Destroy() performClose() end
    function winObj:SetScale(v) applyScale(v) end
    function winObj:GetScale() return currentScale end

    --========================= Tabs =========================================
    function winObj:Tab(name)
        local tabObj = {_name = name}

        local btn = MakeButton(tabScroll, {
            Size = UDim2.new(1, 0, 0, MET.TAB_H), BackgroundColor3 = C.ELEM,
            BackgroundTransparency = 1, ZIndex = 35,
        })
        MakeCorner(btn, 6)

        local ind = MakeFrame(btn, {
            Size = UDim2.new(0, 2, 0, 0), Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = C.WHITE,
            BackgroundTransparency = 0, ZIndex = 36,
        })
        MakeCorner(ind, 1)

        local dot = MakeFrame(btn, {
            Size = UDim2.fromOffset(4, 4), Position = UDim2.new(0, 10, 0.5, -2),
            BackgroundColor3 = C.T_DIM, BackgroundTransparency = 0, ZIndex = 36,
        })
        MakeCorner(dot, 2)

        local lbl = MakeLabel(btn, {
            Text = name, TextSize = MET.F_ROW, TextColor3 = C.T_DIM,
            Size = UDim2.new(1, -26, 1, 0), Position = UDim2.new(0, 22, 0, 0), ZIndex = 36,
        })

        local panel = MakeScrollFrame(contentArea, {
            Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = IS_MOB and 3 or 3,
            Visible = false, ZIndex = 2,
        })
        panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
        MakePadding(panel, MET.PAD, MET.PAD, MET.PAD, MET.PAD)
        MakeList(panel, Enum.FillDirection.Vertical, MET.GAP)
        -- Breathing room so the last section isn't glued to the bottom edge.
        MakeFrame(panel, {Size = UDim2.new(1, 0, 0, 4), LayoutOrder = 100000, ZIndex = 2})

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
                    Tw(t._btn, TI.HOVER, {BackgroundTransparency = 1})
                    Tw(t._ind, TI.FAST, {Size = UDim2.new(0, 2, 0, 0)})
                    Tw(t._dot, TI.HOVER, {BackgroundColor3 = C.T_DIM})
                    Tw(t._lbl, TI.HOVER, {TextColor3 = C.T_DIM})
                end
            end
            panel.Visible = true
            panel.Position = UDim2.new(0, 6, 0, 0)
            Tw(panel, TI.MED,    {Position = UDim2.new(0, 0, 0, 0)})
            Tw(btn,   TI.MED,    {BackgroundTransparency = 0, BackgroundColor3 = C.ELEM})
            Tw(ind,   TI.SPRING, {Size = UDim2.new(0, 2, 0, MET.TAB_H * 0.5)})
            Tw(dot,   TI.HOVER,  {BackgroundColor3 = C.WHITE})
            Tw(lbl,   TI.HOVER,  {TextColor3 = C.T_PRI})
            if IS_MOB then setSidebarState(false) end
        end

        tabObj.Activate = activate

        btn.MouseButton1Click:Connect(function() Ripple(btn); activate() end)
        Hover(btn,
            function()
                if panel.Visible then return end
                Tw(btn, TI.HOVER, {BackgroundTransparency = 0.86, BackgroundColor3 = C.ELEM})
                Tw(lbl, TI.HOVER, {TextColor3 = C.T_SEC})
            end,
            function()
                if panel.Visible then return end
                Tw(btn, TI.HOVER, {BackgroundTransparency = 1})
                Tw(lbl, TI.HOVER, {TextColor3 = C.T_DIM})
            end)

        if #self._tabs == 1 then activate() end

        --===================== Sections =====================================
        function tabObj:Section(secName)
            local secObj = {}
            local collapsed = false
            local foldToken = 0

            local wrap = MakeFrame(panel, {
                Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = C.CARD,
                BackgroundTransparency = 0, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 3,
            })
            wrap.ClipsDescendants = true
            MakeCorner(wrap, 8)
            local wrapStroke = MakeStroke(wrap, C.BORDER, 1)

            local hdr = MakeFrame(wrap, {
                Size = UDim2.new(1, 0, 0, MET.SEC_HDR_H), BackgroundColor3 = C.ELEM,
                BackgroundTransparency = 0, ZIndex = 4,
            })
            MakeCorner(hdr, 8)
            local bottomCover = MakeFrame(hdr, {
                Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundColor3 = C.ELEM, BackgroundTransparency = 0, ZIndex = 4,
            })
            local stripe = MakeFrame(hdr, {
                Size = UDim2.fromOffset(2, 14), Position = UDim2.new(0, 8, 0.5, -7),
                BackgroundColor3 = C.WHITE, BackgroundTransparency = 0, ZIndex = 5,
            })
            MakeCorner(stripe, 1)
            MakeLabel(hdr, {
                Text = string.upper(secName or "Section"), TextSize = MET.F_SUB,
                Font = Enum.Font.GothamBold, TextColor3 = C.T_SEC,
                Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 18, 0, 0), ZIndex = 5,
            })
            local collBtn = MakeLabel(hdr, {
                Text = "-", TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = C.T_DIM,
                TextXAlignment = Enum.TextXAlignment.Center,
                Size = UDim2.new(0, 32, 1, 0), Position = UDim2.new(1, -34, 0, 0), ZIndex = 6,
            })

            local elemsWrap = MakeFrame(wrap, {
                Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, MET.SEC_HDR_H),
                AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 4,
            })
            elemsWrap.ClipsDescendants = true

            local elems = MakeFrame(elemsWrap, {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 4,
            })
            MakePadding(elems, 8, 10, 10, 10)
            MakeList(elems, Enum.FillDirection.Vertical, 6)

            -- AbsoluteSize is in real pixels, so divide by the window scale to
            -- get an offset that's correct at any zoom level.
            local function contentHeight()
                return math.max(0, math.floor(elems.AbsoluteSize.Y / math.max(CurScale(), 0.01) + 0.5))
            end

            local function setCollapsed(state)
                collapsed = state
                foldToken += 1
                local token = foldToken
                if collapsed then
                    local h = contentHeight()
                    elemsWrap.AutomaticSize = Enum.AutomaticSize.None
                    elemsWrap.Size = UDim2.new(1, 0, 0, h)
                    Tw(elemsWrap, TI.FOLD, {Size = UDim2.new(1, 0, 0, 0)})
                    Tw(collBtn, TI.FOLD, {Rotation = 90})
                    Tw(stripe, TI.HOVER, {BackgroundColor3 = C.T_DIM})
                    task.delay(TI.FOLD.Time + 0.02, function()
                        if token == foldToken and collapsed then elemsWrap.Visible = false end
                    end)
                else
                    elemsWrap.Visible = true
                    elemsWrap.AutomaticSize = Enum.AutomaticSize.None
                    elemsWrap.Size = UDim2.new(1, 0, 0, 0)
                    Tw(elemsWrap, TI.FOLD, {Size = UDim2.new(1, 0, 0, contentHeight())})
                    Tw(collBtn, TI.FOLD, {Rotation = 0})
                    Tw(stripe, TI.HOVER, {BackgroundColor3 = C.WHITE})
                    task.delay(TI.FOLD.Time + 0.02, function()
                        if token == foldToken and not collapsed then
                            elemsWrap.AutomaticSize = Enum.AutomaticSize.Y
                        end
                    end)
                end
            end

            local hdrHit = MakeButton(hdr, {Size = UDim2.new(1, 0, 1, 0), ZIndex = 7})
            hdrHit.MouseButton1Click:Connect(function()
                Ripple(hdr)
                setCollapsed(not collapsed)
            end)
            Hover(hdrHit,
                function()
                    Tw(hdr, TI.HOVER, {BackgroundColor3 = C.HOVER})
                    Tw(bottomCover, TI.HOVER, {BackgroundColor3 = C.HOVER})
                    Tw(wrapStroke, TI.HOVER, {Color = C.BORDER_LT})
                    Tw(collBtn, TI.HOVER, {TextColor3 = C.WHITE})
                end,
                function()
                    Tw(hdr, TI.HOVER, {BackgroundColor3 = C.ELEM})
                    Tw(bottomCover, TI.HOVER, {BackgroundColor3 = C.ELEM})
                    Tw(wrapStroke, TI.HOVER, {Color = C.BORDER})
                    Tw(collBtn, TI.HOVER, {TextColor3 = C.T_DIM})
                end)

            secObj.SetCollapsed = function(_, v) setCollapsed(v and true or false) end

            --=================== Element primitives =========================
            local function ElemRow(h)
                local f = MakeFrame(elems, {
                    Size = UDim2.new(1, 0, 0, h or ROW_H), BackgroundColor3 = C.ELEM,
                    BackgroundTransparency = 0, ZIndex = 5,
                })
                MakeCorner(f, 7)
                MakeStroke(f, C.BORDER, 1)
                return f
            end

            -- Shared on/off switch used by Toggle and ToggleBind.
            local function MakeSwitch(row, rightOffset)
                local track = MakeFrame(row, {
                    Size = UDim2.fromOffset(MET.SW_W, MET.SW_H),
                    Position = UDim2.new(1, -(MET.SW_W + rightOffset), 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = C.ACC_OFF, BackgroundTransparency = 0, ZIndex = 6,
                })
                MakeCorner(track, MET.SW_H / 2)
                MakeStroke(track, C.BORDER, 1)
                local fill = MakeFrame(track, {
                    Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.WHITE,
                    BackgroundTransparency = 0.4, ZIndex = 7,
                })
                MakeCorner(fill, MET.SW_H / 2)
                local tSz = MET.SW_H - 6
                local thumb = MakeFrame(track, {
                    Size = UDim2.fromOffset(tSz, tSz), Position = UDim2.new(0, 3, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = C.T_DIM,
                    BackgroundTransparency = 0, ZIndex = 8,
                })
                MakeCorner(thumb, tSz / 2)
                return track, fill, thumb, tSz
            end

            local function AnimateSwitch(on, row, lbl, track, fill, thumb, tSz)
                local endX = on and (MET.SW_W - tSz - 3) or 3
                Tw(track, TI.MED, {BackgroundColor3 = on and C.ON or C.ACC_OFF})
                Tw(fill,  TI.MED, {Size = on and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 0, 1, 0)})
                Tw(lbl,   TI.HOVER, {TextColor3 = on and C.T_PRI or C.T_SEC})
                Tw(row,   TI.HOVER, {BackgroundColor3 = on and C.ON_ROW or C.ELEM})
                Tw(thumb, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, endX, 0.5, 0),
                    BackgroundColor3 = on and C.WHITE or C.T_DIM,
                    Size = UDim2.fromOffset(tSz + 2, tSz),
                })
                task.delay(0.13, function()
                    Tw(thumb, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(tSz, tSz),
                    })
                end)
            end

            --=================== Label / Separator ==========================
            function secObj:Label(text, col)
                local obj = {}
                local f = MakeFrame(elems, {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 5,
                })
                local l = MakeLabel(f, {
                    Text = text or "", TextSize = MET.F_ROW, TextColor3 = col or C.T_SEC,
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    TextWrapped = true, TextTruncate = Enum.TextTruncate.None, ZIndex = 6,
                })
                function obj:Set(v) l.Text = tostring(v) end
                function obj:Get() return l.Text end
                return obj
            end

            function secObj:Separator()
                local f = MakeFrame(elems, {Size = UDim2.new(1, 0, 0, 8), ZIndex = 5})
                MakeFrame(f, {
                    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0),
                    BackgroundColor3 = C.BORDER, BackgroundTransparency = 0, ZIndex = 6,
                })
            end

            --=================== Button =====================================
            function secObj:Button(text, cb)
                local row = MakeButton(elems, {
                    BackgroundColor3 = C.ELEM, BackgroundTransparency = 0,
                    Size = UDim2.new(1, 0, 0, ROW_H), ZIndex = 5,
                })
                local rowStrk = MakeStroke(row, C.BORDER, 1)
                MakeCorner(row, 7)
                local glow = MakeFrame(row, {
                    Size = UDim2.new(0, 2, 0, 0), Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = C.WHITE,
                    BackgroundTransparency = 0, ZIndex = 6,
                })
                MakeCorner(glow, 1)
                MakeLabel(row, {
                    Text = text or "Button", TextSize = MET.F_ROW, TextColor3 = C.T_SEC,
                    Size = UDim2.new(1, -38, 1, 0), Position = UDim2.new(0, 12, 0, 0), ZIndex = 6,
                })
                local arrow = MakeLabel(row, {
                    Text = ">", TextSize = MET.F_ROW, Font = Enum.Font.GothamBold, TextColor3 = C.T_DIM,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Size = UDim2.new(0, 22, 1, 0), Position = UDim2.new(1, -26, 0, 0), ZIndex = 6,
                })
                Hover(row,
                    function()
                        Tw(row, TI.HOVER, {BackgroundColor3 = C.HOVER})
                        Tw(glow, TI.MED, {Size = UDim2.new(0, 2, 0.5, 0)})
                        Tw(arrow, TI.HOVER, {TextColor3 = C.WHITE, Position = UDim2.new(1, -24, 0, 0)})
                        Tw(rowStrk, TI.HOVER, {Color = C.BORDER_LT})
                    end,
                    function()
                        Tw(row, TI.HOVER, {BackgroundColor3 = C.ELEM})
                        Tw(glow, TI.HOVER, {Size = UDim2.new(0, 2, 0, 0)})
                        Tw(arrow, TI.HOVER, {TextColor3 = C.T_DIM, Position = UDim2.new(1, -26, 0, 0)})
                        Tw(rowStrk, TI.HOVER, {Color = C.BORDER})
                    end)
                row.MouseButton1Click:Connect(function()
                    Ripple(row)
                    if cb then task.spawn(cb) end
                end)
            end

            --=================== Toggle =====================================
            function secObj:Toggle(text, cb)
                local obj, state = {}, false
                local row = ElemRow(ROW_H)
                local rowStrk = row:FindFirstChildOfClass("UIStroke")
                local tLbl = MakeLabel(row, {
                    Text = text or "Toggle", TextSize = MET.F_ROW, TextColor3 = C.T_SEC,
                    Size = UDim2.new(1, -(MET.SW_W + 32), 1, 0),
                    Position = UDim2.new(0, 12, 0, 0), ZIndex = 6,
                })
                local track, fill, thumb, tSz = MakeSwitch(row, 12)

                local function setState(v, silent)
                    state = v and true or false
                    AnimateSwitch(state, row, tLbl, track, fill, thumb, tSz)
                    if not silent and cb then task.spawn(cb, state) end
                end

                local hit = MakeButton(row, {Size = UDim2.new(1, 0, 1, 0), ZIndex = 15})
                hit.MouseButton1Click:Connect(function()
                    Ripple(row)
                    setState(not state)
                end)
                Hover(hit,
                    function()
                        if rowStrk then Tw(rowStrk, TI.HOVER, {Color = C.BORDER_LT}) end
                        if not state then Tw(row, TI.HOVER, {BackgroundColor3 = C.HOVER}) end
                    end,
                    function()
                        if rowStrk then Tw(rowStrk, TI.HOVER, {Color = C.BORDER}) end
                        if not state then Tw(row, TI.HOVER, {BackgroundColor3 = C.ELEM}) end
                    end)

                function obj:Set(v, silent) setState(v, silent) end
                function obj:Get() return state end
                cfgSys:Register((text or "tog") .. #cfgSys.entries, obj.Get, function(v) obj:Set(v, false) end)
                return obj
            end

            --=================== ToggleBind =================================
            function secObj:ToggleBind(text, defaultKey, cb)
                local obj, state, bound, binding = {}, false, defaultKey, false
                local row = ElemRow(ROW_H)
                local rowStrk = row:FindFirstChildOfClass("UIStroke")
                local rightBlock = MET.SW_W + MET.PILL_W + 24

                local tLbl = MakeLabel(row, {
                    Text = text or "ToggleBind", TextSize = MET.F_ROW, TextColor3 = C.T_SEC,
                    Size = UDim2.new(1, -(rightBlock + 16), 1, 0),
                    Position = UDim2.new(0, 12, 0, 0), ZIndex = 6,
                })

                local function kn(k)
                    if not k then return "-" end
                    return (tostring(k):gsub("Enum.KeyCode.", ""))
                end

                local pill = MakeButton(row, {
                    Text = kn(bound), TextSize = MET.F_TINY, Font = Enum.Font.GothamBold,
                    TextColor3 = C.T_SEC, BackgroundColor3 = C.CARD, BackgroundTransparency = 0,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Size = UDim2.fromOffset(MET.PILL_W, MET.PILL_H),
                    Position = UDim2.new(1, -(MET.SW_W + MET.PILL_W + 20), 0.5, -MET.PILL_H / 2),
                    ZIndex = 16,
                })
                MakeCorner(pill, 5)
                MakeStroke(pill, C.BORDER, 1)
                Hover(pill,
                    function() Tw(pill, TI.HOVER, {BackgroundColor3 = C.HOVER}) end,
                    function() if not binding then Tw(pill, TI.HOVER, {BackgroundColor3 = C.CARD}) end end)

                local track, fill, thumb, tSz = MakeSwitch(row, 12)

                local function setState(v, silent)
                    state = v and true or false
                    AnimateSwitch(state, row, tLbl, track, fill, thumb, tSz)
                    if not silent and cb then task.spawn(cb, state) end
                end

                local function setBind(k, silent)
                    bound = k
                    binding = false
                    pill.Text = kn(k)
                    Tw(pill, TI.HOVER, {TextColor3 = C.T_SEC, BackgroundColor3 = C.CARD, TextTransparency = 0})
                    if not silent and cb then task.spawn(cb, state) end
                end

                pill.MouseButton1Click:Connect(function()
                    Ripple(pill)
                    if binding then return end
                    if not UIS.KeyboardEnabled then
                        AlterLib:Notify({Title = "Keybind", Message = "No keyboard detected on this device.", Duration = 3})
                        return
                    end
                    binding = true
                    pill.Text = "..."
                    Tw(pill, TI.FAST, {TextColor3 = C.WHITE, BackgroundColor3 = C.ELEM})
                    task.spawn(function()
                        while binding do
                            Tw(pill, TI.SINE, {TextTransparency = 0.5}); task.wait(0.3)
                            if not binding then break end
                            Tw(pill, TI.SINE, {TextTransparency = 0}); task.wait(0.3)
                        end
                        Tw(pill, TI.FAST, {TextTransparency = 0})
                    end)
                end)

                table.insert(cleanup, OnBegan(function(i, gp)
                    if gp or destroyed then return end
                    if binding and i.UserInputType == Enum.UserInputType.Keyboard then
                        setBind(i.KeyCode, false)
                    elseif (not binding) and bound and i.KeyCode == bound then
                        setState(not state, false)
                    end
                end))

                local hit = MakeButton(row, {
                    Size = UDim2.new(1, -(rightBlock + 4), 1, 0), ZIndex = 15,
                })
                hit.MouseButton1Click:Connect(function()
                    Ripple(row)
                    setState(not state, false)
                end)
                Hover(hit,
                    function()
                        if rowStrk then Tw(rowStrk, TI.HOVER, {Color = C.BORDER_LT}) end
                        if not state then Tw(row, TI.HOVER, {BackgroundColor3 = C.HOVER}) end
                    end,
                    function()
                        if rowStrk then Tw(rowStrk, TI.HOVER, {Color = C.BORDER}) end
                        if not state then Tw(row, TI.HOVER, {BackgroundColor3 = C.ELEM}) end
                    end)

                function obj:Set(v, silent) setState(v, silent) end
                function obj:SetKey(k, silent) setBind(k, silent) end
                function obj:Get() return state end
                function obj:GetKey() return bound end
                cfgSys:Register((text or "togbind") .. #cfgSys.entries, obj.Get, function(v) obj:Set(v, false) end)
                return obj
            end

            --=================== Slider =====================================
            function secObj:Slider(text, min, max, default, cb, step)
                local obj = {}
                min = min or 0; max = max or 100; step = step or 1
                if max <= min then max = min + 1 end
                default = math.clamp(default or min, min, max)
                local val = default

                local sRowH = IS_MOB and 60 or 52
                local wrap2 = ElemRow(sRowH)
                local rowStrk = wrap2:FindFirstChildOfClass("UIStroke")
                MakePadding(wrap2, 8, 8, 12, 12)

                local topRow = MakeFrame(wrap2, {Size = UDim2.new(1, 0, 0, MET.F_ROW + 6), ZIndex = 6})
                MakeLabel(topRow, {
                    Text = text or "Slider", TextSize = MET.F_ROW, TextColor3 = C.T_PRI,
                    Size = UDim2.new(0.62, 0, 1, 0), ZIndex = 7,
                })
                local valLbl = MakeLabel(topRow, {
                    TextSize = MET.F_SUB + 1, Font = Enum.Font.GothamBold, TextColor3 = C.T_DIM,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Size = UDim2.new(0.38, 0, 1, 0), Position = UDim2.new(0.62, 0, 0, 0), ZIndex = 7,
                })

                local trackH = IS_MOB and 6 or 4
                local trackBg = MakeFrame(wrap2, {
                    Size = UDim2.new(1, 0, 0, trackH),
                    Position = UDim2.new(0, 0, 1, -(trackH + (IS_MOB and 10 or 8))),
                    BackgroundColor3 = C.BORDER, BackgroundTransparency = 0, ZIndex = 6,
                })
                MakeCorner(trackBg, trackH / 2)
                local fill = MakeFrame(trackBg, {
                    Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.WHITE,
                    BackgroundTransparency = 0, ZIndex = 7,
                })
                MakeCorner(fill, trackH / 2)
                local sSz  = IS_MOB and 18 or 13
                local sOff = -sSz / 2
                local thumb = MakeFrame(trackBg, {
                    Size = UDim2.fromOffset(sSz, sSz),
                    Position = UDim2.new(0, sOff, 0.5, sOff),
                    BackgroundColor3 = C.WHITE, BackgroundTransparency = 0, ZIndex = 9,
                })
                MakeCorner(thumb, sSz / 2)
                MakeStroke(thumb, C.BORDER_LT, 1)

                local function fmt(n)
                    if step >= 1 then return tostring(math.floor(n + 0.5)) end
                    local d = math.max(0, math.ceil(-math.log10(step + 1e-9)))
                    return string.format("%." .. d .. "f", n)
                end

                local function update(v, silent)
                    local snapped = math.floor((v - min) / step + 0.5) * step + min
                    val = math.clamp(snapped, min, max)
                    if step < 1 then
                        local m = 10 ^ math.ceil(-math.log10(step + 1e-9))
                        val = math.floor(val * m + 0.5) / m
                    end
                    local pct = (val - min) / (max - min)
                    valLbl.Text = fmt(val)
                    Tw(fill,  TI.FAST, {Size = UDim2.new(pct, 0, 1, 0)})
                    Tw(thumb, TI.FAST, {Position = UDim2.new(pct, sOff, 0.5, sOff)})
                    if not silent and cb then task.spawn(cb, val) end
                end
                update(default, true)

                local hit = MakeButton(wrap2, {Size = UDim2.new(1, 24, 1, 0), Position = UDim2.new(0, -12, 0, 0), ZIndex = 15})
                table.insert(cleanup, BindTrack(hit, trackBg,
                    function(rel) update(min + rel * (max - min)) end,
                    function()
                        -- Stop the tab from scrolling under your finger.
                        panel.ScrollingEnabled = false
                        Tw(thumb, TI.FAST, {Size = UDim2.fromOffset(sSz + 3, sSz + 3)})
                        Tw(wrap2, TI.FAST, {BackgroundColor3 = C.HOVER})
                    end,
                    function()
                        panel.ScrollingEnabled = true
                        Tw(thumb, TI.SPRING, {Size = UDim2.fromOffset(sSz, sSz)})
                        Tw(wrap2, TI.FAST, {BackgroundColor3 = C.ELEM})
                    end))

                Hover(hit,
                    function()
                        if rowStrk then Tw(rowStrk, TI.HOVER, {Color = C.BORDER_LT}) end
                        Tw(wrap2, TI.FAST, {BackgroundColor3 = C.HOVER})
                    end,
                    function()
                        if rowStrk then Tw(rowStrk, TI.HOVER, {Color = C.BORDER}) end
                        Tw(wrap2, TI.FAST, {BackgroundColor3 = C.ELEM})
                    end)

                function obj:Set(v, silent) update(v, silent) end
                function obj:Get() return val end
                cfgSys:Register((text or "sl") .. #cfgSys.entries, obj.Get, function(v) obj:Set(v, false) end)
                return obj
            end

            --=================== Input ======================================
            function secObj:Input(text, placeholder, cb)
                local obj = {}
                local row = ElemRow(ROW_H)
                local rowStrk = row:FindFirstChildOfClass("UIStroke")
                MakeLabel(row, {
                    Text = text or "Input", TextSize = MET.F_ROW, TextColor3 = C.T_SEC,
                    Size = UDim2.new(0.4, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0), ZIndex = 6,
                })
                local boxH = ROW_H - (IS_MOB and 12 or 10)
                local inputBG = MakeFrame(row, {
                    Size = UDim2.new(0.55, -12, 0, boxH),
                    Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = C.CARD, BackgroundTransparency = 0, ZIndex = 6,
                })
                MakeCorner(inputBG, 4)
                local boxStrk = MakeStroke(inputBG, C.BORDER, 1)
                local box = MakeTextBox(inputBG, {
                    Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 6, 0, 0),
                    PlaceholderText = placeholder or "Enter text...", TextSize = MET.F_SUB + 1, ZIndex = 7,
                })
                box.Focused:Connect(function() Tw(boxStrk, TI.FAST, {Color = C.WHITE}) end)
                box.FocusLost:Connect(function(enter)
                    Tw(boxStrk, TI.FAST, {Color = C.BORDER})
                    if cb then task.spawn(cb, box.Text, enter) end
                end)
                Hover(MakeButton(row, {Size = UDim2.new(0.42, 0, 1, 0), ZIndex = 5}),
                    function() if rowStrk then Tw(rowStrk, TI.HOVER, {Color = C.BORDER_LT}) end end,
                    function() if rowStrk then Tw(rowStrk, TI.HOVER, {Color = C.BORDER}) end end)

                function obj:Set(v) box.Text = tostring(v) end
                function obj:Get() return box.Text end
                return obj
            end

            --=================== Dropdown internals =========================
            -- Shared shell for Dropdown and MultiDropdown.
            local function DropdownShell(text, headerRightBuilder)
                local sh = {}
                local ddWrap = MakeFrame(elems, {
                    Size = UDim2.new(1, 0, 0, ROW_H), BackgroundColor3 = C.ELEM,
                    BackgroundTransparency = 0, ZIndex = 10,
                })
                ddWrap.ClipsDescendants = true
                MakeCorner(ddWrap, 7)
                local ddStrk = MakeStroke(ddWrap, C.BORDER, 1)

                local ddHdr = MakeButton(ddWrap, {Size = UDim2.new(1, 0, 0, ROW_H), ZIndex = 11})
                MakeLabel(ddHdr, {
                    Text = text or "Dropdown", TextSize = MET.F_ROW, TextColor3 = C.T_SEC,
                    Size = UDim2.new(0.46, 0, 1, 0), Position = UDim2.new(0, 12, 0, 0), ZIndex = 12,
                })
                local valLbl = headerRightBuilder(ddHdr)
                local chev = MakeLabel(ddHdr, {
                    Text = "v", TextSize = MET.F_ROW, Font = Enum.Font.GothamBold, TextColor3 = C.T_DIM,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -24, 0, 0), ZIndex = 12,
                })

                local ddPanel = MakeScrollFrame(ddWrap, {
                    Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, ROW_H + 2),
                    ScrollBarThickness = 2, ZIndex = 20,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                })
                ddPanel.ClipsDescendants = true
                ddPanel.Visible = false

                local ddInner = MakeFrame(ddPanel, {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 21,
                })
                MakePadding(ddInner, 4, 4, 5, 5)
                MakeList(ddInner, Enum.FillDirection.Vertical, 2)

                sh.wrap, sh.hdr, sh.panel, sh.inner = ddWrap, ddHdr, ddPanel, ddInner
                sh.valLbl, sh.chev, sh.stroke = valLbl, chev, ddStrk
                return sh
            end

            local function buildSearchBox(inner, current, onChange, height)
                local searchBG = MakeFrame(inner, {
                    Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = C.CARD,
                    BackgroundTransparency = 0, ZIndex = 22, LayoutOrder = -1,
                })
                MakeCorner(searchBG, 5)
                local sStrk = MakeStroke(searchBG, C.BORDER, 1)
                local sBox = MakeTextBox(searchBG, {
                    Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0),
                    PlaceholderText = "Search...", Text = current, TextSize = MET.F_SUB, ZIndex = 23,
                })
                sBox.Focused:Connect(function() Tw(sStrk, TI.FAST, {Color = C.WHITE}) end)
                sBox.FocusLost:Connect(function() Tw(sStrk, TI.FAST, {Color = C.BORDER}) end)
                sBox:GetPropertyChangedSignal("Text"):Connect(function() onChange(sBox.Text) end)
                return sBox
            end

            local function matches(str, filter)
                if filter == "" then return true end
                return string.find(string.lower(str), string.lower(filter), 1, true) ~= nil
            end

            --=================== Dropdown ===================================
            function secObj:Dropdown(text, opts, cb)
                local obj, sel, open = {}, nil, false
                opts = opts or {}
                local ITEM_H  = ROW_H - 4
                local SEARCH_H = IS_MOB and 32 or 26
                local searchFilter = ""

                local sh = DropdownShell(text, function(hdr)
                    return MakeLabel(hdr, {
                        Text = "None", TextSize = MET.F_ROW, Font = Enum.Font.GothamBold,
                        TextColor3 = C.T_PRI, TextXAlignment = Enum.TextXAlignment.Right,
                        Size = UDim2.new(0.42, 0, 1, 0), Position = UDim2.new(0.48, 0, 0, 0), ZIndex = 12,
                    })
                end)

                local function useSearch() return #opts > 5 end

                local function applyFilter()
                    for _, child in ipairs(sh.inner:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.Visible = matches(child:GetAttribute("OptValue") or "", searchFilter)
                        end
                    end
                end

                local function buildOpts()
                    sh.inner:ClearAllChildren()
                    MakePadding(sh.inner, 4, 4, 5, 5)
                    MakeList(sh.inner, Enum.FillDirection.Vertical, 2)

                    if useSearch() then
                        buildSearchBox(sh.inner, searchFilter, function(t)
                            searchFilter = t
                            applyFilter()
                        end, SEARCH_H)
                    end

                    for idx, opt in ipairs(opts) do
                        local isSel = (opt == sel)
                        local optStr = tostring(opt)
                        local ob = MakeButton(sh.inner, {
                            Text = optStr, TextSize = MET.F_ROW,
                            Font = isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                            TextColor3 = isSel and C.T_PRI or C.T_SEC,
                            BackgroundColor3 = isSel and C.ELEM or C.CARD,
                            BackgroundTransparency = 0, TextXAlignment = Enum.TextXAlignment.Left,
                            Size = UDim2.new(1, 0, 0, ITEM_H), ZIndex = 22, LayoutOrder = idx,
                        })
                        ob:SetAttribute("OptValue", optStr)
                        MakePadding(ob, 0, 0, 10, 22)
                        MakeCorner(ob, 5)
                        ob.Visible = matches(optStr, searchFilter)
                        if isSel then
                            MakeLabel(ob, {
                                Text = "*", TextSize = MET.F_ROW, Font = Enum.Font.GothamBold,
                                TextColor3 = C.WHITE, TextXAlignment = Enum.TextXAlignment.Center,
                                Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(1, 4, 0, 0), ZIndex = 23,
                            })
                        end
                        Hover(ob,
                            function() if not isSel then Tw(ob, TI.HOVER, {BackgroundColor3 = C.HOVER}) end end,
                            function() if not isSel then Tw(ob, TI.HOVER, {BackgroundColor3 = C.CARD}) end end)
                        ob.MouseButton1Click:Connect(function() obj:Set(opt, false) end)
                    end
                end

                local function panelHeight()
                    local n = #opts
                    local h = n * ITEM_H + math.max(0, n - 1) * 2 + 12
                    if useSearch() then h = h + SEARCH_H + 2 end
                    return math.clamp(h, 0, MET.DD_MAX)
                end

                local function setOpen(state)
                    open = state
                    if open then
                        searchFilter = ""
                        buildOpts()
                        sh.panel.Visible = true
                        local h = panelHeight()
                        Tw(sh.chev, TI.MED, {Rotation = 180, TextColor3 = C.WHITE})
                        Tw(sh.wrap, TI.FAST, {BackgroundColor3 = C.HOVER, Size = UDim2.new(1, 0, 0, ROW_H + 2 + h)})
                        Tw(sh.panel, TI.MED, {Size = UDim2.new(1, 0, 0, h)})
                        -- Scroll the open list into view if it hangs off the bottom.
                        task.delay(0.24, function()
                            if not open or destroyed then return end
                            local bottom = sh.wrap.AbsolutePosition.Y + sh.wrap.AbsoluteSize.Y
                            local limit  = panel.AbsolutePosition.Y + panel.AbsoluteSize.Y
                            if bottom > limit then
                                local delta = (bottom - limit + 10) / math.max(CurScale(), 0.01)
                                Tw(panel, TI.MED, {CanvasPosition = panel.CanvasPosition + Vector2.new(0, delta)})
                            end
                        end)
                    else
                        Tw(sh.chev, TI.MED, {Rotation = 0, TextColor3 = C.T_DIM})
                        Tw(sh.wrap, TI.FAST, {BackgroundColor3 = C.ELEM, Size = UDim2.new(1, 0, 0, ROW_H)})
                        Tw(sh.panel, TI.MED, {Size = UDim2.new(1, 0, 0, 0)})
                        task.delay(TI.MED.Time + 0.02, function()
                            if not open then sh.panel.Visible = false end
                        end)
                    end
                end

                sh.hdr.MouseButton1Click:Connect(function() Ripple(sh.wrap); setOpen(not open) end)
                Hover(sh.hdr,
                    function()
                        Tw(sh.stroke, TI.HOVER, {Color = C.BORDER_LT})
                        if not open then Tw(sh.wrap, TI.HOVER, {BackgroundColor3 = C.HOVER}) end
                    end,
                    function()
                        Tw(sh.stroke, TI.HOVER, {Color = C.BORDER})
                        if not open then Tw(sh.wrap, TI.HOVER, {BackgroundColor3 = C.ELEM}) end
                    end)

                function obj:Set(v, silent)
                    sel = v
                    sh.valLbl.Text = v == nil and "None" or tostring(v)
                    if open then buildOpts() end
                    if not silent and cb then task.spawn(cb, v) end
                end
                function obj:Refresh(o, del)
                    opts = o or {}
                    if del then sel = nil; sh.valLbl.Text = "None" end
                    if open then
                        buildOpts()
                        local h = panelHeight()
                        Tw(sh.wrap, TI.FAST, {Size = UDim2.new(1, 0, 0, ROW_H + 2 + h)})
                        Tw(sh.panel, TI.MED, {Size = UDim2.new(1, 0, 0, h)})
                    end
                end
                function obj:Get() return sel end
                cfgSys:Register((text or "dd") .. #cfgSys.entries, obj.Get, function(v) obj:Set(v, false) end)
                return obj
            end

            --=================== MultiDropdown ==============================
            function secObj:MultiDropdown(text, opts, cb)
                local obj, selected, open = {}, {}, false
                opts = opts or {}
                local ITEM_H  = ROW_H - 4
                local SEARCH_H = IS_MOB and 32 or 26
                local searchFilter = ""

                local sh = DropdownShell(text, function(hdr)
                    return MakeLabel(hdr, {
                        Text = "None", TextSize = MET.F_SUB + 1, Font = Enum.Font.GothamBold,
                        TextColor3 = C.T_DIM, TextXAlignment = Enum.TextXAlignment.Right,
                        Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), ZIndex = 12,
                    })
                end)

                local function useSearch() return #opts > 5 end

                local function updateCount()
                    local n = 0
                    for _ in pairs(selected) do n += 1 end
                    sh.valLbl.Text = (n == 0) and "None" or (n .. " selected")
                    Tw(sh.valLbl, TI.HOVER, {TextColor3 = n == 0 and C.T_DIM or C.T_PRI})
                end

                local function applyFilter()
                    for _, child in ipairs(sh.inner:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.Visible = matches(child:GetAttribute("OptValue") or "", searchFilter)
                        end
                    end
                end

                local function buildOpts()
                    sh.inner:ClearAllChildren()
                    MakePadding(sh.inner, 4, 4, 5, 5)
                    MakeList(sh.inner, Enum.FillDirection.Vertical, 2)

                    if useSearch() then
                        buildSearchBox(sh.inner, searchFilter, function(t)
                            searchFilter = t
                            applyFilter()
                        end, SEARCH_H)
                    end

                    for idx, opt in ipairs(opts) do
                        local isSel = selected[opt] == true
                        local optStr = tostring(opt)
                        local ob = MakeButton(sh.inner, {
                            BackgroundColor3 = isSel and C.ELEM or C.CARD, BackgroundTransparency = 0,
                            Size = UDim2.new(1, 0, 0, ITEM_H), ZIndex = 22, LayoutOrder = idx,
                        })
                        ob:SetAttribute("OptValue", optStr)
                        MakeCorner(ob, 5)
                        ob.Visible = matches(optStr, searchFilter)

                        local chk = MakeFrame(ob, {
                            Size = UDim2.fromOffset(13, 13), Position = UDim2.new(0, 9, 0.5, -6.5),
                            BackgroundColor3 = isSel and C.WHITE or C.BORDER,
                            BackgroundTransparency = 0, ZIndex = 23,
                        })
                        MakeCorner(chk, 3)
                        if isSel then
                            MakeLabel(chk, {
                                Text = "*", TextSize = MET.F_SUB, Font = Enum.Font.GothamBold,
                                TextColor3 = C.BLACK, TextXAlignment = Enum.TextXAlignment.Center,
                                Size = UDim2.fromScale(1, 1), ZIndex = 24,
                            })
                        end
                        MakeLabel(ob, {
                            Text = optStr, TextSize = MET.F_ROW,
                            Font = isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                            TextColor3 = isSel and C.T_PRI or C.T_SEC,
                            Size = UDim2.new(1, -38, 1, 0), Position = UDim2.new(0, 30, 0, 0), ZIndex = 23,
                        })
                        Hover(ob,
                            function() Tw(ob, TI.HOVER, {BackgroundColor3 = C.HOVER}) end,
                            function() Tw(ob, TI.HOVER, {BackgroundColor3 = isSel and C.ELEM or C.CARD}) end)
                        ob.MouseButton1Click:Connect(function()
                            if selected[opt] then selected[opt] = nil else selected[opt] = true end
                            updateCount()
                            buildOpts()
                            if cb then
                                local arr = {}
                                for k in pairs(selected) do table.insert(arr, k) end
                                task.spawn(cb, arr)
                            end
                        end)
                    end
                end

                local function panelHeight()
                    local n = #opts
                    local h = n * ITEM_H + math.max(0, n - 1) * 2 + 12
                    if useSearch() then h = h + SEARCH_H + 2 end
                    return math.clamp(h, 0, MET.DD_MAX)
                end

                local function setOpen(state)
                    open = state
                    if open then
                        searchFilter = ""
                        buildOpts()
                        sh.panel.Visible = true
                        local h = panelHeight()
                        Tw(sh.chev, TI.MED, {Rotation = 180, TextColor3 = C.WHITE})
                        Tw(sh.wrap, TI.FAST, {BackgroundColor3 = C.HOVER, Size = UDim2.new(1, 0, 0, ROW_H + 2 + h)})
                        Tw(sh.panel, TI.MED, {Size = UDim2.new(1, 0, 0, h)})
                        task.delay(0.24, function()
                            if not open or destroyed then return end
                            local bottom = sh.wrap.AbsolutePosition.Y + sh.wrap.AbsoluteSize.Y
                            local limit  = panel.AbsolutePosition.Y + panel.AbsoluteSize.Y
                            if bottom > limit then
                                local delta = (bottom - limit + 10) / math.max(CurScale(), 0.01)
                                Tw(panel, TI.MED, {CanvasPosition = panel.CanvasPosition + Vector2.new(0, delta)})
                            end
                        end)
                    else
                        Tw(sh.chev, TI.MED, {Rotation = 0, TextColor3 = C.T_DIM})
                        Tw(sh.wrap, TI.FAST, {BackgroundColor3 = C.ELEM, Size = UDim2.new(1, 0, 0, ROW_H)})
                        Tw(sh.panel, TI.MED, {Size = UDim2.new(1, 0, 0, 0)})
                        task.delay(TI.MED.Time + 0.02, function()
                            if not open then sh.panel.Visible = false end
                        end)
                    end
                end

                sh.hdr.MouseButton1Click:Connect(function() Ripple(sh.wrap); setOpen(not open) end)
                Hover(sh.hdr,
                    function()
                        Tw(sh.stroke, TI.HOVER, {Color = C.BORDER_LT})
                        if not open then Tw(sh.wrap, TI.HOVER, {BackgroundColor3 = C.HOVER}) end
                    end,
                    function()
                        Tw(sh.stroke, TI.HOVER, {Color = C.BORDER})
                        if not open then Tw(sh.wrap, TI.HOVER, {BackgroundColor3 = C.ELEM}) end
                    end)

                function obj:Set(arr, silent)
                    selected = {}
                    if type(arr) == "table" then for _, v in ipairs(arr) do selected[v] = true end end
                    updateCount()
                    if open then buildOpts() end
                    if not silent and cb then
                        local out = {}
                        for k in pairs(selected) do table.insert(out, k) end
                        task.spawn(cb, out)
                    end
                end
                function obj:Get()
                    local arr = {}
                    for k in pairs(selected) do table.insert(arr, k) end
                    return arr
                end
                function obj:Refresh(o, reset)
                    opts = o or {}
                    if reset then selected = {} end
                    updateCount()
                    if open then
                        buildOpts()
                        local h = panelHeight()
                        Tw(sh.wrap, TI.FAST, {Size = UDim2.new(1, 0, 0, ROW_H + 2 + h)})
                        Tw(sh.panel, TI.MED, {Size = UDim2.new(1, 0, 0, h)})
                    end
                end
                cfgSys:Register((text or "mdd") .. #cfgSys.entries, obj.Get, function(v) obj:Set(v, false) end)
                return obj
            end

            --=================== Bind =======================================
            function secObj:Bind(text, default, cb)
                local obj, bound, binding = {}, default, false
                local row = ElemRow(ROW_H)
                local rowStrk = row:FindFirstChildOfClass("UIStroke")

                local cleanText = string.lower(text or "")
                local isMenuBind = (string.find(cleanText, "toggle") or string.find(cleanText, "hide")
                    or string.find(cleanText, "menu")) and true or false
                if isMenuBind then winObj:SetKeybind(default) end

                local pillW = MET.PILL_W + 10
                MakeLabel(row, {
                    Text = text or "Bind", TextSize = MET.F_ROW, TextColor3 = C.T_SEC,
                    Size = UDim2.new(1, -(pillW + 30), 1, 0), Position = UDim2.new(0, 12, 0, 0), ZIndex = 6,
                })

                local function kn(k)
                    if not k then return "-" end
                    return (tostring(k):gsub("Enum.KeyCode.", ""))
                end

                local pill = MakeButton(row, {
                    Text = kn(bound), TextSize = MET.F_TINY, Font = Enum.Font.GothamBold,
                    TextColor3 = C.T_SEC, BackgroundColor3 = C.CARD, BackgroundTransparency = 0,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Size = UDim2.fromOffset(pillW, MET.PILL_H),
                    Position = UDim2.new(1, -(pillW + 12), 0.5, -MET.PILL_H / 2), ZIndex = 16,
                })
                MakeCorner(pill, 5)
                MakeStroke(pill, C.BORDER, 1)
                Hover(pill,
                    function() Tw(pill, TI.HOVER, {BackgroundColor3 = C.HOVER}) end,
                    function() if not binding then Tw(pill, TI.HOVER, {BackgroundColor3 = C.CARD}) end end)

                local function setBind(k, silent)
                    bound = k
                    binding = false
                    pill.Text = kn(k)
                    Tw(pill, TI.HOVER, {TextColor3 = C.T_SEC, BackgroundColor3 = C.CARD, TextTransparency = 0})
                    if isMenuBind then winObj:SetKeybind(k) end
                    if not silent and cb then task.spawn(cb, k) end
                end

                pill.MouseButton1Click:Connect(function()
                    Ripple(pill)
                    if binding then return end
                    if not UIS.KeyboardEnabled then
                        AlterLib:Notify({Title = "Keybind", Message = "No keyboard detected on this device.", Duration = 3})
                        return
                    end
                    binding = true
                    pill.Text = "..."
                    Tw(pill, TI.FAST, {TextColor3 = C.WHITE, BackgroundColor3 = C.ELEM})
                    task.spawn(function()
                        while binding do
                            Tw(pill, TI.SINE, {TextTransparency = 0.5}); task.wait(0.3)
                            if not binding then break end
                            Tw(pill, TI.SINE, {TextTransparency = 0}); task.wait(0.3)
                        end
                        Tw(pill, TI.FAST, {TextTransparency = 0})
                    end)
                end)

                table.insert(cleanup, OnBegan(function(i, gp)
                    if gp or destroyed then return end
                    if binding and i.UserInputType == Enum.UserInputType.Keyboard then
                        setBind(i.KeyCode, false)
                    elseif (not binding) and bound and i.KeyCode == bound then
                        if not isMenuBind and cb then task.spawn(cb, bound) end
                    end
                end))

                local hit = MakeButton(row, {Size = UDim2.new(1, -(pillW + 20), 1, 0), ZIndex = 15})
                hit.MouseButton1Click:Connect(function()
                    Ripple(row)
                    if isMenuBind then
                        toggleUIVisibility()
                    elseif cb and bound then
                        task.spawn(cb, bound)
                    end
                end)
                Hover(hit,
                    function()
                        if rowStrk then Tw(rowStrk, TI.HOVER, {Color = C.BORDER_LT}) end
                        Tw(row, TI.HOVER, {BackgroundColor3 = C.HOVER})
                    end,
                    function()
                        if rowStrk then Tw(rowStrk, TI.HOVER, {Color = C.BORDER}) end
                        Tw(row, TI.HOVER, {BackgroundColor3 = C.ELEM})
                    end)

                function obj:Set(k, silent) setBind(k, silent) end
                function obj:Get() return bound end
                cfgSys:Register((text or "bind") .. #cfgSys.entries,
                    function() return kn(bound) end,
                    function(v) pcall(function() setBind(Enum.KeyCode[v], false) end) end)
                return obj
            end

            return secObj
        end

        return tabObj
    end

    task.spawn(function()
        task.wait(2)
        cfgSys:MarkReady()
    end)

    return winObj
end

AlterLib.Colors = C

return AlterLib
