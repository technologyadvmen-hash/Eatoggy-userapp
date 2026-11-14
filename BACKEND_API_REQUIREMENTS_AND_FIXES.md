# 🛠️ EATOGGY — Backend API Specification & Required Action Guide
**Prepared for**: Backend Engineering Team & Tech Leads  
**Server Environment**: Production (`https://api.eatoggy.in/api`)  
**Stack**: Node.js / Express.js / MongoDB (Mongoose) / Razorpay  
**Date**: October 7, 2026  
**Document Purpose**: Complete, copy-paste ready API specification, schemas, and Express controller implementations required to support the new mobile UI/UX release.

---

## 📌 Table of Contents
1. [Executive Action Checklist (Do This First)](#1-executive-action-checklist-do-this-first)
2. [P0 Critical Blockers (Must Deploy Immediately)](#2-p0-critical-blockers-must-deploy-immediately)
   - [2.1 Food Order Razorpay Payment Verification](#21-food-order-razorpay-payment-verification-p0)
   - [2.2 Apple App Store Mandatory Account Deletion](#22-apple-app-store-mandatory-account-deletion-p0)
   - [2.3 Unblock Guest Users on Discovery Routes](#23-unblock-guest-users-on-discovery-routes-p0)
   - [2.4 MongoDB Test Data Sanitization & Seeding](#24-mongodb-test-data-sanitization--seeding-p0)
3. [P1 Required New Endpoints & Updates (Matching New UI/UX)](#3-p1-required-new-endpoints--updates-matching-new-uiux)
   - [3.1 Customer Notification Center](#31-customer-notification-center)
   - [3.2 Live Valet GPS Tracking](#32-live-valet-gps-tracking)
   - [3.3 Order Multi-Category Review & Ratings](#33-order-multi-category-review--ratings)
   - [3.4 Customer Profile Update](#34-customer-profile-update)
   - [3.5 Checkout Initiation Payload Updates](#35-checkout-initiation-payload-updates)
   - [3.6 Subscription Customization Updates](#36-subscription-customization-updates)
   - [3.7 Dynamic Offers & Coupon Validation](#37-dynamic-offers--coupon-validation)
   - [3.8 App Initialization & System Status (Edge Cases)](#38-app-initialization--system-status-edge-cases)
   - [3.9 Dynamic Legal Documents](#39-dynamic-legal-documents)
   - [3.10 Sync Customer Preferences](#310-sync-customer-preferences)
4. [P2 Supporting Services](#4-p2-supporting-services)
   - [4.1 Location Geofence & Serviceability Check](#41-location-geofence--serviceability-check)
   - [4.2 Device Push Notification Registration](#42-device-push-notification-registration)
5. [Master API Status Reference Table](#5-master-api-status-reference-table)

---

## 1. Executive Action Checklist (Do This First)

| Priority | Task | Affected Flow | Current Blocker |
| :---: | :--- | :--- | :--- |
| **P0** | Deploy `POST /api/checkout/verify-payment` | Regular Food Cart Checkout | Returns **404**. Customers cannot pay for food online. |
| **P0** | Deploy `DELETE /api/customer-auth/account` | Settings → Delete Account | Returns **404**. Mandatory for Apple App Store (Guideline 5.1.1). |
| **P0** | Remove `authCustomer` middleware from `/api/customers/discovery/*` | App Launch & Guest Browsing | Returns **401 Unauthorized** before user signs in. |
| **P0** | Purge empty `{ _id }` documents in `restaurants` collection | Home & Search Screens | Corrupted test documents crash mobile UI lists. |
| **P1** | Deploy `GET /api/customer/notifications` | Notifications Screen (`c30`) | Brand new UI screen with no backend support. |
| **P1** | Deploy `GET /api/customers/orders/tracking/:orderId` | Live Map Tracking (`c22`) | Returns **404**. App is forced to use mock GPS coords. |
| **P1** | Deploy `POST /api/customers/orders/:orderId/review` | Write Review Screen (`c34`) | Route missing. Customers cannot submit food/valet feedback. |
| **P1** | Deploy `PATCH /api/customer-auth/me` | Profile Screen (`c31`) | Returns **404**. Users cannot edit name/email/dietary preferences. |

---

## 2. P0 Critical Blockers (Must Deploy Immediately)

### 2.1 Food Order Razorpay Payment Verification (P0)

* **Route**: `POST /api/checkout/verify-payment`
* **Auth**: `authCustomer` (Bearer JWT)
* **Status**: 🔴 Currently returns `HTTP 404 Route Not Found`
* **Description**: Verifies Razorpay HMAC SHA256 payment signature, transitions order from `PENDING` to `CONFIRMED`, and clears the customer's cart.

#### Request Body (`application/json`):
```json
{
  "checkoutSessionId": "chk_session_65f1234abcd",
  "razorpayOrderId": "order_EK53Ju3rO1cu12",
  "razorpayPaymentId": "pay_EK53nIPlb2p123",
  "razorpaySignature": "9f83cf134c8a29a6fb514be8c8942b08a1c97a523b092248557a53f2253818e6"
}
```

#### Expected Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "Payment verified and order confirmed successfully",
  "data": {
    "order": {
      "id": "67041a8e9b21f311a8c90012",
      "orderNumber": "#EAT-84920",
      "status": "CONFIRMED",
      "paymentStatus": "PAID",
      "grandTotal": 407.45,
      "placedAt": "2026-10-07T12:30:00.000Z",
      "estimatedDelivery": "30-40 mins"
    }
  }
}
```

#### Node.js / Express Controller Implementation:
```javascript
const crypto = require('crypto');

exports.verifyPayment = async (req, res) => {
  try {
    const { checkoutSessionId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;
    const customerId = req.user.id;

    if (!checkoutSessionId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({ success: false, message: 'All payment fields are required' });
    }

    // 1. Verify Razorpay HMAC SHA256 Signature
    const body = razorpayOrderId + "|" + razorpayPaymentId;
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(body.toString())
      .digest('hex');

    if (expectedSignature !== razorpaySignature) {
      return res.status(400).json({ success: false, message: 'Invalid payment signature. Verification failed.' });
    }

    // 2. Fetch checkout session
    const session = await CheckoutSession.findById(checkoutSessionId);
    if (!session) {
      return res.status(404).json({ success: false, message: 'Checkout session not found' });
    }

    // 3. Create confirmed Order
    const order = await Order.create({
      customerId,
      orderNumber: `#EAT-${Date.now().toString().slice(-5)}`,
      items: session.items,
      subtotal: session.subtotal,
      deliveryFee: session.deliveryFee || 40.0,
      taxesAndSurcharges: session.taxesAndSurcharges || 18.45,
      discount: session.discount || 0.0,
      grandTotal: session.grandTotal,
      address: session.deliveryAddress,
      deliverySlot: session.deliverySlot,
      status: 'CONFIRMED',
      paymentStatus: 'PAID',
      paymentDetails: {
        gateway: 'RAZORPAY',
        paymentId: razorpayPaymentId,
        orderId: razorpayOrderId,
      },
      placedAt: new Date(),
      estimatedDelivery: '30-40 mins'
    });

    // 4. Auto-clear customer cart
    await Cart.findOneAndUpdate({ customerId }, { $set: { items: [], subtotal: 0 } });

    return res.status(200).json({
      success: true,
      message: 'Payment verified and order confirmed successfully',
      data: {
        order: {
          id: order._id,
          orderNumber: order.orderNumber,
          status: order.status,
          paymentStatus: order.paymentStatus,
          grandTotal: order.grandTotal,
          placedAt: order.placedAt,
          estimatedDelivery: order.estimatedDelivery
        }
      }
    });
  } catch (error) {
    console.error('Payment verification error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error during verification' });
  }
};
```

---

### 2.2 Apple App Store Mandatory Account Deletion (P0)

* **Route**: `DELETE /api/customer-auth/account`
* **Auth**: `authCustomer` (Bearer JWT)
* **Status**: 🔴 Currently returns `HTTP 404 Route Not Found`
* **Legal Obligation**: **Apple Store Guideline 5.1.1**. Any app allowing account registration MUST provide account deletion in-app.

#### Expected Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "Customer account and associated personal data deleted successfully"
}
```

#### Node.js / Express Controller Implementation:
```javascript
exports.deleteAccount = async (req, res) => {
  try {
    const customerId = req.user.id;

    // Remove or anonymize customer records
    await Customer.findByIdAndDelete(customerId);
    await Address.deleteMany({ customerId });
    await Cart.deleteMany({ customerId });
    // Soft-delete or anonymize orders to keep financial audit trail intact
    await Order.updateMany({ customerId }, { $set: { customerDeleted: true } });

    return res.status(200).json({
      success: true,
      message: 'Customer account and associated personal data deleted successfully'
    });
  } catch (error) {
    console.error('Account deletion error:', error);
    return res.status(500).json({ success: false, message: 'Failed to delete account' });
  }
};
```

---

### 2.3 Unblock Guest Users on Discovery Routes (P0)

* **Issue**: Unauthenticated guest opening the mobile app receives:
  ```http
  HTTP/1.1 401 Unauthorized
  {"message": "No token, authorization denied"}
  ```
* **Fix**: Remove `authCustomer` / `verifyToken` middleware from discovery routes in `routes/discoveryRoutes.js`:

```javascript
// BEFORE (BROKEN - Blocks guests):
router.get('/customers/discovery/restaurants', authCustomer, discoveryController.getRestaurants);
router.get('/customers/discovery/restaurants/:id/menu', authCustomer, discoveryController.getMenu);
router.get('/customers/discovery/banners', authCustomer, discoveryController.getBanners);
router.get('/customers/discovery/collections', authCustomer, discoveryController.getCollections);
router.get('/customers/discovery/gourmet', authCustomer, discoveryController.getGourmetDishes);

// AFTER (CORRECT - Allows public browsing):
router.get('/customers/discovery/restaurants', discoveryController.getRestaurants);
router.get('/customers/discovery/restaurants/:id/menu', discoveryController.getMenu);
router.get('/customers/discovery/banners', discoveryController.getBanners);
router.get('/customers/discovery/collections', discoveryController.getCollections);
router.get('/customers/discovery/gourmet', discoveryController.getGourmetDishes);
```

---

### 2.4 MongoDB Test Data Sanitization & Seeding (P0)

1. **Delete corrupted test documents**:
   ```javascript
   await Restaurant.deleteMany({
     $or: [
       { restaurantName: { $exists: false } },
       { restaurantName: null },
       { restaurantName: "" },
       { restaurantName: /jshmf/i },
       { restaurantName: /test/i }
     ]
   });
   ```

2. **Required Schema Fields for Mobile UI Rendering**:
   ```typescript
   interface IRestaurant {
     _id: ObjectId;
     restaurantName: string;       // e.g. "Hotel Maithili"
     cuisine: string;              // e.g. "Pure Veg, North Indian, Thali"
     city: string;                 // e.g. "Lutyens' Delhi"
     fullAddress: string;          // e.g. "Plot 42, Sector 29, Gurugram"
     rating: number;               // e.g. 4.5
     ratingCount: string;          // e.g. "12K+ ratings"
     deliveryTime: string;         // e.g. "25-35 mins"
     distance: string;             // e.g. "2.4 km"
     costForTwo: string;           // e.g. "₹350 for two"
     isPureVeg: boolean;           // true or false
     isHygieneVerified: boolean;   // true
     offerText: string;            // e.g. "50% OFF upto ₹100"
     image: string;                // Public HTTPS image URL
   }
   ```

---

## 3. P1 Required New Endpoints & Updates (Matching New UI/UX)

### 3.1 Customer Notification Center

* **Screen Reference**: `EATOGGY SVG Layout/c30-notifications.svg`
* **Features in UI**: Filter tabs (`All`, `Offers`, `Orders`, `System`), "Mark All Read" action button.

#### A. Fetch Customer Notifications
* **Method**: `GET`
* **Route**: `/api/customer/notifications`
* **Auth**: `authCustomer` (Bearer JWT)
* **Query Parameters**:
  - `category`: `ALL` | `OFFERS` | `ORDERS` | `SYSTEM` (Optional, defaults to `ALL`)
  - `page`: `1`
  - `limit`: `20`

**Response (`200 OK`)**:
```json
{
  "success": true,
  "data": {
    "unreadCount": 3,
    "notifications": [
      {
        "id": "notif_001",
        "category": "ORDERS",
        "title": "Royal Feast Out For Delivery",
        "message": "Your Shahi Paneer Thali is prepared by our master chef and is out with executive courier.",
        "orderId": "67041a8e9b21f311a8c90012",
        "isRead": false,
        "createdAt": "2026-10-07T12:20:00.000Z"
      },
      {
        "id": "notif_002",
        "category": "OFFERS",
        "title": "Festive Gift Awaits You!",
        "message": "Use code FESTIVE60 to receive a complimentary Nawabi dessert with your weekly subscription.",
        "couponCode": "FESTIVE60",
        "isRead": false,
        "createdAt": "2026-10-07T10:15:00.000Z"
      },
      {
        "id": "notif_003",
        "category": "SYSTEM",
        "title": "Subscription Payment Success",
        "message": "Payment of ₹2,299 for your Signature Royal Subscription was successfully processed.",
        "isRead": true,
        "createdAt": "2026-10-06T15:00:00.000Z"
      }
    ]
  }
}
```

#### B. Mark All Notifications as Read
* **Method**: `PATCH`
* **Route**: `/api/customer/notifications/mark-all-read`
* **Auth**: `authCustomer` (Bearer JWT)
* **Response (`200 OK`)**:
```json
{
  "success": true,
  "message": "All notifications marked as read"
}
```

---

### 3.2 Live Valet GPS Tracking

* **Screen Reference**: `EATOGGY SVG Layout/c22-live-tracking.svg`
* **Features in UI**: Real-time rider coordinates, ETA banner (*"Arriving in 14 Mins"*), valet name (*"Ramesh Kumar"*), rating (*"4.9 Star Valet Partner"*), and phone number.

* **Method**: `GET`
* **Route**: `/api/customers/orders/tracking/:orderId`
* **Auth**: `authCustomer` (Bearer JWT)
* **Response (`200 OK`)**:
```json
{
  "success": true,
  "data": {
    "orderId": "67041a8e9b21f311a8c90012",
    "orderNumber": "#EAT-94821",
    "status": "OUT_FOR_DELIVERY",
    "etaMinutes": 14,
    "etaText": "Arriving in 14 Mins",
    "valet": {
      "name": "Ramesh Kumar",
      "phone": "+919876543210",
      "rating": 4.9,
      "badge": "4.9 Star Valet Partner",
      "currentLocation": {
        "lat": 28.5983,
        "lng": 77.2215
      }
    },
    "restaurantLocation": {
      "name": "The Great Kitchen Hub",
      "address": "Amrita Shergil Marg, Lutyens' Delhi",
      "lat": 28.6010,
      "lng": 77.2180
    },
    "deliveryLocation": {
      "address": "Villa 14, Amrita Shergil Marg, New Delhi",
      "lat": 28.5950,
      "lng": 77.2250
    }
  }
}
```

---

### 3.3 Order Multi-Category Review & Ratings

* **Screen Reference**: `EATOGGY SVG Layout/c34-ratings-review.svg`
* **Features in UI**: 3 rating categories (Overall, Food Quality, Delivery & Packaging), 500-char text review, and photo attachments.

* **Method**: `POST`
* **Route**: `/api/customers/orders/:orderId/review`
* **Auth**: `authCustomer` (Bearer JWT)
* **Request Body (`application/json`)**:
```json
{
  "rating": 5,
  "foodRating": 5,
  "deliveryRating": 4,
  "comment": "The Awadhi Rogan Thali was absolutely fantastic. Rich, aromatic spice blends and flawless royal packaging.",
  "images": [
    "https://pub-advmenngo.r2.dev/reviews/photo1.jpg"
  ]
}
```

* **Response (`201 Created`)**:
```json
{
  "success": true,
  "message": "Review submitted successfully",
  "data": {
    "reviewId": "rev_6704381a1c9e8",
    "orderId": "67041a8e9b21f311a8c90012",
    "rating": 5,
    "createdAt": "2026-10-07T12:35:00.000Z"
  }
}
```

---

### 3.4 Customer Profile Update

* **Screen Reference**: `EATOGGY SVG Layout/c31-profile.svg`
* **Method**: `PATCH`
* **Route**: `/api/customer-auth/me`
* **Auth**: `authCustomer` (Bearer JWT)
* **Request Body (`application/json`)**:
```json
{
  "name": "Raghavendra Dev",
  "email": "raghavendra.dev@example.com",
  "dietaryPreference": "VEG"
}
```
* **Response (`200 OK`)**:
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "customer": {
      "id": "6ac35ddddcd1494d029cc126",
      "name": "Raghavendra Dev",
      "mobile": "9876543210",
      "email": "raghavendra.dev@example.com",
      "dietaryPreference": "VEG",
      "role": "Customer",
      "isMobileVerified": true
    }
  }
}
```

---

### 3.5 Checkout Initiation Payload Updates

* **Screen Reference**: `EATOGGY SVG Layout/c15-checkout.svg`
* **Method**: `POST`
* **Route**: `/api/checkout/initiate`
* **Auth**: `authCustomer` (Bearer JWT)
* **Enhancement**: The controller must accept and persist the customer's selected **Delivery Slot** and **Cooking Notes**.

#### Request Body (`application/json`):
```json
{
  "addressId": "66f7d43890209e7284f281e1",
  "deliverySlot": {
    "slot": "Gourmet Lunch Slot",
    "time": "12:30 - 1:15",
    "date": "2026-10-07"
  },
  "notes": "Please deliver in insulated hot-case. Ring bell once."
}
```

#### Response (`200 OK`):
```json
{
  "success": true,
  "message": "Checkout initiated successfully",
  "data": {
    "checkoutSessionId": "chk_session_65f1234abcd",
    "orderId": "order_EK53Ju3rO1cu12",
    "amount": 40745,
    "currency": "INR",
    "razorpayKey": "rzp_live_xxxxxxxxxxxxxx"
  }
}
```

---

### 3.6 Subscription Customization Updates

* **Screen Reference**: `EATOGGY SVG Layout/c25-customize-subscription.svg` & `c26-subscription-checkout.svg`
* **Method**: `POST`
* **Route**: `/api/customers/subscriptions`
* **Auth**: `authCustomer` (Bearer JWT)
* **Enhancement**: Accept selected delivery days, time slot, and allergy notes.

#### Request Body (`application/json`):
```json
{
  "planId": "plan_maharaja_monthly_30d",
  "addressId": "66f7d43890209e7284f281e1",
  "startDate": "2026-10-08",
  "mealType": "VEG",
  "deliveryDays": ["Mon", "Tue", "Wed", "Thu", "Fri"],
  "preferredSlot": "Lunch Box (12:00 PM - 1:30 PM)",
  "dietaryNotes": "No peanuts, moderate spice levels only"
}
```

---

### 3.7 Dynamic Offers & Coupon Validation

* **Screen Reference**: `EATOGGY SVG Layout/c29-offers-coupons.svg`
* **Coupons in UI**: `ROYALTREAT50` (Flat ₹50 off), `FESTIVE60` (60% off up to ₹150), `FREEDELUXE` (Free delivery).

#### A. List Active Coupons
* **Method**: `GET`
* **Route**: `/api/offers`
* **Response (`200 OK`)**:
```json
{
  "success": true,
  "data": [
    {
      "code": "ROYALTREAT50",
      "discountPercent": 14.33,
      "maxDiscount": 50,
      "minOrderValue": 299,
      "description": "Flat ₹50 saved on your current box.",
      "expiresAt": "2026-10-15T23:59:59.000Z"
    },
    {
      "code": "FESTIVE60",
      "discountPercent": 60,
      "maxDiscount": 150,
      "minOrderValue": 499,
      "description": "Get 60% off up to ₹150 on luxury weekly subscriptions.",
      "expiresAt": "2026-10-10T23:59:59.000Z"
    },
    {
      "code": "FREEDELUXE",
      "discountPercent": 100,
      "maxDiscount": 40,
      "minOrderValue": 199,
      "description": "Free delivery on all premium bespoke gourmet boxes.",
      "expiresAt": "2026-10-14T23:59:59.000Z"
    }
  ]
}
```

#### B. Validate & Apply Coupon
* **Method**: `POST`
* **Route**: `/api/offers/apply-coupon`
* **Request Body**:
```json
{
  "couponCode": "ROYALTREAT50",
  "subtotal": 349.0
}
```
* **Response (`200 OK`)**:
```json
{
  "success": true,
  "message": "ROYALTREAT50 applied! ₹50 saved on your current box.",
  "data": {
    "code": "ROYALTREAT50",
    "discountAmount": 50.0,
    "finalSubtotal": 299.0
  }
}
```

---

### 3.8 App Initialization & System Status (Edge Cases)

* **Screen Reference**: `force_update_screen.dart`, `maintenance_screen.dart`, `whats_new_screen.dart`
* **Method**: `GET`
* **Route**: `/api/system/status`
* **Description**: A public initialization route the app calls on boot to check for maintenance mode, force updates, and fetch the latest changelog.

**Response (`200 OK`)**:
```json
{
  "success": true,
  "data": {
    "isMaintenanceMode": false,
    "maintenanceMessage": "We are currently upgrading our servers. Please check back in 10 minutes.",
    "minRequiredVersion": "4.10.0",
    "latestVersion": "4.12.0",
    "updateUrl": "https://play.google.com/store/apps/details?id=com.eatoggy.customer",
    "changelog": [
      { "title": "Luxury UI Overhaul", "desc": "Brand new Ivory and Imperial Red Royal design." },
      { "title": "Lightning Fast Search", "desc": "Optimized food search engine." }
    ]
  }
}
```

---

### 3.9 Dynamic Legal Documents

* **Screen Reference**: `privacy_policy_screen.dart`, `terms_screen.dart`, `refund_policy_screen.dart`
* **Method**: `GET`
* **Route**: `/api/legal/documents`
* **Description**: Returns HTML/Markdown strings for Legal screens to avoid App Store updates for policy changes. Required for Razorpay Merchant approval.

**Response (`200 OK`)**:
```json
{
  "success": true,
  "data": {
    "terms": "<h1>Terms of Service</h1><p>Welcome to Eatoggy...</p>",
    "privacy": "<h1>Privacy Policy</h1><p>Your data is secure...</p>",
    "refunds": "<h1>Refund Policy</h1><p>Orders can be cancelled within 60 seconds...</p>"
  }
}
```

---

### 3.10 Sync Customer Preferences

* **Screen Reference**: `settings_screen.dart`
* **Method**: `PATCH`
* **Route**: `/api/customer-auth/preferences`
* **Auth**: `authCustomer` (Bearer JWT)
* **Description**: Syncs locally changed push/email notification toggles to the backend.

**Request Body**:
```json
{
  "pushNotifications": true,
  "emailNotifications": false,
  "smsAlerts": true
}
```

---

## 4. P2 Supporting Services

### 4.1 Location Geofence & Serviceability Check
* **Route**: `GET /api/serviceability/check?lat=28.5983&lng=77.2215`
* **Response (`200 OK`)**:
```json
{
  "success": true,
  "serviceable": true,
  "kitchenHub": "Lutyens' Delhi Imperial Hub",
  "estimatedDeliveryTime": "25-35 mins"
}
```

### 4.2 Device Push Notification Registration
* **Route**: `POST /api/notifications/subscribe`
* **Request Body**:
```json
{
  "fcmToken": "eX_ample_fcm_token_string...",
  "deviceType": "android",
  "appVersion": "4.12.0"
}
```
* **Response (`200 OK`)**:
```json
{
  "success": true,
  "message": "Notification token registered successfully"
}
```

---

## 5. Master API Status Reference Table

| # | Method | Path | Auth | Priority | Backend Status | Action Required |
|:--:|:---:|:---|:---:|:---:|:---:|:---|
| 1 | `POST` | `/api/customer-auth/send-otp` | Public | P0 | 🟢 200 OK | Operational. None. |
| 2 | `POST` | `/api/customer-auth/verify-otp` | Public | P0 | 🟢 200 OK | Operational. None. |
| 3 | `GET` | `/api/customer-auth/me` | JWT | P0 | 🟢 200 OK | Operational. None. |
| 4 | `PATCH` | `/api/customer-auth/me` | JWT | P1 | 🔴 404 | **Deploy update controller (Section 3.4).** |
| 5 | `DELETE` | `/api/customer-auth/account` | JWT | **P0** | 🔴 404 | **Deploy deletion controller (Section 2.2 - Apple Store Requirement).** |
| 6 | `GET` | `/api/customers/discovery/restaurants` | Public | **P0** | 🟡 401 & Bad Data | **Remove JWT auth + delete corrupted test docs.** |
| 7 | `GET` | `/api/customers/discovery/restaurants/:id/menu` | Public | P1 | 🟡 401 | **Remove JWT auth.** |
| 8 | `GET` | `/api/customers/discovery/banners` | Public | P1 | 🟡 401 | **Remove JWT auth.** |
| 9 | `GET` | `/api/customers/discovery/collections` | Public | P1 | 🟡 401 | **Remove JWT auth.** |
| 10 | `GET` | `/api/customers/discovery/gourmet` | Public | P1 | 🟡 401 | **Remove JWT auth + `.populate('restaurantId')`.** |
| 11 | `GET` | `/api/customers/addresses` | JWT | P0 | 🟢 200 OK | Operational. None. |
| 12 | `POST` | `/api/customers/addresses` | JWT | P0 | 🟢 200 OK | Operational. None. |
| 13 | `GET` | `/api/checkout/summary` | JWT | P1 | 🟢 200 OK | Operational. |
| 14 | `POST` | `/api/checkout/initiate` | JWT | P1 | 🟢 200 OK | Add `deliverySlot` & `notes` persistence. |
| 15 | `POST` | `/api/checkout/verify-payment` | JWT | **P0** | 🔴 404 | **Deploy Razorpay HMAC verification controller (Section 2.1).** |
| 16 | `GET` | `/api/customers/orders` | JWT | P0 | 🟢 200 OK | Operational. None. |
| 17 | `GET` | `/api/customers/orders/tracking/:id` | JWT | P1 | 🔴 404 | **Deploy live GPS tracking route (Section 3.2).** |
| 18 | `POST` | `/api/customers/orders/:id/review` | JWT | P1 | ⚪ Missing | **Deploy review submission route (Section 3.3).** |
| 19 | `GET` | `/api/customer/notifications` | JWT | P1 | ⚪ Missing | **Deploy notifications list route (Section 3.1).** |
| 20 | `PATCH`| `/api/customer/notifications/mark-all-read` | JWT | P1 | ⚪ Missing | **Deploy mark-all-read route (Section 3.1).** |
| 21 | `GET` | `/api/offers` | Public | P1 | 🔴 404 | **Deploy active offers route (Section 3.7).** |
| 22 | `POST` | `/api/offers/apply-coupon` | JWT | P1 | 🔴 404 | **Deploy coupon validation route (Section 3.7).** |
| 23 | `GET` | `/api/customers/tiffin-plans` | Public | P0 | 🟢 200 OK | Operational. None. |
| 24 | `POST` | `/api/customers/subscriptions` | JWT | P0 | 🟢 200 OK | Support `deliveryDays`, `preferredSlot`, `dietaryNotes`. |
| 25 | `POST` | `/api/customers/subscriptions/verify-payment` | JWT | P0 | 🟢 200 OK | Operational. None. |
| 26 | `GET` | `/api/support/tickets/my` | JWT | P1 | 🟢 200 OK | Operational. None. |
| 27 | `POST` | `/api/support/tickets` | JWT | P1 | 🟢 200 OK | Operational. None. |
| 28 | `GET` | `/api/serviceability/check` | Public | P2 | 🔴 404 | Deploy geofence validation. |
| 29 | `POST` | `/api/notifications/subscribe` | JWT | P2 | 🔴 404 | Deploy device token registration. |
| 30 | `GET` | `/api/system/status` | Public | **P0** | ⚪ Missing | **Deploy App Boot/Edge Case validator (Section 3.8).** |
| 31 | `GET` | `/api/legal/documents` | Public | P1 | ⚪ Missing | **Deploy Dynamic Legal text route (Section 3.9).** |
| 32 | `PATCH` | `/api/customer-auth/preferences` | JWT | P1 | ⚪ Missing | **Deploy settings sync route (Section 3.10).** |
