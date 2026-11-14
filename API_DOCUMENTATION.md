# Eatoggy Backend API Specification

This document serves as the master reference for all APIs in the Eatoggy Postman Collection.

**Base URL**: `{{baseUrl}}/api` (e.g., `https://dash-eatoggy-backend.onrender.com/api`)

---

## 📁 1. Auth

Authentication and customer session management APIs.

### 1.1 Customer Send OTP
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/customer-auth/send-otp`
* **Description**: Send a 6-digit mobile OTP for customer authentication.
* **Auth**: Public (None)
* **Headers**:
  ```http
  Content-Type: application/json
  Accept: application/json
  ```
* **Request Body** (`raw / json`):
  ```json
  {
    "mobile": "9454310605"
  }
  ```

### 1.2 Customer Verify OTP (Existing Customer)
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/customer-auth/verify-otp`
* **Description**: Verify mobile OTP for an existing customer and return Customer JWT token.
* **Auth**: Public (None)
* **Headers**:
  ```http
  Content-Type: application/json
  Accept: application/json
  ```
* **Request Body** (`raw / json`):
  ```json
  {
    "mobile": "9454310605",
    "otp": "786507"
  }
  ```

### 1.3 Customer Verify OTP (New Customer - Auto Provision)
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/customer-auth/verify-otp`
* **Description**: Verify mobile OTP for a NEW mobile number. Auto-provisions customer account in database and returns Customer JWT token.
* **Auth**: Public (None)
* **Headers**:
  ```http
  Content-Type: application/json
  Accept: application/json
  ```
* **Request Body** (`raw / json`):
  ```json
  {
    "mobile": "9888877777",
    "otp": "123456"
  }
  ```

### 1.4 Customer Me Profile
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customer-auth/me`
* **Description**: Get authenticated customer profile information.
* **Auth**: Customer Bearer JWT
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```
* **Request Body**: None

### 1.5 [LEGACY] Customer Signup
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/customer-auth/signup`
* **Description**: Legacy signup endpoint with name, email, and password.
* **Auth**: Public (None)
* **Headers**:
  ```http
  Content-Type: application/json
  Accept: application/json
  ```
* **Request Body** (`raw / json`):
  ```json
  {
    "name": "Jane Customer",
    "mobile": "9876543210",
    "email": "customer@example.com",
    "password": "CustomerPass@123"
  }
  ```

### 1.6 [LEGACY] Customer Password Login
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/customer-auth/login`
* **Description**: Legacy password login endpoint.
* **Auth**: Public (None)
* **Headers**:
  ```http
  Content-Type: application/json
  Accept: application/json
  ```
* **Request Body** (`raw / json`):
  ```json
  {
    "mobile": "9876543210",
    "password": "CustomerPass@123"
  }
  ```

---

## 📁 2. Cart & Checkout

Cart operations, checkout initiation, audited pricing summaries, and live order tracking.

### 2.1 Get Cart
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/cart`
* **Description**: Fetch active customer cart.
* **Auth**: Customer Bearer JWT
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```
* **Request Body**: None

### 2.2 Add Item to Cart
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/cart/items`
* **Description**: Add an approved available menu item to customer cart.
* **Auth**: Customer Bearer JWT
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Content-Type: application/json
  Accept: application/json
  ```
* **Request Body** (`raw / json`):
  ```json
  {
    "menuItemId": "{{menuItemId}}",
    "quantity": 2
  }
  ```

### 2.3 Update Cart Item Quantity
* **Method**: `PATCH`
* **Endpoint**: `{{baseUrl}}/api/cart/items/:itemId`
* **Description**: Update quantity for an item in cart. Setting quantity to 0 removes the item.
* **Auth**: Customer Bearer JWT
* **Path Variables**:
  - `itemId`: The unique ID of the cart item (e.g., `6ab26e49389aa9a7c25711af`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Content-Type: application/json
  Accept: application/json
  ```
* **Request Body** (`raw / json`):
  ```json
  {
    "quantity": 4
  }
  ```

### 2.4 Remove Item from Cart
* **Method**: `DELETE`
* **Endpoint**: `{{baseUrl}}/api/cart/items/:itemId`
* **Description**: Remove a specific item from customer cart.
* **Auth**: Customer Bearer JWT
* **Path Variables**:
  - `itemId`: The unique ID of the cart item (e.g., `6ab26e49389aa9a7c25711af`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```
* **Request Body**: None

### 2.5 Clear Cart
* **Method**: `DELETE`
* **Endpoint**: `{{baseUrl}}/api/cart`
* **Description**: Clear all items from customer cart.
* **Auth**: Customer Bearer JWT
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```
* **Request Body**: None

### 2.6 Initiate Checkout Session
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/checkout/initiate`
* **Description**: Initiate checkout session with server-calculated price snapshot ready for payment.
* **Auth**: Customer Bearer JWT
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Content-Type: application/json
  Accept: application/json
  ```
* **Request Body** (`raw / json`):
  ```json
  {
    "addressId": "{{addressId}}"
  }
  ```

### 2.7 Get Checkout Summary & Audited Pricing
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/checkout/summary?addressId={{addressId}}`
* **Description**: Fetch server-calculated pricing breakdown (subtotal, GST 5%, packaging fee, delivery fee, platform fee, grand total).
* **Auth**: Customer Bearer JWT
* **Query Parameters**:
  - `addressId`: `{{addressId}}`
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```
* **Request Body**: None

### 2.8 Customer Live Order Tracking
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/orders/tracking/:orderId`
* **Description**: Fetch live tracking payload for customer including delivery status, assigned rider details, delivery OTP, and live rider location coordinates.
* **Auth**: Customer Bearer JWT
* **Path Variables**:
  - `orderId`: The order ID to track
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```
* **Request Body**: None

### 2.9 Customer - Initiate Subscription Checkout
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/customers/subscriptions`
* **Description**: Initiate subscription checkout and generate Razorpay payment order.
* **Auth**: Customer Bearer JWT
* **Status**: ✅ **Connected & Active** (`SubscriptionRepository.initiateSubscription` & `SubscriptionCalendarScreen`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Content-Type: application/json
  Accept: application/json
  ```
* **Request Body** (`raw / json`):
  ```json
  {
    "planId": "{{planId}}",
    "addressId": "{{addressId}}",
    "startDate": "2026-09-20"
  }
  ```

---

## 📁 3. Discovery

Restaurant discovery, menus, global search, banners, curated collections, and public meal plans.

### 3.1 Restaurant Discovery
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/discovery/restaurants`
* **Description**: Fetch approved restaurants for customer discovery.
* **Auth**: Public / Customer JWT
* **Headers**:
  ```http
  Accept: application/json
  ```

### 3.2 Restaurant Detail
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/discovery/restaurants/:id`
* **Description**: Fetch specific restaurant details by restaurant ID.
* **Path Variables**:
  - `id`: The restaurant ID (e.g., `6ab2a1e0497ff8fed6393e24`)
* **Headers**:
  ```http
  Accept: application/json
  ```

### 3.3 Restaurant Menu
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/discovery/restaurants/:id/menu`
* **Description**: Fetch approved menu for a restaurant organized by category.
* **Path Variables**:
  - `id`: The restaurant ID (e.g., `6ab2a1e0497ff8fed6393e24`)
* **Headers**:
  ```http
  Accept: application/json
  ```

### 3.4 Global Search
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/discovery/search?q=thali`
* **Description**: Global search for restaurants and menu items by keyword.
* **Query Parameters**:
  - `q`: Search query string (e.g., `thali`)
* **Headers**:
  ```http
  Accept: application/json
  ```

### 3.5 Get Banners
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/discovery/banners`
* **Description**: Fetch active promotional banners for the home screen.
* **Headers**:
  ```http
  Accept: application/json
  ```

### 3.6 Get Collections
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/discovery/collections`
* **Description**: Fetch active curated collections (e.g., Thali, Rice, Breads).
* **Headers**:
  ```http
  Accept: application/json
  ```

### 3.7 Get Gourmet Creations
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/discovery/gourmet`
* **Description**: Fetch featured / top gourmet menu items for customer discovery.
* **Headers**:
  ```http
  Accept: application/json
  ```

### 3.8 Customer - Public Tiffin Plans Discovery
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/tiffin-plans`
* **Description**: Public API to discover available active tiffin plans across restaurants.
* **Status**: ✅ **Connected & Active** (`SubscriptionRepository.getTiffinPlans`, `SubscriptionPlansBloc`, `SubscriptionCubit`, `SubscriptionPlansScreen`)
* **Headers**:
  ```http
  Accept: application/json
  ```

---

## 📁 4. Addresses

Delivery address management and location selection.

### 4.1 Get Customer Delivery Addresses
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/addresses`
* **Description**: Fetch saved customer delivery addresses.
* **Auth**: Customer Bearer JWT
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```

### 4.2 Create Delivery Address
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/customers/addresses`
* **Description**: Add a new delivery address for the customer.
* **Auth**: Customer Bearer JWT
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Content-Type: application/json
  Accept: application/json
  ```
* **Request Body** (`raw / json`):
  ```json
  {
    "name": "Rahul Sharma",
    "mobile": "9876543210",
    "addressLine1": "Flat 402, Sunshine Heights",
    "addressLine2": "Sector 62",
    "city": "Noida",
    "state": "Delhi NCR",
    "pincode": "201301",
    "label": "Home",
    "isDefault": true
  }
  ```

### 4.3 Delete Delivery Address
* **Method**: `DELETE`
* **Endpoint**: `{{baseUrl}}/api/customers/addresses/:id`
* **Description**: Delete a customer delivery address by address ID.
* **Auth**: Customer Bearer JWT
* **Path Variables**:
  - `id`: The address ID (e.g., `6ab272e169dcca664acf7743`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```

---

## 📁 5. Subscriptions & Tiffin Plans

Customer subscription lifecycle, payments, calendar skipping, pausing, resuming, and cancellation.

### 5.1 Verify Payment & Activate Subscription
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/customers/subscriptions/verify-payment`
* **Description**: Verify Razorpay payment signature and transition subscription to `ACTIVE` status.
* **Auth**: Customer Bearer JWT
* **Status**: ✅ **Connected & Active** (`SubscriptionRepository.verifyPayment` & `SubscriptionCalendarScreen`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Content-Type: application/json
  Accept: application/json
  ```
* **Request Body** (`raw / json`):
  ```json
  {
    "subscriptionId": "{{subscriptionId}}",
    "razorpay_order_id": "{{razorpay_order_id}}",
    "razorpay_payment_id": "pay_sim_123456",
    "razorpay_signature": "sig_sim_123456"
  }
  ```

### 5.2 Get My Subscriptions List
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/subscriptions`
* **Description**: Fetch active and past subscriptions for the logged-in customer.
* **Auth**: Customer Bearer JWT
* **Status**: ✅ **Connected & Active** (`SubscriptionRepository.getMySubscriptions` & `MySubscriptionScreen`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```

### 5.3 Get Subscription Detail Timeline
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/subscriptions/:id`
* **Description**: Fetch subscription details with calendar schedule and upcoming daily meal occurrences.
* **Auth**: Customer Bearer JWT
* **Status**: ✅ **Connected & Active** (`SubscriptionRepository.getSubscriptionDetail`)
* **Path Variables**:
  - `id`: The subscription ID (`{{subscriptionId}}`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```

### 5.4 Pause Subscription
* **Method**: `PATCH`
* **Endpoint**: `{{baseUrl}}/api/customers/subscriptions/:id/pause`
* **Description**: Pause active subscription deliveries.
* **Auth**: Customer Bearer JWT
* **Status**: ✅ **Connected & Active** (`SubscriptionRepository.pauseSubscription` & `MySubscriptionScreen`)
* **Path Variables**:
  - `id`: The subscription ID (`{{subscriptionId}}`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```

### 5.5 Resume Subscription
* **Method**: `PATCH`
* **Endpoint**: `{{baseUrl}}/api/customers/subscriptions/:id/resume`
* **Description**: Resume paused subscription deliveries.
* **Auth**: Customer Bearer JWT
* **Status**: ✅ **Connected & Active** (`SubscriptionRepository.resumeSubscription` & `MySubscriptionScreen`)
* **Path Variables**:
  - `id`: The subscription ID (`{{subscriptionId}}`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```

### 5.6 Skip Scheduled Occurrence
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/customers/subscriptions/:id/occurrences/:occId/skip`
* **Description**: Skip a specific upcoming daily meal occurrence on the subscription calendar.
* **Auth**: Customer Bearer JWT
* **Status**: ✅ **Connected & Active** (`SubscriptionRepository.skipOccurrence` & interactive "Skip Meal" button on `MySubscriptionScreen`)
* **Path Variables**:
  - `id`: The subscription ID (`{{subscriptionId}}`)
  - `occId`: The occurrence ID (`{{occurrenceId}}`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```

### 5.7 Cancel Subscription
* **Method**: `PATCH`
* **Endpoint**: `{{baseUrl}}/api/customers/subscriptions/:id/cancel`
* **Description**: Cancel an active subscription.
* **Auth**: Customer Bearer JWT
* **Status**: ✅ **Connected & Active** (`SubscriptionRepository.cancelSubscription` & `SubscriptionCubit`)
* **Path Variables**:
  - `id`: The subscription ID (`{{subscriptionId}}`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```

---

## 📁 6. Reviews & Support

Order ratings, customer review history, and helpdesk support tickets.

### 6.1 Submit Order Review
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/customers/orders/:orderId/review`
* **Description**: Customer submits a 1-5 star review with sub-ratings and photos for a delivered order.
* **Auth**: Customer Bearer JWT
* **Status**: ✅ **Connected & Active** (`ReviewRepository.submitOrderReview` & `WriteReviewScreen`)
* **Path Variables**:
  - `orderId`: The completed order ID
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Content-Type: application/json
  Accept: application/json
  ```
* **Request Body** (`raw / json`):
  ```json
  {
    "rating": 5,
    "foodRating": 5,
    "deliveryRating": 5,
    "comment": "Delicious food and super fast delivery!",
    "images": [
      "https://images.unsplash.com/photo-1546069901-ba9599a7e63c"
    ]
  }
  ```

### 6.2 Get My Submitted Reviews
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/reviews`
* **Description**: Fetch all reviews previously submitted by the authenticated customer.
* **Auth**: Customer Bearer JWT
* **Status**: ✅ **Connected & Active** (`ReviewRepository.getMyReviews`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```

### 6.3 Get My Support Tickets
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/support/tickets/my`
* **Description**: Fetch support tickets and issue threads submitted by the authenticated customer.
* **Auth**: Customer Bearer JWT
* **Status**: ✅ **Connected & Active** (`SupportRepository.getMyTickets` & `SupportScreen`)
* **Headers**:
  ```http
  Authorization: Bearer {{customerToken}}
  Accept: application/json
  ```

---

## 📁 7. Missing Required APIs (App Requirements)

These endpoints are strictly required by the Flutter client screens but are currently missing from the Postman collection and backend:

### 7.1 Verify Food Order Payment & Place Order
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/checkout/verify-payment`
* **Description**: Verifies Razorpay payment signature and confirms food order creation from active checkout session.
* **Auth**: Customer Bearer JWT
* **Request Body** (`raw / json`):
  ```json
  {
    "checkoutSessionId": "chk_session_123456",
    "razorpayPaymentId": "pay_xyz987654",
    "razorpayOrderId": "order_abc123456",
    "razorpaySignature": "9f83...signature"
  }
  ```

### 7.2 Get Customer Orders History
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/orders`
* **Description**: Fetch customer's active, past, and cancelled order history for `OrdersScreen`.
* **Auth**: Customer Bearer JWT
* **Query Parameters**:
  - `status`: `active` | `delivered` | `cancelled`
  - `page`: `1`
  - `limit`: `20`

### 7.3 Get Order Details
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/customers/orders/:orderId`
* **Description**: Fetch complete item breakdown, delivery address, taxes, and timeline status for `OrderDetailsScreen`.
* **Auth**: Customer Bearer JWT

### 7.4 Cancel Active Order
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/customers/orders/:orderId/cancel`
* **Description**: Cancel an active food order before restaurant preparation starts.
* **Auth**: Customer Bearer JWT
* **Request Body** (`raw / json`):
  ```json
  {
    "reason": "Placed by mistake / Changed mind"
  }
  ```

### 7.5 Get Food Categories
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/categories`
* **Description**: Fetch dish categories (*"Royal Thali"*, *"Curries"*, *"Breads"*, *"Desserts"*) for `MenuScreen` filter tabs.
* **Auth**: Public

### 7.6 Get Active Coupons & Offers
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/offers`
* **Description**: Fetch active promo coupons (*"ROYALTREAT50"*, *"FESTIVE60"*) for `OffersScreen`.
* **Auth**: Public / Customer Bearer JWT

### 7.7 Apply Coupon to Cart
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/cart/apply-coupon`
* **Description**: Server-side validation of promo code against active cart total.
* **Auth**: Customer Bearer JWT
* **Request Body** (`raw / json`):
  ```json
  {
    "couponCode": "ROYALTREAT50"
  }
  ```

### 7.8 Update Customer Profile
* **Method**: `PATCH`
* **Endpoint**: `{{baseUrl}}/api/customer-auth/me`
* **Description**: Update customer display name, email, dietary preferences, or profile image.
* **Auth**: Customer Bearer JWT
* **Request Body** (`raw / json`):
  ```json
  {
    "name": "Aman Sharma",
    "email": "aman@example.com",
    "dietaryPreference": "Veg"
  }
  ```

### 7.9 Update Saved Address / Set Default
* **Method**: `PATCH`
* **Endpoint**: `{{baseUrl}}/api/customers/addresses/:id`
* **Description**: Edit an existing saved delivery address or mark it as default.
* **Auth**: Customer Bearer JWT
* **Request Body** (`raw / json`):
  ```json
  {
    "isDefault": true,
    "landmark": "Near Central Park"
  }
  ```

### 7.10 Register Push Notification (FCM) Token
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/notifications/subscribe`
* **Description**: Register device FCM token for live delivery push notifications.
* **Auth**: Customer Bearer JWT
* **Request Body** (`raw / json`):
  ```json
  {
    "fcmToken": "c_xxxx...xxxx",
    "deviceType": "android"
  }
  ```

### 7.11 Customer Logout
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/customer-auth/logout`
* **Description**: Invalidate customer refresh token and session on server.
* **Auth**: Customer Bearer JWT

### 7.12 Check Delivery Serviceability
* **Method**: `GET`
* **Endpoint**: `{{baseUrl}}/api/serviceability/check?lat={{lat}}&lng={{lng}}`
* **Description**: Verify if customer's selected location falls within Eatoggy's cloud kitchen delivery radius.
* **Auth**: Public

### 7.13 Create Support Ticket / Report Issue
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/support/tickets`
* **Description**: Customer raises a complaint or issue regarding missing items, delivery delay, or quality.
* **Auth**: Customer Bearer JWT
* **Request Body** (`raw / json`):
  ```json
  {
    "orderId": "order_12345",
    "category": "FOOD_QUALITY",
    "subject": "Missing dish in delivery",
    "description": "The item Dal Makhani was not in the package.",
    "images": [
      "https://images.unsplash.com/photo-1546069901-ba9599a7e63c"
    ]
  }
  ```

### 7.14 Customer Support Ticket Reply
* **Method**: `POST`
* **Endpoint**: `{{baseUrl}}/api/support/tickets/:id/reply`
* **Description**: Customer sends a follow-up message or chat reply within an existing support ticket thread.
* **Auth**: Customer Bearer JWT
* **Request Body** (`raw / json`):
  ```json
  {
    "message": "Attached is the photo of the bill and food package."
  }
  ```

### 7.15 Delete Customer Account
* **Method**: `DELETE`
* **Endpoint**: `{{baseUrl}}/api/customer-auth/account`
* **Description**: Permanent account deletion request (**Mandatory for Google Play Store and Apple App Store compliance**).
* **Auth**: Customer Bearer JWT
* **Request Body** (`raw / json`):
  ```json
  {
    "reason": "Account no longer needed"
  }
  ```

---

## 📁 8. Obsolete & Legacy Endpoints (To Purge From Codebase)

The following endpoints declared in `lib/core/constants/api_constants.dart` originate from a previous home-services template ("NOROZZ") and are **not relevant** for Eatoggy:

* ❌ `services` (`$baseUrl/services`)
* ❌ `serviceDetails` (`$baseUrl/services/details/:id`)
* ❌ `servicePackages` (`$baseUrl/packages/service/:serviceId`)
* ❌ `featuredServices` (`$baseUrl/customer/services/featured`)
* ❌ `bookings` / `myBookings` (`$baseUrl/bookings`)
* ❌ `starterPack` (`$baseUrl/customer/starter-pack`)
* ❌ `aiChatHistory` / `aiChatSend` (`$baseUrl/customer/ai-chat`)
* ❌ `translate` / `translateBatch` (`$baseUrl/translation/translate`)
* ❌ `customerWallet` / `addMoney` (unless a prepaid wallet is formally introduced)

