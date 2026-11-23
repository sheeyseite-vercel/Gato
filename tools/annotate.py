"""Turn flutter/gradle output into GitHub annotations so failures are readable via the API."""
import re
import sys

text = open(sys.argv[1], errors="replace").read().splitlines()
pat = re.compile(r"^\s*(error|warning)\s+[•-]\s+(.*?)\s+[•-]\s+(\S+?):(\d+):(\d+)\s+[•-]\s+(\S+)")
n = 0
for line in text:
    m = pat.match(line)
    if m and m.group(1) == "error" and n < 10:
        kind, msg, path, ln, col, code = m.groups()
        print(f"::error file={path},line={ln},col={col}::{msg} ({code})")
        n += 1
if n == 0:
    hits = [l for l in text if re.search(r"error:|FAILURE|What went wrong|Execution failed|e: |Could not|not found|Unresolved", l)]
    for l in hits[:10]:
        print("::error::" + l.strip()[:900])
