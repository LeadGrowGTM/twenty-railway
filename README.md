# Twenty CRM on Railway

One command deploys a fresh [Twenty CRM](https://github.com/twentyhq/twenty) as its own Railway project: the Twenty app, a background worker, Postgres, Redis and a Railway storage bucket for file uploads.

No custom Dockerfile. It runs Twenty's official image, `twentycrm/twenty:v2.49.0`.

## Deploy

You need the [Railway CLI](https://docs.railway.com/cli), logged in (`railway login`), plus `python3` and `curl`.

```bash
git clone https://github.com/LeadGrowGTM/twenty-railway && cd twenty-railway
./deploy.sh "Twenty CRM - <client>"              # uses your default workspace
./deploy.sh "Twenty CRM - <client>" <workspace>  # or pick one (ID or name)
```

The script prints the project link, then waits until the app answers (first boot sets up the database, about 5 minutes) and prints the URL.

**The first person to sign up becomes the workspace admin.** Sign up straight away.

## What gets created

| Service | What it is |
|---|---|
| `twenty` | The web app, with a public `*.up.railway.app` domain and a `/healthz` health check |
| `twenty-worker` | Background jobs (`yarn worker:prod`). It skips migrations and cron registration, which the app does |
| `Postgres` | Database, with a volume |
| `Redis` | Job queue, with a volume, run with `--maxmemory-policy noeviction` as Twenty requires |
| `twenty-files` | Railway bucket. Uploads go here because the app and worker can't share a disk on Railway |

Secrets are generated per deploy: Postgres and Redis passwords, and Twenty's `ENCRYPTION_KEY` (the worker references the app's key). Bucket keys are Railway references. `twenty.template.json` holds no secret values.

Rough cost: $15-30 a month per copy.

## Why not just deploy the image by hand

Twenty's first boot sets up the database. If `SERVER_URL` is empty at that point (the public domain doesn't exist yet), setup crashes after creating an empty `core` schema, and every later boot sees that schema and skips setup. The homepage then shows "Unable to load Twenty" (503) and the logs say `relation "core.workspace" does not exist`.

This template creates the domain in the same call as the services, so `SERVER_URL` is set on the first boot. To fix an instance that already hit the problem (only while it holds no data): `drop schema core;` on its database, then redeploy `twenty`.

## After deploy

- **Custom domain:** add it to the `twenty` service in Railway, then set `SERVER_URL=https://<your domain>` on `twenty` (the worker follows it) and redeploy.
- **Email, Google or Microsoft sign-in:** see Twenty's [self-hosting docs](https://twenty.com/developers/section/self-hosting) for the variables, and set them on both `twenty` and `twenty-worker`.
- **Upgrade:** change the image tag on both `twenty` and `twenty-worker` (and in `twenty.template.json`). Migrations run when the app boots.

## Files

- `twenty.template.json`: the Railway template config (services, variables, volumes, bucket, domain).
- `deploy.sh`: creates the project and deploys the config in one call (`templateDeployV2`). `TWENTY_TEMPLATE_ID` overrides the Railway template it's attached to.
