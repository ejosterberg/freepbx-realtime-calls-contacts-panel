# Translations

Each subdirectory is an [i18next](https://www.i18next.com/) locale.
The frontend auto-detects the user's browser language and falls back
to English.

## Translation status

| Locale | Language | Source | Reviewed by native speaker? |
|---|---|---|---|
| `en` | English (canonical) | Upstream (Alexander Droste) | N/A — source of truth |
| `de` | German (Deutsch) | Upstream (Alexander Droste) | ✅ Yes — author is German |
| `es` | Spanish (Español) | This fork — machine-assisted | ❌ Not yet — needs native review |
| `fr` | French (Français) | This fork — machine-assisted | ❌ Not yet — needs native review |
| `it` | Italian (Italiano) | This fork — machine-assisted | ❌ Not yet — needs native review |

**About the machine-assisted translations:** these are first-pass
translations produced with AI assistance against the canonical
English source. They use standard PBX terminology that's
consistent across the industry (Voicemail / Buzón de voz / Boîte
vocale / Segreteria, etc.) and should be 90-95% accurate for
typical usage. Edge cases — regional dialect preferences,
particularly idiomatic short labels — may benefit from native
review.

If you spot a translation that's off, please open a PR or issue at
[github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/issues](https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/issues).

## Adding a new language

1. Create a new directory with the BCP-47 language tag (e.g. `pl`,
   `ru`, `zh-CN`, `pt-BR`, `nl`)
2. Copy `en/translation.json` into it
3. Translate every value, keeping every key identical
4. **Important:** preserve interpolation tokens exactly as-is:
   - `{{val, datetime}}` must stay literal — i18next uses this for
     date formatting; translating "val" or "datetime" breaks it
5. Test the build with `npm run build` from the `frontend/`
   directory (no special steps — CRA picks up everything in
   `public/`)
6. Add a row to the table above so users know it exists
7. Open a PR

### Style guide

- **Short labels** (Buttons, headers): one or two words. Match the
  English brevity.
- **Sentences** (e.g. `removeContact.description`): translate
  fully and naturally; don't over-literal-translate.
- **PBX terms** (Voicemail, Caller ID, Extension): use the
  established industry term in your language. If unsure, look at
  how Sangoma's own Italian/Spanish/etc. FreePBX documentation
  translates the term.
- **`{{val, datetime}}` and other interpolation tokens**: NEVER
  modify. Copy verbatim from English.
