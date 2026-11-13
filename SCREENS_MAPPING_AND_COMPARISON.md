# EATOGGY App Screens Audit, SVG Mapping & Design Comparison

## Executive Summary

A comprehensive audit was performed comparing the **existing Flutter application (`lib/features/`)** against the newly added **Figma SVG Layout designs (`EATOGGY SVG Layout/`)**.

An executive Excel spreadsheet has been generated in the project root:
📁 **[`EATOGGY_Screens_Mapping_And_Comparison.xlsx`](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/EATOGGY_Screens_Mapping_And_Comparison.xlsx)**

---

## 1. High-Level Findings & Core Changes

### 🎨 1. Major Visual & Brand Theme Shift
| Attribute | Current Flutter App | New SVG Layout Design |
| :--- | :--- | :--- |
| **Background Color** | `#11110F` (Pitch Dark / Black) | `#FAF7F2` (Warm Ivory / Alabaster Cream) |
| **Primary Accent** | `#D9A24F` & `#F1CC8A` (Gold Gradient) | `#DC2626` & `#B91C1C` (Imperial Royal Red) |
| **Primary Text** | `#FFF1D2` (Pale Vanilla Gold) | `#1C1917` (Deep Charcoal Black) |
| **Secondary Text** | `#B8B4AE` & `#77736D` (Muted Ash) | `#78716C` (Stone-500) & `#A8A29E` (Stone-400) |
| **Cards & Surfaces** | `#191714` (Dark Charcoal) | `#FFFFFF` (White) with `#E7E5E4` (Stone-200) borders |
| **CTA Buttons** | Gold gradient pills | High-contrast Solid Red (`#DC2626`) buttons with white text |
| **Brand Concept** | Generic restaurant aggregator (Dark mode) | **"Authentic Home Cooked Luxury / FeastBox / Royal Tiffin Subscription"** |

---

### 🚨 2. Missing Screens & Components Identified
1. **Notifications Screen (`c30-notifications.svg`)**:
   - **Current State**: MISSING in Flutter app! There is only a background `notification_service.dart`.
   - **New Requirement**: Create `lib/features/notifications/presentation/notifications_screen.dart`, add `/notifications` route, filter tabs `[All, Orders, Offers, System]`, and link AppBar notification bell.
2. **Tiffin Subscription Announcement Popup (`c10-home-popup.svg`)**:
   - **Current State**: MISSING.
   - **New Requirement**: Dismissible promotional card/modal overlay on Home introducing weekly/monthly tiffin passes with "Explore Plans" CTA.
3. **Dedicated Subscription Checkout Screen (`c26-subscription-checkout.svg`)**:
   - **Current State**: Customizing subscription immediately triggers payment rather than showing a review order screen.
   - **New Requirement**: Dedicated "Confirm Plan" screen displaying plan breakdown, delivery schedule, address, taxes, and "Pay & Start Subscription" CTA.
4. **Onboarding Slide 2 Missing Copy**:
   - **Current State**: In [onboarding_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/onboarding/presentation/onboarding_screen.dart#L26-L29), slide 2 is missing the description text (`'description': ...`).

---

### 🧩 3. App-Only Screens (Numbered Gaps in SVG Sequence)
The SVG layout files use a numbering system (`c01` to `c38`). The missing numbers in the SVG sequence correspond exactly to active screens in the Flutter app:
- **`c08`**: [select_location_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/location/presentation/select_location_screen.dart) (Interactive Map Location Picker)
- **`c16/c17`**: [payment_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/payment/presentation/payment_screen.dart) (Razorpay Gateway / Payment processing)
- **`c21`**: [order_details_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/orders/presentation/order_details_screen.dart) (Order breakdown & Invoice receipt)
- **`c28`**: [subscription_calendar_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/subscription/presentation/subscription_calendar_screen.dart) (Daily meal delivery calendar)
- **`c33`**: [my_reviews_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/orders/presentation/my_reviews_screen.dart) (Customer review history)
- **`c36`**: [ticket_detail_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/support/presentation/ticket_detail_screen.dart) (Support ticket conversation thread)

---

## 2. Complete Screen-by-Screen Mapping Table

| ID | Module | Screen Name | Flutter File | SVG File | Status | Key Differences & What Is Changing |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **c01** | Splash | Splash Screen | [splash_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/splash/presentation/splash_screen.dart) | `c01-splash.svg` | 🟠 Major Reskin | Theme from `#11110F` to `#FAF7F2`; replace gold glow with centered brand crest. |
| **c02** | Onboarding | Authentic Home Food | [onboarding_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/onboarding/presentation/onboarding_screen.dart) | `c02-onboarding-home-food.svg` | 🟢 Minor Reskin | Ivory background `#FAF7F2`, white bottom card, red `#DC2626` "Next" button. |
| **c03** | Onboarding | Fresh Daily Meals | [onboarding_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/onboarding/presentation/onboarding_screen.dart) | `c03-onboarding-fresh-meals.svg` | 🟣 Bug Fix & Style | Fix missing description text in Dart; add top "Back" button; red "Next" CTA. |
| **c04** | Onboarding | Seamless Delivery | [onboarding_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/onboarding/presentation/onboarding_screen.dart) | `c04-onboarding-delivery.svg` | 🟢 Minor Reskin | Hot-case delivery illustration, red `#DC2626` "Get Started" button. |
| **c05** | Auth | Login Screen | [login_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/authentication/presentation/login_screen.dart) | `c05-login.svg` | 🟠 Major Reskin | Invert dark theme to ivory; clean input box with stone border & `+91`; red "Continue" CTA. |
| **c06** | Auth | OTP Verification | [otp_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/authentication/presentation/otp_screen.dart) | `c06-otp-verification.svg` | 🟣 Field Polish | 4 clean square PIN boxes with red focus border; timer "Resend code in 0:45"; red "Verify & Proceed". |
| **c07** | Location | Location Permission | [location_permission_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/location/presentation/location_permission_screen.dart) | `c07-location-permission.svg` | 🟢 Minor Reskin | Secondary button changed to "Remind Later"; red primary button; light pin graphic. |
| **c08** | Location | Select Location (Map) | [select_location_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/location/presentation/select_location_screen.dart) | *(App Only)* | 🔵 App Only | Retain map logic; reskin bottom sheet & search bar to ivory/white with red button. |
| **c09** | Location | Add Address / Delivery Details | [add_address_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/location/presentation/add_address_screen.dart) | `c09-add-address.svg` | 🟣 Form Enhancement | Rename to "Delivery Details"; infer City/State from Pincode/GPS; clean uppercase labels; red CTA. |
| **c10** | Home | Home Dashboard | [home_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/home/presentation/home_screen.dart) | `c10-home.svg` | 🟠 Major Reskin | Complete reskin to `#FAF7F2`; add 2 Value Prop Cards; add "Add to Box" buttons on dishes; update category pills. |
| **c10-pop** | Home | Tiffin Service Popup | [home_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/home/presentation/home_screen.dart) | `c10-home-popup.svg` | 🟡 New Component | New dismissible announcement banner/modal for tiffin passes with "Explore Plans" CTA. |
| **c11** | Search | Search Screen | [search_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/search/presentation/search_screen.dart) | `c11-search.svg` | 🟣 Feature Enhancement | Added "RECENT ENQUIRIES" tag cloud; added "TRENDING DISHES" section when query is blank. |
| **c12** | Menu | Menu & Categories | [menu_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/menu/presentation/menu_screen.dart) | `c12-menu-categories.svg` | 🟠 Major Reskin | "The Royal Menu" title; rounded category tabs; clean dish cards; red "+ Add" pill buttons. |
| **c13** | Food | Food Item Detail | [food_detail_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/food_detail/presentation/food_detail_screen.dart) | `c13-food-detail.svg` | 🟢 Minor Reskin | Logic matches! Update background to `#FAF7F2`; add "Imperial" & "Hygiene Verified" badges; red bottom CTA. |
| **c14** | Cart | Shopping Box / Cart | [cart_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/cart/presentation/cart_screen.dart) | `c14-cart.svg` | 🟢 Minor Reskin | "Your Box" header; "LUXURY BILL SUMMARY"; rename fee to "Insulated Hot-Case Delivery"; red CTA. |
| **c15** | Checkout | Checkout & Slots | [checkout_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/checkout/presentation/checkout_screen.dart) | `c15-checkout.svg` | 🟢 Minor Reskin | Slot selection as explicit selectable cards; payment radio options; red "Pay & Place Order" button. |
| **c16/17** | Payment | Payment Processing | [payment_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/payment/presentation/payment_screen.dart) | *(App Only)* | 🔵 App Only | Update background and loading indicator to ivory and red; retain Razorpay SDK logic. |
| **c18** | Orders | Order Success | [order_success_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/orders/presentation/order_success_screen.dart) | `c18-order-success.svg` | 🟢 Minor Reskin | Ivory background; "Insulated Delivery System: Active Hot-Case" info card; red "Track Your Order →". |
| **c19** | Orders | Active Orders Tab | [orders_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/orders/presentation/orders_screen.dart) | `c19-orders-active.svg` | 🟢 Minor Reskin | Added ETA countdown badge ("14 mins remaining"); insulated box delivery tag; red "Track Live Order" button. |
| **c20** | Orders | Orders History Tab | [orders_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/orders/presentation/orders_screen.dart) | `c20-orders-history.svg` | 🟢 Minor Reskin | Redesigned buttons: outlined "Reorder Pack" & solid red "Rate Meal"; payment method chip. |
| **c21** | Orders | Order Details | [order_details_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/orders/presentation/order_details_screen.dart) | *(App Only)* | 🔵 App Only | Update screen background to ivory; white invoice cards with stone borders; light theme stepper. |
| **c22** | Tracking | Live Tracking | [tracking_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/tracking/presentation/tracking_screen.dart) | `c22-live-tracking.svg` | 🟠 Major Reskin | Replace dark Google Maps JSON with daytime light style; white floating card with "Hot-case Insulated" badge. |
| **c23** | Subscription | Royal Meal Plans | [subscription_plans_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/subscription/presentation/subscription_plans_screen.dart) | `c23-subscription-plans.svg` | 🟠 Major Reskin | Dedicated "Royal Meal Plans" screen; "SAVE 15%" badge; per-meal breakdown; red "View Plan Details" CTA. |
| **c24** | Subscription | Plan Detail | [plan_detail_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/subscription/presentation/plan_detail_screen.dart) | `c24-subscription-detail.svg` | 🟣 Form Enhancement | Added "Choose Meal Type" (Pure Veg vs Mixed); pricing breakdown table; red "Continue to Customize" CTA. |
| **c25** | Subscription | Customize Subscription | [customize_subscription_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/subscription/presentation/customize_subscription_screen.dart) | `c25-customize-subscription.svg` | 🟣 Form Enhancement | Added "Allergies & Dietary Notes" text area; Lunch/Dinner box time window cards; circular day pills. |
| **c26** | Subscription | Confirm Plan (Checkout) | [customize_subscription_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/subscription/presentation/customize_subscription_screen.dart) | `c26-subscription-checkout.svg` | 🔴 New Screen | Build dedicated pre-payment review screen with plan summary, schedule, address, tax summary, red CTA. |
| **c27** | Subscription | My Subscription | [my_subscription_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/subscription/presentation/my_subscription_screen.dart) | `c27-my-subscription.svg` | 🟢 Minor Reskin | Added "DELIVERY TIP" info card; restyled remaining meals progress card; stone border action buttons. |
| **c28** | Subscription | Subscription Calendar | [subscription_calendar_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/subscription/presentation/subscription_calendar_screen.dart) | *(App Only)* | 🔵 App Only | Update calendar grid and daily meal modal from dark theme to light ivory (#FAF7F2). |
| **c29** | Offers | Offers & Coupons | [offers_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/offers/presentation/offers_screen.dart) | `c29-offers-coupons.svg` | 🟢 Minor Reskin | Logic matches! Restyle coupons with clean white ticket borders, red badges, and applied feedback banner. |
| **c30** | Notifications | Notifications Screen | *(MISSING - To Build)* | `c30-notifications.svg` | 🔴 New Screen | Build dedicated screen with [All, Orders, Offers, System] tabs, "Mark All Read", and connect to AppBar bell. |
| **c31** | Profile | Profile Screen | [profile_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/profile/presentation/profile_screen.dart) | `c31-profile.svg` | 🟢 Minor Reskin | Added "ROYAL PATRON MEMBER" badge; live status badges on menu items ("3 Active"); light ivory theme. |
| **c32** | Location | Saved Addresses | [saved_addresses_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/location/presentation/saved_addresses_screen.dart) | `c32-saved-addresses.svg` | 🟢 Minor Reskin | Clean white address cards with stone border; prominent red "+ Add New Address" button. |
| **c33** | Orders | My Reviews | [my_reviews_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/orders/presentation/my_reviews_screen.dart) | *(App Only)* | 🔵 App Only | Update background and cards to light ivory and white; retain review list logic. |
| **c34** | Orders | Write a Review | [write_review_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/orders/presentation/write_review_screen.dart) | `c34-ratings-review.svg` | 🟢 Minor Reskin | Logic matches 100%! Reskin to ivory; gold stars `#F59E0B`; red "Submit Royal Review" button. |
| **c35** | Support | Help & Support | [support_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/support/presentation/support_screen.dart) | `c35-help-support.svg` | 🟣 Form Enhancement | Added "Recent Order Assistance" quick card; FAQ category chips; direct contact buttons (Chat/Call/Ticket). |
| **c36** | Support | Ticket Detail | [ticket_detail_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/support/presentation/ticket_detail_screen.dart) | *(App Only)* | 🔵 App Only | Update background and chat bubbles to light theme; retain ticket message polling. |
| **c37** | Settings | Settings Screen | [settings_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/profile/presentation/settings_screen.dart) | `c37-settings.svg` | 🟢 Minor Reskin | Restyle cards to white with stone borders; red switch active tracks; red "Log Out" button. |
| **c38** | Settings | Logout Modal | [settings_screen.dart](file:///Users/dhruva/Documents/KMP%20Android/Eatoggy/Eatoggy-usserapp/eatoggy-userapp/lib/features/profile/presentation/settings_screen.dart) | `c38-logout-confirmation.svg` | 🟡 New Component | Red exit icon header; updated subscription warning text; destructive solid red "Log Out" button. |

---

## 3. Recommended Implementation Roadmap

1. **Step 1: Update Global Design Tokens**
   - Update `AppColors.dart` to define `#FAF7F2` (background), `#DC2626` (primary red), `#1C1917` (primary text), `#E7E5E4` (borders), `#F59E0B` (ratings gold).
2. **Step 2: Build Missing Notifications Screen (`c30`)**
   - Implement `NotificationsScreen`, register route `/notifications`, and connect header bell icon.
3. **Step 3: Build Subscription Checkout Review (`c26`)**
   - Insert "Confirm Plan" screen before payment session initiation.
4. **Step 4: Add Home Tiffin Promo Popup (`c10-popup`)**
   - Create dismissible modal banner with local persistence.
5. **Step 5: Reskin Screens in Batches**
   - Batch A: Auth & Onboarding (`c01` - `c06`)
   - Batch B: Home, Search, Menu, Food Detail (`c10` - `c13`)
   - Batch C: Cart, Checkout, Orders, Tracking (`c14` - `c22`)
   - Batch D: Subscription Suite (`c23` - `c27`)
   - Batch E: Profile, Addresses, Settings, Support (`c31` - `c38`)
