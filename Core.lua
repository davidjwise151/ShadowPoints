local ADDON_NAME = "ShadowPoints"
local MAX_POINT_FRAMES = 6
local PLAYER_CLASS = UnitClassBase("player")

-- Create Root Addon Frame
local addonFrame = CreateFrame("Frame", ADDON_NAME .. "Frame", UIParent)

--------------------------------------------------------------------------------
-- Texture Smoothing Helper
--------------------------------------------------------------------------------
local function CrispTexture(tex)
    if not tex then return end
    tex:SetHorizTile(false)
    tex:SetVertTile(false)
    if tex.SetFilterMode then
        tex:SetFilterMode("TRILINEAR")
    end
end

--------------------------------------------------------------------------------
-- Individual Combo Point Initialization & Animation Structure
--------------------------------------------------------------------------------
local function initComboPoint(parent, frameID)
    if parent[frameID] then return parent[frameID] end

    local pointFrame = CreateFrame("Frame", nil, parent)
    pointFrame.on = false
    pointFrame:SetSize(20, 21)
    pointFrame:SetParentKey(frameID)

    -- Inactive Background Socket
    local pointBg = pointFrame:CreateTexture(nil, "BACKGROUND")
    pointBg:SetAtlas("ComboPoints-PointBg", false)
    pointBg:SetSize(20, 21)
    pointBg:SetPoint("CENTER")
    CrispTexture(pointBg)
    pointFrame.PointOff = pointBg

    -- Active Combo Point Center
    local actualPoint = pointFrame:CreateTexture(nil, "ARTWORK")
    actualPoint:SetAtlas("ComboPoints-ComboPoint", false)
    actualPoint:SetBlendMode("BLEND")
    actualPoint:SetAlpha(0)
    actualPoint:SetSize(20, 21)
    actualPoint:SetPoint("CENTER")
    CrispTexture(actualPoint)
    pointFrame.Point = actualPoint

    -- Circle Burst FX Texture
    local fxCircle = pointFrame:CreateTexture(nil, "ARTWORK")
    fxCircle:SetAtlas("ComboPoints-FX-Circle", true)
    fxCircle:SetBlendMode("BLEND")
    fxCircle:SetAlpha(0)
    fxCircle:SetPoint("CENTER")
    CrispTexture(fxCircle)
    pointFrame.CircleBurst = fxCircle

    -- Star Burst FX Texture
    local fxStar = pointFrame:CreateTexture(nil, "OVERLAY")
    fxStar:SetAtlas("ComboPoints-FX-Star", true)
    fxStar:SetBlendMode("ADD")
    fxStar:SetAlpha(0)
    fxStar:SetPoint("CENTER")
    CrispTexture(fxStar)
    pointFrame.Star = fxStar

    ----------------------------------------------------------------------------
    -- Animations Configuration
    ----------------------------------------------------------------------------
    local pointAnim = pointFrame:CreateAnimationGroup()
    pointAnim:SetToFinalAlpha(true)
    local pointAlpha = pointAnim:CreateAnimation("Alpha")
    pointAlpha:SetDuration(0.25)
    pointAlpha:SetOrder(1)
    pointAlpha:SetFromAlpha(0)
    pointAlpha:SetToAlpha(1)
    pointAlpha:SetChildKey("Point")

    local pointScale = pointAnim:CreateAnimation("Scale")
    pointScale:SetSmoothing("OUT")
    pointScale:SetDuration(0.25)
    pointScale:SetOrder(1)
    pointScale:SetScaleFrom(0.8, 0.8)
    pointScale:SetScaleTo(1, 1)
    pointScale:SetChildKey("Point")
    pointFrame.PointAnim = pointAnim

    -- Entry Burst Animation
    local animIn = pointFrame:CreateAnimationGroup()
    animIn:SetToFinalAlpha(true)

    local starScale = animIn:CreateAnimation("Scale")
    starScale:SetSmoothing("OUT")
    starScale:SetDuration(0.5)
    starScale:SetOrder(1)
    starScale:SetScaleFrom(0.25, 0.25)
    starScale:SetScaleTo(0.9, 0.9)
    starScale:SetChildKey("Star")

    local starRot = animIn:CreateAnimation("Rotation")
    starRot:SetSmoothing("OUT")
    starRot:SetDuration(0.8)
    starRot:SetOrder(1)
    starRot:SetDegrees(-60)
    starRot:SetChildKey("Star")

    local starAlpha = animIn:CreateAnimation("Alpha")
    starAlpha:SetSmoothing("IN")
    starAlpha:SetDuration(0.4)
    starAlpha:SetOrder(1)
    starAlpha:SetFromAlpha(0.75)
    starAlpha:SetToAlpha(0)
    starAlpha:SetStartDelay(0.5)
    starAlpha:SetChildKey("Star")

    local circleAlpha = animIn:CreateAnimation("Alpha")
    circleAlpha:SetDuration(0.1)
    circleAlpha:SetOrder(1)
    circleAlpha:SetFromAlpha(0)
    circleAlpha:SetToAlpha(1)
    circleAlpha:SetChildKey("CircleBurst")

    local circleScale = animIn:CreateAnimation("Scale")
    circleScale:SetSmoothing("OUT")
    circleScale:SetDuration(0.25)
    circleScale:SetOrder(1)
    circleScale:SetScaleFrom(1.25, 1.25)
    circleScale:SetScaleTo(0.75, 0.75)
    circleScale:SetChildKey("CircleBurst")

    local circleAlpha2 = animIn:CreateAnimation("Alpha")
    circleAlpha2:SetSmoothing("IN")
    circleAlpha2:SetDuration(0.25)
    circleAlpha2:SetOrder(1)
    circleAlpha2:SetFromAlpha(1)
    circleAlpha2:SetToAlpha(0)
    circleAlpha2:SetStartDelay(0.25)
    circleAlpha2:SetChildKey("CircleBurst")
    pointFrame.AnimIn = animIn

    -- Exit Burst Animation
    local animOut = pointFrame:CreateAnimationGroup()
    animOut:SetToFinalAlpha(true)

    local outCircleAlpha = animOut:CreateAnimation("Alpha")
    outCircleAlpha:SetDuration(0.1)
    outCircleAlpha:SetOrder(1)
    outCircleAlpha:SetFromAlpha(0)
    outCircleAlpha:SetToAlpha(1)
    outCircleAlpha:SetChildKey("CircleBurst")

    local outCircleScale = animOut:CreateAnimation("Scale")
    outCircleScale:SetSmoothing("OUT")
    outCircleScale:SetDuration(0.4)
    outCircleScale:SetOrder(1)
    outCircleScale:SetScaleFrom(0.8, 0.8)
    outCircleScale:SetScaleTo(0.6, 0.6)
    outCircleScale:SetChildKey("CircleBurst")

    local outCircleAlpha2 = animOut:CreateAnimation("Alpha")
    outCircleAlpha2:SetSmoothing("IN")
    outCircleAlpha2:SetDuration(0.25)
    outCircleAlpha2:SetOrder(1)
    outCircleAlpha2:SetFromAlpha(1)
    outCircleAlpha2:SetToAlpha(0)
    outCircleAlpha2:SetStartDelay(0.25)
    outCircleAlpha2:SetChildKey("CircleBurst")
    pointFrame.AnimOut = animOut

    return pointFrame
end

-- Layout Spacing
local layoutByMaxPoints = {
    [5] = { width = 20, height = 21, xOffs = 1 },
    [6] = { width = 18, height = 19, xOffs = -1 },
}

local function updateComboPointLayout(maxPoints, currentPoint, prevPoint)
    local layout = layoutByMaxPoints[maxPoints] or layoutByMaxPoints[5]
    currentPoint:SetSize(layout.width, layout.height)
    currentPoint.PointOff:SetSize(layout.width, layout.height)
    currentPoint.Point:SetSize(layout.width, layout.height)

    if prevPoint then
        currentPoint:SetPoint("LEFT", prevPoint, "RIGHT", layout.xOffs, 0)
    end
end

--------------------------------------------------------------------------------
-- Main Combo Point Bar Construction & Logic
--------------------------------------------------------------------------------
local ComboPointBarMixin = {}

function ComboPointBarMixin:OnLoad()
    self:SetSize(126, 18)
    self:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
    self:SetMovable(true)
    self:EnableMouse(true)
    self:RegisterForDrag("LeftButton")

    self:SetScript("OnDragStart", function(s) if IsAltKeyDown() then s:StartMoving() end end)
    self:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)

    self.BackGround = self:CreateTexture(nil, "OVERLAY")
    self.BackGround:SetAtlas("ComboPoints-AllPointsBG", true)
    self.BackGround:SetPoint("TOPLEFT")
    CrispTexture(self.BackGround)

    self.maxPlayerComboPoints = 5
    self:InitilizeComboPoints()
    self:LayoutComboPoints()

    self:SetScript("OnEvent", self.OnEvent)
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")

    if PLAYER_CLASS == "DRUID" then
        self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    end

    -- Independent worker frame parented to UIParent so OnUpdate never halts when main bar hides
    local pollFrame = CreateFrame("Frame", nil, UIParent)
    local interval = 0
    pollFrame:SetScript("OnUpdate", function(_, elapsed)
        interval = interval + elapsed
        if interval > 0.05 then
            self:UpdateComboPoints()
            interval = 0
        end
    end)
end

function ComboPointBarMixin:InitilizeComboPoints()
    self.ComboPoints = {}
    for i = 1, MAX_POINT_FRAMES do
        local frameKey = "ComboPoint" .. i
        local pointFrame = initComboPoint(self, frameKey)
        if i == 1 then
            pointFrame:SetPoint("TOPLEFT", 11, -2)
        else
            pointFrame:SetPoint("LEFT", self.ComboPoints[i - 1], "RIGHT", 1, 0)
        end
        pointFrame:SetShown(false)
        self.ComboPoints[i] = pointFrame
    end
end

function ComboPointBarMixin:LayoutComboPoints()
    for i = 1, self.maxPlayerComboPoints do
        updateComboPointLayout(
            self.maxPlayerComboPoints,
            self.ComboPoints[i],
            self.ComboPoints[i - 1]
        )
        self.ComboPoints[i]:SetShown(true)
    end
end

function ComboPointBarMixin:UpdateComboPoints(forcePoints)
    local currentPoints = forcePoints

    if not currentPoints then
        local targetPoints = GetComboPoints("player", "target") or 0
        local powerPoints = UnitPower("player", 4) or 0
        currentPoints = math.max(targetPoints, powerPoints)
    end

    local maxPoints = self.maxPlayerComboPoints or 5
    local hasTarget = UnitExists("target") and not UnitIsDead("target")

    local shouldShow = (currentPoints > 0 or self.isTesting) and (hasTarget or self.isTesting)

    if not shouldShow then
        if self:IsShown() then
            self:Hide()
            for i = 1, MAX_POINT_FRAMES do
                local point = self.ComboPoints[i]
                if point then
                    point.on = false
                    if point.AnimIn then point.AnimIn:Stop() end
                    if point.AnimOut then point.AnimOut:Stop() end
                    if point.Point then point.Point:SetAlpha(0) end
                end
            end
        end
        return
    end

    if not self:IsShown() then
        self:Show()
    end

    -- Process active points
    for i = 1, math.min(currentPoints, maxPoints) do
        local point = self.ComboPoints[i]
        if point then
            if not point.on then
                point.on = true
                if point.AnimOut then point.AnimOut:Stop() end
                point.AnimIn:Play()
                if point.PointAnim then point.PointAnim:Play() end
            end
            if point.Point then point.Point:SetAlpha(1) end
        end
    end

    -- Clear unused points
    for i = currentPoints + 1, maxPoints do
        local point = self.ComboPoints[i]
        if point then
            if point.on then
                point.on = false
                if point.AnimIn then point.AnimIn:Stop() end
                point.AnimOut:Play()
            else
                if point.Point then point.Point:SetAlpha(0) end
            end
        end
    end
end

function ComboPointBarMixin:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" then
        self:UpdateComboPoints()
    elseif event == "UNIT_DISPLAYPOWER" then
        local pType = UnitPowerType("player")
        local useComboPoints = (pType == 3)
        if not useComboPoints then
            self:Hide()
        end
    end
end

--------------------------------------------------------------------------------
-- Addon Initialization & Slash Commands
--------------------------------------------------------------------------------
addonFrame:RegisterEvent("ADDON_LOADED")
addonFrame:SetScript("OnEvent", function(self, event, tocName)
    if tocName == ADDON_NAME then
        if PLAYER_CLASS ~= "ROGUE" and PLAYER_CLASS ~= "DRUID" then return end

        local Bar = CreateFrame("Frame", ADDON_NAME .. "Bar", UIParent)
        Bar = Mixin(Bar, ComboPointBarMixin)
        Bar:OnLoad()

        SLASH_SHADOWPOINTS1 = "/sp"
        SLASH_SHADOWPOINTS2 = "/shadowpoints"
        SlashCmdList["SHADOWPOINTS"] = function()
            if Bar.isTesting then
                Bar.isTesting = false
                Bar:UpdateComboPoints()
                DEFAULT_CHAT_FRAME:AddMessage("|cff9966ff[ShadowPoints]|r Test mode disabled.")
            else
                Bar.isTesting = true
                Bar:Show()
                Bar:UpdateComboPoints(5)
                DEFAULT_CHAT_FRAME:AddMessage("|cff9966ff[ShadowPoints]|r Test mode enabled. Hold ALT + Drag to move. Type /sp to close.")
            end
        end
    end
end)