# discourse-zkill-embed

`discourse-zkill-embed` adds a server-side Onebox for standalone zKillboard killmail URLs such as `https://zkillboard.com/kill/136795801/`. Matching links are rendered as compact cards with ship, victim, final blow, system, kill time, total ISK value, and a link back to zKillboard.

## Installation

Clone the plugin into your Discourse app:

```bash
cd /var/discourse
git clone https://github.com/example/discourse-zkill-embed.git plugins/discourse-zkill-embed
./launcher rebuild app
```

## How it works

- Matches only `http` or `https` killmail URLs on `zkillboard.com` or `www.zkillboard.com` with numeric kill IDs.
- Fetches the killmail from `https://zkillboard.com/api/killID/<kill_id>/`.
- Resolves ship, system, character, corporation, and alliance names through ESI `universe/names`.
- Uses `https://images.evetech.net/types/<type_id>/render?size=128` for the ship thumbnail.

## Admin settings

- `zkillboard_onebox_enabled`: master on/off switch. Default `true`.
- `zkillboard_onebox_cache_ttl_hours`: cache lifetime for successful upstream data. Default `12`.
- `zkillboard_onebox_request_timeout_seconds`: outbound request timeout. Default `5`.
- `zkillboard_onebox_show_ship_image`: show or hide the ship render. Default `true`.

## Caching, rate limits, and failures

Successful upstream responses are cached through `Discourse.cache`. Failed or missing lookups are cached for 10 minutes to avoid repeated retries. If the upstream request fails or the payload cannot be parsed, the Onebox returns blank HTML so Discourse leaves the plain link in place.

## Security notes

- Only fixed HTTPS endpoints are requested.
- Kill IDs are validated as integers before use.
- Remote text is escaped before rendering.
- No remote HTML or JavaScript is rendered.
- Image URLs are generated only from numeric EVE type IDs on `images.evetech.net`.

## Testing

This repository includes fixture-backed `minitest/spec` coverage for matching, parsing, escaping, fallback handling, and cache behavior.

```bash
ruby -Ilib:spec spec/run_all.rb
```

If you are testing inside a Discourse checkout, also verify a real cooked post with the example URL above.

## Troubleshooting

- Check site settings if links stay plain.
- Review Rails logs for `[discourse-zkill-embed]` warnings.
- Confirm outbound HTTPS access to `zkillboard.com`, `esi.evetech.net`, and `images.evetech.net`.
