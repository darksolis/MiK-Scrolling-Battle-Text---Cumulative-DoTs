MSBT Cumulative DoT Tracker v5.4.86-Darksolis

INSTALL
1. Fully exit World of Warcraft.
2. Delete these existing folders from Interface\AddOns:
   MikScrollingBattleText
   MSBTOptions
3. Copy both replacement folders from this package into Interface\AddOns.
4. Launch the game and type /msbt.
5. Open the Cumulative DoTs tab.

WHAT CHANGED IN v5.4.86
- Replaced the cycling font button with a proper dropdown list.
- Added a live text preview for font, size, outline, color, alignment, labels, and number style.
- Reorganized the tab into Tracking, Text Style, Labels & Detail, Position & Cleanup, and Spell Whitelist sections.
- Increased spacing and removed overlapping/cluttered controls.
- Kept all Cumulative DoT settings inside the native /msbt menu.

The MSBT title bar should show v5.4.86-Darksolis.


v5.4.86 QA fix: Cumulative DoT tab now registers before its dropdown controls are lazily constructed, preventing the tab from disappearing on older clients.
