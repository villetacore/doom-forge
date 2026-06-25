#!/usr/bin/env bash
ls -la /tmp/iwads 2>/dev/null || echo "no dir"
echo "--- sizes ---"
du -h /tmp/iwads/*.wad 2>/dev/null
echo "--- magic (should be IWAD) ---"
head -c 4 /tmp/iwads/freedoom1.wad; echo
