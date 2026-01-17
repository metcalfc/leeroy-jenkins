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
Type "git fetch origin refs/notes/leeroy:refs/notes/leeroy" Sleep 300ms Enter
Sleep 1.5s

Type "" Enter
Type "# List AI-attested commits" Sleep 300ms Enter
Type "~/.leeroy/bin/leeroy list" Sleep 300ms Enter
Sleep 1.5s

Type "" Enter
Type "# Show full attestation with prompts" Sleep 300ms Enter
Type "~/.leeroy/bin/leeroy show db908d2" Sleep 300ms Enter
Sleep 3s

Type "" Enter
Type "# Verify cryptographic signatures (2 layers)" Sleep 300ms Enter
Type "~/.leeroy/bin/leeroy verify db908d2" Sleep 300ms Enter
Sleep 3s

Type "" Enter
Type "# Repository statistics" Sleep 300ms Enter
Type "~/.leeroy/bin/leeroy stats" Sleep 300ms Enter
Sleep 2s
