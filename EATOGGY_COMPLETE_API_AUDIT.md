# 🛠️ EATOGGY — Backend Engineering Action Specification & Fix Guide

**Target Audience**: Backend Engineering Team & Tech Leads  
**Server Environment**: Production (`https://api.eatoggy.in/api`)  
**Stack**: Node.js / Express.js / MongoDB (Mongoose) / Cloudflare R2 / Razorpay  
**Date**: October 5, 2026  
**Document Goal**: Provide complete, copy-paste ready request/response schemas, controller logic, and database seeding rules required to make the mobile application 100% operational.

---

## 📌 Table of Contents
1. [Executive Status Overview](#1-executive-status-overview)
2. [Critical Fix 1: Public Discovery & Guest Browsing (P0)](#critical-fix-1-public-discovery--guest-browsing-p0)
3. [Critical Fix 2: Database Sanitization & Restaurant Seeding (P0)](#critical-fix-2-database-sanitization--restaurant-seeding-p0)
4. [Critical Fix 3: Food Order Razorpay Payment Verification (P0)](#critical-fix-3-food-order-razorpay-payment-verification-p0)
5. [Critical Fix 4: Apple Store Mandatory Account Deletion (P0)](#critical-fix-4-apple-store-mandatory-account-deletion-p0)
6. [Critical Fix 5: Customer Profile Update (P0)](#critical-fix-5-customer-profile-update-p0)
7. [Priority 1 Fixes: Mongoose Population & Missing Endpoints](#priority-1-fixes-mongoose-population--missing-endpoints)
8. [Storage Fix: Cloudflare R2 Bucket Permissions](#storage-fix-cloudflare-r2-bucket-permissions)
9. [Complete Master API Specification Reference](#complete-master-api-specification-reference)

---

## 1. Executive Status Overview

| Metric | Count | Details |
| :--- | :---: | :--- |
| **Total Mapped Endpoints** | **76** | Evaluated across Postman Collection & Mobile App Code |
| **Operational Endpoints** | **16** | Auth (OTP), Saved Addresses, Basic Subscriptions, Tickets |
| **Broken / Corrupted Endpoints** | **5** | Discovery locked behind JWT, incomplete MongoDB documents |
| **404 Route Not Found** | **33** | Checkout verification, profile update, account deletion, tracking |
| **Missing From Architecture** | **3** | Order review creation, subscription meal swap, cooking instructions |

---

## Critical Fix 1: Public Discovery & Guest Browsing (P0)

### 🔴 The Issue
Currently, all discovery routes use the `authCustomer` JWT verification middleware. An unauthenticated guest opening the mobile app receives:
```http
HTTP/1.1 401 Unauthorized
{"message": "No token, authorization denied"}
```
Industry standard (Swiggy, Zomato) requires that users can explore restaurants, collections, and menus **before** signing in.

### 🛠️ The Fix
Remove the `authCustomer` / `verifyToken` middleware from the following routes in your Express router:

```javascript
// BEFORE (BROKEN):
router.get('/customers/discovery/restaurants', authCustomer, discoveryController.getRestaurants);
router.get('/customers/discovery/restaurants/:id/menu', authCustomer, discoveryController.getMenu);
router.get('/customers/discovery/banners', authCustomer, discoveryController.getBanners);
router.get('/customers/discovery/collections', authCustomer, discoveryController.getCollections);
router.get('/customers/discovery/gourmet', authCustomer, discoveryController.getGourmetDishes);

// AFTER (CORRECT):
router.get('/customers/discovery/restaurants', discoveryController.getRestaurants);
router.get('/customers/discovery/restaurants/:id/menu', discoveryController.getMenu);
router.get('/customers/discovery/banners', discoveryController.getBanners);
router.get('/customers/discovery/collections', discoveryController.getCollections);
router.get('/customers/discovery/gourmet', discoveryController.getGourmetDishes);
```

---

## Critical Fix 2: Database Sanitization & Restaurant Seeding (P0)

### 🔴 The Issue
Running a live `GET /api/customers/discovery/restaurants` returns 10 records, but **8 of them are corrupted test documents containing only an `_id`**. One document contains keyboard mash (`"jshmfkjdhfbgv"`). Only one real restaurant exists (`"The Great Kitchen"`).

### 🛠️ The Fix
1. **Purge test/corrupted documents**:
   ```javascript
   // Delete documents where restaurantName is missing or invalid
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

2. **Schema & Required Fields**:
   Every restaurant document in MongoDB **must** contain these fields to render correctly in the mobile app:

   ```typescript
   interface IRestaurant {
     _id: ObjectId;
     restaurantName: string;       // e.g. "Hotel Maithili"
     cuisine: string;              // e.g. "Pure Veg, North Indian, Thali"
     city: string;                 // e.g. "Kranti Nagar"
     fullAddress: string;          // e.g. "Plot 42, Sector 29, Gurugram"
     rating: number;               // e.g. 4.4
     ratingCount: string;          // e.g. "6.1K+ ratings"
     deliveryTime: string;         // e.g. "25-30 mins"
     distance: string;             // e.g. "2.4 km"
     costForTwo: string;           // e.g. "₹350 for two"
     isPureVeg: boolean;           // true or false
     isHygieneVerified: boolean;   // true
     offerText: string;            // e.g. "10% OFF UPTO ₹75"
     image: string;                // Public HTTPS image URL
     operatingHours: {
       open: string;               // e.g. "09:00"
       close: string;              // e.g. "23:00"
     };
   }
   ```

3. **Seed at least 4–6 realistic restaurants**:
   * *Hotel Maithili* (Pure Veg, North Indian, Thali)
   * *The Great Kitchen* (North Indian, Mughlai, Royal Biryani)
   * *Punjab Heritage & Grill* (North Indian, Tandoori, Parathas)
   * *Awadh Dawat-e-Khaas* (Awadhi, Dum Pukht, Kebabs)

---

## Critical Fix 3: Food Order Razorpay Payment Verification (P0)

### 🔴 The Issue
* **Route**: `POST /api/checkout/verify-payment`
* **Current Status**: `HTTP 404 Route not found`
* **Impact**: Subscriptions verify properly (`/api/customers/subscriptions/verify-payment`), but regular food cart checkouts have no verification endpoint deployed. Customers cannot complete online payments for food orders.

### 🛠️ The Fix (Controller Implementation)

* **Route**: `POST /api/checkout/verify-payment`
* **Auth**: `authCustomer` (Bearer JWT)
* **Headers**: `Content-Type: application/json`

#### Request Body (`application/json`):
```json
{
  "checkoutSessionId": "chk_session_65f1234abcd",
  "razorpayOrderId": "order_EK53Ju3rO1cu12",
  "razorpayPaymentId": "pay_EK53nIPlb2p123",
  "razorpaySignature": "9f83cf134c8a29a6fb514be8c8942b08a1c97a523b092248557a53f2253818e6"
}
```

#### Node.js / Express Verification Controller:
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

    // 2. Fetch checkout session and transition order
    const session = await CheckoutSession.findById(checkoutSessionId);
    if (!session) {
      return res.status(404).json({ success: false, message: 'Checkout session not found' });
    }

    // 3. Create or update confirmed Order
    const order = await Order.create({
      customerId,
      orderNumber: `#EAT-${Date.now().toString().slice(-6)}`,
      items: session.items,
      subtotal: session.subtotal,
      deliveryFee: session.deliveryFee,
      discount: session.discount,
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

## Critical Fix 4: Apple Store Mandatory Account Deletion (P0)

### 🔴 The Issue
* **Route**: `DELETE /api/customer-auth/account`
* **Current Status**: `HTTP 404 Route not found`
* **Impact**: **Mandatory Apple App Store Guideline 5.1.1.** Apps supporting account creation must allow users to delete their account in-app. Apple reviewers reject submissions if this route 404s.

### 🛠️ The Fix

* **Route**: `DELETE /api/customer-auth/account`
* **Auth**: `authCustomer` (Bearer JWT)
* **Expected Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Customer account deleted successfully"
  }
  ```

#### Controller Implementation:
```javascript
exports.deleteAccount = async (req, res) => {
  try {
    const customerId = req.user.id;

    // Anonymize or remove customer records
    await Customer.findByIdAndDelete(customerId);
    await Address.deleteMany({ customerId });
    await Cart.deleteMany({ customerId });

    return res.status(200).json({
      success: true,
      message: 'Customer account deleted successfully'
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to delete account' });
  }
};
```

---

## Critical Fix 5: Customer Profile Update (P0)

### 🔴 The Issue
* **Route**: `PATCH /api/customer-auth/me`
* **Current Status**: `HTTP 404 Route not found`
* **Impact**: The "Edit Profile" modal in the mobile app cannot persist customer name, email, or dietary preferences.

### 🛠️ The Fix

* **Route**: `PATCH /api/customer-auth/me`
* **Auth**: `authCustomer` (Bearer JWT)
* **Request Body (`application/json`)**:
  ```json
  {
    "name": "Arjun Sharma",
    "email": "arjun.sharma@example.com",
    "dietaryPreference": "VEG"
  }
  ```
* **Expected Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Profile updated successfully",
    "data": {
      "customer": {
        "id": "6ac35ddddcd1494d029cc126",
        "name": "Arjun Sharma",
        "mobile": "9999999999",
        "email": "arjun.sharma@example.com",
        "dietaryPreference": "VEG",
        "role": "Customer",
        "isMobileVerified": true
      }
    }
  }
  ```

---

## Priority 1 Fixes: Mongoose Population & Missing Endpoints

### 7.1 Populate Restaurant in Gourmet Dishes
In `controllers/discoveryController.js`, update `getGourmetDishes`:

```javascript
// BEFORE (Returns raw or unpopulated ObjectId):
const dishes = await Dish.find({ isGourmet: true });

// AFTER (Populate restaurant details):
const dishes = await Dish.find({ isGourmet: true })
  .populate('restaurantId', 'restaurantName city cuisine image rating deliveryTime costForTwo isPureVeg');

res.status(200).json({
  success: true,
  data: dishes
});
```

---

### 7.2 Restaurant Menu Category Structure
* **Route**: `GET /api/customers/discovery/restaurants/:restaurantId/menu`
* **Expected Structure**:
  ```json
  {
    "success": true,
    "message": "Menu fetched successfully",
    "data": [
      {
        "_id": "cat_01",
        "name": "Royal Thali",
        "subcategories": [
          {
            "_id": "sub_01",
            "name": "Special Thali",
            "items": [
              {
                "_id": "dish_101",
                "name": "Maharaja Royal Thali",
                "description": "Grand feast with Shahi Paneer, Dal Makhani, 2 Laccha Parathas, Pulao & Gulab Jamun.",
                "price": 399,
                "foodType": "VEG",
                "image": "https://cdn.eatoggy.in/dishes/thali.png",
                "rating": 4.9,
                "isAvailable": true,
                "nutrition": "Prep: 25m • Complete Royal Feast",
                "ingredients": ["Shahi Paneer", "Dal Makhani", "Laccha Paratha", "Gulab Jamun"]
              }
            ]
          }
        ]
      }
    ]
  }
  ```

---

### 7.3 Coupon Validation Endpoint
* **Route**: `POST /api/offers/apply-coupon`
* **Auth**: `authCustomer`
* **Request Body**:
  ```json
  {
    "couponCode": "ROYALTREAT50",
    "subtotal": 450.0
  }
  ```
* **Expected Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Coupon applied successfully",
    "data": {
      "discountAmount": 50.0,
      "finalTotal": 400.0,
      "code": "ROYALTREAT50"
    }
  }
  ```

---

### 7.4 Live Order Tracking Polling Endpoint
* **Route**: `GET /api/customers/orders/tracking/:orderId`
* **Auth**: `authCustomer`
* **Expected Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": {
      "orderId": "6aba43dcd4360b9e1933b2b9",
      "status": "OUT_FOR_DELIVERY",
      "eta": "15-20 mins",
      "valet": {
        "name": "Vikram Singh",
        "phone": "+919876543210",
        "rating": 4.8,
        "currentLocation": {
          "lat": 28.4595,
          "lng": 77.0266
        }
      },
      "destination": {
        "lat": 28.4682,
        "lng": 77.0345
      }
    }
  }
  ```

---

## Storage Fix: Cloudflare R2 Bucket Permissions

### 🔴 The Issue
Image assets under `https://pub-advmenngo.r2.dev/` fail with 403 Forbidden or network errors.

### 🛠️ The Fix in Cloudflare Dashboard:
1. Open Cloudflare Dashboard → **R2 Object Storage**.
2. Select your bucket (`pub-advmenngo` or `eatoggy-media`).
3. Under **Settings** → **Public Access**, enable **Allow Public Access via Custom Domain or R2.dev**.
4. Set CORS Policy:
   ```json
   [
     {
       "AllowedOrigins": ["*"],
       "AllowedMethods": ["GET", "HEAD"],
       "AllowedHeaders": ["*"],
       "MaxAgeSeconds": 3600
     }
   ]
   ```

---

## Complete Master API Specification Reference

| # | Method | Path | Auth | Current Status | Action Needed |
|:--:|:---:|:---|:---:|:---:|:---|
| 1 | `POST` | `/api/customer-auth/send-otp` | Public | 🟢 200 OK | None. Fully functional. |
| 2 | `POST` | `/api/customer-auth/verify-otp` | Public | 🟢 200 OK | None. Fully functional. |
| 3 | `GET` | `/api/customer-auth/me` | JWT | 🟢 200 OK | None. Fully functional. |
| 4 | `PATCH` | `/api/customer-auth/me` | JWT | 🔴 404 | **Deploy controller (Critical Fix 5).** |
| 5 | `DELETE` | `/api/customer-auth/account` | JWT | 🔴 404 | **Deploy controller (Critical Fix 4).** |
| 6 | `GET` | `/api/customers/discovery/restaurants` | Public | 🟡 401 & Bad Data | **Remove auth + sanitize DB.** |
| 7 | `GET` | `/api/customers/discovery/restaurants/:id/menu` | Public | 🟡 401 & Empty | **Remove auth + seed menus.** |
| 8 | `GET` | `/api/customers/discovery/banners` | Public | 🟡 401 | **Remove auth requirement.** |
| 9 | `GET` | `/api/customers/discovery/collections` | Public | 🟡 401 | **Remove auth requirement.** |
| 10 | `GET` | `/api/customers/discovery/gourmet` | Public | 🟡 401 & Unpopulated | **Remove auth + `.populate('restaurantId')`.** |
| 11 | `GET` | `/api/customers/addresses` | JWT | 🟢 200 OK | None. Fully functional. |
| 12 | `POST` | `/api/customers/addresses` | JWT | 🟢 200 OK | None. Fully functional. |
| 13 | `POST` | `/api/checkout/initiate` | JWT | 🟢 200 OK | Add `deliverySlot` & `specialInstructions` support. |
| 14 | `POST` | `/api/checkout/verify-payment` | JWT | 🔴 404 | **Deploy Razorpay verification (Critical Fix 3).** |
| 15 | `GET` | `/api/customers/orders` | JWT | 🟢 200 OK | None. Fully functional. |
| 16 | `GET` | `/api/customers/orders/tracking/:id` | JWT | 🔴 404 | **Deploy live GPS tracking route.** |
| 17 | `POST` | `/api/customers/orders/:id/cancel` | JWT | 🔴 404 | **Deploy cancel route.** |
| 18 | `GET` | `/api/offers` | JWT | 🔴 404 | **Deploy offers list route.** |
| 19 | `POST` | `/api/offers/apply-coupon` | JWT | 🔴 404 | **Deploy apply coupon route.** |
| 20 | `GET` | `/api/customers/tiffin-plans` | Public | 🟢 200 OK | None. Fully functional. |
| 21 | `GET` | `/api/customers/subscriptions` | JWT | 🟢 200 OK | None. Fully functional. |
| 22 | `POST` | `/api/customers/subscriptions` | JWT | 🟢 200 OK | None. Fully functional. |
| 23 | `POST` | `/api/customers/subscriptions/verify-payment` | JWT | 🟢 200 OK | None. Fully functional. |
| 24 | `GET` | `/api/support/tickets/my` | JWT | 🟢 200 OK | None. Fully functional. |
| 25 | `POST` | `/api/support/tickets` | JWT | 🟢 200 OK | None. Fully functional. |
| 26 | `POST` | `/api/customers/orders/:id/review` | JWT | ⚪ Missing | **Create route to accept reviews & ratings.** |
| 27 | `POST` | `/api/notifications/subscribe` | JWT | 🔴 404 | **Deploy FCM device token registration.** |
| 28 | `GET` | `/api/serviceability/check` | Public | 🔴 404 | **Deploy lat/lng geofence check.** |
| 29 | `GET` | `/api/public/config` | Public | 🔴 404 | **Deploy runtime Razorpay/Maps config route.** |

---

## 🎯 4-Step Meeting Action Summary

Share these exact 4 items with the backend lead:

1. **Unblock Guest Users**: Remove the `authCustomer` middleware from `/api/customers/discovery/*`.
2. **Clean MongoDB**: Remove empty `{ _id }` documents and seed 6–10 complete restaurants with names, cuisines, and images.
3. **Deploy Food Payment**: Deploy `POST /api/checkout/verify-payment` using the HMAC verification logic in **Section 4**.
4. **App Store Compliance**: Deploy `DELETE /api/customer-auth/account` so Apple does not reject the iOS app.
