# ElvUI Frame Spacer

A World of Warcraft addon that dynamically repositions ElvUI player and target unit frames to create space for your cooldown bar in the center, preventing overlap.


Built to solve this horrible UI problem <img width="995" height="187" alt="image" src="https://github.com/user-attachments/assets/b6ddcf0d-23b3-4aaf-aaf7-b84e87c78d2c" />

## Features

- **Dynamic Frame Positioning**: Automatically moves ElvUI player frame to the left and target frame to the right
- **Configurable Gap**: Set the center gap width to match your cooldown bar (Blizzard's built-in or WeakAuras)
- **Profile Support**: Settings are saved per ElvUI profile, so each character/spec can have different configurations
- **Graphical Config Panel**: Full GUI inside ElvUI options (`/ec` → Frame Spacer)
- **ElvUI Integration**: Properly integrates with ElvUI's plugin system

## Installation

1. Copy the `ElvUI_FrameSpacer` folder to your `World of Warcraft/_retail_/Interface/AddOns/` directory
2. Ensure ElvUI is installed and enabled
3. Restart WoW or `/reload`

## Configuration

### GUI (Recommended)

Open ElvUI config and navigate to Frame Spacer:
- Type `/efs` or `/ec` → Frame Spacer

### Slash Commands

| Command | Description |
|---------|-------------|
| `/efs` | Open configuration panel |
| `/efs toggle` | Enable/disable frame repositioning |
| `/efs gap <number>` | Set the center gap width (default: 430) |
| `/efs spacing <number>` | Set padding between frames and gap (default: 0) |
| `/efs voffset <number>` | Set vertical offset from screen center (default: -200) |
| `/efs status` | Display current settings |
| `/efs reset` | Reset all settings to defaults |

## Gap Width Reference

For Blizzard's built-in cooldown bar:

| Icons | Approximate Gap Width |
|-------|----------------------|
| 10    | ~360                 |
| 12    | ~430                 |
| 14    | ~500                 |
| 16    | ~580                 |

## Profile Support

Settings are stored in your ElvUI profile. This means:
- Each character can have different settings if using different profiles
- Copying an ElvUI profile also copies Frame Spacer settings
- Profile imports/exports include Frame Spacer configuration

## API for Other Addons

```lua
-- Get the module
local EFS = ElvUIFrameSpacer

-- Update the center gap width and reposition frames
EFS:SetGapWidth(newWidth)

-- Adjust spacing
EFS:SetFrameSpacing(newSpacing)

-- Adjust vertical position
EFS:SetVerticalOffset(newOffset)

-- Manually trigger repositioning
EFS:RepositionUnitFrames()
```

## Requirements

- World of Warcraft: The War Within (11.1.0+)
- ElvUI

## Troubleshooting

- **Frames don't move after installation**: Type `/reload`
- **Settings not saving**: ElvUI profiles are saved on logout - exit the game cleanly
- **Positions reset after profile change**: This is expected - each profile has its own settings
- Use `/efs status` to verify current settings

## Changelog

### v1.1.0
- Added GUI configuration panel in ElvUI options
- Added profile support via ElvUI's profile system
- Improved initialization for better reliability across characters
- Fixed API compatibility with modern WoW clients

### v1.0.0
- Initial release
