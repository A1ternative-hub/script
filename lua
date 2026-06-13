--[[
    ╔═══════════════════════════════════════════════╗
    ║              A L T E R                        ║
    ║     Monochromatic UI Library — v2             ║
    ║  • Momentum drag  • Section collapse          ║
    ║  • Rich animations on every element           ║
    ╚═══════════════════════════════════════════════╝
--]]

local AlterLib = {}
AlterLib.__index = AlterLib

--> Services
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")

--> Player
local LP = Players.LocalPlayer

--> Palette
local C = {
    BLACK      = Color3.fromRGB(0,   0,   0  ),
    WHITE      = Color3.fromRGB(255, 255, 255),
    SURFACE    = Color3.fromRGB(8,   8,   8  ),
    PANEL      = Color3.fromRGB(14,  14,  14 ),
    CARD       = Color3.fromRGB(20,  20,  20 ),
    ELEMENT    = Color3.fromRGB(28,  28,  28 ),
    HOVER      = Color3.fromRGB(38,  38,  38 ),
    ACTIVE     = Color3.fromRGB(50,  50,  50 ),
    BORDER     = Color3.fromRGB(50,  50,  50 ),
    BORDER_DIM = Color3.fromRGB(28,  28,  28 ),
    TEXT_PRI   = Color3.fromRGB(235, 235, 235),
    TEXT_SEC   = Color3.fromRGB(120, 120, 120),
    TEXT_DIM   = Color3.fromRGB(60,  60,  60 ),
    ACCENT_OFF = Color3.fromRGB(40,  40,  40 ),
}

--> Tween presets
local TI = {
    INSTANT = TweenInfo.new(0.06, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    FAST    = TweenInfo.new(0.14, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    MED     = TweenInfo.new(0.24, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    SLOW    = TweenInfo.new(0.38, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    SPRING  = TweenInfo.new(0.45, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
    BOUNCE  = TweenInfo.new(0.5,  Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    SINE    = TweenInfo.new(0.3,  Enum.EasingStyle.Sine,   Enum.EasingDirection.Out),
}

--> Helpers
local function Tween(o, ti, p) TweenService:Create(o, ti, p):Play() end

local function New(cls, props, kids)
    local i = Instance.new(cls)
    for k,v in pairs(props or {}) do i[k] = v end
    for _,c in ipairs(kids  or {}) do c.Parent = i end
    return i
end

local function Pad(p, t, b, l, r)
    return New("UIPadding",{
        Parent=p,
        PaddingTop    = UDim.new(0,t or 0),
        PaddingBottom = UDim.new(0,b or 0),
        PaddingLeft   = UDim.new(0,l or 0),
        PaddingRight  = UDim.new(0,r or 0),
    })
end

local function Corner(p, r)
    return New("UICorner",{Parent=p, CornerRadius=UDim.new(0,r or 6)})
end

local function Stroke(p, col, th, tr)
    return New("UIStroke",{
        Parent=p, Color=col or C.BORDER,
        Thickness=th or 1, Transparency=tr or 0,
    })
end

local function List(p, dir, gap, ha, va)
    return New("UIListLayout",{
        Parent=p,
        FillDirection       = dir or Enum.FillDirection.Vertical,
        Padding             = UDim.new(0, gap or 0),
        HorizontalAlignment = ha  or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = va  or Enum.VerticalAlignment.Top,
        SortOrder           = Enum.SortOrder.LayoutOrder,
    })
end

--> Ripple effect on any frame
local function Ripple(parent, x, y)
    local r = New("Frame",{
        Parent               = parent,
        Size                 = UDim2.new(0,0,0,0),
        Position             = UDim2.new(0, x - parent.AbsolutePosition.X,
                                          0, y - parent.AbsolutePosition.Y),
        AnchorPoint          = Vector2.new(0.5,0.5),
        BackgroundColor3     = C.WHITE,
        BackgroundTransparency = 0.82,
        ZIndex               = parent.ZIndex + 10,
        ClipsDescendants     = false,
    })
    Corner(r, 999)
    local sz = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.2
    Tween(r, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{
        Size = UDim2.new(0,sz,0,sz),
        BackgroundTransparency = 1,
    })
    task.delay(0.46, function() r:Destroy() end)
end

--> Smooth momentum dragging
local function MakeDraggable(handle, target)
    local down       = false
    local velocity   = Vector2.new()
    local lastPos    = Vector2.new()
    local lastDelta  = Vector2.new()
    local dragStart  = Vector2.new()
    local startOff   = Vector2.new()
    local connection

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end

        down      = true
        dragStart = Vector2.new(inp.Position.X, inp.Position.Y)
        startOff  = Vector2.new(target.Position.X.Offset, target.Position.Y.Offset)
        velocity  = Vector2.new()
        lastPos   = dragStart

        -- cancel any momentum loop
        if connection then connection:Disconnect(); connection = nil end

        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then
                down = false
                -- momentum
                local vel = lastDelta
                connection = RunService.Heartbeat:Connect(function(dt)
                    vel = vel * (1 - math.min(1, dt * 14))
                    if vel.Magnitude < 0.3 then
                        connection:Disconnect(); connection = nil; return
                    end
                    local cur = target.Position
                    -- clamp to screen
                    local sg = target.Parent
                    local maxX = sg and sg.AbsoluteSize.X - target.AbsoluteSize.X or 9999
                    local maxY = sg and sg.AbsoluteSize.Y - target.AbsoluteSize.Y or 9999
                    local nx = math.clamp(cur.X.Offset + vel.X, 0, maxX)
                    local ny = math.clamp(cur.Y.Offset + vel.Y, 0, maxY)
                    target.Position = UDim2.new(cur.X.Scale, nx, cur.Y.Scale, ny)
                end)
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not down then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end

        local cur    = Vector2.new(inp.Position.X, inp.Position.Y)
        local delta  = cur - dragStart
        lastDelta    = cur - lastPos
        lastPos      = cur

        local sg   = target.Parent
        local maxX = sg and sg.AbsoluteSize.X - target.AbsoluteSize.X or 9999
        local maxY = sg and sg.AbsoluteSize.Y - target.AbsoluteSize.Y or 9999
        local nx   = math.clamp(startOff.X + delta.X, 0, maxX)
        local ny   = math.clamp(startOff.Y + delta.Y, 0, maxY)
        target.Position = UDim2.new(target.Position.X.Scale, nx,
                                     target.Position.Y.Scale, ny)
    end)
end

--> ScreenGui factory
local function MakeSG(name)
    local n = "ALTER_" .. name
    pcall(function()
        local e = CoreGui:FindFirstChild(n)
        if e then e:Destroy() end
    end)
    local sg
    pcall(function()
        sg = New("ScreenGui",{
            Name=n, Parent=CoreGui,
            ResetOnSpawn=false,
            ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset=true,
            DisplayOrder=999,
        })
    end)
    if not sg then
        sg = New("ScreenGui",{
            Name=n,
            Parent=LP:WaitForChild("PlayerGui"),
            ResetOnSpawn=false,
            ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset=true,
        })
    end
    return sg
end

-->═══════════════════════════════════════════╗
-->                 RICHTEXT                  ║
-->═══════════════════════════════════════════╝
function AlterLib:RichText(color)
    local hex = string.format("#%02X%02X%02X",
        math.floor(color.R*255),
        math.floor(color.G*255),
        math.floor(color.B*255))
    return setmetatable({},{
        __index = function(_,word)
            return string.format('<font color="%s">%s</font>', hex, word)
        end
    })
end

-->═══════════════════════════════════════════╗
-->                  PROMPT                   ║
-->═══════════════════════════════════════════╝
function AlterLib:Prompt(cfg)
    local sg = MakeSG("PROMPT")

    local backdrop = New("Frame",{
        Parent=sg,
        Size=UDim2.fromScale(1,1),
        BackgroundColor3=C.BLACK,
        BackgroundTransparency=1,
        ZIndex=100,
    })
    Tween(backdrop, TI.MED, {BackgroundTransparency=0.5})

    local card = New("Frame",{
        Parent=backdrop,
        Size=UDim2.new(0,360,0,170),
        Position=UDim2.fromScale(0.5,0.5),
        AnchorPoint=Vector2.new(0.5,0.5),
        BackgroundColor3=C.PANEL,
        BackgroundTransparency=1,
        ZIndex=101,
    })
    Corner(card,10)
    Stroke(card, C.BORDER, 1)

    -- top accent line
    local accentLine = New("Frame",{
        Parent=card,
        Size=UDim2.new(1,0,0,2),
        BackgroundColor3=C.WHITE,
        BorderSizePixel=0,
        ZIndex=104,
    })
    Corner(accentLine,1)

    local hdr = New("Frame",{
        Parent=card,
        Size=UDim2.new(1,0,0,48),
        BackgroundColor3=C.CARD,
        ZIndex=102,
    })
    Corner(hdr,10)
    New("Frame",{Parent=hdr,Size=UDim2.new(1,0,0,10),
        Position=UDim2.new(0,0,1,-10),
        BackgroundColor3=C.CARD,BorderSizePixel=0,ZIndex=102})

    New("TextLabel",{
        Parent=hdr, Text=cfg.Title or "Prompt",
        TextSize=13, Font=Enum.Font.GothamBold,
        TextColor3=C.TEXT_PRI,
        BackgroundTransparency=1,
        Size=UDim2.new(1,-16,1,0),
        Position=UDim2.new(0,16,0,0),
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=103,
    })

    New("TextLabel",{
        Parent=card, Text=cfg.Message or "",
        TextSize=12, Font=Enum.Font.Gotham,
        TextColor3=C.TEXT_SEC,
        BackgroundTransparency=1,
        Size=UDim2.new(1,-32,0,38),
        Position=UDim2.new(0,16,0,56),
        TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true, ZIndex=103,
    })

    local btnRow = New("Frame",{
        Parent=card,
        Size=UDim2.new(1,-32,0,36),
        Position=UDim2.new(0,16,1,-52),
        BackgroundTransparency=1, ZIndex=102,
    })
    List(btnRow, Enum.FillDirection.Horizontal, 8)

    local function PBtn(txt, primary, cb)
        local b = New("TextButton",{
            Parent=btnRow, Text=txt,
            TextSize=12, Font=Enum.Font.GothamBold,
            TextColor3=primary and C.BLACK or C.TEXT_SEC,
            BackgroundColor3=primary and C.WHITE or C.ELEMENT,
            Size=UDim2.new(0.5,-4,1,0),
            AutoButtonColor=false, ZIndex=103,
        })
        Corner(b,6)
        if not primary then Stroke(b,C.BORDER,1) end
        b.MouseButton1Click:Connect(function()
            -- close animation
            Tween(card, TI.MED,{
                Size=UDim2.new(0,360,0,0),
                BackgroundTransparency=1,
            })
            Tween(backdrop, TI.MED,{BackgroundTransparency=1})
            task.delay(0.25, function()
                if cb then cb() end
                sg:Destroy()
            end)
        end)
        b.MouseEnter:Connect(function()
            Tween(b,TI.FAST,{BackgroundColor3=primary and Color3.fromRGB(220,220,220) or C.HOVER})
        end)
        b.MouseLeave:Connect(function()
            Tween(b,TI.FAST,{BackgroundColor3=primary and C.WHITE or C.ELEMENT})
        end)
        b.MouseButton1Down:Connect(function()
            Tween(b,TI.INSTANT,{BackgroundColor3=primary and Color3.fromRGB(190,190,190) or C.ACTIVE})
        end)
    end

    PBtn(cfg.NoText  or "Cancel",  false, cfg.No)
    PBtn(cfg.YesText or "Confirm", true,  cfg.Yes)

    -- animate in
    card.Size = UDim2.new(0,360,0,0)
    Tween(card, TI.SPRING,{
        Size=UDim2.new(0,360,0,170),
        BackgroundTransparency=0,
    })

    backdrop.MouseButton1Click:Connect(function()
        Tween(card,    TI.MED,{Size=UDim2.new(0,360,0,0),BackgroundTransparency=1})
        Tween(backdrop,TI.MED,{BackgroundTransparency=1})
        task.delay(0.25, function() sg:Destroy() end)
    end)
end

-->═══════════════════════════════════════════╗
-->                  WINDOW                   ║
-->═══════════════════════════════════════════╝
function AlterLib:Window(cfg)
    cfg = cfg or {}

    local WIN_W = 580
    local WIN_H = 500
    local TAB_W = 138

    local sg   = MakeSG(cfg.Folder or "WIN")
    local root = New("Frame",{
        Parent=sg,
        Size=UDim2.new(0,WIN_W,0,0),
        Position=UDim2.new(0,60,0,60),
        BackgroundColor3=C.SURFACE,
        BackgroundTransparency=1,
        ClipsDescendants=false,
    })
    Corner(root,10)
    Stroke(root,C.BORDER_DIM,1)

    -- Glow shadow underneath
    local shadow = New("ImageLabel",{
        Parent=root,
        Size=UDim2.new(1,40,1,40),
        Position=UDim2.new(0,-20,0,-20),
        BackgroundTransparency=1,
        Image="rbxassetid://6015897843",
        ImageColor3=C.BLACK,
        ImageTransparency=0.7,
        ScaleType=Enum.ScaleType.Slice,
        SliceCenter=Rect.new(49,49,450,450),
        ZIndex=0,
    })

    -->[ Title bar ]
    local titleBar = New("Frame",{
        Parent=root,
        Size=UDim2.new(1,0,0,48),
        BackgroundColor3=C.PANEL,
        ZIndex=3,
    })
    Corner(titleBar,10)
    New("Frame",{Parent=titleBar,
        Size=UDim2.new(1,0,0,10),
        Position=UDim2.new(0,0,1,-10),
        BackgroundColor3=C.PANEL,BorderSizePixel=0,ZIndex=3})
    Stroke(titleBar,C.BORDER_DIM,1)

    -- thin top accent
    local topAccent = New("Frame",{
        Parent=titleBar,
        Size=UDim2.new(0,0,0,2),
        Position=UDim2.new(0,10,0,0),
        BackgroundColor3=C.WHITE,
        BorderSizePixel=0,
        ZIndex=5,
    })
    Corner(topAccent,1)
    -- animate accent width on open
    task.delay(0.1, function()
        Tween(topAccent, TweenInfo.new(0.7,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{
            Size=UDim2.new(1,-20,0,2)
        })
    end)

    -- Hub name
    local hubName = New("TextLabel",{
        Parent=titleBar,
        Text=cfg.Name or "Alter",
        TextSize=14,
        Font=Enum.Font.GothamBlack,
        TextColor3=C.TEXT_PRI,
        BackgroundTransparency=1,
        Size=UDim2.new(0.5,0,1,0),
        Position=UDim2.new(0,18,0,0),
        TextXAlignment=Enum.TextXAlignment.Left,
        RichText=true,
        ZIndex=4,
        TextTransparency=1,
    })
    Tween(hubName, TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
        TextTransparency=0
    })

    -- Version tag
    New("TextLabel",{
        Parent=titleBar,
        Text="v2.0",
        TextSize=10,
        Font=Enum.Font.Gotham,
        TextColor3=C.TEXT_DIM,
        BackgroundTransparency=1,
        Size=UDim2.new(0,40,0,14),
        Position=UDim2.new(0,18,1,-18),
        ZIndex=4,
    })

    -- Controls
    local ctrlRow = New("Frame",{
        Parent=titleBar,
        Size=UDim2.new(0,60,0,22),
        Position=UDim2.new(1,-72,0.5,-11),
        BackgroundTransparency=1,
        ZIndex=4,
    })
    List(ctrlRow,Enum.FillDirection.Horizontal,6)

    local minimised = false
    local bodyRef

    local function CtrlBtn(sym, action)
        local b = New("TextButton",{
            Parent=ctrlRow,
            Text=sym,
            TextSize=11,
            Font=Enum.Font.GothamBold,
            TextColor3=C.TEXT_DIM,
            BackgroundColor3=C.ELEMENT,
            Size=UDim2.new(0,22,0,22),
            AutoButtonColor=false,
            ZIndex=5,
        })
        Corner(b,5)
        Stroke(b,C.BORDER_DIM,1)
        b.MouseButton1Click:Connect(action)
        b.MouseEnter:Connect(function()
            Tween(b,TI.FAST,{BackgroundColor3=C.HOVER,TextColor3=C.WHITE})
        end)
        b.MouseLeave:Connect(function()
            Tween(b,TI.FAST,{BackgroundColor3=C.ELEMENT,TextColor3=C.TEXT_DIM})
        end)
        b.MouseButton1Down:Connect(function()
            Tween(b,TI.INSTANT,{BackgroundColor3=C.ACTIVE})
        end)
        return b
    end

    CtrlBtn("−", function()
        minimised = not minimised
        Tween(root, TI.MED,{
            Size = minimised
                and UDim2.new(0,WIN_W,0,48)
                or  UDim2.new(0,WIN_W,0,WIN_H)
        })
    end)
    CtrlBtn("×", function()
        Tween(root, TI.MED,{
            Size=UDim2.new(0,WIN_W,0,0),
            BackgroundTransparency=1,
        })
        task.delay(0.28,function() sg:Destroy() end)
    end)

    MakeDraggable(titleBar, root)

    -->[ Body ]
    local body = New("Frame",{
        Parent=root,
        Size=UDim2.new(1,0,1,-48),
        Position=UDim2.new(0,0,0,48),
        BackgroundTransparency=1,
        ClipsDescendants=true,
    })
    bodyRef = body

    -->[ Sidebar ]
    local sidebar = New("Frame",{
        Parent=body,
        Size=UDim2.new(0,TAB_W,1,0),
        BackgroundColor3=C.PANEL,
        BorderSizePixel=0,
        ZIndex=2,
    })
    Corner(sidebar,10)
    -- square off top-right + bottom-right
    New("Frame",{Parent=sidebar,
        Size=UDim2.new(0,10,1,0),
        Position=UDim2.new(1,-10,0,0),
        BackgroundColor3=C.PANEL,BorderSizePixel=0,ZIndex=2})
    New("Frame",{Parent=sidebar,
        Size=UDim2.new(1,0,0,10),
        BackgroundColor3=C.PANEL,BorderSizePixel=0,ZIndex=2})

    -- separator
    New("Frame",{Parent=sidebar,
        Size=UDim2.new(0,1,1,0),
        Position=UDim2.new(1,0,0,0),
        BackgroundColor3=C.BORDER_DIM,BorderSizePixel=0,ZIndex=3})

    -- Brand mark
    local brand = New("TextLabel",{
        Parent=sidebar,
        Text="ALTER",
        TextSize=13,
        Font=Enum.Font.GothamBlack,
        TextColor3=C.TEXT_DIM,
        LetterSpacing=8,
        BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,48),
        Position=UDim2.new(0,0,0,6),
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=3,
        TextTransparency=1,
    })
    Tween(brand,TweenInfo.new(0.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
        TextTransparency=0
    })

    -- divider under brand
    New("Frame",{Parent=sidebar,
        Size=UDim2.new(1,-24,0,1),
        Position=UDim2.new(0,12,0,52),
        BackgroundColor3=C.BORDER_DIM,BorderSizePixel=0,ZIndex=3})

    local tabScroll = New("ScrollingFrame",{
        Parent=sidebar,
        Size=UDim2.new(1,0,1,-62),
        Position=UDim2.new(0,0,0,60),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ScrollBarThickness=0,
        CanvasSize=UDim2.new(0,0,0,0),
        ZIndex=3,
    })
    Pad(tabScroll,6,6,8,8)
    local tabLL = List(tabScroll,Enum.FillDirection.Vertical,2)
    tabLL.Changed:Connect(function()
        tabScroll.CanvasSize=UDim2.new(0,0,0,tabLL.AbsoluteContentSize.Y+12)
    end)

    -->[ Content area ]
    local content = New("Frame",{
        Parent=body,
        Size=UDim2.new(1,-TAB_W,1,0),
        Position=UDim2.new(0,TAB_W,0,0),
        BackgroundTransparency=1,
        ClipsDescendants=true,
    })

    -- Open animation
    Tween(root, TI.SPRING,{
        Size=UDim2.new(0,WIN_W,0,WIN_H),
        BackgroundTransparency=0,
    })

    -->════════════════════════════════════════
    local winObj = { _tabs = {} }

    function winObj:Tab(name)
        local tabObj = { _name=name }

        -- Tab button
        local btn = New("TextButton",{
            Parent=tabScroll,
            Text="",
            Size=UDim2.new(1,0,0,34),
            BackgroundColor3=C.PANEL,
            BackgroundTransparency=1,
            AutoButtonColor=false,
            ZIndex=4,
        })
        Corner(btn,6)

        -- indicator bar (left edge)
        local ind = New("Frame",{
            Parent=btn,
            Size=UDim2.new(0,2,0,16),
            Position=UDim2.new(0,1,0.5,-8),
            BackgroundColor3=C.WHITE,
            BackgroundTransparency=1,
            BorderSizePixel=0,
            ZIndex=5,
        })
        Corner(ind,1)

        -- icon dot
        local dot = New("Frame",{
            Parent=btn,
            Size=UDim2.new(0,5,0,5),
            Position=UDim2.new(0,10,0.5,-2.5),
            BackgroundColor3=C.TEXT_DIM,
            BorderSizePixel=0,
            ZIndex=5,
        })
        Corner(dot,3)

        local lbl = New("TextLabel",{
            Parent=btn,
            Text=name,
            TextSize=12,
            Font=Enum.Font.GothamMedium,
            TextColor3=C.TEXT_DIM,
            BackgroundTransparency=1,
            Size=UDim2.new(1,-26,1,0),
            Position=UDim2.new(0,22,0,0),
            TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=5,
        })

        -- Panel
        local panel = New("ScrollingFrame",{
            Parent=content,
            Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1,
            BorderSizePixel=0,
            ScrollBarThickness=2,
            ScrollBarImageColor3=C.BORDER,
            CanvasSize=UDim2.new(0,0,0,0),
            Visible=false,
            ZIndex=2,
        })
        Pad(panel,14,14,14,14)
        local panelLL = List(panel,Enum.FillDirection.Vertical,10)
        panelLL.Changed:Connect(function()
            panel.CanvasSize=UDim2.new(0,0,0,panelLL.AbsoluteContentSize.Y+28)
        end)

        tabObj._panel = panel
        tabObj._btn   = btn
        tabObj._ind   = ind
        tabObj._dot   = dot
        tabObj._lbl   = lbl
        table.insert(winObj._tabs, tabObj)

        local function activate()
            for _,t in ipairs(winObj._tabs) do
                if t ~= tabObj then
                    -- slide panel out
                    t._panel.Visible = false
                    Tween(t._btn, TI.FAST,{BackgroundTransparency=1})
                    Tween(t._ind, TI.FAST,{BackgroundTransparency=1,Size=UDim2.new(0,2,0,10)})
                    Tween(t._dot, TI.FAST,{BackgroundColor3=C.TEXT_DIM})
                    Tween(t._lbl, TI.FAST,{TextColor3=C.TEXT_DIM, TextSize=12})
                end
            end
            panel.Visible = true
            panel.Position = UDim2.new(0,12,0,0)
            Tween(panel, TI.MED,{Position=UDim2.new(0,0,0,0)})

            Tween(btn, TI.MED,{
                BackgroundColor3=C.ELEMENT,
                BackgroundTransparency=0,
            })
            Tween(ind, TI.SPRING,{
                BackgroundTransparency=0,
                Size=UDim2.new(0,2,0,20),
            })
            Tween(dot, TI.FAST,{BackgroundColor3=C.WHITE})
            Tween(lbl, TI.FAST,{TextColor3=C.TEXT_PRI, TextSize=12})
        end

        btn.MouseButton1Click:Connect(function()
            activate()
            Ripple(btn, UserInputService:GetMouseLocation().X,
                        UserInputService:GetMouseLocation().Y)
        end)
        btn.MouseEnter:Connect(function()
            if panel.Visible then return end
            Tween(btn, TI.FAST,{BackgroundTransparency=0.88,BackgroundColor3=C.ELEMENT})
            Tween(lbl, TI.FAST,{TextColor3=C.TEXT_SEC})
        end)
        btn.MouseLeave:Connect(function()
            if panel.Visible then return end
            Tween(btn, TI.FAST,{BackgroundTransparency=1})
            Tween(lbl, TI.FAST,{TextColor3=C.TEXT_DIM})
        end)

        if #winObj._tabs == 1 then activate() end

        -->══════════════════════════════════
        function tabObj:Section(secName)
            local secObj = {}
            local secCollapsed = false

            local secWrap = New("Frame",{
                Parent=panel,
                Size=UDim2.new(1,0,0,0),
                BackgroundColor3=C.CARD,
                AutomaticSize=Enum.AutomaticSize.Y,
                ClipsDescendants=true,
                ZIndex=3,
            })
            Corner(secWrap,8)
            Stroke(secWrap,C.BORDER_DIM,1)

            -- Section slides in on creation
            secWrap.Size = UDim2.new(1,0,0,0)
            secWrap.BackgroundTransparency = 1
            task.defer(function()
                Tween(secWrap, TI.SPRING,{BackgroundTransparency=0})
            end)

            -- Header
            local secHdr = New("Frame",{
                Parent=secWrap,
                Size=UDim2.new(1,0,0,36),
                BackgroundColor3=C.ELEMENT,
                ZIndex=4,
            })
            Corner(secHdr,8)
            New("Frame",{Parent=secHdr,
                Size=UDim2.new(1,0,0,8),
                Position=UDim2.new(0,0,1,-8),
                BackgroundColor3=C.ELEMENT,BorderSizePixel=0,ZIndex=4})

            -- left accent stripe on section header
            local secAccent = New("Frame",{
                Parent=secHdr,
                Size=UDim2.new(0,2,0,16),
                Position=UDim2.new(0,8,0.5,-8),
                BackgroundColor3=C.WHITE,
                BorderSizePixel=0,
                ZIndex=5,
            })
            Corner(secAccent,1)

            local secLbl = New("TextLabel",{
                Parent=secHdr,
                Text=string.upper(secName or "Section"),
                TextSize=10,
                Font=Enum.Font.GothamBold,
                TextColor3=C.TEXT_SEC,
                BackgroundTransparency=1,
                Size=UDim2.new(1,-50,1,0),
                Position=UDim2.new(0,18,0,0),
                TextXAlignment=Enum.TextXAlignment.Left,
                ZIndex=5,
            })

            -- Collapse chevron button
            local chevBtn = New("TextButton",{
                Parent=secHdr,
                Text="∧",
                TextSize=11,
                Font=Enum.Font.GothamBold,
                TextColor3=C.TEXT_DIM,
                BackgroundTransparency=1,
                Size=UDim2.new(0,30,1,0),
                Position=UDim2.new(1,-34,0,0),
                AutoButtonColor=false,
                ZIndex=6,
            })

            -- Element container
            local elemWrap = New("Frame",{
                Parent=secWrap,
                Size=UDim2.new(1,0,0,0),
                Position=UDim2.new(0,0,0,36),
                BackgroundTransparency=1,
                AutomaticSize=Enum.AutomaticSize.Y,
                ZIndex=4,
                ClipsDescendants=false,
            })
            Pad(elemWrap,6,10,10,10)
            local elemLL = List(elemWrap,Enum.FillDirection.Vertical,6)

            -- store natural height for collapse
            local collapsedH  = 36
            local expandedH   = 0  -- computed after first render

            chevBtn.MouseButton1Click:Connect(function()
                secCollapsed = not secCollapsed

                if secCollapsed then
                    -- capture current expanded height
                    expandedH = secWrap.AbsoluteSize.Y
                    Tween(chevBtn, TI.MED, {Rotation=180})
                    secWrap.AutomaticSize = Enum.AutomaticSize.None
                    Tween(secWrap, TI.MED,{Size=UDim2.new(1,0,0,collapsedH)})
                    Tween(secLbl,  TI.FAST,{TextColor3=C.TEXT_DIM})
                else
                    Tween(chevBtn, TI.MED,{Rotation=0})
                    Tween(secWrap, TI.MED,{Size=UDim2.new(1,0,0,expandedH)})
                    Tween(secLbl,  TI.FAST,{TextColor3=C.TEXT_SEC})
                    task.delay(0.25,function()
                        secWrap.AutomaticSize = Enum.AutomaticSize.Y
                    end)
                end
            end)

            chevBtn.MouseEnter:Connect(function()
                Tween(chevBtn,TI.FAST,{TextColor3=C.WHITE})
            end)
            chevBtn.MouseLeave:Connect(function()
                Tween(chevBtn,TI.FAST,{TextColor3=C.TEXT_DIM})
            end)

            -- Click header to also collapse
            local hdrBtn = New("TextButton",{
                Parent=secHdr,
                Text="",
                Size=UDim2.new(1,-40,1,0),
                BackgroundTransparency=1,
                ZIndex=7,
            })
            hdrBtn.MouseButton1Click:Connect(function()
                chevBtn.MouseButton1Click:Fire()
            end)
            hdrBtn.MouseEnter:Connect(function()
                Tween(secHdr,TI.FAST,{BackgroundColor3=C.HOVER})
            end)
            hdrBtn.MouseLeave:Connect(function()
                Tween(secHdr,TI.FAST,{BackgroundColor3=C.ELEMENT})
            end)

            -->══════════════════════════════
            --> BUTTON
            -->══════════════════════════════
            function secObj:Button(lbl, cb)
                local btn = New("TextButton",{
                    Parent=elemWrap,
                    Text="",
                    Size=UDim2.new(1,0,0,36),
                    BackgroundColor3=C.ELEMENT,
                    AutoButtonColor=false,
                    ZIndex=5,
                })
                Corner(btn,6)
                Stroke(btn,C.BORDER_DIM,1)

                -- left glow bar (hidden until hover)
                local glowBar = New("Frame",{
                    Parent=btn,
                    Size=UDim2.new(0,2,0,0),
                    Position=UDim2.new(0,0,0.5,0),
                    AnchorPoint=Vector2.new(0,0.5),
                    BackgroundColor3=C.WHITE,
                    BorderSizePixel=0,
                    ZIndex=6,
                })
                Corner(glowBar,1)

                local btnTxt = New("TextLabel",{
                    Parent=btn,
                    Text=lbl or "Button",
                    TextSize=12,
                    Font=Enum.Font.GothamMedium,
                    TextColor3=C.TEXT_SEC,
                    BackgroundTransparency=1,
                    Size=UDim2.new(1,-40,1,0),
                    Position=UDim2.new(0,14,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left,
                    ZIndex=6,
                })

                local arrow = New("TextLabel",{
                    Parent=btn,
                    Text="→",
                    TextSize=14,
                    Font=Enum.Font.GothamBold,
                    TextColor3=C.TEXT_DIM,
                    BackgroundTransparency=1,
                    Size=UDim2.new(0,24,1,0),
                    Position=UDim2.new(1,-28,0,0),
                    TextXAlignment=Enum.TextXAlignment.Center,
                    ZIndex=6,
                })

                btn.MouseEnter:Connect(function()
                    Tween(btn,    TI.FAST,{BackgroundColor3=C.HOVER})
                    Tween(btnTxt, TI.FAST,{TextColor3=C.TEXT_PRI})
                    Tween(arrow,  TI.FAST,{TextColor3=C.WHITE, Position=UDim2.new(1,-22,0,0)})
                    Tween(glowBar,TI.MED, {Size=UDim2.new(0,2,0.6,0),Position=UDim2.new(0,0,0.2,0)})
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn,    TI.FAST,{BackgroundColor3=C.ELEMENT})
                    Tween(btnTxt, TI.FAST,{TextColor3=C.TEXT_SEC})
                    Tween(arrow,  TI.FAST,{TextColor3=C.TEXT_DIM, Position=UDim2.new(1,-28,0,0)})
                    Tween(glowBar,TI.FAST,{Size=UDim2.new(0,2,0,0),Position=UDim2.new(0,0,0.5,0)})
                end)
                btn.MouseButton1Down:Connect(function()
                    Tween(btn,    TI.INSTANT,{BackgroundColor3=C.ACTIVE})
                    Tween(btnTxt, TI.INSTANT,{TextColor3=C.WHITE})
                    local mp = UserInputService:GetMouseLocation()
                    Ripple(btn, mp.X, mp.Y)
                end)
                btn.MouseButton1Up:Connect(function()
                    Tween(btn,    TI.FAST,{BackgroundColor3=C.HOVER})
                    if cb then task.spawn(cb) end
                end)
            end

            -->══════════════════════════════
            --> TOGGLE
            -->══════════════════════════════
            function secObj:Toggle(lbl, cb)
                local obj   = {}
                local state = false

                local row = New("Frame",{
                    Parent=elemWrap,
                    Size=UDim2.new(1,0,0,36),
                    BackgroundColor3=C.ELEMENT,
                    ZIndex=5,
                })
                Corner(row,6)
                Stroke(row,C.BORDER_DIM,1)

                local togLbl = New("TextLabel",{
                    Parent=row,
                    Text=lbl or "Toggle",
                    TextSize=12,
                    Font=Enum.Font.GothamMedium,
                    TextColor3=C.TEXT_SEC,
                    BackgroundTransparency=1,
                    Size=UDim2.new(1,-60,1,0),
                    Position=UDim2.new(0,12,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left,
                    ZIndex=6,
                })

                local track = New("Frame",{
                    Parent=row,
                    Size=UDim2.new(0,36,0,19),
                    Position=UDim2.new(1,-48,0.5,-9.5),
                    BackgroundColor3=C.ACCENT_OFF,
                    ZIndex=6,
                })
                Corner(track,10)
                Stroke(track,C.BORDER,1)

                local thumb = New("Frame",{
                    Parent=track,
                    Size=UDim2.new(0,13,0,13),
                    Position=UDim2.new(0,3,0.5,-6.5),
                    BackgroundColor3=C.TEXT_DIM,
                    ZIndex=7,
                })
                Corner(thumb,7)

                local function setToggle(v, silent)
                    state = v
                    Tween(track, TI.MED,{BackgroundColor3=state and C.WHITE or C.ACCENT_OFF})
                    Tween(thumb, TI.SPRING,{
                        Position=state
                            and UDim2.new(0,20,0.5,-6.5)
                            or  UDim2.new(0,3, 0.5,-6.5),
                        BackgroundColor3=state and C.BLACK or C.TEXT_DIM,
                        Size=state
                            and UDim2.new(0,13,0,13)
                            or  UDim2.new(0,13,0,13),
                    })
                    Tween(togLbl,TI.FAST,{TextColor3=state and C.TEXT_PRI or C.TEXT_SEC})
                    if not silent and cb then task.spawn(cb,state) end
                end

                local hitbox = New("TextButton",{
                    Parent=row,Text="",
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1,ZIndex=8,
                })
                hitbox.MouseButton1Click:Connect(function()
                    setToggle(not state)
                    local mp=UserInputService:GetMouseLocation()
                    Ripple(row,mp.X,mp.Y)
                end)
                hitbox.MouseEnter:Connect(function()
                    Tween(row,TI.FAST,{BackgroundColor3=C.HOVER})
                end)
                hitbox.MouseLeave:Connect(function()
                    Tween(row,TI.FAST,{BackgroundColor3=C.ELEMENT})
                end)

                function obj:Set(v) setToggle(v,true) end
                function obj:Get() return state end
                return obj
            end

            -->══════════════════════════════
            --> SLIDER
            -->══════════════════════════════
            function secObj:Slider(lbl, min, max, default, cb)
                local obj = {}
                min=min or 0; max=max or 100
                default=math.clamp(default or min, min, max)
                local val = default

                local wrap = New("Frame",{
                    Parent=elemWrap,
                    Size=UDim2.new(1,0,0,52),
                    BackgroundColor3=C.ELEMENT,
                    ZIndex=5,
                })
                Corner(wrap,6)
                Stroke(wrap,C.BORDER_DIM,1)
                Pad(wrap,8,8,12,12)

                local topRow = New("Frame",{
                    Parent=wrap,
                    Size=UDim2.new(1,0,0,16),
                    BackgroundTransparency=1,ZIndex=6,
                })
                New("TextLabel",{
                    Parent=topRow,Text=lbl or "Slider",
                    TextSize=12,Font=Enum.Font.GothamMedium,
                    TextColor3=C.TEXT_PRI,BackgroundTransparency=1,
                    Size=UDim2.new(0.7,0,1,0),
                    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,
                })
                local valLbl = New("TextLabel",{
                    Parent=topRow,Text=tostring(val),
                    TextSize=12,Font=Enum.Font.GothamBold,
                    TextColor3=C.TEXT_SEC,BackgroundTransparency=1,
                    Size=UDim2.new(0.3,0,1,0),
                    Position=UDim2.new(0.7,0,0,0),
                    TextXAlignment=Enum.TextXAlignment.Right,ZIndex=7,
                })

                local track = New("Frame",{
                    Parent=wrap,
                    Size=UDim2.new(1,0,0,4),
                    Position=UDim2.new(0,0,1,-12),
                    BackgroundColor3=C.BORDER,ZIndex=6,
                })
                Corner(track,2)

                local fill = New("Frame",{
                    Parent=track,Size=UDim2.new(0,0,1,0),
                    BackgroundColor3=C.WHITE,ZIndex=7,
                })
                Corner(fill,2)

                local thumb = New("Frame",{
                    Parent=track,
                    Size=UDim2.new(0,14,0,14),
                    Position=UDim2.new(0,-7,0.5,-7),
                    BackgroundColor3=C.WHITE,ZIndex=8,
                })
                Corner(thumb,7)
                Stroke(thumb,C.BORDER,1)

                local function update(v, silent)
                    val = math.clamp(math.floor(v+0.5), min, max)
                    local pct = (val-min)/(max-min)
                    valLbl.Text = tostring(val)
                    Tween(fill,  TI.FAST,{Size=UDim2.new(pct,0,1,0)})
                    Tween(thumb, TI.FAST,{Position=UDim2.new(pct,-7,0.5,-7)})
                    if not silent and cb then task.spawn(cb,val) end
                end
                update(default,true)

                local dragging=false
                local function fromInput(inp)
                    local rel=math.clamp(
                        (inp.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                    update(min+rel*(max-min))
                end

                track.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1
                    or i.UserInputType==Enum.UserInputType.Touch then
                        dragging=true
                        Tween(thumb,TI.FAST,{Size=UDim2.new(0,18,0,18),Position=UDim2.new((val-min)/(max-min),-9,0.5,-9)})
                        fromInput(i)
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1
                    or i.UserInputType==Enum.UserInputType.Touch then
                        if dragging then
                            dragging=false
                            Tween(thumb,TI.SPRING,{Size=UDim2.new(0,14,0,14)})
                        end
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and(i.UserInputType==Enum.UserInputType.MouseMovement
                    or i.UserInputType==Enum.UserInputType.Touch) then
                        fromInput(i)
                    end
                end)

                -- hover
                wrap.MouseEnter:Connect(function()
                    Tween(wrap,TI.FAST,{BackgroundColor3=C.HOVER})
                end)
                wrap.MouseLeave:Connect(function()
                    Tween(wrap,TI.FAST,{BackgroundColor3=C.ELEMENT})
                end)

                function obj:Set(v) update(v,true) end
                function obj:Get() return val end
                return obj
            end

            -->══════════════════════════════
            --> DROPDOWN
            -->══════════════════════════════
            function secObj:Dropdown(lbl, opts, cb)
                local obj={} ; local sel=nil ; local open=false
                opts = opts or {}

                local ddFrame=New("Frame",{
                    Parent=elemWrap,
                    Size=UDim2.new(1,0,0,36),
                    BackgroundColor3=C.ELEMENT,
                    ClipsDescendants=false,ZIndex=10,
                })
                Corner(ddFrame,6)
                Stroke(ddFrame,C.BORDER_DIM,1)

                local ddHdr=New("TextButton",{
                    Parent=ddFrame,Text="",
                    Size=UDim2.new(1,0,0,36),
                    BackgroundTransparency=1,
                    AutoButtonColor=false,ZIndex=11,
                })
                New("TextLabel",{
                    Parent=ddHdr,Text=lbl or "Dropdown",
                    TextSize=12,Font=Enum.Font.GothamMedium,
                    TextColor3=C.TEXT_SEC,BackgroundTransparency=1,
                    Size=UDim2.new(0.5,0,1,0),
                    Position=UDim2.new(0,12,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,
                })
                local selLbl=New("TextLabel",{
                    Parent=ddHdr,Text="None",
                    TextSize=12,Font=Enum.Font.GothamMedium,
                    TextColor3=C.TEXT_PRI,BackgroundTransparency=1,
                    Size=UDim2.new(0.42,0,1,0),
                    Position=UDim2.new(0.5,0,0,0),
                    TextXAlignment=Enum.TextXAlignment.Right,ZIndex=12,
                })
                local chev=New("TextLabel",{
                    Parent=ddHdr,Text="⌄",TextSize=13,
                    Font=Enum.Font.GothamBold,TextColor3=C.TEXT_DIM,
                    BackgroundTransparency=1,
                    Size=UDim2.new(0,20,1,0),
                    Position=UDim2.new(1,-22,0,0),
                    TextXAlignment=Enum.TextXAlignment.Center,ZIndex=12,
                })

                local ddPanel=New("Frame",{
                    Parent=ddFrame,
                    Size=UDim2.new(1,0,0,0),
                    Position=UDim2.new(0,0,0,40),
                    BackgroundColor3=C.CARD,
                    ClipsDescendants=true,ZIndex=20,Visible=false,
                })
                Corner(ddPanel,6)
                Stroke(ddPanel,C.BORDER_DIM,1)

                local ddScroll=New("ScrollingFrame",{
                    Parent=ddPanel,Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1,BorderSizePixel=0,
                    ScrollBarThickness=2,ScrollBarImageColor3=C.BORDER,
                    CanvasSize=UDim2.new(0,0,0,0),ZIndex=21,
                })
                Pad(ddScroll,4,4,6,6)
                local ddLL=List(ddScroll,Enum.FillDirection.Vertical,2)
                ddLL.Changed:Connect(function()
                    ddScroll.CanvasSize=UDim2.new(0,0,0,ddLL.AbsoluteContentSize.Y+8)
                end)

                local function build()
                    for _,c in ipairs(ddScroll:GetChildren()) do
                        if c:IsA("UIListLayout") or c:IsA("UIPadding") then continue end
                        c:Destroy()
                    end
                    for _,opt in ipairs(opts) do
                        local ob=New("TextButton",{
                            Parent=ddScroll,Text=tostring(opt),
                            TextSize=12,Font=Enum.Font.GothamMedium,
                            TextColor3=opt==sel and C.TEXT_PRI or C.TEXT_SEC,
                            BackgroundColor3=opt==sel and C.ELEMENT or C.CARD,
                            Size=UDim2.new(1,0,0,28),
                            AutoButtonColor=false,
                            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=22,
                        })
                        Pad(ob,0,0,8,0)
                        Corner(ob,4)
                        if opt==sel then
                            New("TextLabel",{
                                Parent=ob,Text="✓",TextSize=10,
                                Font=Enum.Font.GothamBold,TextColor3=C.TEXT_PRI,
                                BackgroundTransparency=1,
                                Size=UDim2.new(0,18,1,0),
                                Position=UDim2.new(1,-20,0,0),
                                TextXAlignment=Enum.TextXAlignment.Center,ZIndex=23,
                            })
                        end
                        ob.MouseEnter:Connect(function()
                            if opt~=sel then Tween(ob,TI.FAST,{BackgroundColor3=C.HOVER}) end
                        end)
                        ob.MouseLeave:Connect(function()
                            if opt~=sel then Tween(ob,TI.FAST,{BackgroundColor3=C.CARD}) end
                        end)
                        ob.MouseButton1Click:Connect(function()
                            sel=opt; selLbl.Text=tostring(opt); build()
                            if cb then task.spawn(cb,opt) end
                        end)
                    end
                end
                build()

                local function toggleDD()
                    open=not open
                    if open then
                        local h=math.min(#opts*30+8, 5*30+8)
                        ddPanel.Visible=true
                        ddPanel.Size=UDim2.new(1,0,0,0)
                        Tween(ddPanel,TI.MED,{Size=UDim2.new(1,0,0,h)})
                        Tween(chev,TI.MED,{Rotation=180})
                        Tween(ddFrame,TI.FAST,{BackgroundColor3=C.HOVER})
                    else
                        Tween(ddPanel,TI.MED,{Size=UDim2.new(1,0,0,0)})
                        Tween(chev,TI.MED,{Rotation=0})
                        Tween(ddFrame,TI.FAST,{BackgroundColor3=C.ELEMENT})
                        task.delay(0.25,function()
                            if not open then ddPanel.Visible=false end
                        end)
                    end
                end

                ddHdr.MouseButton1Click:Connect(function()
                    toggleDD()
                    local mp=UserInputService:GetMouseLocation()
                    Ripple(ddFrame,mp.X,mp.Y)
                end)
                ddHdr.MouseEnter:Connect(function()
                    if not open then Tween(ddFrame,TI.FAST,{BackgroundColor3=C.HOVER}) end
                end)
                ddHdr.MouseLeave:Connect(function()
                    if not open then Tween(ddFrame,TI.FAST,{BackgroundColor3=C.ELEMENT}) end
                end)

                function obj:Set(v) sel=v; selLbl.Text=tostring(v); build() end
                function obj:Refresh(o,del)
                    opts=o or {}
                    if del then sel=nil; selLbl.Text="None" end
                    build()
                end
                function obj:Get() return sel end
                return obj
            end

            -->══════════════════════════════
            --> BIND
            -->══════════════════════════════
            function secObj:Bind(lbl, default, cb)
                local obj={} ; local bound=default ; local binding=false

                local row=New("Frame",{
                    Parent=elemWrap,
                    Size=UDim2.new(1,0,0,36),
                    BackgroundColor3=C.ELEMENT,ZIndex=5,
                })
                Corner(row,6)
                Stroke(row,C.BORDER_DIM,1)

                New("TextLabel",{
                    Parent=row,Text=lbl or "Bind",
                    TextSize=12,Font=Enum.Font.GothamMedium,
                    TextColor3=C.TEXT_SEC,BackgroundTransparency=1,
                    Size=UDim2.new(0.55,0,1,0),
                    Position=UDim2.new(0,12,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6,
                })

                local function kn(k)
                    if not k then return "None" end
                    return tostring(k):gsub("Enum.KeyCode.","")
                end

                local pill=New("TextButton",{
                    Parent=row,
                    Text="["..kn(bound).."]",
                    TextSize=11,Font=Enum.Font.GothamBold,
                    TextColor3=C.TEXT_PRI,
                    BackgroundColor3=C.CARD,
                    Size=UDim2.new(0,76,0,24),
                    Position=UDim2.new(1,-86,0.5,-12),
                    AutoButtonColor=false,ZIndex=6,
                })
                Corner(pill,5)
                Stroke(pill,C.BORDER,1)

                local function setBind(k,silent)
                    bound=k; binding=false
                    pill.Text="["..kn(k).."]"
                    Tween(pill,TI.FAST,{
                        TextColor3=C.TEXT_PRI,
                        BackgroundColor3=C.CARD,
                    })
                    if not silent and cb then task.spawn(cb,k) end
                end

                pill.MouseButton1Click:Connect(function()
                    if binding then return end
                    binding=true
                    pill.Text="[  ···  ]"
                    Tween(pill,TI.FAST,{
                        TextColor3=C.WHITE,
                        BackgroundColor3=C.ELEMENT,
                    })
                    -- pulse while waiting
                    local pulse; pulse=task.spawn(function()
                        while binding do
                            Tween(pill,TI.SINE,{TextTransparency=0.5})
                            task.wait(0.3)
                            Tween(pill,TI.SINE,{TextTransparency=0})
                            task.wait(0.3)
                        end
                    end)
                end)

                UserInputService.InputBegan:Connect(function(i,gp)
                    if gp then return end
                    if binding then
                        if i.UserInputType==Enum.UserInputType.Keyboard then
                            setBind(i.KeyCode)
                        end
                    else
                        if bound and i.KeyCode==bound then
                            if cb then task.spawn(cb,bound) end
                        end
                    end
                end)

                row.MouseEnter:Connect(function()
                    Tween(row,TI.FAST,{BackgroundColor3=C.HOVER})
                end)
                row.MouseLeave:Connect(function()
                    Tween(row,TI.FAST,{BackgroundColor3=C.ELEMENT})
                end)

                function obj:Set(k) setBind(k,true) end
                function obj:Get() return bound end
                return obj
            end

            return secObj
        end -- :Section()

        return tabObj
    end -- :Tab()

    return winObj
end -- :Window()

return AlterLib
