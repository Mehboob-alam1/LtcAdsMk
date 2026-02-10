# Remote Config – Ad parameters (Android only)

**remote_config_parameters.json** is in **Firebase Remote Config template format** so you can import it directly.

- **Import:** Firebase Console → your project → **Engage** → **Remote Config** → **⋮** (menu) → **Import** → choose this JSON file.
- **iOS** is not included; only Android ad unit IDs.

## If you add parameters manually instead

1. **Firebase Console** → your project → **Engage** → **Remote Config**.
2. For each key in the `parameters` section of the JSON:
   - Click **Add parameter**
   - **Parameter key** = exact key (e.g. `banner_adx_android`)
   - **Data type** = see table below
   - **Default value** = value from the JSON (or your own ad unit IDs)
3. **Publish** changes.

## Parameter types (set in Firebase)

| Type in Firebase | Keys |
|------------------|------|
| **String** | All `*_android` ad unit IDs (banner_adx_android, banner_admob_android, native_*, interstitial_*, rewarded_*, app_open_*). iOS omitted for now. |
| **Boolean** | `ads_enabled` – single switch to turn all ads on or off |
| **Number** | `interstitial_chance_percent`, `interstitial_min_interval_seconds`, `boost_multiplier_rewarded`, `boost_duration_minutes` |

For **Boolean** parameters, in Firebase set type **Boolean** and value `true` or `false` (not the string `"true"`).  
For **Number** parameters, set type **Number** and the numeric value.

## Values in the JSON

- The JSON uses **Google test ad unit IDs** so the app works without your own IDs.
- For production, replace those values with your real unit IDs from [AdMob](https://admob.google.com) and [Ad Manager](https://admanager.google.com).
- Ad unit ID format: `ca-app-pub-PUBLISHER_ID/AD_UNIT_ID` (same for AdMob and Ad Manager in most cases).

## Ad logic

The app loads **both** AdMob and AdX for each slot (banner, native, interstitial, rewarded, app open) and shows **whichever loads first**.
