#!/usr/bin/env python3
"""check-length.py — 驗證 post 字元數喺範圍內（LinkedIn / FB 上限見 SKILL.md）。

用法：python3 check-length.py <file> <min> <max>
Exit 0 = 合格；1 = 超出範圍。字元以 Unicode code point 計（同 LinkedIn / FB 計法一致）。
"""

import sys
from pathlib import Path


def main(path, min_chars, max_chars):
    length = len(Path(path).read_text(encoding="utf-8").strip())
    ok = min_chars <= length <= max_chars
    print(f"{'✅' if ok else '❌'} {path}: {length} chars (allowed {min_chars}-{max_chars})")
    return 0 if ok else 1


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit("usage: check-length.py <file> <min> <max>")
    sys.exit(main(sys.argv[1], int(sys.argv[2]), int(sys.argv[3])))
