# Why ads might not show – checklist

## 1. **Firebase Remote Config – `ads_enabled`**
- In Firebase Console → Remote Config, ensure parameter **`ads_enabled`** is set to **`true`**.
- If it is `false`, the app will not load or show any ads.

## 2. **Ad unit IDs in Remote Config**
- All ad unit IDs come from Firebase Remote Config (with in-app defaults).
- In Firebase Console → Remote Config, check that these parameters exist and have valid IDs (or leave defaults):
  - **Android:** `banner_admob_android`, `banner_adx_android`, `interstitial_admob_android`, `interstitial_adx_android`, `rewarded_admob_android`, `rewarded_adx_android`, `native_admob_android`, `native_adx_android`, `app_open_admob_android`, `app_open_adx_android`
  - **iOS:** same names with `_ios` suffix
- If a parameter is missing or empty, the app now falls back to **test** ad unit IDs so ads can still load.

## 3. **Google AdMob / Ads app ID**
- **Android:** In `android/app/src/main/AndroidManifest.xml` there must be:
  ```xml
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
  ```
  Use your real App ID from AdMob for production. For testing you can use the test ID: `ca-app-pub-3940256099942544~3347511713`.
- **iOS:** In `ios/Runner/Info.plist` add (or check) `GADApplicationIdentifier` with your AdMob App ID.

## 4. **AdMob app and ad units**
- Create an app in [AdMob](https://admob.google.com) and get the **App ID** (used in manifest/Info.plist).
- Create ad units (Banner, Interstitial, Rewarded, Native, App Open) and use those IDs in Remote Config (or keep test IDs for development).

## 5. **When interstitial and app-open show**
- **Interstitial:** Shown only when `tryShowInterstitialRandomly()` runs (e.g. on some screen opens). It uses **chance %** and **min interval** from Remote Config (`interstitial_chance_percent`, default 28; `interstitial_min_interval_seconds`, default 55). So it does not show every time.
- **App open:** Shown only when the user **returns from background** after at least **30 seconds** away, and not again within **4 hours**. It does **not** show on cold start.
- If interstitial or app-open fail to load (both networks), the app retries after **15 seconds**.

## 6. **Load timing**
- Interstitial, Rewarded, and App Open ads load at startup; Withdraw Watch ad preloads rewarded when the screen and 20-ads dialog open. If the user taps “Watch ad” or a screen that shows an ad **before** the load finishes, the UI shows a message and triggers another load. “Ad is loading…” in that case.
- Wait a few seconds after opening the app before testing full-screen or rewarded ads.

## 7. **Network and “no fill”**
- Device must have internet. If the request fails (timeout, no fill, invalid request), the ad will not show. Test IDs usually have good fill; production IDs can have no fill in some regions or during testing.

## 8. **Logs**
- Run the app from terminal: `flutter run` and watch the console. Look for AdMob/Google Mobile Ads errors (e.g. “Invalid ad unit ID”, “No fill”, “Internal error”). Those messages explain why a specific ad did not show.

## Summary
Most often ads do not show because: **`ads_enabled` is false**, **wrong or missing App ID** in manifest/Info.plist, **ad unit IDs missing or wrong** in Remote Config, or **ads not finished loading** when the user tries to open them. Use the checklist above and the console logs to narrow it down.
