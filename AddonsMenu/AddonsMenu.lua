--------------------------------------------------
-- AddonsMenu - WoW Vanilla 1.12.1 / OctoWoW
-- Interface: 11200
-- Retail-style AddOns manager
--------------------------------------------------

local addonFrame
local addonRows = {}
local tooltip = nil

-- Configuration
local ROW_HEIGHT = 28
local MAX_ROWS = 15
local ROW_WIDTH = 420
local SCROLL_SPEED = 3

local function CreateTooltip()
    if tooltip then
        return tooltip
    end

    tooltip = CreateFrame("Frame", "AddonTooltip", UIParent)
    tooltip:SetWidth(250)
    tooltip:SetHeight(80)
    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:Hide()

    -- Backdrop
    tooltip:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    tooltip:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    tooltip:SetBackdropBorderColor(1, 1, 0, 1)

    -- Text (without SetWordWrap for vanilla compatibility)
    local tooltipText = tooltip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tooltipText:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 8, -8)
    tooltipText:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -8, 8)
    tooltip.text = tooltipText

    return tooltip
end

local function ShowAddonTooltip(row, notes)
    local tt = CreateTooltip()
    if tt and tt.text then
        tt.text:SetText(notes or "No description available")
        tt:SetPoint("TOPLEFT", row, "TOPRIGHT", 10, 0)
        tt:Show()
    end
end

local function HideAddonTooltip()
    if tooltip then
        tooltip:Hide()
    end
end

local function CreateAddonManager()
    if addonFrame then
        return
    end

    -- Main frame
    addonFrame = CreateFrame("Frame", "CustomAddonList", UIParent)
    addonFrame:SetWidth(520)
    addonFrame:SetHeight(560)
    addonFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    addonFrame:SetFrameStrata("DIALOG")
    addonFrame:EnableMouse(true)
    addonFrame:SetMovable(true)
    addonFrame:Hide()

    -- Backdrop
    addonFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 11, top = 12, bottom = 11 }
    })
    addonFrame:SetBackdropColor(1, 1, 1, 1)
    addonFrame:SetBackdropBorderColor(1, 1, 1, 1)

    -- Title
    local title = addonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", addonFrame, "TOP", 0, -20)
    title:SetText("AddOns")

    -- Dragging
    addonFrame:RegisterForDrag("LeftButton")
    addonFrame:SetScript("OnMouseDown", function(self)
        self:StartMoving()
    end)
    addonFrame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
    end)

    -- Scroll frame
    local scroll = CreateFrame("ScrollFrame", "CustomAddonScroll", addonFrame, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", addonFrame, "TOPLEFT", 28, -62)
    scroll:SetPoint("BOTTOMRIGHT", addonFrame, "BOTTOMRIGHT", -42, 72)

    -- Create addon rows
    local function CreateRow(index)
        local row = CreateFrame("Button", nil, addonFrame)
        row:SetWidth(ROW_WIDTH)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", addonFrame, "TOPLEFT", 28, -62 - ((index - 1) * ROW_HEIGHT))
        row:EnableMouse(true)

        -- Highlight
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetBlendMode("ADD")
        highlight:SetAllPoints(row)

        -- Background for better visibility
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(1, 1, 1, 0.05)
        bg:SetAllPoints(row)
        row.bg = bg

        -- Checkbox
        local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        check:SetWidth(24)
        check:SetHeight(24)
        check:SetPoint("LEFT", row, "LEFT", 0, 0)

        -- Addon name
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", check, "RIGHT", 5, 0)
        text:SetWidth(370)
        text:SetJustifyH("LEFT")

        row.check = check
        row.text = text

        -- Checkbox toggle
        check:SetScript("OnClick", function(self)
            if not row.addonIndex then return end
            
            if check:GetChecked() then
                EnableAddOn(row.addonIndex)
            else
                DisableAddOn(row.addonIndex)
            end
        end)

        -- Row toggle
        row:SetScript("OnClick", function(self)
            if not row.addonIndex then return end
            
            local isChecked = check:GetChecked()
            check:SetChecked(not isChecked)
            
            if isChecked then
                DisableAddOn(row.addonIndex)
            else
                EnableAddOn(row.addonIndex)
            end
        end)

        -- Hover effect with tooltip
        row:SetScript("OnEnter", function(self)
            if row.addonIndex then
                row.bg:SetTexture(1, 1, 1, 0.1)
                local name, title, notes, enabled = GetAddOnInfo(row.addonIndex)
                if notes and notes ~= "" then
                    ShowAddonTooltip(row, notes)
                end
            end
        end)

        row:SetScript("OnLeave", function(self)
            row.bg:SetTexture(1, 1, 1, 0.05)
            HideAddonTooltip()
        end)

        return row
    end

    for i = 1, MAX_ROWS do
        addonRows[i] = CreateRow(i)
    end

    -- Update rows
    local function UpdateRows()
        local numAddons = GetNumAddOns()
        local offset = FauxScrollFrame_GetOffset(scroll)

        FauxScrollFrame_Update(scroll, numAddons, MAX_ROWS, ROW_HEIGHT)

        for i = 1, MAX_ROWS do
            local row = addonRows[i]
            local index = i + offset

            if index <= numAddons then
                local name, title, notes, enabled = GetAddOnInfo(index)
                row.addonIndex = index
                row.addonNotes = notes

                -- Display title/name with fallback
                if title and title ~= "" then
                    row.text:SetText(title)
                elseif name and name ~= "" then
                    row.text:SetText(name)
                else
                    row.text:SetText("Unknown AddOn")
                end

                row.check:SetChecked(enabled == 1)
                row:Show()
            else
                row.addonIndex = nil
                row.addonNotes = nil
                row:Hide()
            end
        end
    end

    addonFrame.UpdateRows = UpdateRows

    -- Scroll handling
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, UpdateRows)
    end)

    -- Mousewheel scrolling
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local newValue = scroll:GetVerticalScroll() - (delta * ROW_HEIGHT * SCROLL_SPEED)
        scroll:SetVerticalScroll(math.max(0, math.min(newValue, scroll:GetVerticalScrollRange())))
    end)

    -- Enable All button
    local enableAll = CreateFrame("Button", nil, addonFrame, "UIPanelButtonTemplate")
    enableAll:SetWidth(100)
    enableAll:SetHeight(24)
    enableAll:SetPoint("BOTTOMLEFT", addonFrame, "BOTTOMLEFT", 28, 22)
    enableAll:SetText("Enable All")
    enableAll:SetScript("OnClick", function()
        local numAddons = GetNumAddOns()
        for i = 1, numAddons do
            EnableAddOn(i)
        end
        UpdateRows()
    end)

    -- Disable All button
    local disableAll = CreateFrame("Button", nil, addonFrame, "UIPanelButtonTemplate")
    disableAll:SetWidth(100)
    disableAll:SetHeight(24)
    disableAll:SetPoint("LEFT", enableAll, "RIGHT", 12, 0)
    disableAll:SetText("Disable All")
    disableAll:SetScript("OnClick", function()
        local numAddons = GetNumAddOns()
        for i = 1, numAddons do
            DisableAddOn(i)
        end
        UpdateRows()
    end)

    -- Close button
    local close = CreateFrame("Button", nil, addonFrame, "UIPanelButtonTemplate")
    close:SetWidth(80)
    close:SetHeight(24)
    close:SetPoint("LEFT", disableAll, "RIGHT", 12, 0)
    close:SetText("Close")
    close:SetScript("OnClick", function(self)
        HideAddonTooltip()
        addonFrame:Hide()
    end)

    -- Reload UI button
    local reload = CreateFrame("Button", nil, addonFrame, "UIPanelButtonTemplate")
    reload:SetWidth(100)
    reload:SetHeight(24)
    reload:SetPoint("LEFT", close, "RIGHT", 12, 0)
    reload:SetText("Reload UI")
    reload:SetScript("OnClick", function()
        ReloadUI()
    end)

    -- Allow ESC to close window
    tinsert(UISpecialFrames, "CustomAddonList")
end

local function OpenAddonManager()
    CreateAddonManager()

    if addonFrame and addonFrame.UpdateRows then
        addonFrame.UpdateRows()
    end

    if addonFrame then
        addonFrame:Show()
    end
end

-- Add AddOns button to Game Menu
local button = CreateFrame("Button", "GameMenuButtonAddOns", GameMenuFrame, "GameMenuButtonTemplate")
button:SetText("AddOns")
button:SetPoint("TOP", GameMenuButtonMacros, "BOTTOM", 0, -1)

-- Move Logout button down
GameMenuButtonLogout:SetPoint("TOP", button, "BOTTOM", 0, -1)

-- Increase menu height
GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 25)

-- Open manager on click
button:SetScript("OnClick", function()
    HideUIPanel(GameMenuFrame)
    OpenAddonManager()
end)