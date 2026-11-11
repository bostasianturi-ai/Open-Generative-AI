---
name: generate-media
description: Generate or edit AI images, videos, audio, music and lip-sync clips with MuAPI's 600+ models (FLUX, Nano Banana, Seedream, Midjourney, Kling, Seedance, Veo, Wan, Hailuo, Suno and more). Use when the user asks to create, render, edit, upscale or animate an image or video, make a lip-sync, or generate audio or music.
---

# Generate media with MuAPI

MuAPI is the backend of the Open Generative AI app. Every model is one REST endpoint; jobs are async (submit, then poll).

## Setup

The user needs a MuAPI API key from https://muapi.ai, exported as `MUAPI_API_KEY` before Claude Code starts. If it is missing, tell the user and stop; never ask them to paste the key into chat.

## How to call it

Prefer the `muapi` MCP server tools bundled with this plugin when they are available (they cover generation, polling, uploads and account credits).

Otherwise use the bundled script, which submits, polls and optionally downloads:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/muapi-generate.sh" <endpoint> '<json body>' --download ./outputs
```

Upload a local file first to get a URL for image/video inputs:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/muapi-generate.sh" --upload ./photo.jpg
```

Raw API, if needed: `POST https://api.muapi.ai/api/v1/<endpoint>` with header `x-api-key`, JSON body → `request_id`; poll `GET /api/v1/predictions/<request_id>/result` until `status` is `completed` (or `failed`). Output URLs are in `outputs[]`.

## Picking a model

Look up the endpoint and its exact input fields in `references/models.md` (grep it; it is large). Use only the input names listed for that model. Good defaults:

| Task | Endpoint |
|---|---|
| Text to image | `nano-banana`, `flux-dev-image` |
| Image edit | `nano-banana-edit`, `kling-o3-image-edit` |
| Text to video | `seedance-v2.0-t2v`, `kling-v2.6-pro-t2v`, `veo3-fast-text-to-video` |
| Image to video | `veo3-fast-image-to-video`, `wan2.1-image-to-video` |
| Lip sync, audio, motion control | see those sections of the catalog |

Generation spends the user's MuAPI credits, and video can be expensive. Confirm before running large batches or long/high-resolution videos.

## Report back

Give the user the output URL(s) and any saved file paths, plus the model used.
