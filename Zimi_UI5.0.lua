-- [兼容层] 确保 task / utf8 / table 库在各种执行器上可用
local task = task or {}
if not task.spawn then task.spawn = function(f) return coroutine.wrap(f)() end end
if not task.wait then task.wait = function(t) local s = tick(); repeat until tick() - s >= (t or 0) end end
if not task.delay then task.delay = function(t, f) task.spawn(function() task.wait(t) f() end) end end

local utf8 = utf8 or {}
if not utf8.codes then
    utf8.codes = function(s)
        local i = 1
        return function()
            if i > #s then return nil end
            local c = s:sub(i, i)
            i = i + 1
            return i - 1, c:byte()
        end
    end
end
if not utf8.char then utf8.char = function(...) local a={...}; return string.char(table.unpack(a)) end end

if not table.clear then table.clear = function(t) for k in pairs(t) do t[k] = nil end end end
if not table.unpack then table.unpack = unpack end

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

_G.ZimiUnloaded = false
local ZimiConnections = {}
local StartTime = tick()

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local IslandPanel
local UpdateIslandDisplay
local fpsAccum = 0
local fpsFrames = 0

local ZimiSettings = {
    PlayerModsEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    TpMode = "单次",
    TpTarget = nil,
    TpPosition = "玩家处",
    TpOrbitRadius = 10,
    TpOrbitSpeed = 2,
    TpOrbitHeight = 0,
    TpSmoothSpeed = 15,
    QuickBtnEnabled = false,
    QuickBtnLocked = false,
    AimEnabled = false,
    AimWallCheck = true,
    AimDeathCheck = true,
    AimShieldCheck = true,
    AimTeamCheck = true,
    AimFriendCheck = true,
    AimFov = 120,
    AimFovLimitEnabled = true,
    AimTargetInfo = false,
    AimParts = {},
    AimTarget = nil,
    AimBtnEnabled = false,
    AimBtnLocked = false,
    AimNPCMode = false,
    AimNpcTarget = nil,
    NpcList = {},
    ESP = {
        Master = false,
        MaxDist = 2000,
        DistScale = true,
        Box = {Enabled = false, Color = Color3.fromRGB(255, 255, 255)},
        Skel = {Enabled = false, Color = Color3.fromRGB(255, 255, 255)},
        Chams = {Enabled = false, Color = Color3.fromRGB(255, 50, 50)},
        Name = {Enabled = false, Color = Color3.fromRGB(255, 255, 255)},
        Dist = {Enabled = false, Color = Color3.fromRGB(200, 200, 200)},
        Health = {Enabled = false},
        Tracer = {Enabled = false, Color = Color3.fromRGB(255, 255, 255)},
        ShowNPCs = false,
        AutoScanNPCs = false,
        EspNpcTarget = nil,
        NPCList = {}
    },
    Render = {
        FullBright = false,
        NoFog = false,
        OldAmbient = nil,
        OldOutdoorAmbient = nil,
        OldFogEnd = nil
    },
    Hitbox = {
        Enabled = false,
        TargetPart = "HumanoidRootPart",
        SizeX = 5, SizeY = 5, SizeZ = 5,
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.5,
        Material = Enum.Material.ForceField,
        Outline = false,
        OutlineColor = Color3.fromRGB(255, 255, 255),
        OutlineTrans = 0,
        CanCollide = true,
        NpcTarget = nil,
        NPCMode = false,
        TeamCheck = true,
        FriendCheck = true
    },
    PlayerFunc = {
        FlyEnabled = false,
        FlySpeed = 50,
        FlyBtnEnabled = false,
        FlyBtnLocked = false,
        SpinEnabled = false,
        SpinSpeed = 50,
        Frozen = false,
        PlatformStand = false,
        InfJump = false,
        Derp = false,
        Noclip = false
    },
    ServerFunc = {
        ServerHop = false,
        AntiAfk = false
    },
    GuiFX = {
        Master = false,
        FlowingLight = false,
        FlowHue = 180,
        FlowSpeed = 5,
        MatrixRain = false,
        MatrixDensity = 10,
        MatrixSpeed = 8,
        Snow = false,
        SnowDensity = 20,
        Rain = false,
        RainDensity = 15,
        IslandGlow = false,
        IslandGlowIntensity = 0.5
    }
}

for _, gui in pairs(CoreGui:GetChildren()) do
    if gui.Name == "ZimiUI" or gui.Name == "ZimiQuickBtn" or gui.Name == "ZimiAimBtn" then gui:Destroy() end
end
for _, fx in pairs(Lighting:GetChildren()) do
    if fx.Name == "ZimiBlur" then fx:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZimiUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local success, _ = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local BlurEffect = Instance.new("BlurEffect")
BlurEffect.Name = "ZimiBlur"
BlurEffect.Size = 0
BlurEffect.Parent = Lighting

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 360)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(1.5, 0, 0.5, 0) 
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundTransparency = 1
TopBar.ZIndex = 10
TopBar.Parent = MainFrame

local PillFrame = Instance.new("Frame")
PillFrame.Name = "PillFrame"
PillFrame.Size = UDim2.new(0, 140, 0, 28)
PillFrame.Position = UDim2.new(0, 10, 0.5, -14)
PillFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
PillFrame.BackgroundTransparency = 0.2
PillFrame.BorderSizePixel = 0
PillFrame.ZIndex = 10
PillFrame.Parent = TopBar
local PillCorner = Instance.new("UICorner")
PillCorner.CornerRadius = UDim.new(1, 0)
PillCorner.Parent = PillFrame

local PillAvatar = Instance.new("ImageLabel")
PillAvatar.Size = UDim2.new(0, 24, 0, 24)
PillAvatar.Position = UDim2.new(0, 2, 0.5, -12)
PillAvatar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
task.spawn(function() pcall(function() PillAvatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end) end)
PillAvatar.ZIndex = 10
PillAvatar.Parent = PillFrame
local PillAvatarCorner = Instance.new("UICorner")
PillAvatarCorner.CornerRadius = UDim.new(1, 0)
PillAvatarCorner.Parent = PillAvatar

local PillName = Instance.new("TextLabel")
PillName.Size = UDim2.new(1, -36, 1, 0)
PillName.Position = UDim2.new(0, 32, 0, 0)
PillName.BackgroundTransparency = 1
PillName.Text = LocalPlayer.Name
PillName.TextColor3 = Color3.fromRGB(255, 255, 255)
PillName.TextSize = 12
PillName.Font = Enum.Font.GothamSemibold
PillName.TextXAlignment = Enum.TextXAlignment.Left
PillName.ZIndex = 10
PillName.Parent = PillFrame

local ControlContainer = Instance.new("Frame")
ControlContainer.Size = UDim2.new(0, 70, 1, 0)
ControlContainer.Position = UDim2.new(1, -80, 0, 0)
ControlContainer.BackgroundTransparency = 1
ControlContainer.ZIndex = 10
ControlContainer.Parent = TopBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
MinimizeBtn.Position = UDim2.new(0, 0, 0.5, -13)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MinimizeBtn.BackgroundTransparency = 0.2
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 18
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.ZIndex = 10
MinimizeBtn.Parent = ControlContainer
local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 6)
MinimizeCorner.Parent = MinimizeBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(0, 34, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BackgroundTransparency = 0.2
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = 10
CloseBtn.Parent = ControlContainer
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, 0, 1, -40)
ContentContainer.Position = UDim2.new(0, 0, 0, 40)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 2
ContentContainer.Parent = MainFrame

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0, 1, 1, -20)
Divider.Position = UDim2.new(0, 135, 0, 10)
Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Divider.BackgroundTransparency = 0.92
Divider.BorderSizePixel = 0
Divider.ZIndex = 3
Divider.Parent = ContentContainer

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size = UDim2.new(0, 125, 1, -20)
Sidebar.Position = UDim2.new(0, 10, 0, 10)
Sidebar.BackgroundTransparency = 1
Sidebar.ScrollBarThickness = 2
Sidebar.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.ZIndex = 2
Sidebar.Parent = ContentContainer
local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 4)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -155, 1, -20)
ContentArea.Position = UDim2.new(0, 145, 0, 10)
ContentArea.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ContentArea.BackgroundTransparency = 0.4
ContentArea.BorderSizePixel = 0
ContentArea.ClipsDescendants = true
ContentArea.ZIndex = 2
ContentArea.Parent = ContentContainer
local ContentAreaCorner = Instance.new("UICorner")
ContentAreaCorner.CornerRadius = UDim.new(0, 8)
ContentAreaCorner.Parent = ContentArea

local Tabs = {"信息", "玩家参数", "传送", "自瞄", "ESP", "渲染", "Hitbox", "服务器功能", "玩家功能", "个性GUI", "配置"}
local PageFrames = {}
local TabButtons = {}
local CurrentPage = nil

for i, tabName in ipairs(Tabs) do
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, -6, 0, 30)
    TabBtn.BackgroundColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
    TabBtn.BackgroundTransparency = i == 1 and 0.88 or 0.8
    TabBtn.Text = "  " .. tabName
    TabBtn.TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    TabBtn.TextSize = 12
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.ZIndex = 2
    TabBtn.LayoutOrder = i
    TabBtn.Parent = Sidebar
    local TBCorner = Instance.new("UICorner")
    TBCorner.CornerRadius = UDim.new(0, 6)
    TBCorner.Parent = TabBtn
    
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, -20, 1, -20)
    Page.Position = UDim2.new(0, 10, 0, 10)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.Visible = (i == 1)
    Page.ZIndex = 2
    Page.Parent = ContentArea
    local PageLayout = Instance.new("UIListLayout")
    PageLayout.Padding = UDim.new(0, 10)
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Parent = Page
    
    PageFrames[tabName] = Page
    TabButtons[tabName] = TabBtn
    
    table.insert(ZimiConnections, TabBtn.MouseButton1Click:Connect(function()
        if CurrentPage == Page then return end
        local previousPage = CurrentPage
        CurrentPage = Page
        for name, p in pairs(PageFrames) do
            TweenService:Create(TabButtons[name], TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(25, 25, 25), BackgroundTransparency = 0.8, TextColor3 = Color3.fromRGB(180, 180, 180)}):Play()
        end
        TweenService:Create(TabBtn, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.88, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        if previousPage then
            local prev = previousPage
            local fadeOut = TweenService:Create(prev, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0, -20, 0, 10)})
            fadeOut:Play()
            fadeOut.Completed:Connect(function() if CurrentPage ~= prev then prev.Visible = false end end)
        end
        Page.Visible = true
        Page.Position = UDim2.new(0, 25, 0, 10)
        TweenService:Create(Page, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 10, 0, 10)}):Play()
    end))
    table.insert(ZimiConnections, TabBtn.MouseEnter:Connect(function() if CurrentPage ~= Page then TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play() end end))
    table.insert(ZimiConnections, TabBtn.MouseLeave:Connect(function() if CurrentPage ~= Page then TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.8}):Play() end end))
end

CurrentPage = PageFrames["信息"]

-- [UI Components Helpers]
local function CreateToggle(parent, titleText, default, callback)
    local ToggleFrame = Instance.new("TextButton")
    ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ToggleFrame.BackgroundTransparency = 0.4
    ToggleFrame.AutoButtonColor = false
    ToggleFrame.Text = ""
    ToggleFrame.Parent = parent
    local TCorner = Instance.new("UICorner")
    TCorner.CornerRadius = UDim.new(0, 8)
    TCorner.Parent = ToggleFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = titleText
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = ToggleFrame
    
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(0, 40, 0, 20)
    Track.Position = UDim2.new(1, -50, 0.5, -10)
    Track.BackgroundColor3 = default and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(50, 50, 50)
    Track.Parent = ToggleFrame
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(1, 0)
    BtnCorner.Parent = Track
    
    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 16, 0, 16)
    Indicator.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.Parent = Track
    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(1, 0)
    IndCorner.Parent = Indicator
    
    local state = default
    table.insert(ZimiConnections, ToggleFrame.MouseButton1Click:Connect(function()
        state = not state
        local color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(50, 50, 50)
        local pos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        TweenService:Create(Track, TweenInfo.new(0.25), {BackgroundColor3 = color}):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = pos}):Play()
        if callback then callback(state) end
    end))
    return { GetState = function() return state end }
end

local function CreateSlider(parent, titleText, min, max, default, callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, 0, 0, 55)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SliderFrame.BackgroundTransparency = 0.4
    SliderFrame.Parent = parent
    local SCorner = Instance.new("UICorner")
    SCorner.CornerRadius = UDim.new(0, 8)
    SCorner.Parent = SliderFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 0, 20)
    Label.Position = UDim2.new(0, 15, 0, 8)
    Label.BackgroundTransparency = 1
    Label.Text = titleText
    Label.TextColor3 = Color3.fromRGB(100, 100, 100)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = SliderFrame
    
    local ValueBox = Instance.new("TextBox")
    ValueBox.Size = UDim2.new(0, 45, 0, 20)
    ValueBox.Position = UDim2.new(1, -60, 0, 8)
    ValueBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ValueBox.Text = tostring(default)
    ValueBox.TextColor3 = Color3.fromRGB(100, 100, 100)
    ValueBox.TextSize = 12
    ValueBox.Font = Enum.Font.Gotham
    ValueBox.ClearTextOnFocus = false
    ValueBox.TextEditable = false
    ValueBox.Parent = SliderFrame
    local VBCorner = Instance.new("UICorner")
    VBCorner.CornerRadius = UDim.new(0, 4)
    VBCorner.Parent = ValueBox
    
    local BarBG = Instance.new("TextButton")
    BarBG.Size = UDim2.new(1, -30, 0, 6)
    BarBG.Position = UDim2.new(0, 15, 0, 38)
    BarBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    BarBG.Text = ""
    BarBG.AutoButtonColor = false
    BarBG.Parent = SliderFrame
    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = BarBG
    
    local percent = (default - min) / (max - min)
    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(percent, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    BarFill.Parent = BarBG
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = BarFill
    
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 12, 0, 12)
    Knob.Position = UDim2.new(1, -6, 0.5, -6)
    Knob.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    Knob.Parent = BarFill
    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob
    
    local isInteractable = false
    local dragging = false
    
    local function UpdateValue(newVal)
        if not isInteractable then return end
        newVal = math.clamp(math.floor(newVal), min, max)
        ValueBox.Text = tostring(newVal)
        local p = (newVal - min) / (max - min)
        TweenService:Create(BarFill, TweenInfo.new(0.1), {Size = UDim2.new(p, 0, 1, 0)}):Play()
        if callback then callback(newVal) end
    end
    
    table.insert(ZimiConnections, BarBG.InputBegan:Connect(function(input)
        if not isInteractable then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local p = math.clamp((input.Position.X - BarBG.AbsolutePosition.X) / BarBG.AbsoluteSize.X, 0, 1)
            UpdateValue(min + ((max - min) * p))
        end
    end))
    table.insert(ZimiConnections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))
    table.insert(ZimiConnections, UserInputService.InputChanged:Connect(function(input)
        if dragging and isInteractable and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local p = math.clamp((input.Position.X - BarBG.AbsolutePosition.X) / BarBG.AbsoluteSize.X, 0, 1)
            UpdateValue(min + ((max - min) * p))
        end
    end))
    table.insert(ZimiConnections, ValueBox.FocusLost:Connect(function()
        if not isInteractable then return end
        local num = tonumber(ValueBox.Text)
        if num then UpdateValue(num) else UpdateValue(default) end
    end))
    
    local api = {}
    function api.SetInteractable(state)
        isInteractable = state
        ValueBox.TextEditable = state
        local colorWhite = Color3.fromRGB(255, 255, 255)
        local colorDim = Color3.fromRGB(100, 100, 100)
        TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = state and colorWhite or colorDim}):Play()
        TweenService:Create(ValueBox, TweenInfo.new(0.2), {TextColor3 = state and colorWhite or colorDim}):Play()
        TweenService:Create(BarFill, TweenInfo.new(0.2), {BackgroundColor3 = state and colorWhite or Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {BackgroundColor3 = state and colorWhite or Color3.fromRGB(150, 150, 150)}):Play()
    end
    function api.SetVisible(state) SliderFrame.Visible = state end
    return api
end

local function CreateAccordionDropdown(parent, titleText, options, isPlayerList, callback)
    local MainDrop = Instance.new("Frame")
    MainDrop.Size = UDim2.new(1, 0, 0, 40)
    MainDrop.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainDrop.BackgroundTransparency = 0.4
    MainDrop.ClipsDescendants = true
    MainDrop.Parent = parent
    local MCorner = Instance.new("UICorner")
    MCorner.CornerRadius = UDim.new(0, 8)
    MCorner.Parent = MainDrop
    
    local DropBtn = Instance.new("TextButton")
    DropBtn.Size = UDim2.new(1, 0, 0, 40)
    DropBtn.BackgroundTransparency = 1
    DropBtn.Text = ""
    DropBtn.Parent = MainDrop
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 100, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = titleText
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = DropBtn
    
    local SelectedText = Instance.new("TextLabel")
    SelectedText.Size = UDim2.new(0, 150, 1, 0)
    SelectedText.Position = UDim2.new(1, -180, 0, 0)
    SelectedText.BackgroundTransparency = 1
    SelectedText.Text = "请选择..."
    SelectedText.TextColor3 = Color3.fromRGB(150, 150, 150)
    SelectedText.TextSize = 12
    SelectedText.Font = Enum.Font.Gotham
    SelectedText.TextXAlignment = Enum.TextXAlignment.Right
    SelectedText.Parent = DropBtn
    
    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 20, 1, 0)
    Arrow.Position = UDim2.new(1, -25, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "v"
    Arrow.TextColor3 = Color3.fromRGB(200, 200, 200)
    Arrow.TextSize = 14
    Arrow.Font = Enum.Font.GothamBold
    Arrow.Parent = DropBtn
    
    local ListFrame = Instance.new("ScrollingFrame")
    ListFrame.Size = UDim2.new(1, 0, 1, -45)
    ListFrame.Position = UDim2.new(0, 0, 0, 40)
    ListFrame.BackgroundTransparency = 1
    ListFrame.ScrollBarThickness = 2
    ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ListFrame.CanvasSize = UDim2.new(0,0,0,0)
    ListFrame.Parent = MainDrop
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ListFrame
    
    local expanded = false
    local api = {}
    
    local function RenderOptions(opts)
        for _, child in ipairs(ListFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for i, opt in ipairs(opts) do
            local OptBtn = Instance.new("TextButton")
            OptBtn.Size = UDim2.new(1, 0, 0, 30)
            OptBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            OptBtn.BackgroundTransparency = 0.5
            OptBtn.Text = ""
            OptBtn.AutoButtonColor = false
            OptBtn.LayoutOrder = i
            OptBtn.Parent = ListFrame
            
            local OptName = ""
            if isPlayerList then
                OptName = opt.Name
                local pAvatar = Instance.new("ImageLabel")
                pAvatar.Size = UDim2.new(0, 20, 0, 20)
                pAvatar.Position = UDim2.new(0, 15, 0.5, -10)
                pAvatar.BackgroundTransparency = 1
                task.spawn(function() pcall(function() pAvatar.Image = Players:GetUserThumbnailAsync(opt.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end) end)
                pAvatar.Parent = OptBtn
                local pCorner = Instance.new("UICorner")
                pCorner.CornerRadius = UDim.new(1, 0)
                pCorner.Parent = pAvatar
            else
                OptName = opt
            end
            
            local OLabel = Instance.new("TextLabel")
            OLabel.Size = UDim2.new(1, isPlayerList and -50 or -30, 1, 0)
            OLabel.Position = UDim2.new(0, isPlayerList and 45 or 15, 0, 0)
            OLabel.BackgroundTransparency = 1
            OLabel.Text = OptName
            OLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            OLabel.TextSize = 12
            OLabel.Font = Enum.Font.Gotham
            OLabel.TextXAlignment = Enum.TextXAlignment.Left
            OLabel.Parent = OptBtn
            
            table.insert(ZimiConnections, OptBtn.MouseEnter:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play() end))
            table.insert(ZimiConnections, OptBtn.MouseLeave:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.5}):Play() end))

            table.insert(ZimiConnections, OptBtn.MouseButton1Click:Connect(function()
                local flash = TweenService:Create(OptBtn, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.4})
                flash:Play()
                flash.Completed:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 40), BackgroundTransparency = 0.5}):Play() end)
                SelectedText.Text = OptName
                TweenService:Create(SelectedText, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                expanded = false
                TweenService:Create(MainDrop, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 40)}):Play()
                TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
                if callback then callback(isPlayerList and opt or OptName) end
            end))
        end
    end
    
    RenderOptions(options)
    
    table.insert(ZimiConnections, DropBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        local targetSize = expanded and UDim2.new(1, 0, 0, 160) or UDim2.new(1, 0, 0, 40)
        local targetRot = expanded and 180 or 0
        if expanded and isPlayerList then RenderOptions(Players:GetPlayers()) end
        TweenService:Create(MainDrop, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = targetSize}):Play()
        TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = targetRot}):Play()
    end))
    
    function api.SetVisible(state) MainDrop.Visible = state end
    return api
end

local function CreateColorPicker(parent, titleText, defCol, cb)
    local curCol = defCol
    local expanded = false
    local Cnt = Instance.new("Frame")
    Cnt.Size = UDim2.new(1, 0, 0, 40)
    Cnt.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Cnt.BackgroundTransparency = 0.4
    Cnt.ClipsDescendants = true
    Cnt.Parent = parent
    local CCorner = Instance.new("UICorner"); CCorner.CornerRadius = UDim.new(0, 8); CCorner.Parent = Cnt
    
    local TopArea = Instance.new("TextButton")
    TopArea.Size = UDim2.new(1, 0, 0, 40); TopArea.BackgroundTransparency = 1; TopArea.Text = ""; TopArea.Parent = Cnt
    
    local Lb = Instance.new("TextLabel", TopArea)
    Lb.Size = UDim2.new(1, -100, 1, 0); Lb.Position = UDim2.new(0, 15, 0, 0)
    Lb.BackgroundTransparency = 1; Lb.Text = titleText; Lb.TextColor3 = Color3.fromRGB(255, 255, 255)
    Lb.TextSize = 13; Lb.Font = Enum.Font.GothamSemibold; Lb.TextXAlignment = Enum.TextXAlignment.Left
    
    local CView = Instance.new("Frame", TopArea)
    CView.Size = UDim2.new(0, 20, 0, 20); CView.Position = UDim2.new(1, -65, 0.5, -10)
    CView.BackgroundColor3 = curCol
    local VCorner = Instance.new("UICorner"); VCorner.CornerRadius = UDim.new(0, 4); VCorner.Parent = CView
    
    local ExpBtn = Instance.new("TextLabel", TopArea)
    ExpBtn.Size = UDim2.new(0, 40, 0, 40); ExpBtn.Position = UDim2.new(1, -40, 0, 0)
    ExpBtn.BackgroundTransparency = 1; ExpBtn.Text = "▼"; ExpBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    ExpBtn.TextSize = 12; ExpBtn.Font = Enum.Font.GothamBold
    
    local HueArea = Instance.new("Frame", Cnt)
    HueArea.Size = UDim2.new(1, 0, 0, 40); HueArea.Position = UDim2.new(0, 0, 0, 40); HueArea.BackgroundTransparency = 1
    
    local HueBar = Instance.new("Frame", HueArea)
    HueBar.Size = UDim2.new(1, -30, 0, 20); HueBar.Position = UDim2.new(0, 15, 0, 10)
    local HCorner = Instance.new("UICorner"); HCorner.CornerRadius = UDim.new(1, 0); HCorner.Parent = HueBar
    
    local UIG = Instance.new("UIGradient", HueBar)
    UIG.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255,255,0)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))})
    
    local Pk = Instance.new("Frame", HueBar)
    Pk.Size = UDim2.new(0, 4, 1, 6); Pk.Position = UDim2.new(0, 0, 0, -3); Pk.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    local PCorner = Instance.new("UICorner"); PCorner.CornerRadius = UDim.new(1, 0); PCorner.Parent = Pk
    
    local Hb = Instance.new("TextButton", HueArea)
    Hb.Size = UDim2.new(1, 0, 1, 0); Hb.BackgroundTransparency = 1; Hb.Text = ""
    
    local slding = false
    local function updC(i)
        local p = math.clamp((i.Position.X - HueBar.AbsolutePosition.X)/HueBar.AbsoluteSize.X, 0, 1)
        TweenService:Create(Pk, TweenInfo.new(0.05), {Position = UDim2.new(p, 0, 0, -3)}):Play()
        curCol = Color3.fromHSV(p, 1, 1)
        CView.BackgroundColor3 = curCol
        if cb then cb(curCol) end
    end
    
    table.insert(ZimiConnections, Hb.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            slding = true; updC(i)
        end
    end))
    table.insert(ZimiConnections, UserInputService.InputChanged:Connect(function(i)
        if slding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then updC(i) end
    end))
    table.insert(ZimiConnections, UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then slding = false end
    end))

    table.insert(ZimiConnections, TopArea.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            TweenService:Create(ExpBtn, TweenInfo.new(0.2), {Rotation = 180}):Play()
            TweenService:Create(Cnt, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 85)}):Play()
        else
            TweenService:Create(ExpBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
            TweenService:Create(Cnt, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 40)}):Play()
        end
    end))
end

-- [信息页]
local InfoPage = PageFrames["信息"]
local InfoProfile = Instance.new("Frame")
InfoProfile.Size = UDim2.new(1, 0, 0, 70)
InfoProfile.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
InfoProfile.BackgroundTransparency = 0.4
InfoProfile.Parent = InfoPage
local InfoProfileCorner = Instance.new("UICorner")
InfoProfileCorner.CornerRadius = UDim.new(0, 8)
InfoProfileCorner.Parent = InfoProfile

local BigAvatar = Instance.new("ImageLabel")
BigAvatar.Size = UDim2.new(0, 50, 0, 50)
BigAvatar.Position = UDim2.new(0, 10, 0.5, -25)
BigAvatar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
task.spawn(function() pcall(function() BigAvatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end) end)
BigAvatar.Parent = InfoProfile
local BigAvatarCorner = Instance.new("UICorner")
BigAvatarCorner.CornerRadius = UDim.new(1, 0)
BigAvatarCorner.Parent = BigAvatar

local BigName = Instance.new("TextLabel")
BigName.Size = UDim2.new(1, -80, 0, 25)
BigName.Position = UDim2.new(0, 70, 0, 12)
BigName.BackgroundTransparency = 1
BigName.Text = LocalPlayer.DisplayName
BigName.TextColor3 = Color3.fromRGB(255, 255, 255)
BigName.TextSize = 18
BigName.Font = Enum.Font.GothamBold
BigName.TextXAlignment = Enum.TextXAlignment.Left
BigName.Parent = InfoProfile

local RealName = Instance.new("TextLabel")
RealName.Size = UDim2.new(1, -80, 0, 18)
RealName.Position = UDim2.new(0, 70, 0, 40)
RealName.BackgroundTransparency = 1
RealName.Text = "@" .. LocalPlayer.Name
RealName.TextColor3 = Color3.fromRGB(150, 150, 150)
RealName.TextSize = 13
RealName.Font = Enum.Font.Gotham
RealName.TextXAlignment = Enum.TextXAlignment.Left
RealName.Parent = InfoProfile

local StatContainer = Instance.new("Frame")
StatContainer.Size = UDim2.new(1, 0, 0, 172)
StatContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
StatContainer.BackgroundTransparency = 0.4
StatContainer.Parent = InfoPage
local StatCorner = Instance.new("UICorner")
StatCorner.CornerRadius = UDim.new(0, 8)
StatCorner.Parent = StatContainer
local StatPad = Instance.new("UIPadding")
StatPad.PaddingTop = UDim.new(0, 8)
StatPad.PaddingBottom = UDim.new(0, 8)
StatPad.Parent = StatContainer
local StatLayout = Instance.new("UIListLayout")
StatLayout.Padding = UDim.new(0, 4)
StatLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
StatLayout.VerticalAlignment = Enum.VerticalAlignment.Top
StatLayout.Parent = StatContainer

local function CreateStatLabel(name, textContent)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -30, 0, 18)
    Label.BackgroundTransparency = 1
    Label.Text = textContent
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextSize = 12
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = StatContainer
    return Label
end
local GameTimeLabel = CreateStatLabel("GameTime", "本地时间: 00:00:00")
local PlaytimeLabel = CreateStatLabel("Playtime", "已游玩: 00:00:00")
local FpsLabel = CreateStatLabel("Fps", "FPS: --")
local PingLabel = CreateStatLabel("Ping", "延迟: -- ms")
local PlayerCountLabel = CreateStatLabel("PlayerCount", "在线人数: --")
local ServerNameLabel = CreateStatLabel("ServerName", "游戏: ..")
pcall(function() ServerNameLabel.Text = "游戏: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
local ServerIdLabel = CreateStatLabel("ServerId", "服务器 ID: " .. string.sub(game.JobId, 1, 18) .. "...")
local AgeLabel = CreateStatLabel("Age", "账号年龄: " .. LocalPlayer.AccountAge .. " 天")

-- [玩家参数]
local PlayerPage = PageFrames["玩家参数"]
local SpeedSliderObj, JumpSliderObj
CreateToggle(PlayerPage, "启用修改玩家基础参数", false, function(state)
    ZimiSettings.PlayerModsEnabled = state
    if SpeedSliderObj then SpeedSliderObj.SetInteractable(state) end
    if JumpSliderObj then JumpSliderObj.SetInteractable(state) end
    if not state and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
        LocalPlayer.Character.Humanoid.JumpPower = 50
    end
end)
SpeedSliderObj = CreateSlider(PlayerPage, "移动速度", 16, 300, 16, function(val) ZimiSettings.WalkSpeed = val end)
JumpSliderObj = CreateSlider(PlayerPage, "跳跃高度", 50, 500, 50, function(val) ZimiSettings.JumpPower = val end)

-- [传送分区]
local TpPage = PageFrames["传送"]
local TpModeDrop, TpPlayerDrop, TpPosDrop
local TpRadiusSlider, TpSpeedSlider, TpHeightSlider, TpSmoothSlider

local function UpdateTpUI()
    local mode = ZimiSettings.TpMode
    local isLoop = (mode == "循环")
    local isSmooth = (mode == "平滑")
    
    if TpRadiusSlider then TpRadiusSlider.SetVisible(isLoop) end
    if TpSpeedSlider then TpSpeedSlider.SetVisible(isLoop) end
    if TpHeightSlider then TpHeightSlider.SetVisible(isLoop) end
    if TpSmoothSlider then TpSmoothSlider.SetVisible(isSmooth) end
end

TpModeDrop = CreateAccordionDropdown(TpPage, "传送模式", {"单次", "循环", "平滑"}, false, function(val)
    ZimiSettings.TpMode = val
    UpdateTpUI()
end)

TpPlayerDrop = CreateAccordionDropdown(TpPage, "选择玩家 (点击刷新)", Players:GetPlayers(), true, function(val)
    ZimiSettings.TpTarget = val
end)

local PosOptions = {"上面", "下面", "前面", "后面", "左边", "右边", "玩家处", "环绕"}
TpPosDrop = CreateAccordionDropdown(TpPage, "选择传送位置", PosOptions, false, function(val)
    ZimiSettings.TpPosition = val
end)

TpRadiusSlider = CreateSlider(TpPage, "环绕半径", 1, 50, 10, function(val) ZimiSettings.TpOrbitRadius = val end)
TpRadiusSlider.SetInteractable(true)
TpSpeedSlider = CreateSlider(TpPage, "环绕速度", 1, 20, 2, function(val) ZimiSettings.TpOrbitSpeed = val end)
TpSpeedSlider.SetInteractable(true)
TpHeightSlider = CreateSlider(TpPage, "环绕高度", -10, 30, 0, function(val) ZimiSettings.TpOrbitHeight = val end)
TpHeightSlider.SetInteractable(true)
TpSmoothSlider = CreateSlider(TpPage, "平滑速度", 1, 50, 15, function(val) ZimiSettings.TpSmoothSpeed = val end)

-- 执行传送按钮 (用于单次传送模式)
local TpExecuteBtn = Instance.new("TextButton")
TpExecuteBtn.Size = UDim2.new(1, 0, 0, 38)
TpExecuteBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
TpExecuteBtn.BackgroundTransparency = 0.2
TpExecuteBtn.Text = "[ 执行传送 ]"
TpExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TpExecuteBtn.Font = Enum.Font.GothamBold
TpExecuteBtn.TextSize = 14
TpExecuteBtn.Parent = TpPage
local TpBtnCorner = Instance.new("UICorner")
TpBtnCorner.CornerRadius = UDim.new(0, 8)
TpBtnCorner.Parent = TpExecuteBtn
table.insert(ZimiConnections, TpExecuteBtn.MouseButton1Click:Connect(ExecuteTeleport))
TpSmoothSlider.SetInteractable(true)
UpdateTpUI()

local QuickBtnGui = Instance.new("ScreenGui")
QuickBtnGui.Name = "ZimiQuickBtn"
QuickBtnGui.ResetOnSpawn = false
QuickBtnGui.IgnoreGuiInset = true
QuickBtnGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local succ2, _ = pcall(function() QuickBtnGui.Parent = CoreGui end)
if not succ2 then QuickBtnGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local QuickFrame = Instance.new("Frame")
QuickFrame.Size = UDim2.new(0, 50, 0, 50)
QuickFrame.Position = UDim2.new(0.8, 0, 0.8, 0)
QuickFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
QuickFrame.BackgroundTransparency = 0.2
QuickFrame.Visible = false
QuickFrame.Parent = QuickBtnGui
local QFCorner = Instance.new("UICorner")
QFCorner.CornerRadius = UDim.new(1, 0)
QFCorner.Parent = QuickFrame

local QuickActionBtn = Instance.new("TextButton")
QuickActionBtn.Size = UDim2.new(1, 0, 1, 0)
QuickActionBtn.BackgroundTransparency = 1
QuickActionBtn.Text = "TP"
QuickActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
QuickActionBtn.TextSize = 16
QuickActionBtn.Font = Enum.Font.GothamBold
QuickActionBtn.Parent = QuickFrame

local tpActiveState = false
local function ExecuteTeleport()
    local target = ZimiSettings.TpTarget
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local myHrp = LocalPlayer.Character.HumanoidRootPart
    local tHrp = target.Character.HumanoidRootPart
    local posStr = ZimiSettings.TpPosition
    local offset = CFrame.new()
    
    if posStr == "上面" then offset = CFrame.new(0, 5, 0)
    elseif posStr == "下面" then offset = CFrame.new(0, -5, 0)
    elseif posStr == "前面" then offset = CFrame.new(0, 0, -5)
    elseif posStr == "后面" then offset = CFrame.new(0, 0, 5)
    elseif posStr == "左边" then offset = CFrame.new(-5, 0, 0)
    elseif posStr == "右边" then offset = CFrame.new(5, 0, 0)
    end

    local finalCFrame = tHrp.CFrame * offset
    
    if ZimiSettings.TpMode == "单次" then
        myHrp.CFrame = finalCFrame
    elseif ZimiSettings.TpMode == "平滑" then
        local dist = (myHrp.Position - finalCFrame.Position).Magnitude
        local timeToTp = dist / (ZimiSettings.TpSmoothSpeed * 10)
        local tw = TweenService:Create(myHrp, TweenInfo.new(timeToTp, Enum.EasingStyle.Linear), {CFrame = finalCFrame})
        tw:Play()
    elseif ZimiSettings.TpMode == "循环" then
        tpActiveState = not tpActiveState
        QuickActionBtn.BackgroundColor3 = tpActiveState and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(20, 20, 20)
        QuickActionBtn.BackgroundTransparency = tpActiveState and 0.4 or 1
    end
end
table.insert(ZimiConnections, QuickActionBtn.MouseButton1Click:Connect(ExecuteTeleport))

CreateToggle(TpPage, "开启快捷传送按钮", false, function(state)
    ZimiSettings.QuickBtnEnabled = state
    QuickFrame.Visible = state
end)
CreateToggle(TpPage, "锁定快捷按钮位置", false, function(state)
    ZimiSettings.QuickBtnLocked = state
end)

local qDragging = false
local qDragStart, qStartPos
table.insert(ZimiConnections, QuickActionBtn.InputBegan:Connect(function(input)
    if ZimiSettings.QuickBtnLocked then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        qDragging = true
        qDragStart = input.Position
        qStartPos = QuickFrame.Position
    end
end))
table.insert(ZimiConnections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then qDragging = false end
end))
table.insert(ZimiConnections, UserInputService.InputChanged:Connect(function(input)
    if qDragging and not ZimiSettings.QuickBtnLocked and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - qDragStart
        local newX = qStartPos.X.Offset + delta.X
        local newY = qStartPos.Y.Offset + delta.Y
        local screenX = Camera.ViewportSize.X
        local screenY = Camera.ViewportSize.Y
        local clampedX = math.clamp(newX, 0, screenX - QuickFrame.AbsoluteSize.X)
        local clampedY = math.clamp(newY, 0, screenY - QuickFrame.AbsoluteSize.Y)
        QuickFrame.Position = UDim2.new(0, clampedX, 0, clampedY)
    end
end))

-- [自瞄分区]
local AimPage = PageFrames["自瞄"]
local AimFovCircle

local PartMapping = {
    ["Head"] = {"Head"},
    ["Torso"] = {"Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart"},
    ["Left Arm"] = {"Left Arm", "LeftHand", "LeftLowerArm", "LeftUpperArm"},
    ["Right Arm"] = {"Right Arm", "RightHand", "RightLowerArm", "RightUpperArm"},
    ["Left Leg"] = {"Left Leg", "LeftFoot", "LeftLowerLeg", "LeftUpperLeg"},
    ["Right Leg"] = {"Right Leg", "RightFoot", "RightLowerLeg", "RightUpperLeg"}
}
local AimPartOrder = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

local function IsFriend(plr)
    local ok, res = pcall(function() return LocalPlayer:IsFriendsWith(plr.UserId) end)
    return ok and res
end

local function HasSpawnShield(plr)
    local char = plr.Character
    if not char then return false end
    if char:FindFirstChild("ForceField") then return true end
    if char:FindFirstChildOfClass("ForceField") then return true end
    return false
end

local function IsAlive(plr)
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function IsSameTeam(plr)
    if plr.Team == nil or LocalPlayer.Team == nil then return false end
    return plr.Team == LocalPlayer.Team
end

local function IsVisible(part)
    if not LocalPlayer.Character then return true end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = Workspace:Raycast(origin, dir, params)
    if not result then return true end
    return result.Instance:IsDescendantOf(part.Parent)
end

local function GetBestAimPart(char)
    local selected = {}
    for partName, on in pairs(ZimiSettings.AimParts) do
        if on then table.insert(selected, partName) end
    end
    local searchList = (#selected > 0) and selected or AimPartOrder
    local firstAvailable = nil
    for _, uiPartName in ipairs(searchList) do
        local mappedParts = PartMapping[uiPartName] or {uiPartName}
        for _, realPartName in ipairs(mappedParts) do
            local part = char:FindFirstChild(realPartName)
            if part then
                if not firstAvailable then firstAvailable = part end
                if not ZimiSettings.AimWallCheck or IsVisible(part) then
                    return part
                end
            end
        end
    end
    return firstAvailable
end

local function IsValidAimTarget(plr)
    if plr == LocalPlayer then return false end
    if not plr.Character then return false end
    if not plr.Character:FindFirstChild("HumanoidRootPart") then return false end
    if ZimiSettings.AimDeathCheck and not IsAlive(plr) then return false end
    if ZimiSettings.AimShieldCheck and HasSpawnShield(plr) then return false end
    if ZimiSettings.AimTeamCheck and IsSameTeam(plr) then return false end
    if ZimiSettings.AimFriendCheck and IsFriend(plr) then return false end
    return true
end

local function GetAimTarget()
    local best = nil
    local bestDist = math.huge
    local center = Camera.ViewportSize / 2
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidAimTarget(plr) then
            local hrp = plr.Character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if ZimiSettings.AimFovLimitEnabled and dist > ZimiSettings.AimFov then
                    -- skip
                else
                    if dist < bestDist then
                        bestDist = dist
                        best = plr
                    end
                end
            end
        end
    end
    return best
end

CreateToggle(AimPage, "启用自瞄", false, function(state) ZimiSettings.AimEnabled = state end)
CreateToggle(AimPage, "墙壁判定 (只瞄可见)", true, function(state) ZimiSettings.AimWallCheck = state end)
CreateToggle(AimPage, "死亡判定 (跳过死亡)", true, function(state) ZimiSettings.AimDeathCheck = state end)
CreateToggle(AimPage, "出生护盾判定", true, function(state) ZimiSettings.AimShieldCheck = state end)
CreateToggle(AimPage, "队伍判定 (跳过队友)", true, function(state) ZimiSettings.AimTeamCheck = state end)
CreateToggle(AimPage, "好友判定 (跳过好友)", true, function(state) ZimiSettings.AimFriendCheck = state end)
CreateToggle(AimPage, "目标信息显示 (灵动岛)", false, function(state) ZimiSettings.AimTargetInfo = state end)

CreateToggle(AimPage, "自瞄模式 (开:NPC / 关:玩家)", false, function(state) ZimiSettings.AimNPCMode = state end)
local NpcSelecting = false
local NpcSelectBtn = Instance.new("TextButton")
NpcSelectBtn.Size = UDim2.new(1, 0, 0, 35)
NpcSelectBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
NpcSelectBtn.BackgroundTransparency = 0.3
NpcSelectBtn.Text = "点击进入世界选择 NPC"
NpcSelectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NpcSelectBtn.Font = Enum.Font.GothamSemibold
NpcSelectBtn.TextSize = 13
NpcSelectBtn.Parent = AimPage
local NpcBtnCorner = Instance.new("UICorner")
NpcBtnCorner.CornerRadius = UDim.new(0, 6)
NpcBtnCorner.Parent = NpcSelectBtn

local NpcDropdownApi = CreateAccordionDropdown(AimPage, "选择目标 NPC", {}, false, function(val)
    for _, v in ipairs(ZimiSettings.NpcList) do
        if v.Name == val then ZimiSettings.AimNpcTarget = v end
    end
end)

table.insert(ZimiConnections, NpcSelectBtn.MouseButton1Click:Connect(function()
    NpcSelecting = not NpcSelecting
    NpcSelectBtn.Text = NpcSelecting and "正在选择... 请点击世界中的 NPC (再次点击取消)" or "点击进入世界选择 NPC"
    NpcSelectBtn.BackgroundColor3 = NpcSelecting and Color3.fromRGB(80, 150, 100) or Color3.fromRGB(40, 40, 40)
end))

local Mouse = LocalPlayer:GetMouse()
table.insert(ZimiConnections, Mouse.Button1Down:Connect(function()
    if NpcSelecting then
        local t = Mouse.Target
        if t then
            local m = t:FindFirstAncestorOfClass("Model")
            if m and m:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(m) then
                local found = false
                for _, v in ipairs(ZimiSettings.NpcList) do if v == m then found = true end end
                if not found then
                    table.insert(ZimiSettings.NpcList, m)
                    local names = {}
                    for _, v in ipairs(ZimiSettings.NpcList) do table.insert(names, v.Name) end
                    NpcDropdownApi.SetVisible(false)
                    NpcDropdownApi = CreateAccordionDropdown(AimPage, "选择目标 NPC", names, false, function(val)
                        for _, v in ipairs(ZimiSettings.NpcList) do
                            if v.Name == val then ZimiSettings.AimNpcTarget = v end
                        end
                    end)
                    if UpdateIslandDisplay then UpdateIslandDisplay("成功添加 NPC:\n" .. m.Name, 2) end
                end
            end
        end
    end
end))

local AimFovSlider
CreateToggle(AimPage, "启用自瞄圈限制", true, function(state)
    ZimiSettings.AimFovLimitEnabled = state
    if AimFovSlider then AimFovSlider.SetInteractable(state) end
    AimFovCircle.Visible = state
end)
AimFovSlider = CreateSlider(AimPage, "自瞄圈半径", 1, 800, 120, function(val) ZimiSettings.AimFov = val end)
AimFovSlider.SetInteractable(true)

local PartSelectContainer = Instance.new("Frame")
PartSelectContainer.Size = UDim2.new(1, 0, 0, 260)
PartSelectContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PartSelectContainer.BackgroundTransparency = 0.4
PartSelectContainer.Parent = AimPage
local PSCorner = Instance.new("UICorner")
PSCorner.CornerRadius = UDim.new(0, 8)
PSCorner.Parent = PartSelectContainer

local PSTitle = Instance.new("TextLabel")
PSTitle.Size = UDim2.new(1, -20, 0, 24)
PSTitle.Position = UDim2.new(0, 12, 0, 6)
PSTitle.BackgroundTransparency = 1
PSTitle.Text = "自瞄部位选择 (点击切换, 可多选, 不选则自动最优)"
PSTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PSTitle.TextSize = 11
PSTitle.Font = Enum.Font.GothamSemibold
PSTitle.TextXAlignment = Enum.TextXAlignment.Left
PSTitle.Parent = PartSelectContainer

local Dummy = Instance.new("Frame")
Dummy.Size = UDim2.new(0, 120, 0, 210)
Dummy.Position = UDim2.new(0.5, -60, 0, 36)
Dummy.BackgroundTransparency = 1
Dummy.Parent = PartSelectContainer

local PartButtons = {}
local function CreatePartButton(name, sizeUD, posUD)
    local btn = Instance.new("TextButton")
    btn.Size = sizeUD
    btn.Position = posUD
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.BackgroundTransparency = 0.15
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = Dummy
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = btn

    PartButtons[name] = btn
    table.insert(ZimiConnections, btn.MouseButton1Click:Connect(function()
        local newState = not ZimiSettings.AimParts[name]
        ZimiSettings.AimParts[name] = newState
        local target = newState and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(70, 70, 70)
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundColor3 = target}):Play()
    end))
    return btn
end

CreatePartButton("Head", UDim2.new(0, 30, 0, 30), UDim2.new(0.5, -15, 0, 0))
CreatePartButton("Torso", UDim2.new(0, 44, 0, 70), UDim2.new(0.5, -22, 0, 34))
CreatePartButton("Left Arm", UDim2.new(0, 20, 0, 70), UDim2.new(0.5, -46, 0, 34))
CreatePartButton("Right Arm", UDim2.new(0, 20, 0, 70), UDim2.new(0.5, 26, 0, 34))
CreatePartButton("Left Leg", UDim2.new(0, 20, 0, 70), UDim2.new(0.5, -22, 0, 108))
CreatePartButton("Right Leg", UDim2.new(0, 20, 0, 70), UDim2.new(0.5, 2, 0, 108))

AimFovCircle = Instance.new("Frame")
AimFovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
AimFovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
AimFovCircle.Size = UDim2.new(0, 240, 0, 240)
AimFovCircle.BackgroundTransparency = 1
AimFovCircle.BorderSizePixel = 0
AimFovCircle.Visible = false
AimFovCircle.ZIndex = 5

local AimBtnGui = Instance.new("ScreenGui")
AimBtnGui.Name = "ZimiAimBtn"
AimBtnGui.ResetOnSpawn = false
AimBtnGui.IgnoreGuiInset = true
AimBtnGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local succ3, _ = pcall(function() AimBtnGui.Parent = CoreGui end)
if not succ3 then AimBtnGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

AimFovCircle.Parent = AimBtnGui
local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Color = Color3.fromRGB(255, 255, 255)
CircleStroke.Transparency = 0.4
CircleStroke.Parent = AimFovCircle
local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = AimFovCircle

local AimFloatFrame = Instance.new("Frame")
AimFloatFrame.Size = UDim2.new(0, 50, 0, 50)
AimFloatFrame.Position = UDim2.new(0.7, 0, 0.6, 0)
AimFloatFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AimFloatFrame.BackgroundTransparency = 0.2
AimFloatFrame.Visible = false
AimFloatFrame.Parent = AimBtnGui
local AFCorner = Instance.new("UICorner")
AFCorner.CornerRadius = UDim.new(1, 0)
AFCorner.Parent = AimFloatFrame

local AimHoldBtn = Instance.new("TextButton")
AimHoldBtn.Size = UDim2.new(1, 0, 1, 0)
AimHoldBtn.BackgroundTransparency = 1
AimHoldBtn.Text = "AIM"
AimHoldBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AimHoldBtn.TextSize = 14
AimHoldBtn.Font = Enum.Font.GothamBold
AimHoldBtn.Parent = AimFloatFrame

local aimBtnActiveToggle = false
table.insert(ZimiConnections, AimHoldBtn.MouseButton1Click:Connect(function()
    aimBtnActiveToggle = not aimBtnActiveToggle
    AimHoldBtn.BackgroundColor3 = aimBtnActiveToggle and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(20, 20, 20)
    AimHoldBtn.BackgroundTransparency = aimBtnActiveToggle and 0.4 or 1
end))

CreateToggle(AimPage, "开启自瞄悬浮按钮", false, function(state)
    ZimiSettings.AimBtnEnabled = state
    AimFloatFrame.Visible = state
end)
CreateToggle(AimPage, "锁定悬浮按钮位置", false, function(state)
    ZimiSettings.AimBtnLocked = state
end)

local aimDragging = false
local aimDragStart, aimStartPos
table.insert(ZimiConnections, AimHoldBtn.InputBegan:Connect(function(input)
    if ZimiSettings.AimBtnLocked then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        aimDragging = true
        aimDragStart = input.Position
        aimStartPos = AimFloatFrame.Position
    end
end))
table.insert(ZimiConnections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then aimDragging = false end
end))
table.insert(ZimiConnections, UserInputService.InputChanged:Connect(function(input)
    if aimDragging and not ZimiSettings.AimBtnLocked and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - aimDragStart
        local newX = aimStartPos.X.Offset + delta.X
        local newY = aimStartPos.Y.Offset + delta.Y
        local screenX = Camera.ViewportSize.X
        local screenY = Camera.ViewportSize.Y
        local clampedX = math.clamp(newX, 0, screenX - AimFloatFrame.AbsoluteSize.X)
        local clampedY = math.clamp(newY, 0, screenY - AimFloatFrame.AbsoluteSize.Y)
        AimFloatFrame.Position = UDim2.new(0, clampedX, 0, clampedY)
    end
end))


-- [ESP分区]
local EspPage = PageFrames["ESP"]

CreateToggle(EspPage, "启用全局 ESP", false, function(st) ZimiSettings.ESP.Master = st end)
CreateToggle(EspPage, "显示方框 (Box)", false, function(st) ZimiSettings.ESP.Box.Enabled = st end)
CreateToggle(EspPage, "显示骨骼连线 (Skeleton)", false, function(st) ZimiSettings.ESP.Skel.Enabled = st end)
CreateToggle(EspPage, "动态距离算法缩放字号", true, function(st) ZimiSettings.ESP.DistScale = st end)
CreateToggle(EspPage, "显示人物发光 (Chams)", false, function(st) ZimiSettings.ESP.Chams.Enabled = st end)
CreateToggle(EspPage, "显示追踪线 (Tracer)", false, function(st) ZimiSettings.ESP.Tracer.Enabled = st end)
CreateToggle(EspPage, "显示血量条", false, function(st) ZimiSettings.ESP.Health.Enabled = st end)
CreateToggle(EspPage, "显示名字", false, function(st) ZimiSettings.ESP.Name.Enabled = st end)
CreateToggle(EspPage, "显示距离", false, function(st) ZimiSettings.ESP.Dist.Enabled = st end)

-- ESP NPC 模式
CreateToggle(EspPage, "显示 NPC (与自瞄共享列表)", false, function(st) ZimiSettings.ESP.ShowNPCs = st end)

CreateToggle(EspPage, "自动扫描 NPC", false, function(st) ZimiSettings.ESP.AutoScanNPCs = st end)

-- NPC 选择按钮 (与自瞄共享 NpcList)
local EspNpcSelecting = false
local EspNpcSelectBtn = Instance.new("TextButton")
EspNpcSelectBtn.Size = UDim2.new(1, 0, 0, 35)
EspNpcSelectBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
EspNpcSelectBtn.BackgroundTransparency = 0.3
EspNpcSelectBtn.Text = "点击选择 NPC 加入 ESP 列表"
EspNpcSelectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EspNpcSelectBtn.Font = Enum.Font.GothamSemibold
EspNpcSelectBtn.TextSize = 13
EspNpcSelectBtn.Parent = EspPage
local EspNpcBtnCorner = Instance.new("UICorner")
EspNpcBtnCorner.CornerRadius = UDim.new(0, 6)
EspNpcBtnCorner.Parent = EspNpcSelectBtn

local EspNpcListLabel = Instance.new("TextLabel")
EspNpcListLabel.Size = UDim2.new(1, 0, 0, 20)
EspNpcListLabel.BackgroundTransparency = 1
EspNpcListLabel.Text = "已添加 NPC: 0 个"
EspNpcListLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
EspNpcListLabel.TextSize = 11
EspNpcListLabel.Font = Enum.Font.Gotham
EspNpcListLabel.TextXAlignment = Enum.TextXAlignment.Left
EspNpcListLabel.Parent = EspPage

-- ESP NPC 目标选择下拉
local function GetEspNpcNames()
    local names = {}
    for _, v in ipairs(ZimiSettings.NpcList) do
        if v and v.Parent then table.insert(names, v.Name) end
    end
    if #names == 0 then table.insert(names, "(无NPC)") end
    return names
end
local EspNpcTargetDrop = CreateAccordionDropdown(EspPage, "选择 ESP NPC 目标 (留空=全部)", GetEspNpcNames(), false, function(val)
    for _, v in ipairs(ZimiSettings.NpcList) do
        if v.Name == val then ZimiSettings.ESP.EspNpcTarget = v; break end
    end
end)

-- 自动扫描按钮
local EspAutoScanBtn = Instance.new("TextButton")
EspAutoScanBtn.Size = UDim2.new(1, 0, 0, 35)
EspAutoScanBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
EspAutoScanBtn.BackgroundTransparency = 0.3
EspAutoScanBtn.Text = "[ 扫描当前服务器 NPC ]"
EspAutoScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EspAutoScanBtn.Font = Enum.Font.GothamSemibold
EspAutoScanBtn.TextSize = 13
EspAutoScanBtn.Parent = EspPage
local EspScanBtnCorner = Instance.new("UICorner")
EspScanBtnCorner.CornerRadius = UDim.new(0, 6)
EspScanBtnCorner.Parent = EspAutoScanBtn

table.insert(ZimiConnections, EspNpcSelectBtn.MouseButton1Click:Connect(function()
    EspNpcSelecting = not EspNpcSelecting
    EspNpcSelectBtn.Text = EspNpcSelecting and "正在选择... 点击世界中的 NPC (再次取消)" or "点击选择 NPC 加入 ESP 列表"
    EspNpcSelectBtn.BackgroundColor3 = EspNpcSelecting and Color3.fromRGB(80, 150, 100) or Color3.fromRGB(40, 40, 40)
end))

table.insert(ZimiConnections, EspAutoScanBtn.MouseButton1Click:Connect(function()
    local scannedCount = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
            local found = false
            for _, v in ipairs(ZimiSettings.NpcList) do
                if v == obj then found = true; break end
            end
            if not found then
                table.insert(ZimiSettings.NpcList, obj)
                scannedCount = scannedCount + 1
            end
        end
    end
    EspNpcListLabel.Text = "已添加 NPC: " .. #ZimiSettings.NpcList .. " 个 (新扫描: " .. scannedCount .. ")"
    if UpdateIslandDisplay then UpdateIslandDisplay("扫描完成: 发现 " .. scannedCount .. " 个新 NPC", 3) end
end))

-- ESP 的 NPC 点击选择 (使用同一个 Mouse 对象)
table.insert(ZimiConnections, Mouse.Button1Down:Connect(function()
    if not EspNpcSelecting then return end
    local t = Mouse.Target
    if t then
        local m = t:FindFirstAncestorOfClass("Model")
        if m and m:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(m) then
            local found = false
            for _, v in ipairs(ZimiSettings.NpcList) do
                if v == m then found = true; break end
            end
            if not found then
                table.insert(ZimiSettings.NpcList, m)
                EspNpcListLabel.Text = "已添加 NPC: " .. #ZimiSettings.NpcList .. " 个"
                if UpdateIslandDisplay then UpdateIslandDisplay("ESP 已添加 NPC: " .. m.Name, 2) end
            end
        end
    end
end))

CreateColorPicker(EspPage, "ESP 整体主题色调节", Color3.fromRGB(255, 255, 255), function(col)
    ZimiSettings.ESP.Box.Color = col
    ZimiSettings.ESP.Skel.Color = col
    ZimiSettings.ESP.Chams.Color = col
    ZimiSettings.ESP.Name.Color = col
    ZimiSettings.ESP.Dist.Color = col
    ZimiSettings.ESP.Tracer.Color = col
end)

local ESP_Cache = {}

-- 清理离开玩家的 ESP
table.insert(ZimiConnections, Players.PlayerRemoving:Connect(function(plr)
    if ESP_Cache[plr] then
        HideAllESP(ESP_Cache[plr])
        -- 彻底移除 Drawing 对象
        local c = ESP_Cache[plr]
        for _, v in pairs(c) do
            if type(v) == "userdata" and pcall(function() return v.Remove end) then
                pcall(function() v:Remove() end)
            end
        end
        ESP_Cache[plr] = nil
    end
end))

-- 定期清理无效的 ESP 缓存（NPC 被销毁等）
task.spawn(function()
    while not _G.ZimiUnloaded do
        task.wait(3)
        for key, c in pairs(ESP_Cache) do
            -- 检查 key 是否有效
            if typeof(key) == "Instance" and not key.Parent then
                HideAllESP(c)
                for _, v in pairs(c) do
                    if type(v) == "userdata" and pcall(function() return v.Remove end) then
                        pcall(function() v:Remove() end)
                    end
                end
                ESP_Cache[key] = nil
            end
        end
    end
end)

local ESPScreen = Instance.new("ScreenGui")
ESPScreen.Name = "ZimiESP_Screen"
ESPScreen.ResetOnSpawn = false
ESPScreen.IgnoreGuiInset = true 
local succ4, _ = pcall(function() ESPScreen.Parent = CoreGui end)
if not succ4 then ESPScreen.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function CreateEspDrawings(plr)
    if ESP_Cache[plr] then return end
    ESP_Cache[plr] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        DistTxt = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthOutline = Drawing.new("Square"),
        Spine = Drawing.new("Line"),
        LeftArm = Drawing.new("Line"),
        RightArm = Drawing.new("Line"),
        LeftLeg = Drawing.new("Line"),
        RightLeg = Drawing.new("Line"),
        Shoulders = Drawing.new("Line"),
        Hips = Drawing.new("Line"),
        Tracer = Drawing.new("Line"),
        Chams = nil,
        ChamsAdornee = nil
    }
    
    local d = ESP_Cache[plr]
    d.Box.Thickness = 1.5
    d.Box.Filled = false
    
    d.Name.Center = true
    d.Name.Outline = true
    
    d.DistTxt.Center = true
    d.DistTxt.Outline = true
    
    d.HealthBar.Filled = true
    d.HealthOutline.Color = Color3.fromRGB(0, 0, 0)
    d.HealthOutline.Thickness = 1
    d.HealthOutline.Filled = false
    
    local lines = {d.Spine, d.LeftArm, d.RightArm, d.LeftLeg, d.RightLeg, d.Shoulders, d.Hips, d.Tracer}
    for _, line in ipairs(lines) do
        line.Thickness = 1.5
    end
end

local function HideAllESP(c)
    c.Box.Visible = false
    c.Name.Visible = false
    c.DistTxt.Visible = false
    c.HealthBar.Visible = false
    c.HealthOutline.Visible = false
    c.Tracer.Visible = false
    c.Spine.Visible = false
    c.LeftArm.Visible = false
    c.RightArm.Visible = false
    c.LeftLeg.Visible = false
    c.RightLeg.Visible = false
    c.Shoulders.Visible = false
    c.Hips.Visible = false
    -- 隐藏 Chams 透视
    if c.Chams then
        c.Chams.Enabled = false
        c.Chams.Adornee = nil
        c.ChamsAdornee = nil
    end
end

-- Chams 透视实现 (使用 Highlight + AlwaysOnTop 实现穿墙透视)
local function ApplyChamsToCharacter(char, cacheEntry, chamsColor, enabled)
    if not char then return end

    if not enabled then
        if cacheEntry.Chams then
            cacheEntry.Chams.Enabled = false
            cacheEntry.Chams.Adornee = nil
            cacheEntry.ChamsAdornee = nil
        end
        return
    end

    -- 角色没变时跳过重建
    if cacheEntry.ChamsAdornee == char then
        if cacheEntry.Chams then
            cacheEntry.Chams.Enabled = true
            cacheEntry.Chams.FillColor = chamsColor
            cacheEntry.Chams.OutlineColor = chamsColor
        end
        return
    end

    -- 创建或重建 Highlight
    if not cacheEntry.Chams then
        cacheEntry.Chams = Instance.new("Highlight")
    end

    local hl = cacheEntry.Chams
    hl.Name = "ZimiChams"
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.FillColor = chamsColor
    hl.OutlineColor = chamsColor
    hl.Enabled = true

    -- 先放到 CoreGui 再设 Adornee（确保正确渲染）
    pcall(function() hl.Parent = CoreGui end)
    pcall(function() hl.Adornee = char end)

    cacheEntry.ChamsAdornee = char
end

local SkeletonR15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}
local SkeletonR6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}



-- [渲染页面]
local RenderPage = PageFrames["渲染"]
CreateToggle(RenderPage, "全局光照 (FullBright)", false, function(st) ZimiSettings.Render.FullBright = st end)
CreateToggle(RenderPage, "移除雾气 (NoFog)", false, function(st)
    ZimiSettings.Render.NoFog = st
    if st then
        ZimiSettings.Render.OldFogEnd = Lighting.FogEnd
        ZimiSettings.Render.OldFogStart = Lighting.FogStart
        Lighting.FogEnd = 99999
        Lighting.FogStart = 99999
    else
        if ZimiSettings.Render.OldFogEnd then
            Lighting.FogEnd = ZimiSettings.Render.OldFogEnd
            Lighting.FogStart = ZimiSettings.Render.OldFogStart or 0
        end
    end
end)

-- [玩家功能页面]
local PlayerFuncPage = PageFrames["玩家功能"]

-- Fly
CreateToggle(PlayerFuncPage, "飞行 (Fly)", false, function(st)
    ZimiSettings.PlayerFunc.FlyEnabled = st
    if not st and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand = false end
        if hrp then hrp.Anchored = false end
        -- 清理 BodyVelocity/BodyGyro
        for _, v in ipairs({"ZimiFlyVel", "ZimiFlyGyro"}) do
            local obj = LocalPlayer.Character:FindFirstChild(v)
            if obj then obj:Destroy() end
        end
    end
end)

local FlySpeedSlider = CreateSlider(PlayerFuncPage, "飞行速度", 10, 500, 50, function(val) ZimiSettings.PlayerFunc.FlySpeed = val end)
CreateToggle(PlayerFuncPage, "  └ 飞行速度调节", true, function(st) FlySpeedSlider.SetInteractable(st) end)
FlySpeedSlider.SetInteractable(true)

-- Noclip
CreateToggle(PlayerFuncPage, "穿墙 (Noclip)", false, function(st)
    ZimiSettings.PlayerFunc.Noclip = st
    if not st and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end)

-- Spin
CreateToggle(PlayerFuncPage, "自旋转 (Spin)", false, function(st) ZimiSettings.PlayerFunc.SpinEnabled = st end)
local SpinSpeedSlider = CreateSlider(PlayerFuncPage, "旋转速度", 10, 300, 50, function(val) ZimiSettings.PlayerFunc.SpinSpeed = val end)
SpinSpeedSlider.SetInteractable(true)

-- Frozen
CreateToggle(PlayerFuncPage, "冻结位置 (Frozen)", false, function(st)
    ZimiSettings.PlayerFunc.Frozen = st
    if not st and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Anchored = false
    end
end)

-- PlatformStand
CreateToggle(PlayerFuncPage, "站台模式 (PlatformStand)", false, function(st)
    ZimiSettings.PlayerFunc.PlatformStand = st
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.PlatformStand = st
    end
end)

-- InfJump
CreateToggle(PlayerFuncPage, "无限跳跃 (InfJump)", false, function(st) ZimiSettings.PlayerFunc.InfJump = st end)

-- Derp
CreateToggle(PlayerFuncPage, "DERP 瘫痪模式", false, function(st)
    ZimiSettings.PlayerFunc.Derp = st
    if not st and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
    end
end)

-- [Hitbox 页面]
local HitboxPage = PageFrames["Hitbox"]

CreateToggle(HitboxPage, "启用 Hitbox 膨胀", false, function(st)
    ZimiSettings.Hitbox.Enabled = st
    if not st then
        -- 关闭时恢复所有已修改的部件
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                local part = plr.Character:FindFirstChild(ZimiSettings.Hitbox.TargetPart)
                if part and part:IsA("BasePart") then
                    part.Size = Vector3.new(2, 2, 1)
                    part.Transparency = 0
                    part.CanCollide = true
                    local hl = part:FindFirstChild("ZimiHitboxHL")
                    if hl then hl:Destroy() end
                end
            end
        end
    end
end)

local HitboxPartDrop = CreateAccordionDropdown(HitboxPage, "目标部位", {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}, false, function(val)
    ZimiSettings.Hitbox.TargetPart = val
end)

local HitboxSizeXSlider = CreateSlider(HitboxPage, "X轴膨胀", 1, 20, 5, function(val) ZimiSettings.Hitbox.SizeX = val end)
HitboxSizeXSlider.SetInteractable(true)
local HitboxSizeYSlider = CreateSlider(HitboxPage, "Y轴膨胀", 1, 20, 5, function(val) ZimiSettings.Hitbox.SizeY = val end)
HitboxSizeYSlider.SetInteractable(true)
local HitboxSizeZSlider = CreateSlider(HitboxPage, "Z轴膨胀", 1, 20, 5, function(val) ZimiSettings.Hitbox.SizeZ = val end)
HitboxSizeZSlider.SetInteractable(true)

local HitboxTransSlider = CreateSlider(HitboxPage, "透明度", 0, 100, 50, function(val) ZimiSettings.Hitbox.Transparency = val / 100 end)
HitboxTransSlider.SetInteractable(true)

CreateToggle(HitboxPage, "显示描边轮廓 (Outline)", false, function(st) ZimiSettings.Hitbox.Outline = st end)

CreateToggle(HitboxPage, "可碰撞 (CanCollide)", true, function(st) ZimiSettings.Hitbox.CanCollide = st end)

CreateToggle(HitboxPage, "NPC 模式 (使用自瞄 NPC 列表)", false, function(st) ZimiSettings.Hitbox.NPCMode = st end)

-- Hitbox NPC 目标选择下拉框
local function GetHitboxNpcNames()
    local names = {}
    for _, v in ipairs(ZimiSettings.NpcList) do
        if v and v.Parent then table.insert(names, v.Name) end
    end
    if #names == 0 then table.insert(names, "(无NPC)") end
    return names
end

local HitboxNpcTargetDrop = CreateAccordionDropdown(HitboxPage, "选择 Hitbox NPC 目标 (留空=全部)", GetHitboxNpcNames(), false, function(val)
    for _, v in ipairs(ZimiSettings.NpcList) do
        if v.Name == val then ZimiSettings.Hitbox.NpcTarget = v; break end
    end
end)

-- Hitbox NPC 选择 (与自瞄共享 NPC 列表)
local HitboxNpcSelecting = false
local HitboxNpcSelectBtn = Instance.new("TextButton")
HitboxNpcSelectBtn.Size = UDim2.new(1, 0, 0, 35)
HitboxNpcSelectBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
HitboxNpcSelectBtn.BackgroundTransparency = 0.3
HitboxNpcSelectBtn.Text = "点击选择 NPC 加入 Hitbox 列表"
HitboxNpcSelectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxNpcSelectBtn.Font = Enum.Font.GothamSemibold
HitboxNpcSelectBtn.TextSize = 13
HitboxNpcSelectBtn.Parent = HitboxPage
local HitboxNpcBtnCorner = Instance.new("UICorner")
HitboxNpcBtnCorner.CornerRadius = UDim.new(0, 6)
HitboxNpcBtnCorner.Parent = HitboxNpcSelectBtn

local HitboxNpcListLabel = Instance.new("TextLabel")
HitboxNpcListLabel.Size = UDim2.new(1, 0, 0, 20)
HitboxNpcListLabel.BackgroundTransparency = 1
HitboxNpcListLabel.Text = "Hitbox NPC: " .. #ZimiSettings.NpcList .. " 个 (与自瞄/ESP共享)"
HitboxNpcListLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
HitboxNpcListLabel.TextSize = 11
HitboxNpcListLabel.Font = Enum.Font.Gotham
HitboxNpcListLabel.TextXAlignment = Enum.TextXAlignment.Left
HitboxNpcListLabel.Parent = HitboxPage

table.insert(ZimiConnections, HitboxNpcSelectBtn.MouseButton1Click:Connect(function()
    HitboxNpcSelecting = not HitboxNpcSelecting
    HitboxNpcSelectBtn.Text = HitboxNpcSelecting and "正在选择... 点击世界中的 NPC (再次取消)" or "点击选择 NPC 加入 Hitbox 列表"
    HitboxNpcSelectBtn.BackgroundColor3 = HitboxNpcSelecting and Color3.fromRGB(80, 150, 100) or Color3.fromRGB(40, 40, 40)
end))

-- Hitbox NPC 点击选择 (复用 Mouse 对象)
table.insert(ZimiConnections, Mouse.Button1Down:Connect(function()
    if not HitboxNpcSelecting then return end
    local t = Mouse.Target
    if t then
        local m = t:FindFirstAncestorOfClass("Model")
        if m and m:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(m) then
            local found = false
            for _, v in ipairs(ZimiSettings.NpcList) do
                if v == m then found = true; break end
            end
            if not found then
                table.insert(ZimiSettings.NpcList, m)
                HitboxNpcListLabel.Text = "Hitbox NPC: " .. #ZimiSettings.NpcList .. " 个 (与自瞄/ESP共享)"
                if UpdateIslandDisplay then UpdateIslandDisplay("Hitbox 已添加 NPC: " .. m.Name, 2) end
            end
        end
    end
end))

CreateToggle(HitboxPage, "队伍检测", true, function(st) ZimiSettings.Hitbox.TeamCheck = st end)

CreateToggle(HitboxPage, "好友检测", true, function(st) ZimiSettings.Hitbox.FriendCheck = st end)

-- 材质选择
local HitboxMatDrop = CreateAccordionDropdown(HitboxPage, "Hitbox 材质", {"ForceField", "Neon", "Glass", "SmoothPlastic"}, false, function(val)
    ZimiSettings.Hitbox.Material = Enum.Material[val]
end)

-- [服务器功能页面]
local ServerPage = PageFrames["服务器功能"]

CreateToggle(ServerPage, "服务器跳转 (ServerHop)", false, function(st)
    ZimiSettings.ServerFunc.ServerHop = st
    if st then
        -- 自动跳转服务器
        task.spawn(function()
            local HttpService = game:GetService("HttpService")
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
            end)
            if success and result and result.data and #result.data > 0 then
                local servers = {}
                for _, server in ipairs(result.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(servers, server.id)
                    end
                end
                if #servers > 0 then
                    local targetServer = servers[math.random(1, #servers)]
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, targetServer, LocalPlayer)
                else
                    if UpdateIslandDisplay then UpdateIslandDisplay("没有可用服务器", 3) end
                end
            else
                if UpdateIslandDisplay then UpdateIslandDisplay("跳转失败，请重试", 3) end
            end
            ZimiSettings.ServerFunc.ServerHop = false
        end)
    end
end)

CreateToggle(ServerPage, "防挂机 (Anti-AFK)", false, function(st) ZimiSettings.ServerFunc.AntiAfk = st end)

-- ============================================================
-- NPC 统一管理 (集成到服务器分区)
-- ============================================================
local ServerNpcLabel = Instance.new("TextLabel")
ServerNpcLabel.Size = UDim2.new(1, 0, 0, 24)
ServerNpcLabel.BackgroundTransparency = 1
ServerNpcLabel.Text = "-- NPC 管理系统 (共享列表: " .. #ZimiSettings.NpcList .. " 个) --"
ServerNpcLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ServerNpcLabel.TextSize = 12
ServerNpcLabel.Font = Enum.Font.GothamSemibold
ServerNpcLabel.TextXAlignment = Enum.TextXAlignment.Left
ServerNpcLabel.Parent = ServerPage

-- 泛搜索扫描按钮
local ServerScanBtn = Instance.new("TextButton")
ServerScanBtn.Size = UDim2.new(1, 0, 0, 36)
ServerScanBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
ServerScanBtn.BackgroundTransparency = 0.25
ServerScanBtn.Text = "[ 泛搜索扫描全部 NPC ]"
ServerScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ServerScanBtn.Font = Enum.Font.GothamBold
ServerScanBtn.TextSize = 13
ServerScanBtn.Parent = ServerPage
local ServerScanCorner = Instance.new("UICorner")
ServerScanCorner.CornerRadius = UDim.new(0, 8)
ServerScanCorner.Parent = ServerScanBtn

table.insert(ZimiConnections, ServerScanBtn.MouseButton1Click:Connect(function()
    local scannedCount = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
            local found = false
            for _, v in ipairs(ZimiSettings.NpcList) do
                if v == obj then found = true; break end
            end
            if not found then
                table.insert(ZimiSettings.NpcList, obj)
                scannedCount = scannedCount + 1
            end
        end
    end
    ServerNpcLabel.Text = "-- NPC 管理系统 (共享列表: " .. #ZimiSettings.NpcList .. " 个, 新扫描: " .. scannedCount .. ") --"
    if UpdateIslandDisplay then UpdateIslandDisplay("泛搜索完成: " .. scannedCount .. " 个新 NPC", 3) end
end))

-- 清空 NPC 列表按钮
local ServerClearNpcBtn = Instance.new("TextButton")
ServerClearNpcBtn.Size = UDim2.new(1, 0, 0, 30)
ServerClearNpcBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
ServerClearNpcBtn.BackgroundTransparency = 0.25
ServerClearNpcBtn.Text = "[ 清空 NPC 列表 ]"
ServerClearNpcBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ServerClearNpcBtn.Font = Enum.Font.GothamSemibold
ServerClearNpcBtn.TextSize = 12
ServerClearNpcBtn.Parent = ServerPage
local ServerClearCorner = Instance.new("UICorner")
ServerClearCorner.CornerRadius = UDim.new(0, 8)
ServerClearCorner.Parent = ServerClearNpcBtn

table.insert(ZimiConnections, ServerClearNpcBtn.MouseButton1Click:Connect(function()
    table.clear(ZimiSettings.NpcList)
    ZimiSettings.AimNpcTarget = nil
    ServerNpcLabel.Text = "-- NPC 管理系统 (共享列表: 0 个) --"
    if UpdateIslandDisplay then UpdateIslandDisplay("NPC 列表已清空", 2) end
end))

-- 重新加入按钮
local RejoinBtn = Instance.new("TextButton")
RejoinBtn.Size = UDim2.new(1, 0, 0, 40)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
RejoinBtn.BackgroundTransparency = 0.3
RejoinBtn.Text = "重新加入 (Rejoin)"
RejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RejoinBtn.Font = Enum.Font.GothamSemibold
RejoinBtn.TextSize = 13
RejoinBtn.Parent = ServerPage
local RejoinCorner = Instance.new("UICorner")
RejoinCorner.CornerRadius = UDim.new(0, 8)
RejoinCorner.Parent = RejoinBtn
table.insert(ZimiConnections, RejoinBtn.MouseButton1Click:Connect(function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end))

-- 提示标签
local ServerHint = Instance.new("TextLabel")
ServerHint.Size = UDim2.new(1, 0, 0, 30)
ServerHint.BackgroundTransparency = 1
ServerHint.Text = "ServerHop: 随机跳转至同游戏其他服务器"
ServerHint.TextColor3 = Color3.fromRGB(150, 150, 150)
ServerHint.TextSize = 11
ServerHint.Font = Enum.Font.Gotham
ServerHint.TextXAlignment = Enum.TextXAlignment.Left
ServerHint.Parent = ServerPage

-- ============================================================
-- [个性GUI 分区] 背景视觉效果
-- ============================================================
local GuiPage = PageFrames["个性GUI"]

CreateToggle(GuiPage, "启用视觉效果总开关", false, function(st) ZimiSettings.GuiFX.Master = st end)

-- 动态流光效果
CreateToggle(GuiPage, "动态流光扫过", false, function(st) ZimiSettings.GuiFX.FlowingLight = st end)
local FlowColorSlider = CreateSlider(GuiPage, "流光颜色 - 色相偏移", 0, 360, 180, function(val) ZimiSettings.GuiFX.FlowHue = val end)
FlowColorSlider.SetInteractable(true)
local FlowSpeedSlider = CreateSlider(GuiPage, "流光速度", 1, 20, 5, function(val) ZimiSettings.GuiFX.FlowSpeed = val end)
FlowSpeedSlider.SetInteractable(true)

-- 灵动岛背景效果
CreateToggle(GuiPage, "灵动岛背景流光", false, function(st) ZimiSettings.GuiFX.IslandGlow = st end)

-- 提示
local GuiFxHint = Instance.new("TextLabel")
GuiFxHint.Size = UDim2.new(1, 0, 0, 30)
GuiFxHint.BackgroundTransparency = 1
GuiFxHint.Text = "[提示] 流光效果: 半透明光束扫过主面板背景"
GuiFxHint.TextColor3 = Color3.fromRGB(150, 150, 150)
GuiFxHint.TextSize = 11
GuiFxHint.Font = Enum.Font.Gotham
GuiFxHint.TextXAlignment = Enum.TextXAlignment.Left
GuiFxHint.Parent = GuiPage

-- ============================================================
-- [配置分区] 保存 / 加载 / 自动加载
-- ============================================================
local ConfigPage = PageFrames["配置"]

-- 配置文件路径
local CONFIG_FOLDER = "Zimi_Configs"
local AUTO_LOAD_FILE = CONFIG_FOLDER .. "/auto_load.json"

-- 创建配置文件夹
pcall(function() makefolder(CONFIG_FOLDER) end)

-- 获取所有配置文件名
local function GetConfigList()
    local files = {}
    pcall(function() files = listfiles(CONFIG_FOLDER) end)
    local names = {}
    for _, f in ipairs(files) do
        local name = f:match(CONFIG_FOLDER .. "/(.+)%.json$")
        if name and name ~= "auto_load" then
            table.insert(names, name)
        end
    end
    return names
end

-- 递归序列化：将 Color3/Enum/Vector3 等转为可 JSON 的纯表
local function SerializeValue(val, depth)
    depth = depth or 0
    if depth > 20 then return nil end

    local t = type(val)
    if t == "userdata" then
        -- Color3
        if typeof(val) == "Color3" then
            return {__type = "Color3", R = val.R, G = val.G, B = val.B}
        end
        -- Vector3
        if typeof(val) == "Vector3" then
            return {__type = "Vector3", X = val.X, Y = val.Y, Z = val.Z}
        end
        -- Enum
        pcall(function()
            if val.EnumType then
                return {__type = "Enum", Name = tostring(val)}
            end
        end)
        -- 其他 userdata 跳过
        return nil
    elseif t == "table" then
        local result = {}
        for k, v in pairs(val) do
            local sv = SerializeValue(v, depth + 1)
            if sv ~= nil then
                result[k] = sv
            end
        end
        return result
    elseif t == "number" or t == "string" or t == "boolean" then
        return val
    end
    return nil
end

-- 递归反序列化：将纯表还原为 Color3/Enum/Vector3
local function DeserializeValue(val, depth)
    depth = depth or 0
    if depth > 20 then return nil end

    if type(val) ~= "table" then return val end

    -- 检测特殊类型标记
    if val.__type then
        if val.__type == "Color3" and val.R ~= nil then
            return Color3.fromRGB(val.R, val.G, val.B)
        elseif val.__type == "Vector3" and val.X ~= nil then
            return Vector3.new(val.X, val.Y, val.Z)
        elseif val.__type == "Enum" and val.Name then
            local ok, result = pcall(function()
                return Enum[val.Name]
            end)
            if ok and result then return result end
        end
    end

    -- 普通表递归还原
    local result = {}
    for k, v in pairs(val) do
        result[k] = DeserializeValue(v, depth + 1)
    end
    return result
end

-- 深度合并表（保留目标表中的默认字段）
local function DeepMerge(target, source)
    for k, v in pairs(source) do
        if target[k] == nil then
            target[k] = v
        elseif type(v) == "table" and type(target[k]) == "table" then
            -- 检测是否是特殊序列化类型(有__type字段), 如果是则直接覆盖
            if v.__type or target[k].__type then
                target[k] = v
            else
                DeepMerge(target[k], v)
            end
        else
            target[k] = v
        end
    end
end

-- 保存当前设置到文件(完整序列化所有功能)
local function SaveConfigToFile(fileName)
    local success, err = pcall(function()
        local serialized = SerializeValue(ZimiSettings)
        local json = game:GetService("HttpService"):JSONEncode(serialized)
        writefile(CONFIG_FOLDER .. "/" .. fileName .. ".json", json)
    end)
    return success, err
end

-- 从文件加载设置(完整反序列化所有功能)
local function LoadConfigFromFile(fileName)
    local success, data = pcall(function()
        return readfile(CONFIG_FOLDER .. "/" .. fileName .. ".json")
    end)
    if not success or not data then return false, "read failed" end

    local success2, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(data)
    end)
    if not success2 or not decoded then return false, "decode failed" end

    -- 反序列化还原 Color3/Enum/Vector3
    local settings = DeserializeValue(decoded)
    if not settings then return false, "deserialize failed" end

    -- 深度合并到当前设置(保留新字段默认值)
    DeepMerge(ZimiSettings, settings)

    return true, nil
end

-- 删除配置文件
local function DeleteConfigFile(fileName)
    pcall(function() delfile(CONFIG_FOLDER .. "/" .. fileName .. ".json") end)
end

-- 设置自动加载
local function SetAutoLoad(fileName)
    if fileName then
        local json = game:GetService("HttpService"):JSONEncode({auto = fileName})
        writefile(AUTO_LOAD_FILE, json)
    else
        pcall(function() delfile(AUTO_LOAD_FILE) end)
    end
end

-- 获取自动加载配置名
local function GetAutoLoadConfig()
    local success, data = pcall(function() return readfile(AUTO_LOAD_FILE) end)
    if success and data then
        local success2, info = pcall(function() return game:GetService("HttpService"):JSONDecode(data) end)
        if success2 and info and info.auto then
            return info.auto
        end
    end
    return nil
end

-- 配置名称输入框
local ConfigNameBox = Instance.new("TextBox")
ConfigNameBox.Size = UDim2.new(1, 0, 0, 36)
ConfigNameBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ConfigNameBox.BackgroundTransparency = 0.3
ConfigNameBox.Text = ""
ConfigNameBox.PlaceholderText = "输入配置名称..."
ConfigNameBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
ConfigNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfigNameBox.Font = Enum.Font.GothamSemibold
ConfigNameBox.TextSize = 13
ConfigNameBox.ClearTextOnFocus = false
ConfigNameBox.Parent = ConfigPage
local ConfigNameCorner = Instance.new("UICorner")
ConfigNameCorner.CornerRadius = UDim.new(0, 8)
ConfigNameCorner.Parent = ConfigNameBox

-- 当前选中的配置名
local CurrentConfigName = ""

-- 刷新配置列表下拉框
local ConfigListDrop = CreateAccordionDropdown(ConfigPage, "选择已保存的配置", GetConfigList(), false, function(val)
    CurrentConfigName = val
    ConfigNameBox.Text = val
end)

-- 状态提示标签
local ConfigStatusLabel = Instance.new("TextLabel")
ConfigStatusLabel.Size = UDim2.new(1, 0, 0, 24)
ConfigStatusLabel.BackgroundTransparency = 1
ConfigStatusLabel.Text = "就绪 | 自动加载: " .. (GetAutoLoadConfig() or "无")
ConfigStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
ConfigStatusLabel.TextSize = 12
ConfigStatusLabel.Font = Enum.Font.GothamSemibold
ConfigStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
ConfigStatusLabel.Parent = ConfigPage

-- 创建配置按钮的辅助函数
local function CreateConfigButton(parent, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.25
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = parent
    local cr = Instance.new("UICorner")
    cr.CornerRadius = UDim.new(0, 8)
    cr.Parent = btn
    table.insert(ZimiConnections, btn.MouseButton1Click:Connect(function()
        callback()
    end))
    return btn
end

-- 保存配置
CreateConfigButton(ConfigPage, "[ 保存配置 ]", Color3.fromRGB(50, 150, 50), function()
    local name = ConfigNameBox.Text
    if name == "" then
        ConfigStatusLabel.Text = "[X] 请输入配置名称"
        ConfigStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    local ok = SaveConfigToFile(name)
    if ok then
        ConfigStatusLabel.Text = "[OK] 配置已保存: " .. name
        ConfigStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        CurrentConfigName = name
        ConfigListDrop.SetVisible(false)
        ConfigListDrop = CreateAccordionDropdown(ConfigPage, "选择已保存的配置", GetConfigList(), false, function(val)
            CurrentConfigName = val
            ConfigNameBox.Text = val
        end)
        if UpdateIslandDisplay then UpdateIslandDisplay("配置已保存: " .. name, 2) end
    else
        ConfigStatusLabel.Text = "[X] 保存失败"
        ConfigStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

CreateConfigButton(ConfigPage, "[ 覆盖当前配置 ]", Color3.fromRGB(180, 150, 50), function()
    local name = ConfigNameBox.Text
    if name == "" then
        ConfigStatusLabel.Text = "[X] 请先选择或输入配置名称"
        ConfigStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    local ok = SaveConfigToFile(name)
    if ok then
        ConfigStatusLabel.Text = "[OK] 配置已覆盖: " .. name
        ConfigStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        if UpdateIslandDisplay then UpdateIslandDisplay("配置已覆盖: " .. name, 2) end
    else
        ConfigStatusLabel.Text = "[X] 覆盖失败"
        ConfigStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

CreateConfigButton(ConfigPage, "[ 加载配置 ]", Color3.fromRGB(50, 100, 200), function()
    local name = ConfigNameBox.Text
    if name == "" then
        ConfigStatusLabel.Text = "[X] 请先选择或输入配置名称"
        ConfigStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    local ok, err = LoadConfigFromFile(name)
    if ok then
        ConfigStatusLabel.Text = "[OK] 配置已加载: " .. name
        ConfigStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        if UpdateIslandDisplay then UpdateIslandDisplay("配置已加载: " .. name, 2) end
    else
        ConfigStatusLabel.Text = "[X] 加载失败: " .. (err or "未知错误")
        ConfigStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

CreateConfigButton(ConfigPage, "[ 设为自动加载 ]", Color3.fromRGB(180, 120, 50), function()
    local name = ConfigNameBox.Text
    if name == "" then
        ConfigStatusLabel.Text = "[X] 请先选择或输入配置名称"
        ConfigStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    SetAutoLoad(name)
    ConfigStatusLabel.Text = "[OK] 已设为自动加载: " .. name
    ConfigStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    if UpdateIslandDisplay then UpdateIslandDisplay("自动加载: " .. name, 2) end
end)

CreateConfigButton(ConfigPage, "[ 移除自动加载 ]", Color3.fromRGB(180, 80, 80), function()
    SetAutoLoad(nil)
    ConfigStatusLabel.Text = "已移除自动加载"
    ConfigStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    if UpdateIslandDisplay then UpdateIslandDisplay("已移除自动加载", 2) end
end)

CreateConfigButton(ConfigPage, "[ 删除配置 ]", Color3.fromRGB(200, 50, 50), function()
    local name = ConfigNameBox.Text
    if name == "" then
        ConfigStatusLabel.Text = "[X] 请先选择或输入配置名称"
        ConfigStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    if GetAutoLoadConfig() == name then SetAutoLoad(nil) end
    DeleteConfigFile(name)
    ConfigStatusLabel.Text = "配置已删除: " .. name
    ConfigStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    CurrentConfigName = ""
    ConfigNameBox.Text = ""
    ConfigListDrop.SetVisible(false)
    ConfigListDrop = CreateAccordionDropdown(ConfigPage, "选择已保存的配置", GetConfigList(), false, function(val)
        CurrentConfigName = val
        ConfigNameBox.Text = val
    end)
    if UpdateIslandDisplay then UpdateIslandDisplay("配置已删除: " .. name, 2) end
end)

CreateConfigButton(ConfigPage, "[ 刷新配置列表 ]", Color3.fromRGB(80, 80, 80), function()
    ConfigListDrop.SetVisible(false)
    ConfigListDrop = CreateAccordionDropdown(ConfigPage, "选择已保存的配置", GetConfigList(), false, function(val)
        CurrentConfigName = val
        ConfigNameBox.Text = val
    end)
    ConfigStatusLabel.Text = "列表已刷新 | 自动加载: " .. (GetAutoLoadConfig() or "无")
    ConfigStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
end)

local autoLoadName = GetAutoLoadConfig()
if autoLoadName then
    task.spawn(function()
        task.wait(1)
        local ok, err = LoadConfigFromFile(autoLoadName)
        if ok then
            ConfigStatusLabel.Text = "[OK] 已自动加载: " .. autoLoadName
            ConfigStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            ConfigStatusLabel.Text = "[!] 自动加载失败: " .. autoLoadName
            ConfigStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    end)
end

-- [灵动岛 - Dynamic Island]
IslandPanel = Instance.new("TextButton")
IslandPanel.Size = UDim2.new(0, 160, 0, 36)
IslandPanel.Position = UDim2.new(0.5, 0, 0, -50) 
IslandPanel.AnchorPoint = Vector2.new(0.5, 0)
IslandPanel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
IslandPanel.BackgroundTransparency = 0.2
IslandPanel.Text = ""
IslandPanel.AutoButtonColor = false
IslandPanel.Visible = false
IslandPanel.ZIndex = 50
IslandPanel.Parent = ScreenGui
local IslandCorner = Instance.new("UICorner")
IslandCorner.CornerRadius = UDim.new(1, 0)
IslandCorner.Parent = IslandPanel

local IslandAvatar = Instance.new("ImageLabel")
IslandAvatar.Size = UDim2.new(0, 24, 0, 24)
IslandAvatar.Position = UDim2.new(0, 8, 0, 6)
IslandAvatar.BackgroundTransparency = 1
IslandAvatar.Visible = false
IslandAvatar.ZIndex = 51
IslandAvatar.Parent = IslandPanel
local IslandAvatarCorner = Instance.new("UICorner")
IslandAvatarCorner.CornerRadius = UDim.new(1, 0)
IslandAvatarCorner.Parent = IslandAvatar

local IslandText = Instance.new("TextLabel")
IslandText.Size = UDim2.new(1, -20, 1, 0)
IslandText.Position = UDim2.new(0.5, 0, 0, 0)
IslandText.AnchorPoint = Vector2.new(0.5, 0)
IslandText.BackgroundTransparency = 1
IslandText.Text = "Zimi Universal"
IslandText.TextColor3 = Color3.fromRGB(255, 255, 255)
IslandText.Font = Enum.Font.GothamSemibold
IslandText.TextSize = 13
IslandText.TextTransparency = 0
IslandText.ZIndex = 51
IslandText.Parent = IslandPanel

local IslandOverrideTime = 0
local IslandCurrentText = ""
local IslandAnimToken = 0
local IslandQueue = {}
local isIslandAnimating = false

local function getChars(str)
    local chars = {}
    for _, c in utf8.codes(str) do table.insert(chars, utf8.char(c)) end
    return chars
end

local function ProcessIslandQueue()
    if isIslandAnimating or #IslandQueue == 0 or _G.ZimiUnloaded then return end
    isIslandAnimating = true
    
    local nextAnim = table.remove(IslandQueue, 1)
    local text = nextAnim.text
    local overrideDur = nextAnim.dur
    local avatarId = nextAnim.avatarId
    
    if overrideDur then
        IslandOverrideTime = tick() + overrideDur
    end
    
    IslandCurrentText = text
    IslandAnimToken = IslandAnimToken + 1
    local myToken = IslandAnimToken

    local newBounds = TextService:GetTextSize(text, 13, Enum.Font.GothamSemibold, Vector2.new(1000, 1000))
    local avatarPad = avatarId and 42 or 28
    local targetWidth = math.clamp(newBounds.X + avatarPad, 90, 460)
    local targetHeight = math.clamp(newBounds.Y + 20, 36, 130)

    task.spawn(function()
        -- 阶段1: 旧文字逐字消失（面板随文字缩小）
        local oldChars = getChars(IslandText.Text)
        if #oldChars > 0 then
            for i = #oldChars, 0, -1 do
                if _G.ZimiUnloaded or myToken ~= IslandAnimToken then isIslandAnimating = false; return end
                IslandText.Text = table.concat(oldChars, "", 1, i)
                local b = TextService:GetTextSize(IslandText.Text, 13, Enum.Font.GothamSemibold, Vector2.new(1000, 1000))
                local curW = math.clamp(b.X + (IslandAvatar.Visible and 42 or 28), 90, 460)
                local curH = math.clamp(b.Y + 20, 36, 130)
                -- 使用弹性缓动让大小变化更流畅
                TweenService:Create(IslandPanel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, curW, 0, curH)}):Play()
                task.wait(0.012)
            end
        end

        if _G.ZimiUnloaded or myToken ~= IslandAnimToken then isIslandAnimating = false; return end

        -- 阶段2: 更新头像和布局
        if avatarId then
            IslandAvatar.Visible = true
            IslandText.Position = UDim2.new(0, 38, 0, 8)
            IslandText.AnchorPoint = Vector2.new(0, 0)
            IslandText.TextXAlignment = Enum.TextXAlignment.Left
            IslandText.TextYAlignment = Enum.TextYAlignment.Top
            task.spawn(function()
                pcall(function() IslandAvatar.Image = Players:GetUserThumbnailAsync(avatarId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end)
            end)
        else
            IslandAvatar.Visible = false
            IslandText.Position = UDim2.new(0.5, 0, 0.5, 0)
            IslandText.AnchorPoint = Vector2.new(0.5, 0.5)
            IslandText.TextXAlignment = Enum.TextXAlignment.Center
            IslandText.TextYAlignment = Enum.TextYAlignment.Center
        end

        -- 阶段3: 新文字逐字出现（面板随文字增长）
        local newChars = getChars(text)
        for i = 1, #newChars do
            if _G.ZimiUnloaded or myToken ~= IslandAnimToken then isIslandAnimating = false; return end
            IslandText.Text = table.concat(newChars, "", 1, i)
            local b = TextService:GetTextSize(IslandText.Text, 13, Enum.Font.GothamSemibold, Vector2.new(1000, 1000))
            local curW = math.clamp(b.X + (avatarId and 42 or 28), 90, 460)
            local curH = math.clamp(b.Y + 20, 36, 130)
            -- 使用弹性缓动让面板跟随文字增长
            TweenService:Create(IslandPanel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, curW, 0, curH)}):Play()
            task.wait(0.018)
        end

        if _G.ZimiUnloaded or myToken ~= IslandAnimToken then isIslandAnimating = false; return end
        -- 阶段4: 最终微调到精确尺寸
        TweenService:Create(IslandPanel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, targetWidth, 0, targetHeight)}):Play()
        
        task.wait(0.15)
        isIslandAnimating = false
        ProcessIslandQueue()
    end)
end

UpdateIslandDisplay = function(text, overrideDur, avatarId)
    if (not overrideDur and tick() < IslandOverrideTime) then return end
    if text == IslandCurrentText then return end
    
    table.clear(IslandQueue)
    table.insert(IslandQueue, {text = text, dur = overrideDur, avatarId = avatarId})
    
    if not isIslandAnimating then ProcessIslandQueue() end
end

local function SetupHealthHook(char)
    local hum = char:WaitForChild("Humanoid", 3)
    if hum then
        table.insert(ZimiConnections, hum.HealthChanged:Connect(function(hp)
            if not IslandPanel.Visible then return end
            UpdateIslandDisplay("生命值  " .. math.floor(hp) .. " / " .. math.floor(hum.MaxHealth), 2.5)
        end))
    end
end
if LocalPlayer.Character then SetupHealthHook(LocalPlayer.Character) end
table.insert(ZimiConnections, LocalPlayer.CharacterAdded:Connect(SetupHealthHook))

local phrases = {"祝你游戏愉快", "今天也是充满希望的一天", "保持好心情", "Zimi 伴你同行", "注意劳逸结合", "愿你旗开得胜", "稳住 我们能赢"}
task.spawn(function()
    local cycle = 0
    while not _G.ZimiUnloaded do
        task.wait(4)
        if IslandPanel.Visible and tick() >= IslandOverrideTime then
            cycle = cycle + 1
            local r = (cycle % 3)
            if r == 0 then
                local d = os.date("*t")
                UpdateIslandDisplay(string.format("本地时间  %02d:%02d", d.hour, d.min))
            elseif r == 1 then
                local sName = "Roblox Server"
                pcall(function() sName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
                UpdateIslandDisplay(sName)
            else
                UpdateIslandDisplay(phrases[math.random(1, #phrases)])
            end
        end
    end
end)


local LastExpandedPosition = UDim2.new(0.5, 0, 0.5, 0)
local function GetSafeExpandedPosition(posUDim)
    local sX, sY = Camera.ViewportSize.X, Camera.ViewportSize.Y
    local cX = posUDim.X.Offset
    if posUDim.X.Scale > 0 then cX = posUDim.X.Scale * sX end
    local cY = posUDim.Y.Offset
    if posUDim.Y.Scale > 0 then cY = posUDim.Y.Scale * sY end
    local mX, mY = 280, 180
    return UDim2.new(0, math.clamp(cX, mX, sX - mX), 0, math.clamp(cY, mY, sY - mY))
end

table.insert(ZimiConnections, MinimizeBtn.MouseButton1Click:Connect(function()
    LastExpandedPosition = MainFrame.Position
    TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0, 20)}):Play()
    TweenService:Create(BlurEffect, TweenInfo.new(0.35), {Size = 0}):Play()
    task.delay(0.35, function()
        if not _G.ZimiUnloaded then
            MainFrame.Visible = false
            IslandPanel.Visible = true
            TweenService:Create(IslandPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 15)}):Play()
        end
    end)
end))

table.insert(ZimiConnections, IslandPanel.MouseButton1Click:Connect(function()
    TweenService:Create(IslandPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -50)}):Play()
    task.delay(0.2, function()
        if not _G.ZimiUnloaded then
            IslandPanel.Visible = false
            MainFrame.Position = UDim2.new(0.5, 0, 0, 20)
            MainFrame.Size = UDim2.new(0, 0, 0, 0)
            MainFrame.Visible = true
            TweenService:Create(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 560, 0, 360), Position = GetSafeExpandedPosition(LastExpandedPosition)}):Play()
            TweenService:Create(BlurEffect, TweenInfo.new(0.4), {Size = 15}):Play()
        end
    end)
end))

local ClosePopup = Instance.new("Frame")
ClosePopup.Size = UDim2.new(1, 0, 1, 0)
ClosePopup.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ClosePopup.BackgroundTransparency = 1
ClosePopup.Visible = false
ClosePopup.ZIndex = 100
ClosePopup.Parent = ScreenGui

local PopupBox = Instance.new("Frame")
PopupBox.Size = UDim2.new(0, 0, 0, 0)
PopupBox.AnchorPoint = Vector2.new(0.5, 0.5)
PopupBox.Position = UDim2.new(0.5, 0, 0.5, 0)
PopupBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
PopupBox.BackgroundTransparency = 0.1
PopupBox.ClipsDescendants = true
PopupBox.ZIndex = 101
PopupBox.Parent = ClosePopup
local PopupCorner = Instance.new("UICorner")
PopupCorner.CornerRadius = UDim.new(0, 8)
PopupCorner.Parent = PopupBox

local PopupText = Instance.new("TextLabel")
PopupText.Size = UDim2.new(0, 300, 0, 80)
PopupText.AnchorPoint = Vector2.new(0.5, 0)
PopupText.Position = UDim2.new(0.5, 0, 0, 10)
PopupText.BackgroundTransparency = 1
PopupText.Text = "是否确定关闭?\n关闭后将清理后台连接并销毁所有功能。"
PopupText.TextColor3 = Color3.fromRGB(255, 255, 255)
PopupText.TextSize = 13
PopupText.Font = Enum.Font.GothamSemibold
PopupText.ZIndex = 102
PopupText.Parent = PopupBox

local ConfirmBtn = Instance.new("TextButton")
ConfirmBtn.Size = UDim2.new(0, 90, 0, 32)
ConfirmBtn.Position = UDim2.new(0, 45, 0, 95)
ConfirmBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ConfirmBtn.Text = "关闭"
ConfirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmBtn.TextSize = 13
ConfirmBtn.Font = Enum.Font.GothamBold
ConfirmBtn.ZIndex = 102
ConfirmBtn.Parent = PopupBox
local ConfirmCorner = Instance.new("UICorner")
ConfirmCorner.CornerRadius = UDim.new(0, 6)
ConfirmCorner.Parent = ConfirmBtn

local CancelBtn = Instance.new("TextButton")
CancelBtn.Size = UDim2.new(0, 90, 0, 32)
CancelBtn.Position = UDim2.new(1, -135, 0, 95)
CancelBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
CancelBtn.Text = "取消"
CancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CancelBtn.TextSize = 13
CancelBtn.Font = Enum.Font.GothamBold
CancelBtn.ZIndex = 102
CancelBtn.Parent = PopupBox
local CancelCorner = Instance.new("UICorner")
CancelCorner.CornerRadius = UDim.new(0, 6)
CancelCorner.Parent = CancelBtn

table.insert(ZimiConnections, CloseBtn.MouseButton1Click:Connect(function()
    ClosePopup.Visible = true
    PopupBox.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(ClosePopup, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(PopupBox, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, 140)}):Play()
end))

table.insert(ZimiConnections, CancelBtn.MouseButton1Click:Connect(function()
    TweenService:Create(ClosePopup, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    local tw = TweenService:Create(PopupBox, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
    tw:Play()
    tw.Completed:Connect(function() ClosePopup.Visible = false end)
end))

table.insert(ZimiConnections, ConfirmBtn.MouseButton1Click:Connect(function()
    _G.ZimiUnloaded = true
    for _, c in ipairs(ZimiConnections) do if c.Connected then c:Disconnect() end end
    table.clear(ZimiConnections)
    if ZimiSettings.PlayerModsEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
        LocalPlayer.Character.Humanoid.JumpPower = 50
    end
    for _, c in pairs(ESP_Cache) do HideAllESP(c) end
    ESP_Cache = {}
    
    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
    TweenService:Create(BlurEffect, TweenInfo.new(0.3), {Size = 0}):Play()
    task.wait(0.3)
    ScreenGui:Destroy()
    QuickBtnGui:Destroy()
    AimBtnGui:Destroy()
    if ESPScreen then ESPScreen:Destroy() end
    BlurEffect:Destroy()
end))

-- RenderStepped / Main Logic Loop
local aimIslandActive = false
local currentIslandTargetId = nil

table.insert(ZimiConnections, RunService.RenderStepped:Connect(function()
    if _G.ZimiUnloaded then return end
    
    if CurrentPage == InfoPage then
        local d = os.date("*t")
        GameTimeLabel.Text = string.format("本地时间: %02d:%02d:%02d", d.hour, d.min, d.sec)
        local s = tick() - StartTime
        PlaytimeLabel.Text = string.format("已游玩: %02d:%02d:%02d", math.floor(s/3600), math.floor((s%3600)/60), math.floor(s%60))

        -- FPS 统计
        fpsAccum = fpsAccum + 0.016
        fpsFrames = fpsFrames + 1
        if fpsAccum >= 0.5 then
            local fpsValue = math.floor(fpsFrames / fpsAccum)
            FpsLabel.Text = "FPS: " .. fpsValue
            fpsAccum = 0
            fpsFrames = 0
        end

        -- 延迟
        pcall(function()
            local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
            PingLabel.Text = "延迟: " .. ping .. " ms"
        end)

        -- 在线人数
        PlayerCountLabel.Text = "在线人数: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers
    end
    
    if ZimiSettings.PlayerModsEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = ZimiSettings.WalkSpeed
        LocalPlayer.Character.Humanoid.JumpPower = ZimiSettings.JumpPower
    end

    -- [渲染功能]
    if ZimiSettings.Render.FullBright then
        if Lighting.Brightness ~= 2 then Lighting.Brightness = 2 end
        if Lighting.ClockTime ~= 12 then Lighting.ClockTime = 12 end
        if Lighting.FogEnd ~= 99999 then Lighting.FogEnd = 99999 end
    end

    -- [玩家功能]
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        -- Noclip (穿墙)
        if ZimiSettings.PlayerFunc.Noclip then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end

        -- Fly (使用 BodyVelocity + BodyGyro 实现稳定飞行)
        if ZimiSettings.PlayerFunc.FlyEnabled and hrp then
            -- 确保 BodyVelocity 存在
            local bv = LocalPlayer.Character:FindFirstChild("ZimiFlyVel")
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "ZimiFlyVel"
                bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                bv.Velocity = Vector3.new(0, 0, 0)
                bv.Parent = hrp
            end

            -- 确保 BodyGyro 存在
            local bg = LocalPlayer.Character:FindFirstChild("ZimiFlyGyro")
            if not bg then
                bg = Instance.new("BodyGyro")
                bg.Name = "ZimiFlyGyro"
                bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
                bg.CFrame = hrp.CFrame
                bg.Parent = hrp
            end

            hum.PlatformStand = true

            local speed = ZimiSettings.PlayerFunc.FlySpeed
            local moveDir = Vector3.new(0, 0, 0)

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end

            if moveDir.Magnitude > 0 then
                bv.Velocity = moveDir.Unit * speed
            else
                bv.Velocity = Vector3.new(0, 0, 0)
            end

            -- 保持角色朝向
            bg.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + Camera.CFrame.LookVector)
        else
            -- 关闭 Fly 时清理
            if not ZimiSettings.PlayerFunc.FlyEnabled then
                for _, v in ipairs({"ZimiFlyVel", "ZimiFlyGyro"}) do
                    local obj = LocalPlayer.Character:FindFirstChild(v)
                    if obj then obj:Destroy() end
                end
                if hum and not ZimiSettings.PlayerFunc.PlatformStand and not ZimiSettings.PlayerFunc.Derp then
                    hum.PlatformStand = false
                end
            end
        end

        -- Spin (自旋转) - 使用 BodyAngularVelocity 不干扰移动
        if ZimiSettings.PlayerFunc.SpinEnabled and hrp then
            local bav = LocalPlayer.Character:FindFirstChild("ZimiSpinAV")
            if not bav then
                bav = Instance.new("BodyAngularVelocity")
                bav.Name = "ZimiSpinAV"
                bav.MaxTorque = Vector3.new(0, 1e6, 0)
                bav.AngularVelocity = Vector3.new(0, 0, 0)
                bav.Parent = hrp
            end
            bav.AngularVelocity = Vector3.new(0, ZimiSettings.PlayerFunc.SpinSpeed * 0.5, 0)
        else
            local bav = hrp and hrp:FindFirstChild("ZimiSpinAV")
            if bav then bav:Destroy() end
        end

        -- Frozen (冻结位置)
        if ZimiSettings.PlayerFunc.Frozen and hrp then
            hrp.Anchored = true
        end

        -- Infinite Jump (无限跳跃)
        if ZimiSettings.PlayerFunc.InfJump then
            hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        end

        -- Derp (瘫痪模式)
        if ZimiSettings.PlayerFunc.Derp then
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum.PlatformStand = true
            task.wait(0.1)
            hum.PlatformStand = false
        end

        -- PlatformStand (独立于 Fly)
        if ZimiSettings.PlayerFunc.PlatformStand and not ZimiSettings.PlayerFunc.FlyEnabled then
            hum.PlatformStand = true
        end
    end

    -- [服务器功能 - 防挂机]
    if ZimiSettings.ServerFunc.AntiAfk then
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(math.random(100, 600), math.random(100, 400)))
    end

    -- [个性GUI 视觉效果] (轻量版)
    if ZimiSettings.GuiFX.Master then
        -- 动态流光扫过效果
        if ZimiSettings.GuiFX.FlowingLight then
            if not MainFrame:FindFirstChild("ZimiFlowLight") then
                local flowFrame = Instance.new("Frame")
                flowFrame.Name = "ZimiFlowLight"
                flowFrame.Size = UDim2.new(0, 80, 1, 0)
                flowFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                flowFrame.BackgroundTransparency = 0.7
                flowFrame.BorderSizePixel = 0
                flowFrame.ZIndex = 11
                flowFrame.Parent = MainFrame
            end
            local flowFrame = MainFrame:FindFirstChild("ZimiFlowLight")
            if flowFrame then
                local speed = ZimiSettings.GuiFX.FlowSpeed * 80
                local pos = ((tick() * speed) % (MainFrame.AbsoluteSize.X + 160)) - 80
                flowFrame.Position = UDim2.new(0, pos, 0, 0)
                flowFrame.BackgroundColor3 = Color3.fromHSV(ZimiSettings.GuiFX.FlowHue / 360, 0.6, 1)
            end
        else
            local ff = MainFrame:FindFirstChild("ZimiFlowLight")
            if ff then ff:Destroy() end
        end

        -- 灵动岛背景流光
        if ZimiSettings.GuiFX.IslandGlow and IslandPanel then
            IslandPanel.BackgroundColor3 = Color3.fromHSV((tick() * 30) % 360 / 360, 0.6, 0.9)
        end
    else
        local ff = MainFrame:FindFirstChild("ZimiFlowLight")
        if ff then ff:Destroy() end
    end

    if ZimiSettings.TpMode == "循环" and tpActiveState and ZimiSettings.TpTarget and ZimiSettings.TpTarget.Character and ZimiSettings.TpTarget.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHrp = LocalPlayer.Character.HumanoidRootPart
            local tHrp = ZimiSettings.TpTarget.Character.HumanoidRootPart
            local posStr = ZimiSettings.TpPosition
            
            if posStr == "环绕" then
                local angle = tick() * ZimiSettings.TpOrbitSpeed
                local radius = ZimiSettings.TpOrbitRadius
                local height = ZimiSettings.TpOrbitHeight
                local offset = CFrame.new(math.sin(angle) * radius, height, math.cos(angle) * radius)
                local targetPos = tHrp.Position + offset.Position
                myHrp.CFrame = CFrame.lookAt(targetPos, tHrp.Position)
            else
                local offset = CFrame.new()
                if posStr == "上面" then offset = CFrame.new(0, 5, 0)
                elseif posStr == "下面" then offset = CFrame.new(0, -5, 0)
                elseif posStr == "前面" then offset = CFrame.new(0, 0, -5)
                elseif posStr == "后面" then offset = CFrame.new(0, 0, 5)
                elseif posStr == "左边" then offset = CFrame.new(-5, 0, 0)
                elseif posStr == "右边" then offset = CFrame.new(5, 0, 0)
                end
                myHrp.CFrame = tHrp.CFrame * offset
            end
        end
    end

    -- AIMBOT LOGIC
    if AimFovCircle.Visible then
        AimFovCircle.Size = UDim2.new(0, ZimiSettings.AimFov * 2, 0, ZimiSettings.AimFov * 2)
    end

    if not ZimiSettings.AimEnabled then
        ZimiSettings.AimTarget = nil
        if aimIslandActive then
            aimIslandActive = false
            currentIslandTargetId = nil
            if not MainFrame.Visible then IslandPanel.Visible = true end
            UpdateIslandDisplay("Zimi Universal", 0.1)
        end
    else
        local shouldAim = true
        if ZimiSettings.AimBtnEnabled then shouldAim = aimBtnActiveToggle end
        
        if not shouldAim then
            ZimiSettings.AimTarget = nil
        else
            local targetModel, targetName, targetUserId
            if ZimiSettings.AimNPCMode then
                targetModel = ZimiSettings.AimNpcTarget
                if targetModel then targetName = targetModel.Name end
            else
                local targetPlayer = GetAimTarget()
                ZimiSettings.AimTarget = targetPlayer
                if targetPlayer then
                    targetModel = targetPlayer.Character
                    targetName = targetPlayer.DisplayName
                    targetUserId = targetPlayer.UserId
                end
            end

            if targetModel then
                local aimPart = GetBestAimPart(targetModel)
                if aimPart then
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, aimPart.Position)
                    
                    if ZimiSettings.AimTargetInfo then
                        aimIslandActive = true
                        IslandPanel.Visible = true
                        local hum = targetModel:FindFirstChildOfClass("Humanoid")
                        local hp = hum and math.floor(hum.Health) or 0
                        local dist = math.floor((Camera.CFrame.Position - aimPart.Position).Magnitude)
                        local distRounded = math.floor(dist / 5) * 5
                        
                        local targetIdStr = targetName .. aimPart.Name
                        local fullText = targetName .. " [" .. aimPart.Name .. "]\n生命值: " .. hp .. "\n距离: " .. distRounded .. " 米"
                        
                        if currentIslandTargetId ~= targetIdStr then
                            currentIslandTargetId = targetIdStr
                            UpdateIslandDisplay(fullText, 0.6, targetUserId)
                        else
                            if not isIslandAnimating then IslandText.Text = fullText end
                        end
                    end
                end
            end
        end
    end

    -- HITBOX LOGIC
    if ZimiSettings.Hitbox.Enabled then
        local targetPartName = ZimiSettings.Hitbox.TargetPart
        local sx, sy, sz = ZimiSettings.Hitbox.SizeX, ZimiSettings.Hitbox.SizeY, ZimiSettings.Hitbox.SizeZ
        local trans = ZimiSettings.Hitbox.Transparency
        local mat = ZimiSettings.Hitbox.Material
        local useOutline = ZimiSettings.Hitbox.Outline
        local canCollide = ZimiSettings.Hitbox.CanCollide

        if ZimiSettings.Hitbox.NPCMode then
            local targets = (ZimiSettings.Hitbox.NpcTarget and ZimiSettings.Hitbox.NpcTarget.Parent) and {ZimiSettings.Hitbox.NpcTarget} or ZimiSettings.NpcList
            for _, npcModel in ipairs(targets) do
                if npcModel and npcModel.Parent then
                    local part = npcModel:FindFirstChild(targetPartName)
                    if part and part:IsA("BasePart") then
                        part.Size = Vector3.new(sx, sy, sz)
                        part.Transparency = trans
                        part.Material = mat
                        part.CanCollide = canCollide
                        if useOutline then
                            local hl = part:FindFirstChild("ZimiHitboxHL")
                            if not hl then
                                hl = Instance.new("Highlight")
                                hl.Name = "ZimiHitboxHL"
                                hl.Parent = part
                            end
                            hl.FillTransparency = 1
                            hl.OutlineColor = ZimiSettings.Hitbox.OutlineColor
                            hl.OutlineTransparency = ZimiSettings.Hitbox.OutlineTrans
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        else
                            local hl = part:FindFirstChild("ZimiHitboxHL")
                            if hl then hl:Destroy() end
                        end
                    end
                end
            end
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr == LocalPlayer then continue end
                if ZimiSettings.Hitbox.TeamCheck and plr.Team == LocalPlayer.Team then continue end
                if ZimiSettings.Hitbox.FriendCheck then
                    local isFriend = false
                    pcall(function() isFriend = LocalPlayer:IsFriendsWith(plr.UserId) end)
                    if isFriend then continue end
                end
                local char = plr.Character
                if char then
                    local part = char:FindFirstChild(targetPartName)
                    if part and part:IsA("BasePart") then
                        part.Size = Vector3.new(sx, sy, sz)
                        part.Transparency = trans
                        part.Material = mat
                        part.CanCollide = canCollide
                        if useOutline then
                            local hl = part:FindFirstChild("ZimiHitboxHL")
                            if not hl then
                                hl = Instance.new("Highlight")
                                hl.Name = "ZimiHitboxHL"
                                hl.Parent = part
                            end
                            hl.FillTransparency = 1
                            hl.OutlineColor = ZimiSettings.Hitbox.OutlineColor
                            hl.OutlineTransparency = ZimiSettings.Hitbox.OutlineTrans
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        else
                            local hl = part:FindFirstChild("ZimiHitboxHL")
                            if hl then hl:Destroy() end
                        end
                    end
                end
            end
        end
    else
        -- 清理所有 Hitbox 修改（禁用时恢复）
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if char then
                for _, partName in ipairs({"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "UpperTorso", "LowerTorso", "LeftHand", "RightHand", "LeftFoot", "RightFoot"}) do
                    local part = char:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        part.Size = Vector3.new(2, 2, 1)
                        part.Transparency = 0
                        part.Material = Enum.Material.Plastic
                        part.CanCollide = true
                        local hl = part:FindFirstChild("ZimiHitboxHL")
                        if hl then hl:Destroy() end
                    end
                end
            end
        end
        for _, npcModel in ipairs(ZimiSettings.NpcList) do
            if npcModel and npcModel.Parent then
                for _, partName in ipairs({"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "UpperTorso", "LowerTorso", "LeftHand", "RightHand", "LeftFoot", "RightFoot"}) do
                    local part = npcModel:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        local hl = part:FindFirstChild("ZimiHitboxHL")
                        if hl then hl:Destroy() end
                    end
                end
            end
        end
    end

    -- ESP LOGIC
    if ZimiSettings.ESP.Master then
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local e_char = player.Character
            
            if not e_char or not e_char:FindFirstChild("HumanoidRootPart") then continue end
            if not ESP_Cache[player] then CreateEspDrawings(player) end
            local c = ESP_Cache[player]
            
            local hrp = e_char.HumanoidRootPart
            local head = e_char:FindFirstChild("Head")
            local hum = e_char:FindFirstChild("Humanoid")
            local isAlive = hum and hum.Health > 0
            
            local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local distToPlayer = rootPos.Z

            local shouldShowESP = true
            if not ZimiSettings.ESP.Master then shouldShowESP = false end
            if distToPlayer > ZimiSettings.ESP.MaxDist then shouldShowESP = false end
            if not isAlive then shouldShowESP = false end
            if not head then shouldShowESP = false end

            if not shouldShowESP or not onScreen or distToPlayer < 0 then 
                HideAllESP(c)
                continue 
            end
            
            local boxCol = ZimiSettings.ESP.Box.Color
            local trCol = ZimiSettings.ESP.Tracer.Color
            local nmCol = ZimiSettings.ESP.Name.Color
            local skelCol = ZimiSettings.ESP.Skel.Color
            local distCol = ZimiSettings.ESP.Dist.Color
            
            local safeDist = math.max(distToPlayer, 5)
            local scale = 1
            if ZimiSettings.ESP.DistScale then scale = math.clamp(1000 / safeDist, 0.4, 1.2) end
            
            local top2D = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local bottom2D = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            local boxHeight = math.max(math.abs(top2D.Y - bottom2D.Y), 5)
            local boxWidth = math.max(boxHeight * 0.55, 3)
            local posX = rootPos.X - boxWidth/2
            local posY = top2D.Y

            -- Box
            c.Box.Visible = ZimiSettings.ESP.Box.Enabled
            if c.Box.Visible then
                c.Box.Size = Vector2.new(boxWidth, boxHeight)
                c.Box.Position = Vector2.new(posX, posY)
                c.Box.Color = boxCol
                c.Box.Thickness = 1.5 * scale
            end
            
            -- Chams 透视 (Highlight AlwaysOnTop 穿墙可见)
            if ZimiSettings.ESP.Chams.Enabled then
                ApplyChamsToCharacter(e_char, c, ZimiSettings.ESP.Chams.Color, true)
            else
                ApplyChamsToCharacter(e_char, c, nil, false)
            end

            -- Skeleton
            if ZimiSettings.ESP.Skel.Enabled then
                local topo = e_char:FindFirstChild("UpperTorso") and SkeletonR15 or SkeletonR6
                local drawLines = {c.Spine, c.LeftArm, c.RightArm, c.LeftLeg, c.RightLeg, c.Shoulders, c.Hips}
                for i=1, 7 do drawLines[i].Visible = false end
                
                -- Simplified Skeleton drawing logic for optimization
                -- Maps the 7 lines to basic skeleton groups
                local function dr(line, bp1, bp2)
                    local p1, p2 = e_char:FindFirstChild(bp1), e_char:FindFirstChild(bp2)
                    if p1 and p2 then
                        local pos1, o1 = Camera:WorldToViewportPoint(p1.Position)
                        local pos2, o2 = Camera:WorldToViewportPoint(p2.Position)
                        if o1 or o2 then
                            line.Visible = true; line.From = Vector2.new(pos1.X, pos1.Y); line.To = Vector2.new(pos2.X, pos2.Y); line.Color = skelCol; line.Thickness = 1.5 * scale
                        end
                    end
                end
                if e_char:FindFirstChild("UpperTorso") then
                    dr(c.Spine, "Head", "LowerTorso"); dr(c.LeftArm, "LeftUpperArm", "LeftHand"); dr(c.RightArm, "RightUpperArm", "RightHand")
                    dr(c.LeftLeg, "LeftUpperLeg", "LeftFoot"); dr(c.RightLeg, "RightUpperLeg", "RightFoot"); dr(c.Shoulders, "LeftUpperArm", "RightUpperArm"); dr(c.Hips, "LeftUpperLeg", "RightUpperLeg")
                else
                    dr(c.Spine, "Head", "Torso"); dr(c.LeftArm, "Torso", "Left Arm"); dr(c.RightArm, "Torso", "Right Arm")
                    dr(c.LeftLeg, "Torso", "Left Leg"); dr(c.RightLeg, "Torso", "Right Leg")
                end
            else
                c.Spine.Visible = false; c.LeftArm.Visible = false; c.RightArm.Visible = false; c.LeftLeg.Visible = false; c.RightLeg.Visible = false; c.Shoulders.Visible = false; c.Hips.Visible = false
            end

            -- Health
            local hpVis = ZimiSettings.ESP.Health.Enabled
            c.HealthBar.Visible = hpVis; c.HealthOutline.Visible = hpVis
            if hpVis then
                local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                c.HealthOutline.Size = Vector2.new(4 * scale, boxHeight + 2)
                c.HealthOutline.Position = Vector2.new(posX - (6 * scale), posY - 1)
                local barH = boxHeight * hpPct
                c.HealthBar.Size = Vector2.new((4 * scale) - 2, barH)
                c.HealthBar.Position = Vector2.new(posX - (6 * scale) + 1, posY + (boxHeight - barH) + 1)
                c.HealthBar.Color = Color3.new(1 - hpPct, hpPct, 0)
            end

            -- Name & Dist
            local nVis = ZimiSettings.ESP.Name.Enabled
            c.Name.Visible = nVis
            if nVis then
                c.Name.Text = player.Name
                c.Name.Size = 16 * scale
                c.Name.Position = Vector2.new(rootPos.X, posY - c.Name.Size - 4)
                c.Name.Color = nmCol
            end

            local dVis = ZimiSettings.ESP.Dist.Enabled
            c.DistTxt.Visible = dVis
            if dVis then
                c.DistTxt.Text = "[" .. math.floor(distToPlayer) .. "m]"
                c.DistTxt.Size = 14 * scale
                c.DistTxt.Position = Vector2.new(rootPos.X, posY + boxHeight + 4)
                c.DistTxt.Color = distCol
            end

            -- Tracer
            c.Tracer.Visible = ZimiSettings.ESP.Tracer.Enabled
            if c.Tracer.Visible then
                c.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                c.Tracer.To = Vector2.new(rootPos.X, posY + boxHeight)
                c.Tracer.Color = trCol
                c.Tracer.Thickness = 1.5 * scale
            end
        end

        -- ESP NPC 渲染 (使用共享 NpcList)
        if ZimiSettings.ESP.ShowNPCs then
            local targets = (ZimiSettings.ESP.EspNpcTarget and ZimiSettings.ESP.EspNpcTarget.Parent) and {ZimiSettings.ESP.EspNpcTarget} or ZimiSettings.NpcList
            for _, npcModel in ipairs(targets) do
                if not npcModel or not npcModel.Parent then continue end
                local e_char = npcModel
                if not e_char:FindFirstChild("HumanoidRootPart") then continue end
                if not e_char:FindFirstChild("Head") then continue end

                -- 为 NPC 创建 ESP 缓存 (使用 Model 本身作为 key)
                if not ESP_Cache[npcModel] then CreateEspDrawings(npcModel) end
                local c = ESP_Cache[npcModel]

                local hrp = e_char.HumanoidRootPart
                local head = e_char.Head
                local hum = e_char:FindFirstChildOfClass("Humanoid")
                local isAlive = hum and hum.Health > 0

                local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local distToPlayer = rootPos.Z

                if not onScreen or distToPlayer < 0 then
                    HideAllESP(c)
                    continue
                end

                if not isAlive then
                    HideAllESP(c)
                    continue
                end

                if distToPlayer > ZimiSettings.ESP.MaxDist then
                    HideAllESP(c)
                    continue
                end

                local boxCol = ZimiSettings.ESP.Box.Color
                local trCol = ZimiSettings.ESP.Tracer.Color
                local nmCol = ZimiSettings.ESP.Name.Color
                local skelCol = ZimiSettings.ESP.Skel.Color
                local distCol = ZimiSettings.ESP.Dist.Color

                local safeDist = math.max(distToPlayer, 5)
                local scale = 1
                if ZimiSettings.ESP.DistScale then scale = math.clamp(1000 / safeDist, 0.4, 1.2) end

                local top2D = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local bottom2D = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local boxHeight = math.max(math.abs(top2D.Y - bottom2D.Y), 5)
                local boxWidth = math.max(boxHeight * 0.55, 3)
                local posX = rootPos.X - boxWidth/2
                local posY = top2D.Y

                -- Box for NPC
                c.Box.Visible = ZimiSettings.ESP.Box.Enabled
                if c.Box.Visible then
                    c.Box.Size = Vector2.new(boxWidth, boxHeight)
                    c.Box.Position = Vector2.new(posX, posY)
                    c.Box.Color = boxCol
                    c.Box.Thickness = 1.5 * scale
                end

                -- Name for NPC (显示 NPC 名字为绿色区分)
                local nVis = ZimiSettings.ESP.Name.Enabled
                c.Name.Visible = nVis
                if nVis then
                    c.Name.Text = "[NPC] " .. npcModel.Name
                    c.Name.Size = 16 * scale
                    c.Name.Position = Vector2.new(rootPos.X, posY - c.Name.Size - 4)
                    c.Name.Color = Color3.fromRGB(100, 255, 100)
                end

                -- Distance for NPC
                local dVis = ZimiSettings.ESP.Dist.Enabled
                c.DistTxt.Visible = dVis
                if dVis then
                    c.DistTxt.Text = "[" .. math.floor(distToPlayer) .. "m]"
                    c.DistTxt.Size = 14 * scale
                    c.DistTxt.Position = Vector2.new(rootPos.X, posY + boxHeight + 4)
                    c.DistTxt.Color = distCol
                end

                -- Tracer for NPC
                c.Tracer.Visible = ZimiSettings.ESP.Tracer.Enabled
                if c.Tracer.Visible then
                    c.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    c.Tracer.To = Vector2.new(rootPos.X, posY + boxHeight)
                    c.Tracer.Color = Color3.fromRGB(100, 255, 100)
                    c.Tracer.Thickness = 1.5 * scale
                end

                -- Chams 透视 for NPC
                if ZimiSettings.ESP.Chams.Enabled then
                    ApplyChamsToCharacter(e_char, c, Color3.fromRGB(100, 255, 100), true)
                else
                    ApplyChamsToCharacter(e_char, c, nil, false)
                end

                -- Skeleton: 简化处理，NPC 不画骨骼（避免性能问题）
                c.Spine.Visible = false
                c.LeftArm.Visible = false
                c.RightArm.Visible = false
                c.LeftLeg.Visible = false
                c.RightLeg.Visible = false
                c.Shoulders.Visible = false
                c.Hips.Visible = false

                -- Health: 简化
                c.HealthBar.Visible = false
                c.HealthOutline.Visible = false
            end
        end
    else
        for _, c in pairs(ESP_Cache) do HideAllESP(c) end
    end
end))

local function SetupDrag(trigger, root)
    local drag = false
    local ds, sp
    table.insert(ZimiConnections, trigger.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag, ds, sp = true, inp.Position, root.Position
        end
    end))
    table.insert(ZimiConnections, UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then drag = false end
    end))
    table.insert(ZimiConnections, UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local dx, dy = inp.Position.X - ds.X, inp.Position.Y - ds.Y
            root.Position = UDim2.new(0, math.clamp(sp.X.Offset + dx, root.AbsoluteSize.X/2, Camera.ViewportSize.X - root.AbsoluteSize.X/2), 0, math.clamp(sp.Y.Offset + dy, root.AbsoluteSize.Y/2, Camera.ViewportSize.Y - root.AbsoluteSize.Y/2))
        end
    end))
end
SetupDrag(TopBar, MainFrame)

TweenService:Create(MainFrame, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
TweenService:Create(BlurEffect, TweenInfo.new(0.8), {Size = 15}):Play()
