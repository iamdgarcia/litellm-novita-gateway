# Self-Hosted LiteLLM Gateway + Redis Cache

An OpenAI-compatible LiteLLM proxy that routes **only to open-source models on Novita AI**, caches repeated requests in Redis, and stores virtual keys and spend logs in PostgreSQL.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template)

> Replace the deploy URL above with your published Railway template URL. [Get a Novita API key](https://novita.ai/?ref=mzblm2z&utm_source=affiliate) (affiliate link; the publisher may earn a commission).

## Included models

| Client model | Novita model |
| --- | --- |
| `fast` | `meta-llama/llama-3.1-8b-instruct` |
| `smart` | `deepseek/deepseek-v3-0324` |
| `reasoning` | `deepseek/deepseek-r1-turbo` |

Only these aliases are exposed by `config.yaml`; no OpenAI or Anthropic credentials are accepted or required.

## Publish the Railway template

Railway templates are configured in Railway's template composer, not in a repository manifest:

1. Push this directory to its own GitHub repository.
2. In [Railway Templates](https://railway.com/workspace/templates), create a template with three services:
   - **Gateway** — this GitHub repository; under **Settings → Networking → Public Networking**, click **Generate Domain**. Saving the template from this configured project makes every deployment receive a public Railway domain by default.
   - **PostgreSQL** — Railway's PostgreSQL service.
   - **Redis** — Railway's Redis service.
3. Set the Gateway root directory to `/` (or `/products/litellm-novita-gateway` if publishing this monorepo).
4. Add these Gateway variables in the template settings:

| Variable | Template value |
| --- | --- |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
| `REDIS_URL` | `${{Redis.REDIS_URL}}` |
| `NOVITA_API_KEY` | Required user input; description: `Get a key: https://novita.ai/?ref=mzblm2z&utm_source=affiliate` |
| `LITELLM_MASTER_KEY` | `${{secret(48)}}` |
| `LITELLM_SALT_KEY` | `${{secret(48)}}` |
| `STORE_MODEL_IN_DB` | `False` |

5. Confirm only the Gateway has a generated public domain and publish. The repository already configures the health check and listening port through `railway.json`.

### Railway networking defaults

- **Listen address:** `0.0.0.0`
- **Port:** Railway's injected `PORT`; defaults to `4000` outside Railway
- **Health check:** `/health/liveliness`
- **Public URL:** `https://${RAILWAY_PUBLIC_DOMAIN}` after **Generate Domain** is enabled on the Gateway in the template composer

Railway does not support creating a public domain from `railway.json`; it must be enabled once in the template composer and is then inherited by template deployments. PostgreSQL and Redis must remain private.

`LITELLM_SALT_KEY` must never be changed after deployment because it encrypts stored credentials.

## Local run

```bash
cp .env.example .env
# Set NOVITA_API_KEY and replace both LiteLLM secrets in .env
docker compose up --build
```

Open the admin UI at <http://localhost:4000/ui> or call the OpenAI-compatible API:

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"fast","messages":[{"role":"user","content":"Hello"}]}'
```

Use the gateway from an OpenAI SDK by setting:

```text
OPENAI_BASE_URL=https://YOUR-GATEWAY.up.railway.app/v1
OPENAI_API_KEY=<a LiteLLM virtual key or the master key>
```

## Cache check

Send the same deterministic request twice, then inspect the second response headers for LiteLLM cache metadata. Redis connectivity is available at `GET /cache/ping` with the master key.

## Security

- Keep the Gateway service public; keep PostgreSQL and Redis private.
- Give applications virtual keys instead of the master key.
- Set budgets and rate limits in the LiteLLM admin UI.
- Do not enable `STORE_MODEL_IN_DB`: the checked-in allowlist prevents adding non-Novita providers through the UI.
