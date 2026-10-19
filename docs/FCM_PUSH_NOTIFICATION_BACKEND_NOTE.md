# SWR-PMIS — Push Notification Backend Note

**To:** Backend Developer  
**From:** Mobile / Firebase setup  
**Project:** SWR-PMIS (`swrpmismobile`)  
**Date:** 19 Oct 2026  
**Status:** Mobile Android + iOS wired. Web Firebase app + Web Push key pair created. Backend must support token storage and FCM send for **android**, **ios**, and **web**.

---

## 1. Goal

One Firebase project sends push notifications to:

| Client | Platform value |
|--------|----------------|
| Android app | `android` |
| iOS app | `ios` |
| SWR Web application | `web` |

Clients register their FCM token after login. Backend stores tokens per user and sends messages with **Firebase Cloud Messaging HTTP v1**.

---

## 2. Firebase (already done on client side)

| Item | Value / status |
|------|----------------|
| Firebase project | `swrpmismobile` |
| Sender / project number | `945704282160` |
| FCM API (V1) | **Enabled** (use this only; Legacy is disabled) |
| Android app | Package `com.synergiz.swr.pmis` |
| iOS app | Bundle `com.synergiz.swrpmismobile` (APNs auth key uploaded) |
| Web app | **Created** in Firebase |
| Web Push certificates (VAPID) | **Key pair generated** (web team uses this in the browser; backend does **not** need the VAPID key to send) |

### What backend needs from Firebase

1. Open Firebase Console → project **swrpmismobile** → ⚙ **Project settings** → **Service accounts**.
2. Click **Generate new private key** → download the JSON service-account file.
3. Store that JSON **only on the server** (secret / env / vault). Never put it in mobile or web source code.
4. Use this service account with **FCM HTTP v1** to send messages.

Backend does **not** need the Web Push VAPID public key for sending. That key is only for the web frontend when calling `getToken()`.

---

## 3. Token register / deactivate APIs (mobile already calls these)

### Base URLs

| Env | Base |
|-----|------|
| QA | `http://115.124.125.151:8443/swrpmis_qa/` |
| Prod | `http://115.124.125.151:8444/swrpmis/` |

### Endpoints

| Action | Method | Path |
|--------|--------|------|
| Register / update token | `POST` | `wcr/device-tokens/register` |
| Deactivate token (logout) | `POST` | `wcr/device-tokens/deactivate` |

Full examples (QA):

- `POST http://115.124.125.151:8443/swrpmis_qa/wcr/device-tokens/register`
- `POST http://115.124.125.151:8443/swrpmis_qa/wcr/device-tokens/deactivate`

### Auth

- Request is sent **after login**.
- Use the same session as the rest of SWR (Bearer token and/or session cookie).
- **User id is not in the body.** Resolve the user from the authenticated session.

### JSON body (same for register and deactivate)

```json
{
  "fcmToken": "<FCM registration token string>",
  "platform": "android",
  "deviceId": "<stable install/browser uuid>"
}
```

| Field | Type | Notes |
|-------|------|--------|
| `fcmToken` | string | FCM token from Android, iOS, or Web |
| `platform` | string | One of: `android`, `ios`, `web` |
| `deviceId` | string | Client-generated UUID (not hardware ID). Used to upsert the row for that install/browser |

### Expected behaviour

**On register**

1. Identify logged-in user from session.
2. Upsert by (`userId` + `deviceId`) or by `fcmToken`.
3. Save: `userId`, `fcmToken`, `platform`, `deviceId`, `active = true`, `updatedAt`.
4. One user may have **multiple** active tokens (phone + browser + another phone).

**On deactivate (logout)**

1. Same body.
2. Mark that token / device row `active = false` (or delete it).
3. Stop sending to that token.

**Web**

- Web will call the **same** APIs with `"platform": "web"`.
- No separate web-only register URL is required unless you prefer one; same contract is enough.

---

## 4. Sending a notification (FCM HTTP v1)

### Rule

- Use **FCM HTTP v1 only** (project already has V1 enabled).
- Do **not** use the legacy FCM server key API.
- Authenticate with the Firebase **service account** for `swrpmismobile`.
- Send **one message per active token** for the target user(s) (or use multicast / batch as your stack supports).

### Suggested message shape

Include both:

1. **`notification`** — title + body (shown by OS / browser when app/tab is in background).
2. **`data`** — string key/values for deep link / routing when the user taps.

Example conceptual payload:

```json
{
  "message": {
    "token": "<stored fcmToken>",
    "notification": {
      "title": "New RFI created",
      "body": "RFI RFI-123 has been created"
    },
    "data": {
      "type": "RFI_CREATED",
      "referenceType": "RFI",
      "referenceId": "123",
      "userId": "<targetUserId>"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "swr_pmis_default"
      }
    }
  }
}
```

### Notes per platform

| Platform | Notes |
|----------|--------|
| Android | Use notification channel id `swr_pmis_default` (mobile app creates this channel). |
| iOS | APNs is already linked in Firebase for `com.synergiz.swrpmismobile`. No extra APNs work on backend. |
| Web | Same FCM v1 send to the web token. No Android channel. Browser shows the notification via the service worker. |

### `data` fields used by the mobile app

All `data` values must be **strings**.

| Key | Required | Purpose |
|-----|----------|---------|
| `type` | Yes | Event type for routing |
| `referenceType` | Optional | Fallback routing context |
| `referenceId` | Optional | Entity id (e.g. RFI / inspection id) |
| `userId` | Recommended | If present, mobile ignores the tap when it does not match the logged-in user |

### Known `type` values (mobile already maps these)

- `RFI_CREATED`
- `RFI_UPDATED`
- `RFI_CLOSED`
- `RFI_DELETED`
- `RFI_INSPECTION`
- `RFI_VALIDATION`
- `QUALITY_INSPECTION`
- `PROGRESS_VALIDATION_APPROVED`
- `PROGRESS_VALIDATION_REJECTED`

Web can reuse the same `type` / `referenceId` values for opening the matching web page.

---

## 5. End-to-end process

```
[User logs in on Android / iOS / Web]
        ↓
[Client gets FCM token from Firebase]
        ↓
[Client POST /wcr/device-tokens/register]
  body: { fcmToken, platform, deviceId }
  auth: session / Bearer
        ↓
[Backend stores active token for that user]
        ↓
[Business event: e.g. RFI created]
        ↓
[Backend loads all active tokens for target user(s)]
        ↓
[Backend sends FCM HTTP v1 message per token]
        ↓
[Firebase delivers to device / browser]
        ↓
[User taps → client opens screen from data.type / referenceId]
```

On logout:

```
[Client POST /wcr/device-tokens/deactivate]
        ↓
[Backend marks token inactive]
```

---

## 6. Backend checklist

- [ ] Implement / confirm `POST wcr/device-tokens/register`
- [ ] Implement / confirm `POST wcr/device-tokens/deactivate`
- [ ] Accept `platform`: `android` | `ios` | `web`
- [ ] Bind token to user from session (not from body)
- [ ] Support multiple active tokens per user
- [ ] Store Firebase service-account JSON securely for project `swrpmismobile`
- [ ] Send with **FCM HTTP v1** only
- [ ] Include `notification` + `data` (`type`, optional `referenceId`, `userId`)
- [ ] Android: set channel `swr_pmis_default`
- [ ] On invalid/expired token response from FCM, mark that token inactive

---

## 7. What is **not** backend responsibility

| Item | Owner |
|------|--------|
| `google-services.json` / `GoogleService-Info.plist` | Mobile |
| APNs `.p8` upload in Firebase | Mobile / Firebase admin (done) |
| Web Push VAPID key in frontend `getToken()` | Web team (key pair already generated) |
| Service worker `firebase-messaging-sw.js` | Web team |
| Asking browser/OS notification permission | Mobile / Web clients |

---

## 8. Quick test plan for backend

1. Log in on **mobile** → confirm register hits `wcr/device-tokens/register` and a row is saved with `platform` `android` or `ios`.
2. Log in on **web** → confirm register with `platform: "web"`.
3. Trigger a test send (or real event) to that user.
4. Confirm notification appears on phone and/or browser.
5. Log out → deactivate called → further sends do not go to that token.
6. If FCM returns `UNREGISTERED` / invalid token, deactivate that row automatically.

---

## 9. Contact / references

- Firebase project id: `swrpmismobile`
- Sender id: `945704282160`
- Mobile package: `com.synergiz.swr.pmis`
- iOS bundle: `com.synergiz.swrpmismobile`
- Register path: `wcr/device-tokens/register`
- Deactivate path: `wcr/device-tokens/deactivate`

If register/deactivate APIs do not exist yet on the SWR host, please implement them with the contract above so mobile and web can share one backend flow.
