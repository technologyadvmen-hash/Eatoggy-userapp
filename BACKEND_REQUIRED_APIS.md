# 🔴 EATOGGY — Backend APIs To Be Deployed
**Production Server URL**: `https://api.eatoggy.in/api`  
**Authentication**: Bearer JWT (`Authorization: Bearer <customer_token>`)  
**Date**: September 30, 2026  

All endpoints below currently return **404 Route not found** on production. The mobile app is ready to consume these — they just need to be deployed.

---

## Summary

| # | Endpoint | Method | Priority | Feature |
|:-:|:---------|:------:|:--------:|:--------|
| 1 | `/api/checkout/verify-payment` | `POST` | 🔴 P0 | Verify Razorpay payment for food orders |
| 2 | `/api/customers/preferences` | `PATCH` | 🔴 P0 | Customer notification preferences |
| 3 | `/api/notifications/subscribe` | `POST` | 🔴 P0 | Register FCM push token |
| 4 | `/api/categories` | `GET` | 🟠 P1 | Food category filter pills |
| 5 | `/api/cart/apply-coupon` | `POST` | 🟠 P1 | Validate & apply coupon to cart |
| 6 | `/api/customer-auth/me` | `PATCH` | 🟠 P1 | Update profile (name, email) |
| 7 | `/api/customers/addresses/:id` | `PATCH` | 🟠 P1 | Edit address / set default |
| 8 | `/api/customer-auth/account` | `DELETE` | 🟡 P2 | Delete customer account (Apple Store mandatory) |
| 9 | `/api/serviceability/check` | `GET` | 🟡 P2 | GPS delivery area geofence check |
| 10 | `/api/public/config` | `GET` | 🟡 P2 | Runtime config (Razorpay & Maps API keys) |

---

## 🔴 Priority 0 — Critical Blockers

---

### 1. Food Order Payment Verification
* **Method**: `POST`
* **Route**: `/api/checkout/verify-payment`
* **Auth**: Bearer JWT
* **Why It Is Critical**:
  Subscription verify (`/api/customers/subscriptions/verify-payment`) works, but regular food cart checkouts have no verification endpoint. After Razorpay payment on the phone, the app needs this to:
  1. Verify the Razorpay HMAC SHA256 signature.
  2. Transition order status from `PENDING_PAYMENT` to `CONFIRMED`.
  3. Auto-clear the customer's cart in the database.
  4. Dispatch order event to the kitchen dashboard.

* **Request Body** (`application/json`):
  ```json
  {
    "checkoutSessionId": "chk_session_65f1234abcd",
    "razorpayOrderId": "order_EK53Ju3rO1cu12",
    "razorpayPaymentId": "pay_EK53nIPlb2p123",
    "razorpaySignature": "9f83cf134c8a29a6fb514be8c8942b08a1c97a523b092248557a53f2253818e6"
  }
  ```

* **Expected Response** (`200 OK`):
  ```json
  {
    "success": true,
    "message": "Payment verified and order confirmed successfully",
    "data": {
      "order": {
        "id": "6aba43dcd4360b9e1933b2b9",
        "orderNumber": "#EAT-2026-98102",
        "status": "CONFIRMED",
        "paymentStatus": "PAID",
        "grandTotal": 485.0,
        "placedAt": "2026-09-30T10:15:30Z",
        "estimatedDelivery": "30-40 mins"
      }
    }
  }
  ```

---

### 2. Customer Notification Preferences
* **Method**: `PATCH`
* **Route**: `/api/customers/preferences`
* **Auth**: Bearer JWT
* **Why It Is Critical**:
  The Settings screen has toggles for Push, Email, and SMS/WhatsApp notifications. The backend must store opt-out flags so automated cron jobs respect user consent (TRAI DND compliance in India).

* **Request Body** (`application/json`):
  ```json
  {
    "pushNotifications": true,
    "emailNotifications": false,
    "smsWhatsappAlerts": true
  }
  ```

* **Expected Response** (`200 OK`):
  ```json
  {
    "success": true,
    "message": "Notification preferences updated successfully",
    "data": {
      "preferences": {
        "pushNotifications": true,
        "emailNotifications": false,
        "smsWhatsappAlerts": true
      }
    }
  }
  ```

* **Also needed**: `GET /api/customers/preferences` to fetch current settings (or include in `GET /api/customer-auth/me`).

---

### 3. Register FCM Push Token
* **Method**: `POST`
* **Route**: `/api/notifications/subscribe`
* **Auth**: Bearer JWT
* **Why It Is Critical**:
  Without this, the server cannot send push notifications for order status changes (Preparing → Rider Assigned → Out for Delivery → Delivered).

* **Request Body** (`application/json`):
  ```json
  {
    "fcmToken": "f7Z_abc123d4e5f6g7h8_sample_device_fcm_token...",
    "platform": "android",
    "deviceModel": "Pixel 7 Pro",
    "appVersion": "4.12.0"
  }
  ```

* **Expected Response** (`200 OK`):
  ```json
  {
    "success": true,
    "message": "Device token registered successfully"
  }
  ```

---

## 🟠 Priority 1 — Core Customer Flows

---

### 4. Food Category Filter Pills
* **Method**: `GET`
* **Route**: `/api/categories`
* **Auth**: Public or Bearer JWT

* **Expected Response** (`200 OK`):
  ```json
  {
    "success": true,
    "data": [
      { "id": "cat_01", "name": "Premium Thali", "slug": "premium-thali", "icon": "thali_icon_url" },
      { "id": "cat_02", "name": "Biryani & Rice", "slug": "biryani", "icon": "biryani_icon_url" },
      { "id": "cat_03", "name": "Gourmet Curries", "slug": "curries", "icon": "curry_icon_url" }
    ]
  }
  ```

---

### 5. Apply Coupon to Cart
* **Method**: `POST`
* **Route**: `/api/cart/apply-coupon`
* **Auth**: Bearer JWT
* **Note**: The coupon code comes from `GET /api/offers` (which is already live). This endpoint validates and applies it server-side.

* **Request Body** (`application/json`):
  ```json
  {
    "couponCode": "ROYAL50",
    "cartAmount": 450.0
  }
  ```

* **Expected Response** (`200 OK`):
  ```json
  {
    "success": true,
    "message": "Coupon ROYAL50 applied successfully",
    "data": {
      "couponCode": "ROYAL50",
      "discountAmount": 125.0,
      "subtotal": 450.0,
      "newTotal": 325.0
    }
  }
  ```

---

### 6. Update Customer Profile
* **Method**: `PATCH`
* **Route**: `/api/customer-auth/me`
* **Auth**: Bearer JWT
* **Note**: `GET /api/customer-auth/me` works. `PATCH` returns 404.

* **Request Body** (`application/json`):
  ```json
  {
    "name": "Dhruva Kumar",
    "email": "dhruva@example.com"
  }
  ```

* **Expected Response** (`200 OK`):
  ```json
  {
    "success": true,
    "message": "Profile updated successfully",
    "data": {
      "customer": {
        "id": "6abccd8d99a9de948d4e8aea",
        "name": "Dhruva Kumar",
        "email": "dhruva@example.com",
        "mobile": "9324259293"
      }
    }
  }
  ```

---

### 7. Update / Set Default Address
* **Method**: `PATCH`
* **Route**: `/api/customers/addresses/:id`
* **Auth**: Bearer JWT
* **Note**: `GET`, `POST`, `DELETE` all work. Only `PATCH` returns 404.

* **Request Body** (`application/json`):
  ```json
  {
    "isDefault": true,
    "addressLine1": "Flat 402, Royal Imperial Towers",
    "landmark": "Near Main Gate"
  }
  ```

* **Expected Response** (`200 OK`):
  ```json
  {
    "success": true,
    "message": "Address updated successfully"
  }
  ```

---

## 🟡 Priority 2 — Compliance & Operations

---

### 8. Delete Customer Account
* **Method**: `DELETE`
* **Route**: `/api/customer-auth/account`
* **Auth**: Bearer JWT
* **Why It Is Critical**: Apple App Store Guideline 5.1.1(v) — apps **must** allow account deletion or they get rejected.

* **Request Body** (`application/json`):
  ```json
  {
    "reason": "Not using the app anymore"
  }
  ```

* **Expected Response** (`200 OK`):
  ```json
  {
    "success": true,
    "message": "Account deletion scheduled. All personal data will be purged in 30 days."
  }
  ```

---

### 9. Delivery Serviceability Check
* **Method**: `GET`
* **Route**: `/api/serviceability/check?lat={lat}&lng={lng}`
* **Auth**: Public or Bearer JWT

* **Expected Response** (`200 OK`):
  ```json
  {
    "success": true,
    "data": {
      "isServiceable": true,
      "estimatedDeliveryMinutes": 35,
      "kitchenHub": "South Delhi Hub",
      "deliveryFee": 30.0
    }
  }
  ```

---

### 10. Runtime App Config (API Keys)
* **Method**: `GET`
* **Route**: `/api/public/config`
* **Auth**: Public (No JWT)
* **Why It Is Needed**: Prevents hardcoding Razorpay and Google Maps keys in the APK. Allows instant key rotation without app store update.

* **Expected Response** (`200 OK`):
  ```json
  {
    "success": true,
    "data": {
      "razorpayKey": "rzp_live_abc123xyz",
      "googleMapsApiKey": "AIzaSyD-sample-maps-key-here",
      "supportPhoneNumber": "+919324259293",
      "supportEmail": "support@eatoggy.in",
      "minAppVersion": "4.10.0",
      "forceUpdate": false,
      "maintenanceMode": false
    }
  }
  ```
