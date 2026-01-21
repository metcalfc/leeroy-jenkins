# VHS tape for Leeroy demo
# Generate with: vhs demo.tape

Output demo.gif

Set FontSize 13
Set Width 1000
Set Height 600
Set Theme "Dracula"
Set TypingSpeed 50ms

Type "# Leeroy Demo - Transparent AI Attribution" Sleep 500ms Enter
Sleep 1s

Type "# Fetch attestation notes" Sleep 300ms Enter
Type "leeroy fetch" Sleep 300ms Enter
Sleep 2s

Type "" Enter
Type "# List AI-attested commits" Sleep 300ms Enter
Type "leeroy list" Sleep 300ms Enter
Sleep 2s

Type "" Enter
Type "# Show full attestation (Sonnet)" Sleep 300ms Enter
Type "leeroy show HEAD~1" Sleep 300ms Enter
Sleep 4s

Type "" Enter
Type "# Show full attestation (Opus)" Sleep 300ms Enter
Type "leeroy show HEAD" Sleep 300ms Enter
Sleep 4s

Type "" Enter
Type "# Verify both signature layers" Sleep 300ms Enter
Type "leeroy verify HEAD" Sleep 300ms Enter
Sleep 3s

Type "" Enter
Type "# Show commit signature" Sleep 300ms Enter
Type "git log --show-signature -1 HEAD | head -10" Sleep 300ms Enter
Sleep 3s

Type "" Enter
Type "# Repository statistics" Sleep 300ms Enter
Type "leeroy stats" Sleep 300ms Enter
Sleep 2s
