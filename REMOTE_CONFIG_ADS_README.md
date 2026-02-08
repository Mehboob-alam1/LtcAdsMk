# Remote Config – Ad IDs JSON

Use **remote_config_ad_ids.json** as a reference when setting up Firebase Remote Config.

## How to use

1. **Replace placeholders** in the JSON:
   - `XXXXXXXX` = your AdMob/ADX **publisher ID** (e.g. `3940256099942544`)
   - `YYYYYYYYYY` = your **ad unit ID** for that format (e.g. `6300978111` for banner)

2. **In Firebase Console** → your project → **Engage** → **Remote Config**:
   - Click **Add parameter**
   - **Parameter name** = exact key from the JSON (e.g. `banner_adx_android`)
   - **Default value** = the value from the JSON (after you replaced placeholders)
   - Repeat for every key you use

3. **Publish** your changes in Remote Config.

## Keys overview

| Prefix   | Use |
|----------|-----|
| `*_adx_*`    | ADX (Google Ad Manager) – primary |
| `*_admob_*`  | AdMob – fallback |
| `*_enabled`  | Turn that ad type on/off (`"true"` or `"false"`) |

Replace the placeholder IDs with your real unit IDs from [AdMob](https://admob.google.com) and [Ad Manager](https://admanager.google.com).
