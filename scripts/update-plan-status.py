#!/usr/bin/env python3
"""
Called by nightly-runner.ps1 to update a content plan row status.
Usage: python scripts/update-plan-status.py <doctor_folder> <built_slug> <built_url> <status>
  status = "published" | "failed"
"""
import csv, sys, os
from datetime import date

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV  = os.path.join(REPO, "_data", "content-plan.csv")
FIELDNAMES = ["doctor_folder","planned_date","topic_en","slug_hint","status","built_slug","built_url","built_at"]

def main():
    if len(sys.argv) < 4:
        print("Usage: update-plan-status.py <doctor_folder> <built_slug> <built_url> <status>")
        sys.exit(1)

    folder   = sys.argv[1]
    slug     = sys.argv[2]
    url      = sys.argv[3]
    status   = sys.argv[4] if len(sys.argv) > 4 else "published"
    today    = date.today().strftime("%Y-%m-%d")

    rows = []
    updated = False
    with open(CSV, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if (not updated and
                row["doctor_folder"] == folder and
                row["planned_date"] == today and
                row["status"] == "pending"):
                row["status"]     = status
                row["built_slug"] = slug
                row["built_url"]  = url
                row["built_at"]   = today
                updated = True
            rows.append(row)

    if not updated:
        print(f"[plan] No pending row found for {folder} on {today}")
        sys.exit(0)

    with open(CSV, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=FIELDNAMES)
        w.writeheader()
        w.writerows(rows)

    print(f"[plan] Updated {folder} {today} → {status} ({slug})")

if __name__ == "__main__":
    main()
