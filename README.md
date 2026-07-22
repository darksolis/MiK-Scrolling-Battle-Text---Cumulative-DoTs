[README_MSBT_CUMULATIVE_DOT_TRACKER.txt](https://github.com/user-attachments/files/30282464/README_MSBT_CUMULATIVE_DOT_TRACKER.txt)
MIK'S SCROLLING BATTLE TEXT
CUMULATIVE DOT TRACKER — DARKSOLIS EDITION
Version 5.4.88-Darksolis

======================================================================
OVERVIEW
======================================================================

This is a custom modification of Mik's Scrolling Battle Text (MSBT) for
World of Warcraft 3.3.5 / Ascension-style clients.

The project adds a cumulative periodic-damage tracker directly into MSBT.
Instead of every DoT tick scrolling down the screen as a separate number,
selected periodic-damage effects can be added together into one persistent
"sticky" total.

Normal MSBT combat text continues to animate as usual. The cumulative total
stays anchored near a selected MSBT scroll area and updates whenever a tracked
DoT deals damage.

The feature was designed for players who want to see the total contribution
of their damage-over-time effects across a spell application, a target's
lifetime, or several targets at once.

Original MSBT addon by Mikord.
Cumulative DoT concept, development direction, custom integration, and testing
by Darksolis and community feedback.

======================================================================
CORE FEATURES
======================================================================

• Persistent cumulative periodic-damage total
• No stream of individual DoT tick numbers required
• Tracks damage until the target dies or until the current application ends
• Separate totals for multiple enemies
• Optional combined total across all tracked targets
• Track all periodic damage or whitelist only selected spells
• Optional pet periodic-damage support
• Target names, spell names, spell totals, and spell icons are independently
  configurable
• Dedicated representative Stack Icon beside the total
• Native integration into the original /msbt options menu
• Live display preview
• Custom font, size, color, outline, alignment, spacing, and positioning
• Target sorting, target limits, spell-label limits, and cleanup controls
• Compatibility safeguards for private-server combat-log inconsistencies

======================================================================
HOW THE COUNTER WORKS
======================================================================

When a tracked periodic effect deals damage, that damage is added to the
current cumulative total.

Example:

    Tick 1: 500
    Tick 2: 500
    Tick 3: 650

The sticky display updates as:

    500
    1,000
    1,650

The same display object is updated rather than creating another falling
combat-text event for every tick.

======================================================================
RESET MODES
======================================================================

TARGET DEATH

The tracker accumulates periodic damage against each enemy until that enemy
is reported dead. This is useful for bosses, elites, target dummies, and
measuring total DoT contribution over a target's full lifetime.

Optional safeguards can also clear old rows when combat ends or after a
configurable out-of-combat timeout if the server fails to send a reliable
death event.

CURRENT APPLICATION / DOT EXPIRATION

Each tracked spell application has its own lifecycle. Its cumulative total
resets when that spell is reapplied or refreshed and clears after the current
application ends.

Multiple DoTs on the same target are tracked independently, so one DoT
expiring will not incorrectly clear the totals of another active DoT.

======================================================================
MULTI-TARGET DISPLAY
======================================================================

SEPARATE TARGET TOTALS

Each enemy receives its own sticky row. Rows are arranged vertically with
configurable spacing and can be sorted by:

• Most recently damaged
• Highest cumulative damage
• Target name

The maximum number of visible target rows can also be limited.

COMBINED TOTAL

All tracked periodic damage across all enemies is merged into one cumulative
number. This is useful for AoE DoT builds where total output matters more than
individual target totals.

======================================================================
SPELL FILTERING
======================================================================

TRACK ALL PERIODIC DAMAGE

When enabled, all periodic-damage events caused by the player are counted.
Pet periodic damage can be included with a separate toggle.

SPELL WHITELIST

When "Track all periodic damage" is disabled, only spells added to the
whitelist are counted.

The whitelist accepts:

• Exact spell names
• Numeric spell IDs

Spell IDs are recommended for custom-server abilities when names may differ
or be localized.

======================================================================
SPELL DETAILS AND ICONS
======================================================================

The main total can be displayed by itself or with optional detail.

Available combinations include:

• Damage number only
• Damage number with target name
• Damage number with spell names
• Damage number with per-spell cumulative totals
• Damage number with dynamic spell icons
• Damage number with icons but no spell names
• Spell names, icons, and per-spell totals together

Dynamic spell icons are looked up from the spells actually contributing to
the total. Additional fallbacks are included for custom, pet, and proc-based
Ascension abilities, but some private-server spells may not expose a usable
icon through the standard WoW API.

======================================================================
DEDICATED STACK ICON
======================================================================

Version 5.4.88 adds a dedicated Stack Icon system.

This icon is independent from spell names and dynamic per-DoT icons. It acts
as a consistent visual badge for the cumulative total, even when the display
is configured as damage-only.

Stack Icon options include:

• Enable or disable the icon
• Position the icon on the left or right of the total
• Adjust icon size
• Choose an icon by spell ID
• Choose an icon by spell name
• Enter a direct texture path
• One-click Hemorrhage-style icon preset
• Pulse the icon and cumulative total when a DoT tick lands

Example:

    [Hemorrhage Icon] 128.5k

This feature was added because custom-server DoTs, pet attacks, and equipment
procs do not always return reliable spell textures. The Stack Icon provides a
stable visual identity even when dynamic icon lookup fails.

======================================================================
KNOWN ASCENSION / CUSTOM-SPELL EXAMPLES
======================================================================

The tracker was specifically discussed and tested around effects such as:

• Torn to Shreds
• Rake — pet
• Primal Shred — pet
• Ripped Flesh — Bloodtooth necklace proc

These can involve player, pet, or proc combat-log sources. Enable pet damage
where appropriate and use spell IDs in the whitelist when exact-name matching
is unreliable.

A dedicated Stack Icon remains the most reliable presentation option when a
custom spell does not expose a valid icon texture.

======================================================================
DISPLAY CUSTOMIZATION
======================================================================

The Cumulative DoTs tab provides controls for:

TEXT STYLE
• Inherit the selected MSBT scroll area's font
• Choose from registered MSBT fonts using a real dropdown list
• Font size
• Text color
• Font outline
• Left, center, or right alignment
• Exact or abbreviated numbers

LABELS AND DETAIL
• Target-name display
• Spell-name display
• Per-spell totals
• Dynamic spell icons
• Active-only spell labels
• Maximum displayed spell labels

LAYOUT
• Selected MSBT scroll area
• Horizontal offset
• Vertical offset
• Row spacing
• Maximum target rows

ANIMATION
• Pulse on critical periodic ticks
• Pulse on every tracked periodic tick
• Pulse scale and duration
• Dedicated Stack Icon pulse

CLEANUP
• DoT expiration linger time
• Missing-death-event fallback timeout
• Clear totals when combat ends

======================================================================
LIVE PREVIEW
======================================================================

The options page includes a live text preview.

The preview updates when changing settings such as:

• Font
• Font size
• Outline
• Color
• Alignment
• Target labels
• Spell labels
• Spell icons
• Number formatting
• Stack Icon settings

A Test Display button is also available for positioning sample target rows
without needing to enter combat.

======================================================================
OPENING THE OPTIONS
======================================================================

Use:

    /msbt

Then select:

    Cumulative DoTs

The older command remains available as a shortcut:

    /msbtdot

Both commands open the same integrated MSBT options interface.

Additional utility commands:

    /msbtdot reset
    /msbtdot mode death
    /msbtdot mode application
    /msbtdot display targets
    /msbtdot display combined
    /msbtdot add <spell ID or exact spell name>
    /msbtdot remove <spell ID or exact spell name>

======================================================================
INSTALLATION
======================================================================

The package contains two addon folders:

    MikScrollingBattleText
    MSBTOptions

Installation steps:

1. Fully exit World of Warcraft.
2. Open your World of Warcraft\Interface\AddOns folder.
3. Delete the existing MikScrollingBattleText folder.
4. Delete the existing MSBTOptions folder.
5. Copy both replacement folders from this package into Interface\AddOns.
6. Launch the game.
7. Type /msbt and open the Cumulative DoTs tab.

Do not merge this package over an older build. Old Lua files left behind from
previous versions can cause missing tabs, load-order errors, or outdated code
to remain active.

The MSBT title bar should show:

    Mik's Scrolling Battle Text v5.4.88-Darksolis

======================================================================
ADDON-LAUNCHER WARNING
======================================================================

This is a custom modification of MSBT.

If MSBT is managed by an addon launcher, disable automatic updates for both
MikScrollingBattleText and MSBTOptions. A launcher may replace the custom
files with the original public release and remove the Cumulative DoT Tracker.

======================================================================
SAVED SETTINGS
======================================================================

The cumulative tracker uses its own saved-variable database:

    MSBTCumulativeDotsDB

Existing tracker settings are preserved between sessions and migrated where
possible when upgrading from earlier Darksolis builds.

======================================================================
PRIVATE-SERVER COMPATIBILITY
======================================================================

The addon targets the WoW 3.3.5 interface and includes handling for older
combat-log argument layouts.

Private servers can differ from standard Blizzard clients in several ways:

• Custom spells may return no icon texture
• Pet or proc ownership may be reported inconsistently
• Target death events may occasionally be missing
• Spell names or IDs may differ from expected database values

The tracker includes fallback cleanup, icon-resolution fallbacks, and explicit
pet/proc controls to reduce these issues. Spell IDs and the dedicated Stack
Icon are recommended when custom spell metadata is unreliable.

======================================================================
VERSION HISTORY
======================================================================

v5.4.88-Darksolis
• Added dedicated Stack Icon independent from spell labels and dynamic icons
• Added left/right Stack Icon placement
• Added adjustable Stack Icon size
• Added spell ID, spell name, and texture-path icon selection
• Added Hemorrhage icon preset
• Added optional pow-style pulse on every tracked tick
• Improved icon lookup fallbacks for custom, pet, and proc abilities

v5.4.87-Darksolis
• Allowed dynamic spell icons in damage-only mode
• Decoupled spell icons from spell-name labels
• Added icon support to combined-target mode
• Updated live preview combinations

v5.4.86-Darksolis
• Corrected FontString initialization order for older 3.3.5 clients
• Prevented the live preview from failing before a font was assigned

v5.4.85-Darksolis
• Registered the Cumulative DoTs tab before constructing advanced controls
• Added safer lazy-loading behavior for the options page

v5.4.84-Darksolis
• Added proper font dropdown
• Added live style preview
• Reorganized options into cleaner sections
• Improved spacing and native options-page layout

Earlier Darksolis builds introduced the cumulative tracking engine, native
MSBT options integration, multi-target support, combined totals, spell
whitelisting, premium text styling, and private-server cleanup safeguards.

======================================================================
CREDITS
======================================================================

Original Mik's Scrolling Battle Text:
    Mikord

Custom cumulative DoT tracker, integration, product direction, and packaging:
    Darksolis

Community concept and testing feedback:
    gak and the Ascension / CoA community

This project is an unofficial custom modification and is not an official MSBT
or Ascension release.

v5.4.90-Darksolis
- Renamed the grouped display label from "Unknown" to "Grouped DoT Damage".
- Grouped mode now preserves all damage accumulated during the current combat encounter when individual enemies die.
- The grouped session total resets when combat ends or when the user manually resets it.
- Separate-target mode continues to remove individual target rows when those targets die.


v5.4.90-Darksolis
- Grouped mode now uses a dynamic target label.
- With one living target, the sticky counter shows that enemy's name.
- With two or more living targets, it shows "Grouped DoT Damage".
- When a pack drops back to one living enemy, the label switches back to that enemy.
- The cumulative grouped total still preserves damage from defeated enemies until combat ends.
