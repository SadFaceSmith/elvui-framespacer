# ElvUI Frame Spacer

A World of Warcraft addon that dynamically repositions ElvUI player and target unit frames to create space for your cooldown bar in the center, preventing overlap.


Built to solve this horrible UI problem <img width="995" height="187" alt="image" src="https://github.com/user-attachments/assets/b6ddcf0d-23b3-4aaf-aaf7-b84e87c78d2c" />

## Features

- **Dynamic Frame Positioning**: Automatically moves ElvUI player frame to the left and target frame to the right
- **Configurable Gap**: Set the center gap width to match your cooldown bar
- **Adjustable Spacing**: Fine-tune the padding between unit frames and the center area
- **Persistent Settings**: Your configuration is saved between sessions
- **ElvUI Integration**: Hooks into ElvUI's system to maintain positions after updates

## Installation

1. Copy the `ElvUI_FrameSpacer` folder to your `World of Warcraft/_retail_/Interface/AddOns/` directory
2. Ensure ElvUI is installed and enabled
3. Restart WoW or `/reload`

## Commands

| Command | Description |
|---------|-------------|
| `/efs` | Show help and all available commands |
| `/efs toggle` | Enable/disable frame repositioning |
| `/efs gap <number>` | Set the center gap width (default: 400) |
| `/efs spacing <number>` | Set padding between frames and gap (default: 8) |
| `/efs voffset <number>` | Set vertical offset from screen center (default: -200) |
| `/efs status` | Display current settings |
| `/efs reset` | Reset all settings to defaults |

## Configuration Examples

```
/efs gap 500         -- Wider gap pushes frames further apart
/efs spacing 12      -- Add more padding between frames and center
/efs voffset -180    -- Move everything up slightly
```

## API for Other Addons

If you have another addon that needs to adjust the spacing dynamically:

```lua
-- Update the center gap width and reposition frames
ElvUIFrameSpacer:SetGapWidth(newWidth)

-- Adjust spacing
ElvUIFrameSpacer:SetFrameSpacing(newSpacing)

-- Adjust vertical position
ElvUIFrameSpacer:SetVerticalOffset(newOffset)
```

## Requirements

- World of Warcraft: The War Within (11.1.0+)
- ElvUI

## Troubleshooting

- If frames don't move after installation, type `/reload`
- If positions reset, ensure SavedVariables are being written (clean exit from game)
- Use `/efs status` to verify current settings

