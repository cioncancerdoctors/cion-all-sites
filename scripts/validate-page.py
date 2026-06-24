#!/usr/bin/env python3
"""Validate one generated page. Prints 'VALIDATE:OK' or 'VALIDATE:<issues>'. Usage: validate-page.py <file>"""
import re, sys, json

f = sys.argv[1]
c = open(f, encoding="utf-8").read()
te = re.compile("[ఀ-౿]")                                  # Telugu
other = re.compile("[ऀ-ॿ஀-௿ಀ-೿ഀ-ൿ]")  # Devanagari/Tamil/Kannada/Malayalam
iss = []

if c and ord(c[0]) == 0xFEFF: iss.append("BOM")
if not re.search(r'<html[^>]*lang="en"', c): iss.append("lang!=en")
t = (re.search(r"<title>(.*?)</title>", c, re.S) or [None, ""])[1]
if te.search(t): iss.append("telugu-title")
if len(t) > 60: iss.append("title>60(%d)" % len(t))
md = re.search(r'<meta name="description" content="(.*?)"', c, re.S)
if md and len(md.group(1)) > 155: iss.append("meta>155(%d)" % len(md.group(1)))
if other.search(c): iss.append("cross-script-leak")
if len(re.findall(r'class="te-content"', c)) != len(re.findall(r'class="en-content"', c)): iss.append("span-imbalance")
if re.search(r"(₹|\bRs\.?\b|\bINR\b|\blakh|\bcrore)", re.sub(r"<[^>]+>", " ", re.sub(r"<script.*?</script>", "", c, flags=re.S)), re.I): iss.append("price-figure")
for b in re.findall(r'<script type="application/ld\+json">(.*?)</script>', c, re.S):
    try: json.loads(b)
    except Exception: iss.append("jsonld-broken")
if "hreflang" in c.lower() and "<!-- " not in c[:c.lower().find("hreflang")][-12:]:
    if re.search(r'<link[^>]*hreflang', c): iss.append("hreflang-present")

print("VALIDATE:" + (";".join(iss) if iss else "OK"))
