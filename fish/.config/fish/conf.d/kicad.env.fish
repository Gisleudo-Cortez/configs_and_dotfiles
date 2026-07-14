## KiCad environment variables
# Required by skidl and other Python EDA tools to locate KiCad symbol libraries.
# KiCad 10 ships symbols at /usr/share/kicad/symbols (222 libraries as of 2026-07).
# KICAD_SYMBOL_DIR is the canonical variable; versioned variants (KICAD6/7/8/9) are
# checked by older tool versions and set here for backward compatibility.

set -gx KICAD_SYMBOL_DIR /usr/share/kicad/symbols
set -gx KICAD6_SYMBOL_DIR /usr/share/kicad/symbols
set -gx KICAD7_SYMBOL_DIR /usr/share/kicad/symbols
set -gx KICAD8_SYMBOL_DIR /usr/share/kicad/symbols
set -gx KICAD9_SYMBOL_DIR /usr/share/kicad/symbols