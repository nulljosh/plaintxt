#!/bin/sh
# Landing page → plain.jaybulb.com. Screenshots are copied in, not linked, so the
# deploy stays one folder.
cd "$(dirname "$0")" && mkdir -p landing/screenshots && cp screenshots/*.png landing/screenshots/ && cp icon.svg landing/
env -u CLOUDFLARE_API_TOKEN npx wrangler deploy
