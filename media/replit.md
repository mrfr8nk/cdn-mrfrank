# SubZero MD - WhatsApp Bot

Advanced multi-device WhatsApp bot built with Node.js (JavaScript).

## Tech Stack
- **Runtime**: Node.js 20 (ESM modules)
- **WhatsApp**: @whiskeysockets/baileys
- **Media**: ffmpeg, sharp, jimp, wa-sticker-formatter
- **Database**: JSON (default), MongoDB, PostgreSQL, MySQL, or SQLite3
- **AI**: OpenAI GPT, Llama, Mistral integrations
- **Other**: express (keep-alive server), pino (logging), C++ compiled utilities

## Project Structure
- `index.js` — Main entry point, WhatsApp connection & session management
- `config.js` — Bot configuration loader
- `settings.js` — Environment variable mappings
- `lib/` — Core logic (commandHandler, messageHandler, sticker, session, etc.)
- `plugins/` — 298 feature plugins (ai-gpt, youtube-dl, sticker, alive, etc.)
- `assets/` — Media files (thumbnails, intro images)
- `data/` — Local JSON database storage (if no external DB configured)
- `test/` — Vitest unit and integration tests

## Running the Bot
```bash
npm start           # Start normally
npm run start:optimized   # Start with memory optimizations
npm run reset-data  # Reset bot data
npm run reset-session     # Clear WhatsApp session
```

## Configuration
Copy `sample.env` to `.env` and fill in:
- `SESSION_ID` — WhatsApp session (required, or use `PAIRING_NUMBER`)
- `PAIRING_NUMBER` — Phone number for pairing code login
- `OWNER_NUMBER` — Bot owner's phone number
- `PREFIXES` — Command prefixes (default: `.,!,/`)
- `COMMAND_MODE` — `private`, `public`, or `group`
- `MONGO_URL` / `POSTGRES_URL` / `MYSQL_URL` / `DB_URL` — Optional database

## Architecture Notes
- **No build step**: Project runs directly as JavaScript (converted from TypeScript)
- **Plugin system**: Hot-reloads plugins from `plugins/` directory
- **C++ utilities**: Auto-compiled at startup (`dna`, `cipher`, `rle`, `analyze`)
- **Multi-device**: Supports WhatsApp multi-device via Baileys library
