--[[
    ElvUI Frame Spacer
    Dynamically repositions ElvUI player and target frames to create space for your cooldown bar
    
    Features:
    - Profile support (per-character settings via ElvUI profiles)
    - GUI configuration panel in ElvUI options
]]

local E, L, V, P, G = unpack(ElvUI)
local EP = LibStub("LibElvUIPlugin-1.0")
local addon, ns = ...

-- Create the module
local EFS = E:NewModule("FrameSpacer", "AceHook-3.0", "AceEvent-3.0")

-- Addon info for ElvUI plugin system
local addonName = "ElvUI Frame Spacer"
local addonVersion = "1.1.0"

-- Initialization state
local initAttempts = 0
local MAX_INIT_ATTEMPTS = 10
local isInitialized = false

--------------------------------------------------------------------------------
-- Default Profile Settings (stored in ElvUI's profile system)
--------------------------------------------------------------------------------

-- These get inserted into ElvUI's P (profile) table
P.framespacer = {
    enabled = true,
    gapWidth = 430,             -- Width of the center gap (~12 icons from Blizzard cooldown bar)
    frameSpacing = 0,           -- No gap - frames sit snug against the center area
    verticalOffset = -200,      -- Vertical position from center
    playerFrameWidth = 270,     -- Expected width of player frame
    targetFrameWidth = 270,     -- Expected width of target frame
}

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

local function Print(msg)
    print("|cff00ff96ElvUI FrameSpacer:|r " .. msg)
end

--------------------------------------------------------------------------------
-- Frame Positioning Logic
--------------------------------------------------------------------------------

-- Calculate and apply positions for player and target frames
function EFS:RepositionUnitFrames()
    local db = E.db.framespacer
    if not db or not db.enabled then return end
    
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
    if not E or not E.db then return end
    
    local db = E.db.framespacer
    
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
-- Dynamic Width Adjustment (for API/slash commands)
--------------------------------------------------------------------------------

function EFS:SetGapWidth(width)
    E.db.framespacer.gapWidth = width
    self:RepositionUnitFrames()
end

function EFS:SetFrameSpacing(spacing)
    E.db.framespacer.frameSpacing = spacing
    self:RepositionUnitFrames()
end

function EFS:SetVerticalOffset(offset)
    E.db.framespacer.verticalOffset = offset
    self:RepositionUnitFrames()
end

--------------------------------------------------------------------------------
-- Configuration Panel (GUI)
--------------------------------------------------------------------------------

function EFS:GetOptions()
    local options = {
        order = 100,
        type = "group",
        name = "Frame Spacer",
        childGroups = "tab",
        args = {
            header = {
                order = 1,
                type = "header",
                name = "ElvUI Frame Spacer v" .. addonVersion,
            },
            description = {
                order = 2,
                type = "description",
                name = "Repositions ElvUI player and target frames to create space for your cooldown bar in the center.\n\n",
            },
            general = {
                order = 10,
                type = "group",
                name = "General",
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable",
                        desc = "Enable or disable frame repositioning",
                        get = function() return E.db.framespacer.enabled end,
                        set = function(_, value)
                            E.db.framespacer.enabled = value
                            if value then
                                EFS:RepositionUnitFrames()
                            else
                                Print("Disabled - use /reload to restore default positions")
                            end
                        end,
                        width = "full",
                    },
                    spacer1 = {
                        order = 2,
                        type = "description",
                        name = "\n",
                    },
                    gapWidth = {
                        order = 10,
                        type = "range",
                        name = "Center Gap Width",
                        desc = "Width of the center gap where your cooldown bar sits.\n\nReference:\n• 10 icons ≈ 360\n• 12 icons ≈ 430\n• 14 icons ≈ 500\n• 16 icons ≈ 580",
                        min = 100,
                        max = 1000,
                        step = 5,
                        get = function() return E.db.framespacer.gapWidth end,
                        set = function(_, value)
                            E.db.framespacer.gapWidth = value
                            EFS:RepositionUnitFrames()
                        end,
                        width = "full",
                    },
                    frameSpacing = {
                        order = 20,
                        type = "range",
                        name = "Frame Padding",
                        desc = "Additional padding between unit frames and the center gap. Set to 0 for frames to sit snug against the icons.",
                        min = 0,
                        max = 50,
                        step = 1,
                        get = function() return E.db.framespacer.frameSpacing end,
                        set = function(_, value)
                            E.db.framespacer.frameSpacing = value
                            EFS:RepositionUnitFrames()
                        end,
                        width = "full",
                    },
                    verticalOffset = {
                        order = 30,
                        type = "range",
                        name = "Vertical Offset",
                        desc = "Vertical position from the center of the screen. Negative values move frames down.",
                        min = -500,
                        max = 500,
                        step = 5,
                        get = function() return E.db.framespacer.verticalOffset end,
                        set = function(_, value)
                            E.db.framespacer.verticalOffset = value
                            EFS:RepositionUnitFrames()
                        end,
                        width = "full",
                    },
                },
            },
            frameWidths = {
                order = 20,
                type = "group",
                name = "Frame Widths",
                args = {
                    description = {
                        order = 1,
                        type = "description",
                        name = "Adjust these if your unit frames are a different size than the default ElvUI frames.\n\n",
                    },
                    playerFrameWidth = {
                        order = 10,
                        type = "range",
                        name = "Player Frame Width",
                        desc = "Expected width of your player unit frame",
                        min = 100,
                        max = 500,
                        step = 5,
                        get = function() return E.db.framespacer.playerFrameWidth end,
                        set = function(_, value)
                            E.db.framespacer.playerFrameWidth = value
                            EFS:RepositionUnitFrames()
                        end,
                        width = "full",
                    },
                    targetFrameWidth = {
                        order = 20,
                        type = "range",
                        name = "Target Frame Width",
                        desc = "Expected width of your target unit frame",
                        min = 100,
                        max = 500,
                        step = 5,
                        get = function() return E.db.framespacer.targetFrameWidth end,
                        set = function(_, value)
                            E.db.framespacer.targetFrameWidth = value
                            EFS:RepositionUnitFrames()
                        end,
                        width = "full",
                    },
                },
            },
            actions = {
                order = 30,
                type = "group",
                name = "Actions",
                args = {
                    resetDefaults = {
                        order = 1,
                        type = "execute",
                        name = "Reset to Defaults",
                        desc = "Reset all Frame Spacer settings to their default values",
                        func = function()
                            E.db.framespacer = E:CopyTable({}, P.framespacer)
                            EFS:RepositionUnitFrames()
                            Print("Settings reset to defaults")
                        end,
                        confirm = true,
                        confirmText = "Are you sure you want to reset Frame Spacer settings to defaults?",
                    },
                    applyNow = {
                        order = 2,
                        type = "execute",
                        name = "Apply Positions Now",
                        desc = "Manually reapply frame positions",
                        func = function()
                            EFS:RepositionUnitFrames()
                            Print("Positions applied")
                        end,
                    },
                },
            },
        },
    }
    
    return options
end

-- Insert our options into ElvUI's config
function EFS:InsertOptions()
    E.Options.args.framespacer = self:GetOptions()
end

--------------------------------------------------------------------------------
-- Hook into ElvUI's update system to maintain positions
--------------------------------------------------------------------------------

function EFS:HookElvUIUpdates()
    -- Hook the unit frame update functions to reapply our positions
    local UF = E:GetModule("UnitFrames", true)
    if UF then
        self:SecureHook(UF, "CreateAndUpdateUF", function(_, unit)
            if unit == "player" or unit == "target" then
                C_Timer.After(0.1, function()
                    EFS:RepositionUnitFrames()
                end)
            end
        end)
    end
end

--------------------------------------------------------------------------------
-- Module Initialization (ElvUI module system)
--------------------------------------------------------------------------------

function EFS:Initialize()
    -- Prevent duplicate initialization
    if isInitialized then return end
    
    -- Wait for ElvUI to fully initialize
    if E.initialized then
        isInitialized = true
        
        -- Register plugin with ElvUI
        EP:RegisterPlugin(addon, self.InsertOptions, self)
        
        -- Hook into ElvUI updates
        self:HookElvUIUpdates()
        
        -- Small delay to ensure unit frames are created
        C_Timer.After(1, function()
            self:RepositionUnitFrames()
        end)
        
        -- Listen for profile changes
        self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
            C_Timer.After(2, function()
                self:RepositionUnitFrames()
            end)
        end)
    else
        -- ElvUI not ready yet, try again shortly (with retry limit)
        initAttempts = initAttempts + 1
        if initAttempts < MAX_INIT_ATTEMPTS then
            C_Timer.After(1, function()
                self:Initialize()
            end)
        else
            Print("Warning: ElvUI initialization timed out. Try /reload")
        end
    end
end

-- Hook into ElvUI's profile system to reapply positions on profile change
hooksecurefunc(E, "UpdateDB", function()
    if isInitialized then
        C_Timer.After(0.5, function()
            EFS:RepositionUnitFrames()
        end)
    end
end)

--------------------------------------------------------------------------------
-- Slash Commands (kept for convenience)
--------------------------------------------------------------------------------

SLASH_ELVUIFS1 = "/efs"
SLASH_ELVUIFS2 = "/framespacer"

SlashCmdList["ELVUIFS"] = function(msg)
    local cmd, arg = strsplit(" ", msg, 2)
    cmd = cmd:lower()
    
    if cmd == "config" or cmd == "options" or cmd == "" then
        -- Open the ElvUI config to our section
        E:ToggleOptions()
        -- Navigate to our options (slight delay to ensure UI is loaded)
        C_Timer.After(0.1, function()
            if E.Libs.AceConfigDialog then
                E.Libs.AceConfigDialog:SelectGroup("ElvUI", "framespacer")
            end
        end)
        
    elseif cmd == "toggle" then
        E.db.framespacer.enabled = not E.db.framespacer.enabled
        if E.db.framespacer.enabled then
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
        E.db.framespacer = E:CopyTable({}, P.framespacer)
        EFS:RepositionUnitFrames()
        Print("Settings reset to defaults")
        
    elseif cmd == "status" then
        local db = E.db.framespacer
        Print("Current settings:")
        print("  Enabled: " .. tostring(db.enabled))
        print("  Gap Width: " .. db.gapWidth)
        print("  Frame Spacing: " .. db.frameSpacing)
        print("  Vertical Offset: " .. db.verticalOffset)
        print("  Player Frame Width: " .. db.playerFrameWidth)
        print("  Target Frame Width: " .. db.targetFrameWidth)
        
    else
        Print("Commands:")
        print("  /efs - Open configuration panel")
        print("  /efs toggle - Enable/disable frame repositioning")
        print("  /efs gap <num> - Set center gap width")
        print("  /efs spacing <num> - Set padding between frames and gap")
        print("  /efs voffset <num> - Set vertical offset from center")
        print("  /efs status - Show current settings")
        print("  /efs reset - Reset to default settings")
    end
end

-- Make addon globally accessible for other addons
_G.ElvUIFrameSpacer = EFS

-- Register with ElvUI's module system
E:RegisterModule(EFS:GetName())
