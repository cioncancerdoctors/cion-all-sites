#!/usr/bin/env python3
"""
Build trackers/all-sites.xlsx — one sheet per doctor site.
Columns: Date Published | Slug | URL
Run from repo root: python scripts/build-tracker-xlsx.py
"""
import csv, os, glob
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

REPO   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG    = os.path.join(REPO, "page-log.csv")
OUT    = os.path.join(REPO, "trackers", "all-sites.xlsx")

SITES = {
    "dr-owais":        ("Dr. Owais Mohammed",       "cioncancerdrowais.com"),
    "dr-vinay":        ("Dr. Vinay",                 "cioncancerdrvinay.com"),
    "dr-murali":       ("Dr. Murali",                "cioncancerdrmurali.com"),
    "dr-sandeep":      ("Dr. Sandeep",               "cioncancerdrsandeep.com"),
    "dr-kiranmayee":   ("Dr. Kiranmayee",            "cioncancerdrkiranmayee.com"),
    "dr-basudev":      ("Dr. Basudev",               "cioncancerdrbasudev.com"),
    "dr-raghvendra":   ("Dr. Raghvendra",            "cioncancerdrraghvendra.com"),
    "dr-craghavendra": ("Dr. C. Raghavendra",        "cioncancerdrcraghavendra.info"),
    "dr-imad":         ("Dr. Mohammed Imaduddin",    "cioncancerdrimad.com"),
}

# Load page-log into url->date lookup
log_lookup = {}
if os.path.exists(LOG):
    with open(LOG, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            log_lookup[row["url"]] = row["timestamp_utc"]

HEADER_FILL = PatternFill("solid", fgColor="1F4E79")
HEADER_FONT = Font(bold=True, color="FFFFFF", size=11)
ALT_FILL    = PatternFill("solid", fgColor="EBF3FB")
URL_FONT    = Font(color="0563C1", underline="single", size=10)
BORDER_SIDE = Side(style="thin", color="BFBFBF")
CELL_BORDER = Border(bottom=Border(bottom=BORDER_SIDE).bottom)

def thin_border():
    s = Side(style="thin", color="D9D9D9")
    return Border(left=s, right=s, top=s, bottom=s)

wb = Workbook()
wb.remove(wb.active)  # remove default sheet

for folder, (doctor_name, domain) in SITES.items():
    site_dir = os.path.join(REPO, folder)
    pages = []

    if os.path.isdir(site_dir):
        for f in sorted(os.listdir(site_dir)):
            if not f.endswith(".html") or f == "thank-you.html":
                continue
            slug = f.replace(".html", "")
            url  = f"https://{domain}/{f}"
            date = log_lookup.get(url, "NA")
            pages.append((date, slug, url))

    ws = wb.create_sheet(title=folder.replace("dr-", "Dr. ").title())

    # Sheet title row
    ws.merge_cells("A1:C1")
    title_cell = ws["A1"]
    title_cell.value = f"{doctor_name}  ·  {domain}"
    title_cell.font  = Font(bold=True, size=13, color="1F4E79")
    title_cell.alignment = Alignment(horizontal="left", vertical="center")
    ws.row_dimensions[1].height = 28

    # Header row
    headers = ["Date Published", "Slug", "URL"]
    for col, h in enumerate(headers, 1):
        c = ws.cell(row=2, column=col, value=h)
        c.font      = HEADER_FONT
        c.fill      = HEADER_FILL
        c.alignment = Alignment(horizontal="left", vertical="center")
        c.border    = thin_border()
    ws.row_dimensions[2].height = 20

    # Data rows
    for i, (date, slug, url) in enumerate(pages):
        row = i + 3
        fill = ALT_FILL if i % 2 == 0 else PatternFill("solid", fgColor="FFFFFF")

        d_cell = ws.cell(row=row, column=1, value=date if date != "NA" else "NA")
        d_cell.alignment = Alignment(horizontal="center", vertical="center")
        d_cell.fill = fill
        d_cell.border = thin_border()
        if date != "NA":
            d_cell.font = Font(color="2E7D32", size=10)  # green for published
        else:
            d_cell.font = Font(color="999999", size=10)  # grey for NA

        s_cell = ws.cell(row=row, column=2, value=slug)
        s_cell.alignment = Alignment(horizontal="left", vertical="center")
        s_cell.fill   = fill
        s_cell.border = thin_border()
        s_cell.font   = Font(size=10)

        u_cell = ws.cell(row=row, column=3, value=url)
        u_cell.hyperlink  = url
        u_cell.font       = URL_FONT
        u_cell.alignment  = Alignment(horizontal="left", vertical="center")
        u_cell.fill       = fill
        u_cell.border     = thin_border()

        ws.row_dimensions[row].height = 16

    # Column widths
    ws.column_dimensions["A"].width = 26
    ws.column_dimensions["B"].width = 50
    ws.column_dimensions["C"].width = 70

    # Freeze panes below header
    ws.freeze_panes = "A3"

    print(f"  {folder}: {len(pages)} pages")

os.makedirs(os.path.join(REPO, "trackers"), exist_ok=True)
wb.save(OUT)
print(f"\nSaved: {OUT}")
