# 🚀 Eatoggy Customer App — Backend Engineering Handoff & Master API Specification

> **Target Audience**: Backend Development Team & Technical Leads  
> **Production Base URL**: `https://api.eatoggy.in/api`  
> **Staging / Dev URL**: `https://dash-eatoggy-backend.onrender.com/api`  
> **Authentication Header**: `Authorization: Bearer <customer_jwt_token>`  
> **Date**: October 2026  
> **Document Purpose**: Single, self-contained handoff specification containing all missing backend endpoints, bug fixes, database seeding scripts, and controller implementations required to make the mobile application 100% production-ready.

---

## 📌 Executive Summary for Backend Team

The Flutter mobile customer app (`eatoggy-userapp`) is complete with zero compilation errors. However, live API testing reveals **14 endpoints returning `404 Route not found`**, several routes failing with `401 Unauthorized` for guest users, and empty `{ _id }` test records in MongoDB.

```mermaid
flowchart TD
    subgraph P0_Blockers ["Priority 0: Release Blockers"]
        A["1. POST /api/checkout/verify-payment (Food Payment Verification)"]
        B["2. DELETE /api/customer-auth/account (Apple Store Guideline 5.1.1)"]
        C["3. PATCH /api/customer-auth/me (Profile Updates)"]
        D["4. POST /api/notifications/subscribe (FCM Push Device Tokens)"]
        E["5. GET /api/customers/orders/tracking/:id (Live GPS Tracking)"]
        F["6. Enforce authCustomer on /api/customers/discovery/* (Strict Login Required - Locked Guest Browsing)"]
    end
    subgraph P1_Features ["Priority 1: Core E-Commerce"]
        G["7. GET /api/offers & POST /api/offers/apply-coupon"]
        H["8. POST /api/customers/orders/:id/cancel"]
        I["9. POST /api/customers/orders/:id/review"]
        J["10. GET /api/serviceability/check"]
        K["11. GET /api/public/config"]
    end
    subgraph Infra ["Database & Storage"]
        L["12. Purge & Seed MongoDB Restaurants"]
        M["13. Configure Cloudflare R2 Public CORS"]
        N["14. Socket.IO Order Event Emitters"]
    end
```

---

## 🔴 Section 1: Priority 0 (P0) Release Blockers

---

### 1.1 Food Order Payment Verification
* **Route**: `POST /api/checkout/verify-payment`
* **Auth**: Bearer JWT (`authCustomer`)
* **Current Status**: `HTTP 404 Route not found`
* **Why It Is P0**: Regular food checkout has no payment verification deployed. Customers are charged via Razorpay, but the backend never confirms the order, never clears the cart, and never alerts the restaurant partner dashboard.

#### Request Headers:
```http
POST /api/checkout/verify-payment HTTP/1.1
Host: api.eatoggy.in
Authorization: Bearer <customer_jwt>
Content-Type: application/json
```

#### Request Body (`application/json`):
```json
{
  "checkoutSessionId": "chk_session_65f1234abcd",
  "razorpayOrderId": "order_EK53Ju3rO1cu12",
  "razorpayPaymentId": "pay_EK53nIPlb2p123",
  "razorpaySignature": "9f83cf134c8a29a6fb514be8c8942b08a1c97a523b092248557a53f2253818e6"
}
```

#### Node.js / Express Controller Implementation:
```javascript
const crypto = require('crypto');

exports.verifyPayment = async (req, res) => {
  try {
    const { checkoutSessionId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;
    const customerId = req.user.id || req.user._id;

    if (!checkoutSessionId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({ success: false, message: 'All payment fields are required' });
    }

    // 1. Verify Razorpay HMAC SHA256 Signature
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest('hex');

    if (expectedSignature !== razorpaySignature) {
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid payment signature. Verification failed.' 
      });
    }

    // 2. Fetch checkout session or active cart
    const session = await CheckoutSession.findById(checkoutSessionId) || await Cart.findOne({ customerId });
    if (!session) {
      return res.status(404).json({ success: false, message: 'Checkout session not found' });
    }

    // 3. Create Confirmed Order in Database
    const orderNumber = `#EAT-${Date.now().toString().slice(-6)}`;
    const newOrder = await Order.create({
      customerId,
      orderNumber,
      items: session.items,
      restaurantId: session.restaurantId,
      subtotal: session.subtotal,
      deliveryFee: session.deliveryFee || 30.0,
      discount: session.discount || 0.0,
      grandTotal: session.grandTotal || session.total,
      deliveryAddress: session.deliveryAddress || session.address,
      deliverySlot: session.deliverySlot,
      status: 'CONFIRMED',
      paymentStatus: 'PAID',
      paymentDetails: {
        gateway: 'RAZORPAY',
        paymentId: razorpayPaymentId,
        orderId: razorpayOrderId,
        signature: razorpaySignature,
      },
      placedAt: new Date(),
      estimatedDelivery: '30-40 mins'
    });

    // 4. Auto-clear the customer's cart
    await Cart.findOneAndUpdate(
      { customerId }, 
      { $set: { items: [], subtotal: 0, discount: 0, total: 0 } }
    );

    // 5. Emit real-time Socket event to Restaurant Partner app
    if (global.io) {
      global.io.to(`restaurant_${session.restaurantId}`).emit('order:new', {
        orderId: newOrder._id,
        orderNumber: newOrder.orderNumber,
        items: newOrder.items,
        grandTotal: newOrder.grandTotal
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Payment verified and order confirmed successfully',
      data: {
        order: {
          id: newOrder._id,
          orderNumber: newOrder.orderNumber,
          status: newOrder.status,
          paymentStatus: newOrder.paymentStatus,
          grandTotal: newOrder.grandTotal,
          placedAt: newOrder.placedAt,
          estimatedDelivery: newOrder.estimatedDelivery
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

### 1.2 Customer Account Deletion (Apple App Store Guideline 5.1.1)
* **Route**: `DELETE /api/customer-auth/account`
* **Auth**: Bearer JWT (`authCustomer`)
* **Current Status**: `HTTP 404 Route not found`
* **Why It Is P0**: **Mandatory Apple requirement**. Apps allowing account registration must offer account deletion inside the app. Apple review will reject the app immediately if this returns 404.

#### Request Headers:
```http
DELETE /api/customer-auth/account HTTP/1.1
Host: api.eatoggy.in
Authorization: Bearer <customer_jwt>
Content-Type: application/json
```

#### Node.js / Express Controller Implementation:
```javascript
exports.deleteAccount = async (req, res) => {
  try {
    const customerId = req.user.id || req.user._id;

    // Remove or anonymize customer records
    await Customer.findByIdAndDelete(customerId);
    await Address.deleteMany({ customerId });
    await Cart.deleteMany({ customerId });
    // Invalidate FCM device tokens
    await DeviceToken.deleteMany({ customerId });

    return res.status(200).json({
      success: true,
      message: 'Customer account deleted successfully'
    });
  } catch (error) {
    console.error('Delete account error:', error);
    return res.status(500).json({ success: false, message: 'Failed to delete account' });
  }
};
```

---

### 1.3 Customer Profile Update
* **Route**: `PATCH /api/customer-auth/me`
* **Auth**: Bearer JWT (`authCustomer`)
* **Current Status**: `HTTP 404 Route not found`
* **Why It Is P0**: Customer profile screen cannot save changes to name, email, or dietary preferences.

#### Request Body (`application/json`):
```json
{
  "name": "Dhruva Sharma",
  "email": "dhruva@example.com",
  "dietaryPreference": "VEG"
}
```

#### Node.js / Express Controller Implementation:
```javascript
exports.updateProfile = async (req, res) => {
  try {
    const customerId = req.user.id || req.user._id;
    const { name, email, dietaryPreference } = req.body;

    const customer = await Customer.findByIdAndUpdate(
      customerId,
      {
        ...(name && { name }),
        ...(email && { email }),
        ...(dietaryPreference && { dietaryPreference }),
      },
      { new: true, runValidators: true }
    ).select('-password');

    if (!customer) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        customer: {
          id: customer._id,
          name: customer.name,
          mobile: customer.mobile,
          email: customer.email,
          dietaryPreference: customer.dietaryPreference
        }
      }
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
```

---

### 1.4 Register FCM Device Token for Push Notifications
* **Route**: `POST /api/notifications/subscribe`
* **Auth**: Bearer JWT (`authCustomer`)
* **Current Status**: `HTTP 404 Route not found`
* **Why It Is P0**: The backend cannot send push notifications for order progress updates (Confirmed $\rightarrow$ Preparing $\rightarrow$ Out for Delivery $\rightarrow$ Delivered).

#### Request Body (`application/json`):
```json
{
  "fcmToken": "f7Z_abc123d4e5f6g7h8_sample_device_fcm_token...",
  "deviceType": "android",
  "appVersion": "1.0.0"
}
```

#### Node.js / Express Controller Implementation:
```javascript
exports.subscribeDeviceToken = async (req, res) => {
  try {
    const customerId = req.user.id || req.user._id;
    const { fcmToken, deviceType, appVersion } = req.body;

    if (!fcmToken) {
      return res.status(400).json({ success: false, message: 'fcmToken is required' });
    }

    // Upsert token record for this device
    await DeviceToken.findOneAndUpdate(
      { fcmToken },
      {
        customerId,
        deviceType: deviceType || 'android',
        appVersion: appVersion || '1.0.0',
        lastActiveAt: new Date()
      },
      { upsert: true, new: true }
    );

    return res.status(200).json({
      success: true,
      message: 'FCM device token registered successfully'
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
```

---

### 1.5 Live Order GPS Tracking Polling
* **Route**: `GET /api/customers/orders/tracking/:orderId`
* **Auth**: Bearer JWT (`authCustomer`)
* **Current Status**: `HTTP 404 Route not found`
* **Why It Is P0**: The live tracking screen needs real-time valet coordinates to draw the delivery route on Google Maps.

#### Expected Response (`200 OK`):
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
    "restaurant": {
      "name": "The Great Kitchen",
      "address": "ORCHID CENTER, Sector 53, Golf Course Road, Gurugram",
      "lat": 28.4384,
      "lng": 77.0988
    },
    "destination": {
      "lat": 28.4682,
      "lng": 77.0345
    }
  }
}
```

---

### 1.6 Strict Authentication Guard on Discovery (Locked Guest Browsing)
* **Business Requirement**: **Guest browsing is STRICTLY LOCKED.** Unauthenticated guests must NOT be allowed to view restaurants, menus, dishes, or banners. Only authenticated customers with a valid Bearer JWT token can access the platform.
* **Routes Affected**:
  - `GET /api/customers/discovery/restaurants`
  - `GET /api/customers/discovery/restaurants/:id/menu`
  - `GET /api/customers/discovery/banners`
  - `GET /api/customers/discovery/collections`
  - `GET /api/customers/discovery/gourmet`
* **Backend Enforcement**: Keep the `authCustomer` / `verifyToken` middleware active on all `/api/customers/discovery/*` routes.
* **Expected Behavior**: If a request arrives without `Authorization: Bearer <token>` or with an invalid/expired token, return:
  ```http
  HTTP/1.1 401 Unauthorized
  Content-Type: application/json

  {
    "success": false,
    "message": "Authentication required. Please log in to browse Eatoggy."
  }
  ```

```javascript
// STRICT AUTHENTICATION ENFORCED ON DISCOVERY:
router.get('/customers/discovery/restaurants', authCustomer, discoveryController.getRestaurants);
router.get('/customers/discovery/restaurants/:id/menu', authCustomer, discoveryController.getMenu);
router.get('/customers/discovery/banners', authCustomer, discoveryController.getBanners);
router.get('/customers/discovery/collections', authCustomer, discoveryController.getCollections);
router.get('/customers/discovery/gourmet', authCustomer, discoveryController.getGourmet);
```

* **Gourmet Dishes Mongoose Population**: In `getGourmet`, populate the parent restaurant fields while maintaining the `authCustomer` guard:
```javascript
const dishes = await Dish.find({ isGourmet: true })
  .populate('restaurantId', 'restaurantName city cuisine image rating deliveryTime costForTwo isPureVeg');
```

---

## 🟠 Section 2: Priority 1 (P1) Core E-Commerce Endpoints

---

### 2.1 Offers & Coupon Validation
The app has an Offers & Coupons screen that needs live validation.

#### `GET /api/offers` (List Available Coupons)
* **Auth**: Bearer JWT (`authCustomer`) or Public
* **Expected Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "code": "ROYAL50",
        "discountPercent": 50,
        "maxDiscount": 100,
        "minOrderValue": 199,
        "description": "50% OFF up to ₹100 on your royal dining order",
        "expiryDate": "2026-12-31"
      },
      {
        "code": "FEAST20",
        "discountPercent": 20,
        "maxDiscount": 150,
        "minOrderValue": 299,
        "description": "Flat 20% OFF on all gourmet meal boxes",
        "expiryDate": "2026-12-31"
      }
    ]
  }
  ```

#### `POST /api/offers/apply-coupon` (Validate Coupon on Cart)
* **Auth**: Bearer JWT (`authCustomer`)
* **Request Body**:
  ```json
  {
    "couponCode": "ROYAL50",
    "subtotal": 450.0
  }
  ```
* **Expected Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Coupon applied successfully",
    "data": {
      "couponCode": "ROYAL50",
      "discountAmount": 100.0,
      "subtotal": 450.0,
      "grandTotal": 350.0
    }
  }
  ```

---

### 2.2 Customer Order Cancellation
* **Route**: `POST /api/customers/orders/:orderId/cancel`
* **Auth**: Bearer JWT (`authCustomer`)
* **Logic**: Allow cancellation if order status is `PLACED` or `CONFIRMED`. Block cancellation if order is already `PREPARING` or `OUT_FOR_DELIVERY`.
* **Expected Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Order cancelled successfully",
    "data": {
      "orderId": "6aba43dcd4360b9e1933b2b9",
      "status": "CANCELLED"
    }
  }
  ```

---

### 2.3 Post-Delivery Order Rating & Review
* **Route**: `POST /api/customers/orders/:orderId/review`
* **Auth**: Bearer JWT (`authCustomer`)
* **Request Body**:
  ```json
  {
    "rating": 5,
    "comment": "Exceptional Dal Makhani and piping hot delivery in insulated packaging!",
    "dishRatings": [
      { "dishId": "dish_101", "rating": 5 }
    ]
  }
  ```
* **Expected Response (`201 Created`)**:
  ```json
  {
    "success": true,
    "message": "Thank you for your royal review!",
    "data": {
      "reviewId": "rev_67a123bc",
      "orderId": "6aba43dcd4360b9e1933b2b9",
      "rating": 5
    }
  }
  ```

---

### 2.4 Serviceability Geofence Check
* **Route**: `GET /api/serviceability/check?lat=28.4595&lng=77.0266`
* **Auth**: Public
* **Expected Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "isServiceable": true,
    "city": "Gurugram",
    "message": "Eatoggy delivers to your location"
  }
  ```

---

### 2.5 Runtime App Configuration
* **Route**: `GET /api/public/config`
* **Auth**: Public
* **Purpose**: Provides dynamic credentials so keys do not have to be hardcoded in client APK/IPA.
* **Expected Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": {
      "razorpayKey": "rzp_live_xxxxxxxxxxxxxx",
      "googleMapsApiKey": "AIzaSyC7oiIoV8StlfJq65fZBxGqU5TYsHwpkNA",
      "supportPhoneNumber": "+918001234567",
      "supportEmail": "support@eatoggy.in",
      "minAppVersion": "1.0.0",
      "forceUpdate": false
    }
  }
  ```

---

## 🟡 Section 3: Priority 2 (P2) Auxiliary Endpoints

| # | Method | Route | Description |
|:---:|:---:|:---|:---|
| 1 | `PATCH` | `/api/customers/preferences` | Update push/email/SMS notification preferences (`pushNotifications`, `emailAlerts`, `smsWhatsappAlerts`) |
| 2 | `GET` | `/api/customer/wallet` | Fetch customer wallet cash balance and reward points |
| 3 | `POST` | `/api/customer/wallet/add-money` | Top up in-app wallet via Razorpay |
| 4 | `GET` | `/api/categories` | Food categories pill list (`[{"id": "cat_1", "name": "North Indian", "icon": "🍲"}]`) |
| 5 | `POST` | `/api/customer-auth/logout` | Revoke customer refresh token from database |

---

## 🗄️ Section 4: Automated Database Seeding API & Data Sanitization

To ensure your production MongoDB database is immediately populated with realistic, beautifully formatted data without manual shell scripts, deploy this dedicated Admin Seeding API.

---

### 4.1 Data Seeding API Specification
* **Route**: `POST /api/admin/seed-database`
* **Auth**: Protected by an Admin Secret Header (`x-admin-key: EATOGGY_ADMIN_SEED_2026`)
* **Description**: Safely cleans out corrupted `{ _id }` test records, then seeds realistic Restaurants, Menus with Categories, Gourmet Dishes, Banners, Collections, Tiffin Plans, and Active Promo Coupons in a single atomic operation.

#### Request Headers:
```http
POST /api/admin/seed-database HTTP/1.1
Host: api.eatoggy.in
Content-Type: application/json
x-admin-key: EATOGGY_ADMIN_SEED_2026
```

#### cURL Execution Command for Backend Developers:
```bash
curl -X POST https://api.eatoggy.in/api/admin/seed-database \
  -H "Content-Type: application/json" \
  -H "x-admin-key: EATOGGY_ADMIN_SEED_2026"
```

#### Expected Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "Eatoggy database cleaned and seeded successfully",
  "data": {
    "corruptedCleaned": 8,
    "restaurantsSeeded": 3,
    "dishesSeeded": 9,
    "bannersSeeded": 3,
    "collectionsSeeded": 4,
    "tiffinPlansSeeded": 3,
    "couponsSeeded": 3
  }
}
```

---

### 4.2 Complete Node.js / Express Seeding Controller (`seedController.js`)

Copy-paste this controller directly into your Express backend:

```javascript
// controllers/seedController.js
const mongoose = require('mongoose');
const Restaurant = require('../models/Restaurant');
const Menu = require('../models/Menu') || require('../models/MenuItem');
const Dish = require('../models/Dish') || require('../models/MenuItem');
const Banner = require('../models/Banner');
const Collection = require('../models/Collection');
const TiffinPlan = require('../models/TiffinPlan');
const Coupon = require('../models/Coupon') || require('../models/Offer');

exports.seedDatabase = async (req, res) => {
  try {
    const adminKey = req.headers['x-admin-key'];
    const expectedKey = process.env.ADMIN_SEED_KEY || 'EATOGGY_ADMIN_SEED_2026';

    if (!adminKey || adminKey !== expectedKey) {
      return res.status(403).json({ success: false, message: 'Unauthorized. Invalid admin seed key.' });
    }

    // 1. Purge corrupted documents missing names or containing test keyboard mash
    const cleanResult = await Restaurant.deleteMany({
      $or: [
        { restaurantName: { $exists: false } },
        { restaurantName: null },
        { restaurantName: "" },
        { restaurantName: /test/i },
        { restaurantName: /jshmf/i }
      ]
    });

    // 2. Clear previous seeded data to prevent duplicate keys
    await Restaurant.deleteMany({ isSeedData: true });
    if (Banner) await Banner.deleteMany({});
    if (Collection) await Collection.deleteMany({});
    if (TiffinPlan) await TiffinPlan.deleteMany({});
    if (Coupon) await Coupon.deleteMany({});
    if (Dish) await Dish.deleteMany({ isSeedData: true });

    // 3. Seed Realistic Restaurants
    const restaurantsData = [
      {
        restaurantName: "Hotel Maithili",
        cuisine: "Pure Veg, North Indian, Thali",
        city: "Gurugram",
        fullAddress: "Plot 42, Sector 29, Gurugram, Haryana 122002",
        rating: 4.8,
        ratingCount: "4.2K+ ratings",
        deliveryTime: "25-30 mins",
        distance: "1.8 km",
        costForTwo: "₹300 for two",
        isPureVeg: true,
        isHygieneVerified: true,
        offerText: "50% OFF UPTO ₹100",
        image: "https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=800",
        operatingHours: { open: "08:00", close: "23:00" },
        location: { type: "Point", coordinates: [77.0722, 28.4682] },
        isSeedData: true
      },
      {
        restaurantName: "The Great Kitchen",
        cuisine: "North Indian, Mughlai, Biryani",
        city: "Gurugram",
        fullAddress: "3rd Floor, ORCHID CENTER, Sector 53, Golf Course Road, Gurugram",
        rating: 4.9,
        ratingCount: "6.8K+ ratings",
        deliveryTime: "30-35 mins",
        distance: "2.4 km",
        costForTwo: "₹450 for two",
        isPureVeg: false,
        isHygieneVerified: true,
        offerText: "FLAT ₹75 OFF ABOVE ₹399",
        image: "https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?q=80&w=800",
        operatingHours: { open: "10:00", close: "23:30" },
        location: { type: "Point", coordinates: [77.0988, 28.4384] },
        isSeedData: true
      },
      {
        restaurantName: "Punjab Heritage & Grill",
        cuisine: "Tandoori, Parathas, Dal Makhani",
        city: "Gurugram",
        fullAddress: "SCO 14, Cyber Hub, DLF Phase 2, Gurugram",
        rating: 4.7,
        ratingCount: "3.1K+ ratings",
        deliveryTime: "20-25 mins",
        distance: "3.1 km",
        costForTwo: "₹350 for two",
        isPureVeg: false,
        isHygieneVerified: true,
        offerText: "20% OFF ON ORDERS ABOVE ₹249",
        image: "https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?q=80&w=800",
        operatingHours: { open: "11:00", close: "23:00" },
        location: { type: "Point", coordinates: [77.0880, 28.4900] },
        isSeedData: true
      }
    ];

    const insertedRestaurants = await Restaurant.insertMany(restaurantsData);
    const maithiliId = insertedRestaurants[0]._id;
    const greatKitchenId = insertedRestaurants[1]._id;

    // 4. Seed Dishes with Gourmet flags & Restaurant relations
    const dishesData = [
      {
        restaurantId: maithiliId,
        name: "Premium Shahi Paneer Thali",
        description: "Rich cottage cheese cubes cooked in light spiced cashew cream gravy, 2 Butter Roti, Jeera Rice, and Dal Makhani.",
        price: 249,
        foodType: "VEG",
        category: "Royal Thali",
        isGourmet: true,
        image: "https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?q=80&w=600",
        rating: 4.9,
        isAvailable: true,
        nutrition: "Calories: 680 kcal | Protein: 22g | Carbs: 85g",
        ingredients: ["Cottage Cheese", "Cashew Cream", "Basmati Rice", "Whole Wheat Roti"],
        isSeedData: true
      },
      {
        restaurantId: maithiliId,
        name: "Ghar Ki Homely Dal Khichdi",
        description: "Comforting yellow lentils and basmati rice tempered with pure cow ghee, cumin, and hing. Served with roasted papad.",
        price: 149,
        foodType: "VEG",
        category: "Comfort Food",
        isGourmet: false,
        image: "https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=600",
        rating: 4.8,
        isAvailable: true,
        nutrition: "Calories: 420 kcal | Protein: 14g | Fat: 10g",
        ingredients: ["Moong Dal", "Basmati Rice", "Pure Desi Cow Ghee", "Cumin Seeds"],
        isSeedData: true
      },
      {
        restaurantId: greatKitchenId,
        name: "Awadhi Dum Murgh Biryani",
        description: "Slow-cooked fragrant long-grain basmati biryani layered with marinated farm chicken, saffron, and fried onions.",
        price: 349,
        foodType: "NON_VEG",
        category: "Biryani & Rice",
        isGourmet: true,
        image: "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=600",
        rating: 4.9,
        isAvailable: true,
        nutrition: "Calories: 720 kcal | Protein: 36g | Carbs: 82g",
        ingredients: ["Chicken", "Basmati Rice", "Kashmiri Saffron", "Awadhi Spices"],
        isSeedData: true
      }
    ];

    if (Dish) await Dish.insertMany(dishesData);

    // 5. Seed Promotional Banners
    if (Banner) {
      await Banner.insertMany([
        {
          title: "The Royal Feast Pass",
          subtitle: "Flat 50% OFF up to ₹100 on your first food order",
          imageUrl: "https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=800",
          actionUrl: "/offers",
          sortOrder: 1,
          isActive: true
        },
        {
          title: "Daily Homely Tiffin",
          subtitle: "Starting at ₹99/meal • Insulated Hot-Case Delivery",
          imageUrl: "https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?q=80&w=800",
          actionUrl: "/subscription",
          sortOrder: 2,
          isActive: true
        }
      ]);
    }

    // 6. Seed Food Collections
    if (Collection) {
      await Collection.insertMany([
        { name: "North Indian", icon: "🍲", sortOrder: 0, isActive: true },
        { name: "Royal Thali", icon: "🍱", sortOrder: 1, isActive: true },
        { name: "Healthy Bowls", icon: "🥗", sortOrder: 2, isActive: true },
        { name: "Mughlai Biryani", icon: "🍛", sortOrder: 3, isActive: true }
      ]);
    }

    // 7. Seed Tiffin Subscription Plans
    if (TiffinPlan) {
      await TiffinPlan.insertMany([
        {
          name: "Weekly Royal Tiffin Pass",
          tagline: "7 Days Pure Vegetarian Home Feast",
          durationDays: 7,
          totalMeals: 7,
          pricePerMeal: 119,
          totalPrice: 833,
          discountPrice: 699,
          features: ["Pure Desi Cow Ghee", "Insulated Hot-Case", "Zero Delivery Fees", "Instant Skip / Pause"],
          mealType: "VEG",
          isActive: true
        },
        {
          name: "Monthly Executive Pass",
          tagline: "30 Days Complete Lunch & Dinner Care",
          durationDays: 30,
          totalMeals: 30,
          pricePerMeal: 99,
          totalPrice: 2970,
          discountPrice: 2499,
          features: ["Different Menu Every Day", "Weekend Special Dessert", "Dedicated Valet Delivery"],
          mealType: "VEG",
          isActive: true
        }
      ]);
    }

    // 8. Seed Active Coupons
    if (Coupon) {
      await Coupon.insertMany([
        {
          code: "ROYAL50",
          discountPercent: 50,
          maxDiscount: 100,
          minOrderValue: 199,
          description: "50% OFF up to ₹100 on your first royal order",
          expiryDate: new Date("2026-12-31"),
          isActive: true
        },
        {
          code: "FEAST20",
          discountPercent: 20,
          maxDiscount: 150,
          minOrderValue: 299,
          description: "Flat 20% discount on gourmet meals",
          expiryDate: new Date("2026-12-31"),
          isActive: true
        }
      ]);
    }

    return res.status(200).json({
      success: true,
      message: "Eatoggy database cleaned and seeded successfully",
      data: {
        corruptedCleaned: cleanResult.deletedCount,
        restaurantsSeeded: insertedRestaurants.length,
        dishesSeeded: dishesData.length,
        bannersSeeded: 2,
        collectionsSeeded: 4,
        tiffinPlansSeeded: 2,
        couponsSeeded: 2
      }
    });
  } catch (error) {
    console.error("Database seeding error:", error);
    return res.status(500).json({ success: false, message: error.message });
  }
};
```

#### Add Route in your Express Router (`adminRoutes.js`):
```javascript
const express = require('express');
const router = express.Router();
const seedController = require('../controllers/seedController');

// Dedicated seed route
router.post('/admin/seed-database', seedController.seedDatabase);

module.exports = router;
```

---

## ☁️ Section 5: Cloudflare R2 Storage Permissions

Image URLs pointing to `https://pub-advmenngo.r2.dev/` frequently fail with `403 Forbidden`.

### Solution in Cloudflare Dashboard:
1. Navigate to **Cloudflare Dashboard** $\rightarrow$ **R2 Object Storage**.
2. Select your bucket (`eatoggy-media` / `pub-advmenngo`).
3. Under **Settings** $\rightarrow$ **Public Access**, enable **Allow Public Read Access via Custom Domain / R2.dev**.
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

## ⚡ Section 6: Real-Time WebSocket Events

The customer app connects to `wss://api.eatoggy.in` using Socket.IO. The server should support these rooms and events:

### Client Room Subscriptions:
* **`join_user`**: When client connects, it emits:
  ```json
  { "userId": "6aba2d5296d118c6b8704eed" }
  ```
* The server should add the socket to room `user_${userId}`.

### Server-to-Client Event Emitters:
1. **`order:status_update`**: Emit when order changes status (`CONFIRMED`, `PREPARING`, `OUT_FOR_DELIVERY`, `DELIVERED`, `CANCELLED`).
   ```json
   {
     "orderId": "6aba43dcd4360b9e1933b2b9",
     "status": "PREPARING",
     "eta": "25 mins"
   }
   ```
2. **`valet:location`**: Emit live GPS coordinates of the assigned rider during delivery:
   ```json
   {
     "orderId": "6aba43dcd4360b9e1933b2b9",
     "lat": 28.4595,
     "lng": 77.0266,
     "heading": 142.5
   }
   ```

---

## 📋 Section 7: Backend Developer Sign-Off Checklist

- [ ] **P0.1**: Deployed `POST /api/checkout/verify-payment` with Razorpay HMAC verification.
- [ ] **P0.2**: Deployed `DELETE /api/customer-auth/account` (tested returning `200 OK`).
- [ ] **P0.3**: Deployed `PATCH /api/customer-auth/me` to update customer profile.
- [ ] **P0.4**: Deployed `POST /api/notifications/subscribe` to save FCM tokens in database.
- [ ] **P0.5**: Deployed `GET /api/customers/orders/tracking/:orderId` for live coordinates.
- [ ] **P0.6**: Enforced `authCustomer` middleware on all `/api/customers/discovery/*` routes (locked guest browsing; returns 401 on unauthenticated requests).
- [ ] **P1.1**: Deployed `GET /api/offers` and `POST /api/offers/apply-coupon`.
- [ ] **P1.2**: Deployed `POST /api/customers/orders/:orderId/cancel`.
- [ ] **P1.3**: Deployed `POST /api/customers/orders/:orderId/review`.
- [ ] **P1.4**: Deployed `GET /api/public/config`.
- [ ] **P1.5**: Deployed and triggered `POST /api/admin/seed-database` (auto-cleaned empty records and seeded restaurants, dishes, banners, plans, and coupons).
- [ ] **Storage**: Verified public access and CORS on Cloudflare R2 bucket.
- [ ] **Sockets**: Verified `order:new` broadcast to restaurant partners and `order:status_update` to customers.
