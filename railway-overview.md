# Deploy and Host Twenty CRM with Railway

Twenty is the open-source CRM: a modern, fast alternative to Salesforce and HubSpot for managing companies, people, opportunities and workflows. This template is a real one-click setup. One click gives the full Twenty stack, wired together and ready to sign in.

## About Hosting Twenty CRM

Twenty runs as two processes from the same image: the web app, which also runs database setup and migrations on boot, and a background worker for email and calendar sync, workflows and imports. Both need Postgres, Redis and shared file storage. This template deploys all of it: the official Twenty image as app and worker, Postgres and Redis on persistent volumes and Railway's private network, and a Railway Storage Bucket for uploads, since the two processes can't share a disk. Passwords and the encryption key are generated per deploy, so there's nothing to fill in. The first boot takes about 5 minutes. Sign up as soon as it's live: the first account becomes the admin.

## Common Use Cases

- A self-hosted CRM for a sales team that wants to own its data
- One separate CRM instance per client, for agencies
- A CRM with an API and webhooks for custom pipelines and automation
- Replacing a per-seat SaaS CRM with a flat infrastructure cost

## Dependencies for Twenty CRM Hosting

- Twenty (`twentycrm/twenty`, app and worker)
- PostgreSQL
- Redis
- S3-compatible storage (Railway Storage Bucket)

### Deployment Dependencies

- Twenty source and docs: https://github.com/twentyhq/twenty
- Self-hosting configuration (email, Google and Microsoft sign-in): https://twenty.com/developers/section/self-hosting
- Template source and terminal deploy script: https://github.com/LeadGrowGTM/twenty-railway

### Implementation Details

The worker runs `yarn worker:prod` and skips migrations and cron registration, which the app handles. Redis runs with `--maxmemory-policy noeviction`, as Twenty's job queue requires. To use a custom domain, add it to the `twenty` service and set `SERVER_URL` to it.

## Why Deploy Twenty CRM on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Twenty CRM on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
