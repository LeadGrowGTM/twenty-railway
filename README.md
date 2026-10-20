# Twenty CRM on Railway

A real one-click setup for [Twenty](https://github.com/twentyhq/twenty), the open-source CRM. One click gives a complete, production-ready stack on Railway: the app, a background worker, Postgres, Redis and file storage, all wired together with secrets generated per deploy.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/twenty-crm-1?utm_medium=integration&utm_source=button&utm_campaign=twenty-crm)

## What's in the box

| Service | Role |
|---|---|
| `twenty` | Twenty web app (official `twentycrm/twenty:v2.49.0` image) on a public HTTPS domain, with a health check |
| `twenty-worker` | Background jobs: email and calendar sync, workflows, imports |
| `Postgres` | Database on a persistent volume, private network only |
| `Redis` | Job queue and cache on a persistent volume, private network only |
| `twenty-files` | Railway Storage Bucket for attachments and uploads |

Nothing to fill in. Database and Redis passwords and Twenty's encryption key are generated fresh for every deploy, and the services find each other through Railway references. The first boot sets up the database by itself (about 5 minutes).

## Deploy

**One click:** press the button above.

**From the terminal** (same template, handy for spinning up one copy per client):

```bash
git clone https://github.com/LeadGrowGTM/twenty-railway && cd twenty-railway
./deploy.sh "Twenty CRM - Acme"
```

Needs the [Railway CLI](https://docs.railway.com/cli) (logged in), `python3` and `curl`. The script prints the URL once Twenty is up.

## After deploy

- **Sign up right away.** The first account becomes the admin of the instance.
- **Custom domain:** add it to the `twenty` service, set `SERVER_URL=https://<domain>` on `twenty` (the worker follows), redeploy.
- **Email, Google or Microsoft sign-in and sync:** add the variables from Twenty's [self-hosting docs](https://twenty.com/developers/section/self-hosting) to both `twenty` and `twenty-worker`.
- **Upgrade:** bump the image tag on `twenty` and `twenty-worker`. Migrations run on boot.

Typical cost: $15-30 a month per instance.

## Files

- `twenty.template.json`: the Railway template config (services, variables, volumes, bucket, domain). No secret values.
- `deploy.sh`: creates a project and deploys that config in one call.
- `railway-overview.md`: the marketplace listing text.
