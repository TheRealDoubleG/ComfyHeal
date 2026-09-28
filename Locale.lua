ComfyHeal=ComfyHeal or {}
local A=ComfyHeal
local de=GetLocale and GetLocale()=="deDE"

local EN={
 GENERAL="General", BINDINGS="Click Casting", DISPEL="Dispel", PROFILES="Profiles", INFO="Info",
 ENABLE="Enable ComfyHeal", CLICKCAST="Enable secure click casting", APPLY_PLAYER="Apply to player frame",
 APPLY_SINGLE="Apply to friendly single-unit frames", APPLY_PARTY="Apply to party frames", APPLY_RAID="Apply to raid frames",
 BIND_HINT="Enter spell names exactly as they appear in your spellbook. Secure attributes are changed only out of combat.",
 LEFT="Left click", RIGHT="Right click", MIDDLE="Middle click", BUTTON4="Mouse button 4", BUTTON5="Mouse button 5",
 SHIFT_LEFT="Shift + left", SHIFT_RIGHT="Shift + right", CTRL_LEFT="Ctrl + left", CTRL_RIGHT="Ctrl + right",
 ALT_LEFT="Alt + left", ALT_RIGHT="Alt + right",
 DISPEL_CENTER="Show Dispel Center", HIGHLIGHT_FRAMES="Highlight frames with selected debuff types",
 MAGIC="Magic", CURSE="Curse", DISEASE="Disease", POISON="Poison",
 DISPEL_HINT="Choose which debuff types should be highlighted. This is a display filter, not an automatic claim about what your current spec can dispel.",
 CENTER_UNLOCK="Unlock Dispel Center", CENTER_LOCK="Lock Dispel Center", TEST="Test display",
 PENDING="Secure binding changes are queued until combat ends.", APPLIED="Secure click bindings applied.",
 NO_COMFYFRAMES="ComfyFrames is not loaded. Click-casting support for Blizzard frames is planned for a later beta.",
 CHARACTER_PROFILE="Character", ACCOUNT_PROFILE="Account", CUSTOM_PROFILE="Custom profile", CREATE="Create",
 DELETE="Delete custom", RESET_PROFILE="Reset profile", PROFILES_HINT="Every character has its own profile. Account and custom profiles are also available.",
 INFO_NOTICE="ComfyHeal provides UI and secure click bindings only. It never chooses targets or casts spells automatically.",
 INFO_COMMANDS="/comfyheal, /cheal, /cheal test",
 LOADED="Loaded.",
}

local DE={
 GENERAL="Allgemein", BINDINGS="Click-Casting", DISPEL="Entfernen", PROFILES="Profile", INFO="Info",
 ENABLE="ComfyHeal aktivieren", CLICKCAST="Sicheres Click-Casting aktivieren", APPLY_PLAYER="Auf Spielerframe anwenden",
 APPLY_SINGLE="Auf freundliche Einzel-Frames anwenden", APPLY_PARTY="Auf Gruppenframes anwenden", APPLY_RAID="Auf Raidframes anwenden",
 BIND_HINT="Zaubernamen genau so eingeben, wie sie im Zauberbuch stehen. Secure-Attribute werden nur außerhalb des Kampfes geändert.",
 LEFT="Linksklick", RIGHT="Rechtsklick", MIDDLE="Mittelklick", BUTTON4="Maustaste 4", BUTTON5="Maustaste 5",
 SHIFT_LEFT="Shift + links", SHIFT_RIGHT="Shift + rechts", CTRL_LEFT="Strg + links", CTRL_RIGHT="Strg + rechts",
 ALT_LEFT="Alt + links", ALT_RIGHT="Alt + rechts",
 DISPEL_CENTER="Dispel-Center anzeigen", HIGHLIGHT_FRAMES="Frames mit gewählten Debuff-Typen hervorheben",
 MAGIC="Magie", CURSE="Fluch", DISEASE="Krankheit", POISON="Gift",
 DISPEL_HINT="Wähle die Debuff-Typen, die hervorgehoben werden sollen. Das ist ein Anzeigefilter und keine automatische Aussage darüber, was deine aktuelle Spezialisierung entfernen kann.",
 CENTER_UNLOCK="Dispel-Center entsperren", CENTER_LOCK="Dispel-Center sperren", TEST="Testanzeige",
 PENDING="Secure-Binding-Änderungen werden bis zum Kampfende vorgemerkt.", APPLIED="Secure Click-Bindings angewendet.",
 NO_COMFYFRAMES="ComfyFrames ist nicht geladen. Click-Casting für Blizzard-Frames ist für eine spätere Beta geplant.",
 CHARACTER_PROFILE="Charakter", ACCOUNT_PROFILE="Account", CUSTOM_PROFILE="Eigenes Profil", CREATE="Erstellen",
 DELETE="Eigenes löschen", RESET_PROFILE="Profil zurücksetzen", PROFILES_HINT="Jeder Charakter hat ein eigenes Profil. Account- und eigene Profile sind ebenfalls verfügbar.",
 INFO_NOTICE="ComfyHeal stellt nur UI und sichere Click-Bindings bereit. Es wählt nie automatisch Ziele und wirkt nie automatisch Zauber.",
 INFO_COMMANDS="/comfyheal, /cheal, /cheal test",
 LOADED="Geladen.",
}

local L=de and DE or EN
function A:T(k) return L[k] or EN[k] or k end
