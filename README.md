# Fishing Mode

Fishing Mode is a World of Warcraft addon that lets you take advantage of the interact key to fish without needing to mouse over the bobber.

When fishing mode is activated, it temporarily overrides a few settings regarding the interact key's soft targeting to improve the chance that the bobber will be selected as the soft target. It also sets up temporary overrides to keybinds for throwing out your fishing line and interacting.

## Usage

To toggle fishing mode on or off, you can either click the fishing rod icon on your minimap or you can configure a key in the WoW keybinding settings under the Fishing Mode header.

When in fishing mode, an overlay will appear that displays the keys you can press. This overlay remains in place until fishing mode is deactivated. If you enter combat while fishing mode is enabled, it will temporarily disable itself until combat ends.

To ensure that the interact key works consistently, ensure that you are not standing near any other interactable objects. NPCs and players should not interfere with the interact key. You will know that your fishing bobber is targeted for interact when the hook icon appears above it.

## Configuration

### Global Keybindings

To configure the keybinds to toggle fishing mode, open the game options and go to Options🡒Game🡒Keybindings and look for the Fishing Mode section.

### Adjusting the Overlay

The overlay can be moved around and resized by Shift+Right-clicking on the minimap icon. When in this Fishing Mode Edit Mode, you can click on and drag the overlay around. Resizing is performed via the scale slider. To save the changes click Okay. If you wish to undo the changes you just made, click Cancel.

### Fishing Mode Settings

All other options for fishing mode are found under Options🡒AddOns🡒Fishing Mode.

#### Fishing Mode Keybindings

On the addons settings pane you can change the bindings that are used when fishing mode is active. Binding keys here will not unbind them elsewhere as the keybinds are only active while fishing mode is active. These bindings are assigned in the exact same manner as the standard WoW keybinds.

#### Auto-Equip

You can choose to have fishing mode auto-equip a gear set when active. For this to work, you must create a gear set named Fishing. When you toggle fishing mode on, it will equip that gear set. When you toggle fishing mode off, it will equip the gear that you had on when you first toggled fishing mode on.

Note that your fishing rod is considered profession equipment, so this option is only useful if you want the extra fishing skill from a fishing hat.

#### Pause When Mounted

When this option is selected, fishing mode will automatically pause itself when you mount and will automatically resume itself when you dismount. This feature is enabled by default to avoid the chance of fishing mode keybinds preventing full control of a skyriding mount.

#### Volume Overrides

You can have fishing mode automatically adjust the various sound levels of the game when active. To do so, you need to enable the option titled Override Volume Levels. This will cause the controls beneath it to become active. Each one functions the same way for each of the sound channels. If the checkbox for a channel is not ticked, then fishing mode will not make any volume adjustments for that channel. If the box is ticked, then fishing mode will set the volume level to the value selected on the slider to the right. 

# WoW Forever Differences

WoW Forever handles fishing a bit differently than retail. These behaviors are important to be aware of.

## Auto-Equip

The auto-equip option is enabled by default. This is an important option in Forever because you cannot fish unless you have a rod equipped in your main hand. Whenever you enable Fishing Mode and don't have a set you will be prompted to create one. The template created for you will not automatically have a rod included, so after the template is set up you must open your character sheet, choose the "Fishing" set, select a rod, and then save the set. Be sure to put your normal weapons back on after doing this.

## Combat

Addons cannot change your weapons automatically when you are in combat. If you are attacked while Fishing Mode is enabled, you will need to manually equip the weapons you want. The easiest way to do this is to go into the equipment manager and look for the "Fishing Mode Backup" set. This set contains all the items you had before you enabled Fishing Mode, so equipping this will put your weapons back. When you exit combat, Fishing Mode will automatically equip your "Fishing" set again.