--[[
    ElvUI Frame Spacer
    Dynamically repositions ElvUI player and target frames to create space for your cooldown bar
    
    Features:
    - Profile support (per-character settings via ElvUI profiles)
    - GUI configuration panel in ElvUI options
]]

local E, L, V, P, G = unpack(ElvUI)
local EP = LibStub("LibElvUIPlugin-1.0", true)
local addonName, ns = ...

-- Create the module
local EFS = E:NewModule("FrameSpacer", "AceHook-3.0", "AceEvent-3.0")
local UF = E:GetModule("UnitFrames")

-- Localization stub
local L = E.Libs.ACL:GetLocale("ElvUI", E.global.general.locale)

-- Addon version
local addonVersion = "1.1.0"

--------------------------------------------------------------------------------
-- Default Profile Settings (stored in ElvUI's profile system)
--------------------------------------------------------------------------------

P.framespacer = {
    enabled = true,
    gapWidth = 430,
    frameSpacing = 0,
    verticalOffset = -200,
    playerFrameWidth = 270,
    targetFrameWidth = 270,
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

function EFS:RepositionUnitFrames()
    if not E.db.framespacer or not E.db.framespacer.enabled then return end
    if not E.private then return end
    
    local db = E.db.framespacer
    
    local playerFrame = _G["ElvUF_Player"]
    local targetFrame = _G["ElvUF_Target"]
    
    if not playerFrame or not targetFrame then
        C_Timer.After(0.5, function() self:RepositionUnitFrames() end)
        return
    end
    
    local gapHalfWidth = db.gapWidth / 2
    local playerX = -(gapHalfWidth + db.frameSpacing + (db.playerFrameWidth / 2))
    local targetX = gapHalfWidth + db.frameSpacing + (db.targetFrameWidth / 2)
    
    playerFrame:ClearAllPoints()
    playerFrame:SetPoint("CENTER", UIParent, "CENTER", playerX, db.verticalOffset)
    
    targetFrame:ClearAllPoints()
    targetFrame:SetPoint("CENTER", UIParent, "CENTER", targetX, db.verticalOffset)
    
    -- Update movers
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
-- Configuration Options
--------------------------------------------------------------------------------

local function GetOptions()
    E.Options.args.framespacer = {
        order = 100,
        type = "group",
        name = "|cff00ff96Frame Spacer|r",
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
                fontSize = "medium",
            },
            general = {
                order = 10,
                type = "group",
                name = "General",
                guiInline = true,
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable Frame Spacer",
                        desc = "Enable or disable frame repositioning",
                        get = function() return E.db.framespacer.enabled end,
                        set = function(_, value)
                            E.db.framespacer.enabled = value
                            if value then
                                EFS:RepositionUnitFrames()
                                Print("Enabled")
                            else
                                Print("Disabled - use /reload to restore default positions")
                            end
                        end,
                        width = "full",
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
                        disabled = function() return not E.db.framespacer.enabled end,
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
                        disabled = function() return not E.db.framespacer.enabled end,
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
                        disabled = function() return not E.db.framespacer.enabled end,
                    },
                },
            },
            frameWidths = {
                order = 20,
                type = "group",
                name = "Frame Widths",
                guiInline = true,
                args = {
                    description = {
                        order = 1,
                        type = "description",
                        name = "Adjust these if your unit frames are a different size than the default.\n",
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
                        disabled = function() return not E.db.framespacer.enabled end,
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
                        disabled = function() return not E.db.framespacer.enabled end,
                    },
                },
            },
            actions = {
                order = 30,
                type = "group",
                name = "Actions",
                guiInline = true,
                args = {
                    applyNow = {
                        order = 1,
                        type = "execute",
                        name = "Apply Positions Now",
                        desc = "Manually reapply frame positions",
                        func = function()
                            EFS:RepositionUnitFrames()
                            Print("Positions applied")
                        end,
                    },
                    resetDefaults = {
                        order = 2,
                        type = "execute",
                        name = "Reset to Defaults",
                        desc = "Reset all Frame Spacer settings to their default values",
                        func = function()
                            E.db.framespacer = E:CopyTable({}, P.framespacer)
                            EFS:RepositionUnitFrames()
                            Print("Settings reset to defaults")
                        end,
                        confirm = true,
                        confirmText = "Reset Frame Spacer settings to defaults?",
                    },
                },
            },
        },
    }
end

--------------------------------------------------------------------------------
-- Module Initialization
--------------------------------------------------------------------------------

function EFS:Initialize()
    -- Register plugin with ElvUI (shows in plugin list)
    if EP then
        EP:RegisterPlugin(addonName, GetOptions)
    end
    
    -- Hook UnitFrames updates to maintain positions
    if UF then
        self:SecureHook(UF, "CreateAndUpdateUF", function(_, unit)
            if unit == "player" or unit == "target" then
                C_Timer.After(0.1, function()
                    self:RepositionUnitFrames()
                end)
            end
        end)
    end
    
    -- Hook profile changes
    hooksecurefunc(E, "UpdateDB", function()
        C_Timer.After(0.5, function()
            EFS:RepositionUnitFrames()
        end)
    end)
    
    -- Initial positioning
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        C_Timer.After(2, function()
            self:RepositionUnitFrames()
        end)
    end)
    
    -- Also run on initialize
    C_Timer.After(1, function()
        self:RepositionUnitFrames()
    end)
end

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------

SLASH_ELVUIFS1 = "/efs"
SLASH_ELVUIFS2 = "/framespacer"

SlashCmdList["ELVUIFS"] = function(msg)
    local cmd, arg = strsplit(" ", msg, 2)
    cmd = (cmd or ""):lower()
    
    if cmd == "" or cmd == "config" or cmd == "options" then
        E:ToggleOptions()
        C_Timer.After(0.2, function()
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
            Print("Frame repositioning DISABLED - /reload to restore defaults")
        end
        
    elseif cmd == "gap" and arg then
        local width = tonumber(arg)
        if width and width > 0 then
            E.db.framespacer.gapWidth = width
            EFS:RepositionUnitFrames()
            Print("Gap width set to " .. width)
        else
            Print("Usage: /efs gap <number>")
        end
        
    elseif cmd == "spacing" and arg then
        local spacing = tonumber(arg)
        if spacing then
            E.db.framespacer.frameSpacing = spacing
            EFS:RepositionUnitFrames()
            Print("Frame spacing set to " .. spacing)
        else
            Print("Usage: /efs spacing <number>")
        end
        
    elseif cmd == "voffset" and arg then
        local offset = tonumber(arg)
        if offset then
            E.db.framespacer.verticalOffset = offset
            EFS:RepositionUnitFrames()
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
        
    else
        Print("Commands:")
        print("  /efs - Open configuration panel")
        print("  /efs toggle - Enable/disable")
        print("  /efs gap <num> - Set center gap width")
        print("  /efs spacing <num> - Set frame padding")
        print("  /efs voffset <num> - Set vertical offset")
        print("  /efs status - Show current settings")
        print("  /efs reset - Reset to defaults")
    end
end

-- Global reference for other addons
_G.ElvUIFrameSpacer = EFS

-- Register module with ElvUI
E:RegisterModule(EFS:GetName())
