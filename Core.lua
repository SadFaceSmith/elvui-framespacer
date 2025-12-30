--[[
    ElvUI Frame Spacer
    Dynamically repositions ElvUI player and target frames to create space for your cooldown bar
]]

local addon, ns = ...
local E, L, V, P, G

-- Create main addon frame
local EFS = CreateFrame("Frame", "ElvUIFrameSpacer", UIParent)
EFS:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
EFS:RegisterEvent("ADDON_LOADED")
EFS:RegisterEvent("PLAYER_LOGIN")
EFS:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Default settings
local defaults = {
    enabled = true,
    gapWidth = 400,             -- Width of the center gap (for your cooldown bar)
    frameSpacing = 8,           -- Additional gap between unit frames and center area
    verticalOffset = -200,      -- Vertical position from center
    playerFrameWidth = 270,     -- Expected width of player frame
    targetFrameWidth = 270,     -- Expected width of target frame
}

-- Saved variables reference
local db

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

local function Print(msg)
    print("|cff00ff96ElvUI FrameSpacer:|r " .. msg)
end

local function GetElvUI()
    if not E then
        E = unpack(ElvUI)
    end
    return E
end

--------------------------------------------------------------------------------
-- Frame Positioning Logic
--------------------------------------------------------------------------------

-- Calculate and apply positions for player and target frames
function EFS:RepositionUnitFrames()
    if not db or not db.enabled then return end
    
    local E = GetElvUI()
    if not E or not E.private then return end
    
    -- Get ElvUI unit frames
    local playerFrame = _G["ElvUF_Player"]
    local targetFrame = _G["ElvUF_Target"]
    
    if not playerFrame or not targetFrame then
        -- Frames not yet created, try again later
        C_Timer.After(0.5, function() self:RepositionUnitFrames() end)
        return
    end
    
    -- The center gap (where your cooldown bar sits)
    local gapHalfWidth = db.gapWidth / 2
    
    -- Calculate frame positions
    -- Player frame goes to the LEFT of the gap
    local playerX = -(gapHalfWidth + db.frameSpacing + (db.playerFrameWidth / 2))
    
    -- Target frame goes to the RIGHT of the gap
    local targetX = gapHalfWidth + db.frameSpacing + (db.targetFrameWidth / 2)
    
    -- Apply positions
    self:SetFramePosition(playerFrame, "CENTER", UIParent, "CENTER", playerX, db.verticalOffset)
    self:SetFramePosition(targetFrame, "CENTER", UIParent, "CENTER", targetX, db.verticalOffset)
    
    -- Store the mover positions in ElvUI's system
    self:UpdateElvUIMovers(playerX, targetX)
end

-- Set a frame's position with proper clearing
function EFS:SetFramePosition(frame, point, relativeTo, relativePoint, x, y)
    if not frame then return end
    
    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, x, y)
end

-- Update ElvUI's mover system to remember our positions
function EFS:UpdateElvUIMovers(playerX, targetX)
    local E = GetElvUI()
    if not E or not E.db then return end
    
    -- Update the movers if they exist
    local playerMover = _G["ElvUF_PlayerMover"]
    local targetMover = _G["ElvUF_TargetMover"]
    
    if playerMover then
        playerMover:ClearAllPoints()
        playerMover:SetPoint("CENTER", UIParent, "CENTER", playerX, db.verticalOffset)
    end
    
    if targetMover then
        targetMover:ClearAllPoints()
        targetMover:SetPoint("CENTER", UIParent, "CENTER", targetX, db.verticalOffset)
    end
end

--------------------------------------------------------------------------------
-- Dynamic Width Adjustment
--------------------------------------------------------------------------------

-- Call this when the center gap width changes
function EFS:SetGapWidth(width)
    if db then
        db.gapWidth = width
        self:RepositionUnitFrames()
    end
end

-- Adjust spacing dynamically
function EFS:SetFrameSpacing(spacing)
    if db then
        db.frameSpacing = spacing
        self:RepositionUnitFrames()
    end
end

-- Adjust vertical offset
function EFS:SetVerticalOffset(offset)
    if db then
        db.verticalOffset = offset
        self:RepositionUnitFrames()
    end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

function EFS:InitializeSettings()
    -- Load or create saved variables
    if not ElvUI_FrameSpacerDB then
        ElvUI_FrameSpacerDB = CopyTable(defaults)
    end
    
    -- Merge any missing defaults
    for key, value in pairs(defaults) do
        if ElvUI_FrameSpacerDB[key] == nil then
            ElvUI_FrameSpacerDB[key] = value
        end
    end
    
    db = ElvUI_FrameSpacerDB
end

function EFS:Initialize()
    self:InitializeSettings()
    
    -- Wait for ElvUI to fully initialize
    local E = GetElvUI()
    if E and E.initialized then
        -- Small delay to ensure unit frames are created
        C_Timer.After(1, function()
            self:RepositionUnitFrames()
            Print("Unit frames repositioned")
        end)
    end
end

--------------------------------------------------------------------------------
-- Hook into ElvUI's update system to maintain positions
--------------------------------------------------------------------------------

function EFS:HookElvUIUpdates()
    local E = GetElvUI()
    if not E then return end
    
    -- Hook the unit frame update functions to reapply our positions
    local UF = E:GetModule("UnitFrames", true)
    if UF then
        hooksecurefunc(UF, "CreateAndUpdateUF", function(self, unit)
            if unit == "player" or unit == "target" then
                C_Timer.After(0.1, function()
                    EFS:RepositionUnitFrames()
                end)
            end
        end)
    end
end

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

function EFS:ADDON_LOADED(addonName)
    if addonName == addon then
        self:InitializeSettings()
    end
end

function EFS:PLAYER_LOGIN()
    -- Check if ElvUI is loaded
    if not IsAddOnLoaded("ElvUI") then
        Print("ElvUI is required for this addon to function")
        return
    end
    
    self:HookElvUIUpdates()
end

function EFS:PLAYER_ENTERING_WORLD()
    -- Reposition after entering world (handles reloads, zone changes)
    C_Timer.After(2, function()
        self:Initialize()
    end)
end

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------

SLASH_ELVUIFS1 = "/efs"
SLASH_ELVUIFS2 = "/framespacer"

SlashCmdList["ELVUIFS"] = function(msg)
    local cmd, arg = strsplit(" ", msg, 2)
    cmd = cmd:lower()
    
    if cmd == "toggle" then
        db.enabled = not db.enabled
        if db.enabled then
            EFS:RepositionUnitFrames()
            Print("Frame repositioning ENABLED")
        else
            Print("Frame repositioning DISABLED - use /reload to restore default positions")
        end
        
    elseif cmd == "gap" and arg then
        local width = tonumber(arg)
        if width and width > 0 then
            EFS:SetGapWidth(width)
            Print("Gap width set to " .. width)
        else
            Print("Usage: /efs gap <number>")
        end
        
    elseif cmd == "spacing" and arg then
        local spacing = tonumber(arg)
        if spacing then
            EFS:SetFrameSpacing(spacing)
            Print("Frame spacing set to " .. spacing)
        else
            Print("Usage: /efs spacing <number>")
        end
        
    elseif cmd == "voffset" and arg then
        local offset = tonumber(arg)
        if offset then
            EFS:SetVerticalOffset(offset)
            Print("Vertical offset set to " .. offset)
        else
            Print("Usage: /efs voffset <number>")
        end
        
    elseif cmd == "reset" then
        ElvUI_FrameSpacerDB = CopyTable(defaults)
        db = ElvUI_FrameSpacerDB
        EFS:RepositionUnitFrames()
        Print("Settings reset to defaults")
        
    elseif cmd == "status" then
        Print("Current settings:")
        print("  Enabled: " .. tostring(db.enabled))
        print("  Gap Width: " .. db.gapWidth)
        print("  Frame Spacing: " .. db.frameSpacing)
        print("  Vertical Offset: " .. db.verticalOffset)
        
    else
        Print("Commands:")
        print("  /efs toggle - Enable/disable frame repositioning")
        print("  /efs gap <num> - Set center gap width (for your cooldown bar)")
        print("  /efs spacing <num> - Set padding between frames and gap")
        print("  /efs voffset <num> - Set vertical offset from center")
        print("  /efs status - Show current settings")
        print("  /efs reset - Reset to default settings")
    end
end

-- Make addon globally accessible for other addons
_G.ElvUIFrameSpacer = EFS
