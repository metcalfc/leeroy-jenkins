# VHS tape for Leeroy Today demo
# Generate with: vhs today/demo.tape

Output today/demo.gif

Set FontSize 13
Set Width 1000
Set Height 700
Set Theme "Dracula"
Set TypingSpeed 50ms

Type "# Leeroy Today - AI Attribution in Commit Messages" Sleep 500ms Enter
Sleep 1s

Type "# No fetch needed - attestation travels with commits!" Sleep 300ms Enter
Sleep 1s

Type "" Enter
Type "# List AI-assisted commits" Sleep 300ms Enter
Type "leeroy list" Sleep 300ms Enter
Sleep 2s

Type "" Enter
Type "# Show the commit message with embedded attestation" Sleep 300ms Enter
Type "git log -1 --format='%B'" Sleep 300ms Enter
Sleep 4s

Type "" Enter
Type "# The leeroy CLI extracts just the attestation block" Sleep 300ms Enter
Type "leeroy show HEAD" Sleep 300ms Enter
Sleep 3s

Type "" Enter
Type "# Repository statistics" Sleep 300ms Enter
Type "leeroy stats" Sleep 300ms Enter
Sleep 2s

Type "" Enter
Type "# That's it! Simple, portable, works today." Sleep 300ms Enter
Sleep 2s
