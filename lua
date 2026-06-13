-- TeamSkeet UI Library
-- Monochromatic | Cross-Platform | Executor Compatible
-- API: Window > Tab > Section > [Button, Toggle, Slider, Dropdown, Bind]

local TeamSkeetLib = {}
TeamSkeetLib.__index = TeamSkeetLib

-->[ Services ]<--
local Players         = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local RunService      = game:GetService("RunService")
local CoreGui         = game:GetService("CoreGui")
local TextService     = game:GetService("TextService")

-->[ Constants ]<--
local LOCAL_PLAYER  = Players.LocalPlayer
local MOUSE         = LOCAL_PLAYER:GetMouse()
local IS_MOBILE     = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-->[ Palette ]<--
local C = {
    BLACK       = Color3.fromRGB(0,   0,   0  ),
    WHITE       = Color3.fromRGB(255, 255, 255),
    SURFACE     = Color3.fromRGB(10,  10,  10 ),
    PANEL       = Color3.fromRGB(18,  18,  18 ),
    CARD        = Color3.fromRGB(24,  24,  24 ),
    ELEMENT     = Color3.fromRGB(30,  30,  30 ),
    HOVER       = Color3.fromRGB(40,  40,  40 ),
    BORDER      = Color3.fromRGB(55,  55,  55 ),
    BORDER_DIM  = Color3.fromRGB(35,  35,  35 ),
    TEXT_PRI    = Color3.fromRGB(240, 240, 240),
    TEXT_SEC    = Color3.fromRGB(140, 140, 140),
    TEXT_DIM    = Color3.fromRGB(80,  80,  80 ),
    ACCENT      = Color3.fromRGB(255, 255, 255),
    ACCENT_OFF  = Color3.fromRGB(45,  45,  45 ),
    TRANSPARENT = Color3.fromRGB(0,   0,   0  ),
}

-->[ Tween Presets ]<--
local TI = {
    FAST   = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    MED    = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    SLOW   = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    SPRING = TweenInfo.new(0.4,  Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

-->[ Utility ]<--
local function Tween(obj, info, props)
    TweenService:Create(obj, info, props):Play()
end

local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function MakePadding(parent, top, bottom, left, right)
    return Create("UIPadding", {
        Parent          = parent,
        PaddingTop      = UDim.new(0, top    or 0),
        PaddingBottom   = UDim.new(0, bottom or 0),
        PaddingLeft     = UDim.new(0, left   or 0),
        PaddingRight    = UDim.new(0, right  or 0),
    })
end

local function MakeCorner(parent, radius)
    return Create("UICorner", {
        Parent       = parent,
        CornerRadius = UDim.new(0, radius or 6),
    })
end

local function MakeStroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Parent       = parent,
        Color        = color       or C.BORDER,
        Thickness    = thickness   or 1,
        Transparency = transparency or 0,
    })
end

local function MakeListLayout(parent, dir, padding, halign, valign)
    return Create("UIListLayout", {
        Parent          = parent,
        FillDirection   = dir    or Enum.FillDirection.Vertical,
        Padding         = UDim.new(0, padding or 0),
        HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = valign or Enum.VerticalAlignment.Top,
        SortOrder       = Enum.SortOrder.LayoutOrder,
    })
end

local function MakeLabel(parent, text, size, color, xalign, font)
    return Create("TextLabel", {
        Parent           = parent,
        Text             = text   or "",
        TextSize         = size   or 13,
        TextColor3       = color  or C.TEXT_PRI,
        Font             = font   or Enum.Font.GothamMedium,
        TextXAlignment   = xalign or Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, size and size + 4 or 18),
        ClipsDescendants = false,
    })
end

local function AutoSize(frame, layout, axis)
    layout.Changed:Connect(function()
        if axis == "Y" or axis == nil then
            frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset,
                0, layout.AbsoluteContentSize.Y)
        end
        if axis == "X" then
            frame.Size = UDim2.new(0, layout.AbsoluteContentSize.X,
                frame.Size.Y.Scale, frame.Size.Y.Offset)
        end
    end)
end

local function GetTextWidth(text, size, font)
    local params = Instance.new("GetTextBoundsParams")
    params.Text  = text
    params.Size  = size or 13
    params.Font  = Font.fromEnum(font or Enum.Font.GothamMedium)
    params.Width = math.huge
    local success, result = pcall(function()
        return TextService:GetTextBoundsAsync(params)
    end)
    if success then return result.X end
    return #text * (size or 13) * 0.6
end

-->[ Dragging ]<--
local function MakeDraggable(handle, target)
    local dragging   = false
    local dragStart  = Vector2.new()
    local startPos   = UDim2.new()

    local function update(input)
        local delta = input.Position - Vector2.new(dragStart.X, dragStart.Y)
        local newPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        target.Position = newPos
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            update(input)
        end
    end)
end

-->[ Root GUI ]<--
local function GetScreenGui(folder)
    local name = "TSKEET_" .. (folder or "UI")

    -- Executor environment safety
    local existing
    pcall(function() existing = CoreGui:FindFirstChild(name) end)
    if existing then existing:Destroy() end

    local sg
    pcall(function()
        sg = Create("ScreenGui", {
            Name              = name,
            Parent            = CoreGui,
            ResetOnSpawn      = false,
            ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset    = true,
            DisplayOrder      = 999,
        })
    end)

    if not sg then
        sg = Create("ScreenGui", {
            Name           = name,
            Parent         = LOCAL_PLAYER:WaitForChild("PlayerGui"),
            ResetOnSpawn   = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true,
        })
    end

    return sg
end

-->═══════════════════════════════════════════════<--
-->                  RICHTEXT                      <--
-->═══════════════════════════════════════════════<--
function TeamSkeetLib:RichText(color)
    local rt = {}
    local hex = string.format("#%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
    setmetatable(rt, {
        __index = function(_, word)
            return string.format('<font color="%s">%s</font>', hex, word)
        end
    })
    return rt
end

-->═══════════════════════════════════════════════<--
-->                   PROMPT                       <--
-->═══════════════════════════════════════════════<--
function TeamSkeetLib:Prompt(cfg)
    local sg = GetScreenGui("PROMPT")

    -- Backdrop
    local backdrop = Create("Frame", {
        Parent              = sg,
        Size                = UDim2.fromScale(1, 1),
        BackgroundColor3    = C.BLACK,
        BackgroundTransparency = 0.4,
        ZIndex              = 100,
    })

    -- Card
    local card = Create("Frame", {
        Parent              = backdrop,
        Size                = UDim2.new(0, 340, 0, 160),
        Position            = UDim2.fromScale(0.5, 0.5),
        AnchorPoint         = Vector2.new(0.5, 0.5),
        BackgroundColor3    = C.PANEL,
        ZIndex              = 101,
    })
    MakeCorner(card, 8)
    MakeStroke(card, C.BORDER, 1)

    -- Header bar
    local header = Create("Frame", {
        Parent           = card,
        Size             = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = C.CARD,
        ZIndex           = 102,
    })
    Create("UICorner", { Parent = header, CornerRadius = UDim.new(0, 8) })
    -- Bottom square corners for header
    Create("Frame", {
        Parent           = header,
        Size             = UDim2.new(1, 0, 0, 8),
        Position         = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = C.CARD,
        BorderSizePixel  = 0,
        ZIndex           = 102,
    })

    local titleLabel = Create("TextLabel", {
        Parent               = header,
        Text                 = cfg.Title or "Prompt",
        TextSize             = 13,
        Font                 = Enum.Font.GothamBold,
        TextColor3           = C.TEXT_PRI,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, -16, 1, 0),
        Position             = UDim2.new(0, 16, 0, 0),
        TextXAlignment       = Enum.TextXAlignment.Left,
        ZIndex               = 103,
    })

    local msgLabel = Create("TextLabel", {
        Parent               = card,
        Text                 = cfg.Message or "",
        TextSize             = 12,
        Font                 = Enum.Font.Gotham,
        TextColor3           = C.TEXT_SEC,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, -32, 0, 40),
        Position             = UDim2.new(0, 16, 0, 52),
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextWrapped          = true,
        ZIndex               = 103,
    })

    -- Buttons row
    local btnRow = Create("Frame", {
        Parent           = card,
        Size             = UDim2.new(1, -32, 0, 34),
        Position         = UDim2.new(0, 16, 1, -50),
        BackgroundTransparency = 1,
        ZIndex           = 102,
    })
    local btnLayout = MakeListLayout(btnRow, Enum.FillDirection.Horizontal, 8)

    local function MakePromptBtn(text, primary, callback)
        local btn = Create("TextButton", {
            Parent           = btnRow,
            Text             = text,
            TextSize         = 12,
            Font             = Enum.Font.GothamBold,
            TextColor3       = primary and C.BLACK or C.TEXT_SEC,
            BackgroundColor3 = primary and C.WHITE  or C.ELEMENT,
            Size             = UDim2.new(0.5, -4, 1, 0),
            AutoButtonColor  = false,
            ZIndex           = 103,
        })
        MakeCorner(btn, 5)
        if not primary then MakeStroke(btn, C.BORDER, 1) end

        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
            sg:Destroy()
        end)

        btn.MouseEnter:Connect(function()
            Tween(btn, TI.FAST, {
                BackgroundColor3 = primary and Color3.fromRGB(220,220,220) or C.HOVER
            })
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, TI.FAST, {
                BackgroundColor3 = primary and C.WHITE or C.ELEMENT
            })
        end)
        return btn
    end

    MakePromptBtn(cfg.NoText  or "Cancel", false, cfg.No)
    MakePromptBtn(cfg.YesText or "Confirm", true,  cfg.Yes)

    -- Animate in
    card.Position = UDim2.new(0.5, 0, 0.5, 20)
    card.BackgroundTransparency = 1
    Tween(card, TI.SPRING, {
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 0,
    })

    backdrop.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)
end

-->═══════════════════════════════════════════════<--
-->                   WINDOW                       <--
-->═══════════════════════════════════════════════<--
function TeamSkeetLib:Window(cfg)
    local self    = setmetatable({}, { __index = TeamSkeetLib })
    self._cfg     = cfg or {}
    self._tabs    = {}
    self._activeTab = nil

    local sg = GetScreenGui(cfg.Folder or "Window")
    self._sg = sg

    -->[ Root Frame ]<--
    local WIN_W = 560
    local WIN_H = 480
    local TAB_W = 130

    local root = Create("Frame", {
        Parent           = sg,
        Size             = UDim2.new(0, WIN_W, 0, WIN_H),
        Position         = UDim2.fromScale(0.5, 0.5),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.SURFACE,
        ClipsDescendants = false,
    })
    MakeCorner(root, 10)
    MakeStroke(root, C.BORDER_DIM, 1)
    self._root = root

    -->[ Title Bar ]<--
    local titleBar = Create("Frame", {
        Parent           = root,
        Size             = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = C.PANEL,
        ZIndex           = 2,
    })
    Create("UICorner", { Parent = titleBar, CornerRadius = UDim.new(0, 10) })
    Create("Frame", {
        Parent           = titleBar,
        Size             = UDim2.new(1, 0, 0, 10),
        Position         = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = C.PANEL,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    })
    MakeStroke(titleBar, C.BORDER_DIM, 1)

    -- Window name
    local winName = Create("TextLabel", {
        Parent               = titleBar,
        Text                 = cfg.Name or "Window",
        TextSize             = 13,
        Font                 = Enum.Font.GothamBold,
        TextColor3           = C.TEXT_PRI,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(0.5, 0, 1, 0),
        Position             = UDim2.new(0, 16, 0, 0),
        TextXAlignment       = Enum.TextXAlignment.Left,
        RichText             = true,
        ZIndex               = 3,
    })

    -- Close / Minimise buttons
    local ctrlRow = Create("Frame", {
        Parent               = titleBar,
        Size                 = UDim2.new(0, 56, 0, 20),
        Position             = UDim2.new(1, -68, 0.5, -10),
        BackgroundTransparency = 1,
        ZIndex               = 3,
    })
    MakeListLayout(ctrlRow, Enum.FillDirection.Horizontal, 6)

    local function CtrlBtn(symbol, col, action)
        local b = Create("TextButton", {
            Parent           = ctrlRow,
            Text             = symbol,
            TextSize         = 11,
            Font             = Enum.Font.GothamBold,
            TextColor3       = C.SURFACE,
            BackgroundColor3 = col,
            Size             = UDim2.new(0, 20, 0, 20),
            AutoButtonColor  = false,
            ZIndex           = 4,
        })
        MakeCorner(b, 10)
        b.MouseButton1Click:Connect(action)
        b.MouseEnter:Connect(function() Tween(b, TI.FAST, {BackgroundColor3 = C.WHITE}) end)
        b.MouseLeave:Connect(function() Tween(b, TI.FAST, {BackgroundColor3 = col}) end)
        return b
    end

    local minimised = false
    local bodyRef   -- forward declare

    CtrlBtn("–", C.BORDER, function()
        minimised = not minimised
        if bodyRef then
            Tween(bodyRef, TI.MED, {
                Size = minimised
                    and UDim2.new(1, 0, 0, 0)
                    or  UDim2.new(1, 0, 1, -46),
            })
        end
    end)

    CtrlBtn("×", C.BORDER, function()
        Tween(root, TI.MED, {
            Size = UDim2.new(0, WIN_W, 0, 0),
            BackgroundTransparency = 1,
        })
        task.delay(0.25, function() sg:Destroy() end)
    end)

    MakeDraggable(titleBar, root)

    -->[ Body ]<--
    local body = Create("Frame", {
        Parent           = root,
        Size             = UDim2.new(1, 0, 1, -46),
        Position         = UDim2.new(0, 0, 0, 46),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    })
    bodyRef = body

    -->[ Tab Sidebar ]<--
    local sidebar = Create("Frame", {
        Parent           = body,
        Size             = UDim2.new(0, TAB_W, 1, 0),
        BackgroundColor3 = C.PANEL,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    })

    -- Sidebar bottom-left corner only
    Create("UICorner", { Parent = sidebar, CornerRadius = UDim.new(0, 10) })
    Create("Frame", {
        Parent           = sidebar,
        Size             = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = C.PANEL,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    })
    Create("Frame", {
        Parent           = sidebar,
        Size             = UDim2.new(0, 10, 1, 0),
        Position         = UDim2.new(1, -10, 0, 0),
        BackgroundColor3 = C.PANEL,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    })

    local sideStroke = Create("Frame", {
        Parent           = sidebar,
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.BORDER_DIM,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    })

    -- Branding mark in sidebar
    local brandMark = Create("TextLabel", {
        Parent               = sidebar,
        Text                 = "TS",
        TextSize             = 22,
        Font                 = Enum.Font.GothamBlack,
        TextColor3           = C.TEXT_DIM,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, 0, 0, 46),
        Position             = UDim2.new(0, 0, 0, 8),
        TextXAlignment       = Enum.TextXAlignment.Center,
        ZIndex               = 3,
    })

    local tabList = Create("ScrollingFrame", {
        Parent                  = sidebar,
        Size                    = UDim2.new(1, 0, 1, -70),
        Position                = UDim2.new(0, 0, 0, 62),
        BackgroundTransparency  = 1,
        BorderSizePixel         = 0,
        ScrollBarThickness      = 0,
        CanvasSize              = UDim2.new(0, 0, 0, 0),
        ZIndex                  = 3,
    })
    MakePadding(tabList, 4, 4, 8, 8)
    local tabListLayout = MakeListLayout(tabList, Enum.FillDirection.Vertical, 3)
    tabListLayout.Changed:Connect(function()
        tabList.CanvasSize = UDim2.new(0, 0, 0, tabListLayout.AbsoluteContentSize.Y + 8)
    end)

    -->[ Content Area ]<--
    local contentArea = Create("Frame", {
        Parent           = body,
        Size             = UDim2.new(1, -TAB_W, 1, 0),
        Position         = UDim2.new(0, TAB_W, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    })

    self._tabList    = tabList
    self._tabLayout  = tabListLayout
    self._content    = contentArea

    -- Animate in
    root.Size = UDim2.new(0, WIN_W, 0, 0)
    root.BackgroundTransparency = 1
    Tween(root, TI.SPRING, {
        Size = UDim2.new(0, WIN_W, 0, WIN_H),
        BackgroundTransparency = 0,
    })

    -->[ Window Object ]<--
    local winObj = {}
    winObj._lib     = self
    winObj._tabs    = {}
    winObj._tabBtns = {}

    function winObj:Tab(name)
        local tabObj    = {}
        tabObj._sections = {}
        tabObj._name    = name

        -- Tab button
        local tabBtn = Create("TextButton", {
            Parent           = tabList,
            Text             = name,
            TextSize         = 12,
            Font             = Enum.Font.GothamMedium,
            TextColor3       = C.TEXT_DIM,
            BackgroundColor3 = C.TRANSPARENT,
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, 0, 0, 32),
            AutoButtonColor  = false,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 4,
        })
        MakePadding(tabBtn, 0, 0, 10, 0)
        MakeCorner(tabBtn, 5)

        -- Active indicator bar
        local indicator = Create("Frame", {
            Parent           = tabBtn,
            Size             = UDim2.new(0, 2, 0.6, 0),
            Position         = UDim2.new(0, 2, 0.2, 0),
            BackgroundColor3 = C.WHITE,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ZIndex           = 5,
        })
        MakeCorner(indicator, 2)

        -- Tab content panel
        local panel = Create("ScrollingFrame", {
            Parent                  = contentArea,
            Size                    = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency  = 1,
            BorderSizePixel         = 0,
            ScrollBarThickness      = 3,
            ScrollBarImageColor3    = C.BORDER,
            CanvasSize              = UDim2.new(0, 0, 0, 0),
            Visible                 = false,
            ZIndex                  = 2,
        })
        MakePadding(panel, 12, 12, 14, 14)
        local panelLayout = MakeListLayout(panel, Enum.FillDirection.Vertical, 10)
        panelLayout.Changed:Connect(function()
            panel.CanvasSize = UDim2.new(0, 0, 0,
                panelLayout.AbsoluteContentSize.Y + 24)
        end)

        tabObj._panel  = panel
        tabObj._layout = panelLayout

        -- Activate logic
        local function activate()
            -- Deactivate all
            for _, t in ipairs(winObj._tabs) do
                t._panel.Visible = false
                Tween(t._btn, TI.FAST, {
                    BackgroundTransparency = 1,
                    TextColor3 = C.TEXT_DIM,
                })
                Tween(t._ind, TI.FAST, { BackgroundTransparency = 1 })
            end
            -- Activate this
            panel.Visible = true
            Tween(tabBtn, TI.FAST, {
                BackgroundTransparency = 0.85,
                TextColor3 = C.TEXT_PRI,
                BackgroundColor3 = C.ELEMENT,
            })
            Tween(indicator, TI.FAST, { BackgroundTransparency = 0 })
        end

        tabObj._btn = tabBtn
        tabObj._ind = indicator
        table.insert(winObj._tabs, tabObj)

        tabBtn.MouseButton1Click:Connect(activate)
        tabBtn.MouseEnter:Connect(function()
            if panel.Visible then return end
            Tween(tabBtn, TI.FAST, {
                BackgroundTransparency = 0.92,
                BackgroundColor3 = C.ELEMENT,
            })
        end)
        tabBtn.MouseLeave:Connect(function()
            if panel.Visible then return end
            Tween(tabBtn, TI.FAST, { BackgroundTransparency = 1 })
        end)

        -- Auto-activate first tab
        if #winObj._tabs == 1 then
            activate()
        end

        -->[ Section ]<--
        function tabObj:Section(sectionName)
            local secObj = {}

            -- Section wrapper
            local secFrame = Create("Frame", {
                Parent           = panel,
                Size             = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = C.CARD,
                AutomaticSize    = Enum.AutomaticSize.Y,
                ZIndex           = 3,
            })
            MakeCorner(secFrame, 7)
            MakeStroke(secFrame, C.BORDER_DIM, 1)

            -- Section header
            local secHeader = Create("Frame", {
                Parent           = secFrame,
                Size             = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = C.ELEMENT,
                ZIndex           = 4,
            })
            Create("UICorner", { Parent = secHeader, CornerRadius = UDim.new(0, 7) })
            Create("Frame", {
                Parent           = secHeader,
                Size             = UDim2.new(1, 0, 0, 7),
                Position         = UDim2.new(0, 0, 1, -7),
                BackgroundColor3 = C.ELEMENT,
                BorderSizePixel  = 0,
                ZIndex           = 4,
            })

            local secLabel = Create("TextLabel", {
                Parent               = secHeader,
                Text                 = sectionName or "Section",
                TextSize             = 11,
                Font                 = Enum.Font.GothamBold,
                TextColor3           = C.TEXT_DIM,
                BackgroundTransparency = 1,
                Size                 = UDim2.new(1, -24, 1, 0),
                Position             = UDim2.new(0, 12, 0, 0),
                TextXAlignment       = Enum.TextXAlignment.Left,
                ZIndex               = 5,
            })

            -- Element container
            local elemContainer = Create("Frame", {
                Parent           = secFrame,
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.new(0, 0, 0, 34),
                BackgroundTransparency = 1,
                AutomaticSize    = Enum.AutomaticSize.Y,
                ZIndex           = 4,
            })
            MakePadding(elemContainer, 6, 8, 10, 10)
            local elemLayout = MakeListLayout(elemContainer, Enum.FillDirection.Vertical, 6)

            -->══════════════════════════════<--
            -->           BUTTON             <--
            -->══════════════════════════════<--
            function secObj:Button(label, callback)
                local btn = Create("TextButton", {
                    Parent           = elemContainer,
                    Text             = "",
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = C.ELEMENT,
                    AutoButtonColor  = false,
                    ZIndex           = 5,
                })
                MakeCorner(btn, 5)
                MakeStroke(btn, C.BORDER_DIM, 1)

                local btnLabel = Create("TextLabel", {
                    Parent               = btn,
                    Text                 = label or "Button",
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamMedium,
                    TextColor3           = C.TEXT_PRI,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(1, -16, 1, 0),
                    Position             = UDim2.new(0, 12, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    ZIndex               = 6,
                })

                -- Arrow icon
                Create("TextLabel", {
                    Parent               = btn,
                    Text                 = "›",
                    TextSize             = 18,
                    Font                 = Enum.Font.GothamBold,
                    TextColor3           = C.TEXT_DIM,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0, 20, 1, 0),
                    Position             = UDim2.new(1, -24, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Center,
                    ZIndex               = 6,
                })

                btn.MouseEnter:Connect(function()
                    Tween(btn,      TI.FAST, { BackgroundColor3 = C.HOVER })
                    Tween(btnLabel, TI.FAST, { TextColor3 = C.WHITE       })
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn,      TI.FAST, { BackgroundColor3 = C.ELEMENT  })
                    Tween(btnLabel, TI.FAST, { TextColor3 = C.TEXT_PRI })
                end)
                btn.MouseButton1Down:Connect(function()
                    Tween(btn, TI.FAST, { BackgroundColor3 = C.BORDER })
                end)
                btn.MouseButton1Up:Connect(function()
                    Tween(btn, TI.FAST, { BackgroundColor3 = C.HOVER })
                    if callback then
                        task.spawn(callback)
                    end
                end)
            end

            -->══════════════════════════════<--
            -->           TOGGLE             <--
            -->══════════════════════════════<--
            function secObj:Toggle(label, callback)
                local togObj  = {}
                local state   = false

                local row = Create("Frame", {
                    Parent           = elemContainer,
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = C.ELEMENT,
                    ZIndex           = 5,
                })
                MakeCorner(row, 5)
                MakeStroke(row, C.BORDER_DIM, 1)

                local togLabel = Create("TextLabel", {
                    Parent               = row,
                    Text                 = label or "Toggle",
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamMedium,
                    TextColor3           = C.TEXT_SEC,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(1, -56, 1, 0),
                    Position             = UDim2.new(0, 12, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    ZIndex               = 6,
                })

                -- Track (pill)
                local track = Create("Frame", {
                    Parent           = row,
                    Size             = UDim2.new(0, 34, 0, 18),
                    Position         = UDim2.new(1, -46, 0.5, -9),
                    BackgroundColor3 = C.ACCENT_OFF,
                    ZIndex           = 6,
                })
                MakeCorner(track, 9)
                MakeStroke(track, C.BORDER, 1)

                -- Thumb
                local thumb = Create("Frame", {
                    Parent           = track,
                    Size             = UDim2.new(0, 12, 0, 12),
                    Position         = UDim2.new(0, 3, 0.5, -6),
                    BackgroundColor3 = C.TEXT_DIM,
                    ZIndex           = 7,
                })
                MakeCorner(thumb, 6)

                local function setToggle(val, silent)
                    state = val
                    Tween(track, TI.MED, {
                        BackgroundColor3 = state and C.WHITE or C.ACCENT_OFF
                    })
                    Tween(thumb, TI.MED, {
                        Position = state
                            and UDim2.new(0, 19, 0.5, -6)
                            or  UDim2.new(0,  3, 0.5, -6),
                        BackgroundColor3 = state and C.BLACK or C.TEXT_DIM,
                    })
                    Tween(togLabel, TI.FAST, {
                        TextColor3 = state and C.TEXT_PRI or C.TEXT_SEC
                    })
                    if not silent and callback then
                        task.spawn(callback, state)
                    end
                end

                local btn = Create("TextButton", {
                    Parent               = row,
                    Text                 = "",
                    Size                 = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ZIndex               = 8,
                })
                btn.MouseButton1Click:Connect(function()
                    setToggle(not state)
                end)
                btn.MouseEnter:Connect(function()
                    Tween(row, TI.FAST, { BackgroundColor3 = C.HOVER })
                end)
                btn.MouseLeave:Connect(function()
                    Tween(row, TI.FAST, { BackgroundColor3 = C.ELEMENT })
                end)

                function togObj:Set(val)
                    setToggle(val, true)
                end
                function togObj:Get()
                    return state
                end

                return togObj
            end

            -->══════════════════════════════<--
            -->           SLIDER             <--
            -->══════════════════════════════<--
            function secObj:Slider(label, min, max, default, callback)
                local sliderObj = {}
                min     = min     or 0
                max     = max     or 100
                default = default or min
                local value = math.clamp(default, min, max)

                local wrapper = Create("Frame", {
                    Parent           = elemContainer,
                    Size             = UDim2.new(1, 0, 0, 50),
                    BackgroundColor3 = C.ELEMENT,
                    ZIndex           = 5,
                })
                MakeCorner(wrapper, 5)
                MakeStroke(wrapper, C.BORDER_DIM, 1)
                MakePadding(wrapper, 8, 8, 12, 12)

                -- Top row: label + value
                local topRow = Create("Frame", {
                    Parent               = wrapper,
                    Size                 = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    ZIndex               = 6,
                })
                local slidLabel = Create("TextLabel", {
                    Parent               = topRow,
                    Text                 = label or "Slider",
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamMedium,
                    TextColor3           = C.TEXT_PRI,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0.7, 0, 1, 0),
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    ZIndex               = 7,
                })
                local valLabel = Create("TextLabel", {
                    Parent               = topRow,
                    Text                 = tostring(value),
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamBold,
                    TextColor3           = C.TEXT_SEC,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0.3, 0, 1, 0),
                    Position             = UDim2.new(0.7, 0, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Right,
                    ZIndex               = 7,
                })

                -- Track
                local track = Create("Frame", {
                    Parent           = wrapper,
                    Size             = UDim2.new(1, 0, 0, 4),
                    Position         = UDim2.new(0, 0, 1, -12),
                    BackgroundColor3 = C.BORDER,
                    ZIndex           = 6,
                })
                MakeCorner(track, 2)

                -- Fill
                local fill = Create("Frame", {
                    Parent           = track,
                    Size             = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = C.WHITE,
                    ZIndex           = 7,
                })
                MakeCorner(fill, 2)

                -- Thumb
                local thumbSlider = Create("Frame", {
                    Parent           = track,
                    Size             = UDim2.new(0, 12, 0, 12),
                    Position         = UDim2.new(0, 0, 0.5, -6),
                    BackgroundColor3 = C.WHITE,
                    ZIndex           = 8,
                })
                MakeCorner(thumbSlider, 6)
                MakeStroke(thumbSlider, C.BORDER, 1)

                local function updateSlider(val, silent)
                    value = math.clamp(math.floor(val + 0.5), min, max)
                    local pct = (value - min) / (max - min)
                    valLabel.Text = tostring(value)
                    Tween(fill, TI.FAST, { Size = UDim2.new(pct, 0, 1, 0) })
                    Tween(thumbSlider, TI.FAST, {
                        Position = UDim2.new(pct, -6, 0.5, -6)
                    })
                    if not silent and callback then
                        task.spawn(callback, value)
                    end
                end

                -- Initial
                updateSlider(default, true)

                local draggingSlider = false
                local function handleInput(input)
                    local trackAbs = track.AbsolutePosition
                    local trackSz  = track.AbsoluteSize
                    local relX     = math.clamp(
                        (input.Position.X - trackAbs.X) / trackSz.X, 0, 1
                    )
                    updateSlider(min + relX * (max - min))
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = true
                        handleInput(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and (
                        input.UserInputType == Enum.UserInputType.MouseMovement or
                        input.UserInputType == Enum.UserInputType.Touch
                    ) then
                        handleInput(input)
                    end
                end)

                function sliderObj:Set(val)
                    updateSlider(val, true)
                end
                function sliderObj:Get()
                    return value
                end

                return sliderObj
            end

            -->══════════════════════════════<--
            -->          DROPDOWN            <--
            -->══════════════════════════════<--
            function secObj:Dropdown(label, options, callback)
                local ddObj    = {}
                local selected = nil
                local open     = false
                local opts     = options or {}

                local ddFrame = Create("Frame", {
                    Parent           = elemContainer,
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = C.ELEMENT,
                    ClipsDescendants = false,
                    ZIndex           = 10,
                })
                MakeCorner(ddFrame, 5)
                MakeStroke(ddFrame, C.BORDER_DIM, 1)

                -- Header row
                local ddHeader = Create("TextButton", {
                    Parent               = ddFrame,
                    Text                 = "",
                    Size                 = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    AutoButtonColor      = false,
                    ZIndex               = 11,
                })

                local ddLabel = Create("TextLabel", {
                    Parent               = ddHeader,
                    Text                 = label or "Dropdown",
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamMedium,
                    TextColor3           = C.TEXT_SEC,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0.5, 0, 1, 0),
                    Position             = UDim2.new(0, 12, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    ZIndex               = 12,
                })

                local selectedLabel = Create("TextLabel", {
                    Parent               = ddHeader,
                    Text                 = "None",
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamMedium,
                    TextColor3           = C.TEXT_PRI,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0.45, 0, 1, 0),
                    Position             = UDim2.new(0.5, 0, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Right,
                    ZIndex               = 12,
                })

                local chevron = Create("TextLabel", {
                    Parent               = ddHeader,
                    Text                 = "∨",
                    TextSize             = 10,
                    Font                 = Enum.Font.GothamBold,
                    TextColor3           = C.TEXT_DIM,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0, 20, 1, 0),
                    Position             = UDim2.new(1, -22, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Center,
                    ZIndex               = 12,
                })

                -- Dropdown panel
                local ddPanel = Create("Frame", {
                    Parent           = ddFrame,
                    Size             = UDim2.new(1, 0, 0, 0),
                    Position         = UDim2.new(0, 0, 0, 38),
                    BackgroundColor3 = C.CARD,
                    ClipsDescendants = true,
                    ZIndex           = 20,
                    Visible          = false,
                })
                MakeCorner(ddPanel, 5)
                MakeStroke(ddPanel, C.BORDER_DIM, 1)

                local ddScroll = Create("ScrollingFrame", {
                    Parent                  = ddPanel,
                    Size                    = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency  = 1,
                    BorderSizePixel         = 0,
                    ScrollBarThickness      = 2,
                    ScrollBarImageColor3    = C.BORDER,
                    CanvasSize              = UDim2.new(0, 0, 0, 0),
                    ZIndex                  = 21,
                })
                MakePadding(ddScroll, 4, 4, 6, 6)
                local ddLayout = MakeListLayout(ddScroll, Enum.FillDirection.Vertical, 2)
                ddLayout.Changed:Connect(function()
                    ddScroll.CanvasSize = UDim2.new(0, 0, 0,
                        ddLayout.AbsoluteContentSize.Y + 8)
                end)

                local function buildOptions()
                    for _, child in ipairs(ddScroll:GetChildren()) do
                        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                            child:Destroy()
                        end
                    end
                    for _, opt in ipairs(opts) do
                        local optBtn = Create("TextButton", {
                            Parent           = ddScroll,
                            Text             = tostring(opt),
                            TextSize         = 12,
                            Font             = Enum.Font.GothamMedium,
                            TextColor3       = opt == selected and C.TEXT_PRI or C.TEXT_SEC,
                            BackgroundColor3 = opt == selected and C.ELEMENT  or C.CARD,
                            Size             = UDim2.new(1, 0, 0, 28),
                            AutoButtonColor  = false,
                            TextXAlignment   = Enum.TextXAlignment.Left,
                            ZIndex           = 22,
                        })
                        MakePadding(optBtn, 0, 0, 8, 0)
                        MakeCorner(optBtn, 4)

                        if opt == selected then
                            -- Checkmark
                            Create("TextLabel", {
                                Parent               = optBtn,
                                Text                 = "✓",
                                TextSize             = 11,
                                Font                 = Enum.Font.GothamBold,
                                TextColor3           = C.TEXT_PRI,
                                BackgroundTransparency = 1,
                                Size                 = UDim2.new(0, 20, 1, 0),
                                Position             = UDim2.new(1, -22, 0, 0),
                                TextXAlignment       = Enum.TextXAlignment.Center,
                                ZIndex               = 23,
                            })
                        end

                        optBtn.MouseEnter:Connect(function()
                            if opt ~= selected then
                                Tween(optBtn, TI.FAST, {BackgroundColor3 = C.HOVER})
                            end
                        end)
                        optBtn.MouseLeave:Connect(function()
                            if opt ~= selected then
                                Tween(optBtn, TI.FAST, {BackgroundColor3 = C.CARD})
                            end
                        end)
                        optBtn.MouseButton1Click:Connect(function()
                            selected = opt
                            selectedLabel.Text = tostring(opt)
                            buildOptions()
                            if callback then task.spawn(callback, opt) end
                        end)
                    end
                end

                buildOptions()

                local MAX_VISIBLE = 5
                local ITEM_H      = 30
                local PAD         = 8

                local function toggleDD()
                    open = not open
                    if open then
                        local h = math.min(#opts * ITEM_H + PAD, MAX_VISIBLE * ITEM_H + PAD)
                        ddPanel.Visible = true
                        ddPanel.Size    = UDim2.new(1, 0, 0, 0)
                        Tween(ddPanel,  TI.MED, { Size = UDim2.new(1, 0, 0, h) })
                        Tween(chevron,  TI.MED, { Rotation = 180 })
                        Tween(ddFrame,  TI.FAST, { BackgroundColor3 = C.HOVER })
                    else
                        Tween(ddPanel,  TI.MED, { Size = UDim2.new(1, 0, 0, 0) })
                        Tween(chevron,  TI.MED, { Rotation = 0 })
                        Tween(ddFrame,  TI.FAST, { BackgroundColor3 = C.ELEMENT })
                        task.delay(0.22, function()
                            if not open then ddPanel.Visible = false end
                        end)
                    end
                end

                ddHeader.MouseButton1Click:Connect(toggleDD)
                ddHeader.MouseEnter:Connect(function()
                    Tween(ddFrame, TI.FAST, {BackgroundColor3 = C.HOVER})
                end)
                ddHeader.MouseLeave:Connect(function()
                    if not open then
                        Tween(ddFrame, TI.FAST, {BackgroundColor3 = C.ELEMENT})
                    end
                end)

                function ddObj:Set(option)
                    selected = option
                    selectedLabel.Text = tostring(option)
                    buildOptions()
                end
                function ddObj:Refresh(newOptions, deleteCurrent)
                    opts = newOptions or {}
                    if deleteCurrent then
                        selected = nil
                        selectedLabel.Text = "None"
                    end
                    buildOptions()
                end
                function ddObj:Get()
                    return selected
                end

                return ddObj
            end

            -->══════════════════════════════<--
            -->            BIND              <--
            -->══════════════════════════════<--
            function secObj:Bind(label, default, callback)
                local bindObj  = {}
                local bound    = default
                local binding  = false

                local row = Create("Frame", {
                    Parent           = elemContainer,
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = C.ELEMENT,
                    ZIndex           = 5,
                })
                MakeCorner(row, 5)
                MakeStroke(row, C.BORDER_DIM, 1)

                local bindLabel = Create("TextLabel", {
                    Parent               = row,
                    Text                 = label or "Bind",
                    TextSize             = 12,
                    Font                 = Enum.Font.GothamMedium,
                    TextColor3           = C.TEXT_SEC,
                    BackgroundTransparency = 1,
                    Size                 = UDim2.new(0.55, 0, 1, 0),
                    Position             = UDim2.new(0, 12, 0, 0),
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    ZIndex               = 6,
                })

                local function keyName(k)
                    if not k then return "None" end
                    local n = tostring(k):gsub("Enum.KeyCode.", "")
                    return n
                end

                local keyPill = Create("TextButton", {
                    Parent           = row,
                    Text             = "[" .. keyName(bound) .. "]",
                    TextSize         = 11,
                    Font             = Enum.Font.GothamBold,
                    TextColor3       = C.TEXT_PRI,
                    BackgroundColor3 = C.CARD,
                    Size             = UDim2.new(0, 72, 0, 22),
                    Position         = UDim2.new(1, -82, 0.5, -11),
                    AutoButtonColor  = false,
                    ZIndex           = 6,
                })
                MakeCorner(keyPill, 4)
                MakeStroke(keyPill, C.BORDER, 1)

                local function setBinding(k, silent)
                    bound   = k
                    binding = false
                    keyPill.Text      = "[" .. keyName(k) .. "]"
                    keyPill.TextColor3 = C.TEXT_PRI
                    Tween(keyPill, TI.FAST, {BackgroundColor3 = C.CARD})
                    if not silent and callback then
                        task.spawn(callback, k)
                    end
                end

                keyPill.MouseButton1Click:Connect(function()
                    if binding then return end
                    binding = true
                    keyPill.Text       = "[...]"
                    keyPill.TextColor3 = C.WHITE
                    Tween(keyPill, TI.FAST, {BackgroundColor3 = C.ELEMENT})
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if binding then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            setBinding(input.KeyCode)
                        end
                    else
                        if bound and input.KeyCode == bound then
                            if callback then task.spawn(callback, bound) end
                        end
                    end
                end)

                row.MouseEnter:Connect(function()
                    Tween(row, TI.FAST, {BackgroundColor3 = C.HOVER})
                end)
                row.MouseLeave:Connect(function()
                    Tween(row, TI.FAST, {BackgroundColor3 = C.ELEMENT})
                end)

                function bindObj:Set(key)
                    setBinding(key, true)
                end
                function bindObj:Get()
                    return bound
                end

                return bindObj
            end

            return secObj
        end -- Section

        return tabObj
    end -- Tab

    return winObj
end -- Window

return TeamSkeetLib
