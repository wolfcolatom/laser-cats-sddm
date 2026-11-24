#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 tom
# SPDX-License-Identifier: GPL-3.0-or-later
"""Prints qmllint's JSON report (on stdin) as plain lines. qmllint's own
text output leaves some warnings out; the JSON has them all."""
import json
import sys

report = json.load(sys.stdin)
count = 0
for entry in report.get("files", []):
    for warning in entry.get("warnings", []):
        count += 1
        message = warning.get("message", "").replace("\n", " ")
        print(f"{entry['filename']}:{warning.get('line', '?')}: {message} [{warning.get('id', warning.get('type', ''))}]")
print(f"{count} lint warning(s)")
