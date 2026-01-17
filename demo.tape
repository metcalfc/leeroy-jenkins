# VHS tape for Leeroy demo
# Generate with: rm -rf /tmp/leeroy-demo-vhs && vhs demo.tape

Output demo.gif

Set FontSize 13
Set Width 1000
Set Height 600
Set Theme "Dracula"
Set TypingSpeed 50ms
Set Shell bash
Set CursorBlink false

Type "# Leeroy Demo - Transparent AI Attribution" Sleep 500ms Enter
Sleep 1s

Type "# Clone demo repo (or use leeroy fetch command)" Sleep 300ms Enter
Type "cd /tmp && rm -rf leeroy-demo-vhs" Sleep 100ms Enter
Type "git clone https://github.com/metcalfc/leeroy-demo.git leeroy-demo-vhs" Sleep 300ms Enter
Sleep 3s
Type "cd leeroy-demo-vhs" Sleep 300ms Enter
Sleep 500ms

Type "" Enter
Type "# Fetch attestation notes" Sleep 300ms Enter
Type "git fetch origin refs/notes/leeroy:refs/notes/leeroy" Sleep 300ms Enter
Sleep 1.5s

Type "" Enter
Type "# List AI-attested commits" Sleep 300ms Enter
Type "~/.leeroy/bin/leeroy list" Sleep 300ms Enter
Sleep 1.5s

Type "" Enter
Type "# Show full attestation with prompts and model" Sleep 300ms Enter
Type "~/.leeroy/bin/leeroy show 69d51a6" Sleep 300ms Enter
Sleep 3s

Type "" Enter
Type "# Verify both signatures: tool + commit" Sleep 300ms Enter
Type "~/.leeroy/bin/leeroy verify 69d51a6" Sleep 300ms Enter
Sleep 3s

Type "" Enter
Type "# View commit signature" Sleep 300ms Enter
Type "git log --show-signature -1 69d51a6 | head -10" Sleep 300ms Enter
Sleep 3s

Type "" Enter
Type "# Repository statistics" Sleep 300ms Enter
Type "~/.leeroy/bin/leeroy stats" Sleep 300ms Enter
Sleep 2s
