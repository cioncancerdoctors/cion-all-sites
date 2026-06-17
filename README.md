# CION Cancer Doctors — All Sites

Private monorepo for all 9 CION doctor websites. One folder per doctor.

## Structure

```
dr-imad/          → cioncancerdrimad.com
dr-vinay/         → cioncancerdrvinay.com
dr-murali/        → cioncancerdrmurali.com
dr-sandeep/       → cioncancerdrsandeep.com
dr-kiranmayee/    → cioncancerdrkiranmayee.com
dr-basudev/       → cioncancerdrbasudev.com
dr-raghvendra/    → cioncancerdrraghvendra.com
dr-craghavendra/  → cioncancerdrcraghavendra.info
dr-owais/         → cioncancerdrowais.com
```

## How deploys work

Push to `main` → GitHub Actions detects which `dr-*/` folders changed → SFTP-deploys only those folders to the correct Hostinger domain. Other doctors' sites are not touched.

## Adding a new page

1. Create the page folder in the correct `dr-*/` directory
2. Commit and push to main
3. Actions deploys it automatically within ~2 minutes

## Secrets required (GitHub → Settings → Secrets → Actions)

- `SFTP_USER` — Hostinger account username (`u885652959`)
- `SFTP_PASS` — Hostinger account password

## Never commit

- `cion-config.php` (HubSpot token — lives on server at `/home/u885652959/private/`)
- `leads.log`, `errors.log` (patient/lead data)
- `.env` files
