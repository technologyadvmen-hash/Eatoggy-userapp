import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

def build_excel_report():
    wb = openpyxl.Workbook()

    # Define color styles
    navy_header_fill = PatternFill(start_color="1C1917", end_color="1C1917", fill_type="solid")
    sub_header_fill = PatternFill(start_color="292524", end_color="292524", fill_type="solid")
    
    header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    title_font = Font(name="Calibri", size=14, bold=True, color="FFFFFF")
    bold_font = Font(name="Calibri", size=10, bold=True)
    regular_font = Font(name="Calibri", size=10)
    
    # Status fills
    status_fills = {
        "Major Reskin (Theme Shift)": PatternFill(start_color="FFEAD2", end_color="FFEAD2", fill_type="solid"), # soft orange
        "Minor Reskin & Style Update": PatternFill(start_color="D1E7DD", end_color="D1E7DD", fill_type="solid"), # soft green
        "New Screen to Build": PatternFill(start_color="F8D7DA", end_color="F8D7DA", fill_type="solid"), # soft red
        "New Modal / Component": PatternFill(start_color="FFF3CD", end_color="FFF3CD", fill_type="solid"), # soft yellow
        "App Only (No SVG Design)": PatternFill(start_color="CFE2FF", end_color="CFE2FF", fill_type="solid"), # soft blue
        "Form / Field Enhancement": PatternFill(start_color="E2D9F3", end_color="E2D9F3", fill_type="solid"), # soft purple
    }
    
    priority_fills = {
        "Critical": PatternFill(start_color="F8D7DA", end_color="F8D7DA", fill_type="solid"),
        "High": PatternFill(start_color="FFEAD2", end_color="FFEAD2", fill_type="solid"),
        "Medium": PatternFill(start_color="FFF3CD", end_color="FFF3CD", fill_type="solid"),
        "Low": PatternFill(start_color="E2E3E5", end_color="E2E3E5", fill_type="solid"),
    }

    thin_border_side = Side(border_style="thin", color="D6D3D1")
    border_all = Border(left=thin_border_side, right=thin_border_side, top=thin_border_side, bottom=thin_border_side)
    
    # -------------------------------------------------------------
    # SHEET 1: SCREEN MAPPING & COMPARISON
    # -------------------------------------------------------------
    ws1 = wb.active
    ws1.title = "Screen Mapping & Comparison"
    ws1.views.sheetView[0].showGridLines = True
    
    headers_ws1 = [
        "Design ID",
        "Module",
        "Screen Name",
        "Flutter Dart Screen Path",
        "SVG Layout File",
        "Current Flutter App State",
        "New SVG Layout Specification",
        "Mapping Status",
        "Key Differences & What Is Changing",
        "Backend / Data Requirements",
        "Priority"
    ]
    
    data_ws1 = [
        [
            "c01",
            "Splash",
            "Splash Screen",
            "lib/features/splash/presentation/splash_screen.dart",
            "EATOGGY SVG Layout/c01-splash.svg",
            "Dark theme (#11110F), radial gold glow, gold animated logo text & subtitle 'LUXURY DINING EXPERIENCE', watchdog timer & cubit router.",
            "Light cream theme (#FAF7F2), minimalist Eatoggy luxury brand crest logo centered on alabaster ivory background.",
            "Major Reskin (Theme Shift)",
            "1. Background changed from dark (#11110F) to light ivory (#FAF7F2).\n2. Replaced radial gold glow with clean brand crest logo.\n3. Updated typography and loading indicators to royal aesthetic.",
            "No backend changes. Uses existing session check & onboarding flag.",
            "High"
        ],
        [
            "c02",
            "Onboarding",
            "Onboarding 1: Authentic Home Food",
            "lib/features/onboarding/presentation/onboarding_screen.dart (Slide 1)",
            "EATOGGY SVG Layout/c02-onboarding-home-food.svg",
            "Dark theme with top half image asset (o1.png) blended into #11110F background via gradient. Title 'Authentic Home Cooked Luxury'.",
            "Light cream theme (#FAF7F2), top illustration, rounded white container card with charcoal title, stone description, 'Skip' link, red 'Next' button.",
            "Minor Reskin & Style Update",
            "1. Background shifted from dark to ivory (#FAF7F2).\n2. Bottom sheet container uses clean white card styling with rounded top corners.\n3. 'Next' button changed to royal red (#DC2626) with white text.",
            "No backend changes.",
            "Medium"
        ],
        [
            "c03",
            "Onboarding",
            "Onboarding 2: Fresh Meals",
            "lib/features/onboarding/presentation/onboarding_screen.dart (Slide 2)",
            "EATOGGY SVG Layout/c03-onboarding-fresh-meals.svg",
            "Dart code is MISSING description text! Only has title 'Fresh Daily Cooking' and image 'assets/o2.png'. Dark gradient styling.",
            "Complete slide with title, full description ('Savor meticulously prepared traditional meals crafted by culinary experts...'), step 2 dot active, 'Back' and 'Skip' links, red 'Next' CTA.",
            "Form / Field Enhancement",
            "1. BUG FIX: Add missing description text to Slide 2 in Dart.\n2. Add 'Back' button in top navigation bar.\n3. Theme change to ivory background and red CTA button.",
            "No backend changes.",
            "Medium"
        ],
        [
            "c04",
            "Onboarding",
            "Onboarding 3: Seamless Delivery",
            "lib/features/onboarding/presentation/onboarding_screen.dart (Slide 3)",
            "EATOGGY SVG Layout/c04-onboarding-delivery.svg",
            "Slide 3 with 'Seamless Doorstep Delivery', insulated hot-case text, gold 'Get Started' button on dark background.",
            "Ivory background (#FAF7F2), insulated hot-case illustration, step 3 active dot, full-width red 'Get Started' button.",
            "Minor Reskin & Style Update",
            "1. CTA button changed from gold gradient to solid red (#DC2626).\n2. Background and text color inverted from dark to ivory/charcoal.",
            "Sets local preference 'has_completed_onboarding'.",
            "Medium"
        ],
        [
            "c05",
            "Auth",
            "Login Screen",
            "lib/features/authentication/presentation/login_screen.dart",
            "EATOGGY SVG Layout/c05-login.svg",
            "Dark theme (#11110F), gold logo, gold heading 'Welcome to EATOGGY', gold input borders, gold 'Continue' button.",
            "Light cream theme (#FAF7F2), deep charcoal heading (#1C1917), clean input box with stone border (#E7E5E4) and '+91' country code, bold red 'Continue' button (#DC2626), stone terms text.",
            "Major Reskin (Theme Shift)",
            "1. Total visual inversion from dark gold to cream/charcoal/red.\n2. Input field styling updated to modern bordered container.\n3. Button updated to solid red (#DC2626) with high contrast.",
            "Existing API: POST /api/v1/auth/customer/login-register.",
            "High"
        ],
        [
            "c06",
            "Auth",
            "OTP Verification",
            "lib/features/authentication/presentation/otp_screen.dart",
            "EATOGGY SVG Layout/c06-otp-verification.svg",
            "Dark theme, gold OTP digit input fields, 'Verify Code', 'Resend Code' text link, gold verify button.",
            "Light cream theme (#FAF7F2), 'Verify Code' header, mobile number confirmation text, 4 square PIN boxes with active red focus border, countdown timer 'Resend code in 0:45', 'Change Mobile Number', red 'Verify & Proceed' CTA.",
            "Form / Field Enhancement",
            "1. PIN input boxes updated to 4 clean square containers with stone/red active border.\n2. Timer display format aligned ('Resend code in 0:45').\n3. 'Verify & Proceed' primary red button.",
            "Existing API: POST /api/v1/auth/customer/verify-otp.",
            "High"
        ],
        [
            "c07",
            "Location",
            "Location Permission",
            "lib/features/location/presentation/location_permission_screen.dart",
            "EATOGGY SVG Layout/c07-location-permission.svg",
            "Dark theme with circular gold glow and gold pin icon, 'Enable Location Services', 'Allow Location Access' gold button, 'Enter Location Manually' secondary button.",
            "Light cream theme (#FAF7F2), location pin illustration, 'Enable Location Services', red primary button 'Allow Location Access', secondary text button 'Remind Later'.",
            "Minor Reskin & Style Update",
            "1. Secondary button changed from 'Enter Location Manually' to 'Remind Later'.\n2. Primary button updated to red (#DC2626).\n3. Replaced gold circular glow with light theme pin graphic.",
            "No backend changes. Uses geolocator plugin.",
            "Medium"
        ],
        [
            "c08 [Gap]",
            "Location",
            "Select Location / Map View",
            "lib/features/location/presentation/select_location_screen.dart",
            "Missing in SVG exports (Numbered sequence gap between c07 & c09)",
            "Full Google Map screen (712 lines) with interactive pin dragging, Places autocomplete search, GPS button, bottom confirmation sheet.",
            "N/A (App-only screen, represents step between location permission and address form).",
            "App Only (No SVG Design)",
            "1. Retain existing full-featured map logic.\n2. Update bottom confirmation sheet and search bar styling from dark surface (#191714) to light cream (#FAF7F2) and white.\n3. Change confirmation button to red (#DC2626).",
            "Existing Google Places & Geocoding integration.",
            "Medium"
        ],
        [
            "c09",
            "Location",
            "Add Address / Delivery Details",
            "lib/features/location/presentation/add_address_screen.dart",
            "EATOGGY SVG Layout/c09-add-address.svg",
            "Title 'Add Delivery Address', 2 separate sections ('Contact Details' & 'Address Details'), fields for Name, Phone, Flat, Street, Landmark, City, State, Pincode, dark theme.",
            "Title 'Delivery Details', streamlined single card layout: RECEIVER'S NAME, HOUSE / FLAT / BLOCK NO., STREET / ROAD / AREA, LANDMARK (OPTIONAL), PINCODE, SAVE ADDRESS AS chips (Home, Work, Other), red 'Save Address & Continue' CTA.",
            "Form / Field Enhancement",
            "1. Header renamed from 'Add Delivery Address' to 'Delivery Details'.\n2. Streamlined form: City/State automatically inferred from Pincode/GPS rather than cluttered extra inputs.\n3. Modern uppercase input labels (Stone-500) with clean light input boxes.\n4. Save address chips and red CTA button.",
            "Matches existing API: POST /api/v1/customer/addresses.",
            "High"
        ],
        [
            "c10",
            "Home",
            "Home Dashboard",
            "lib/features/home/presentation/home_screen.dart",
            "EATOGGY SVG Layout/c10-home.svg (Also Home Screen.svg, image 1.svg)",
            "Dark theme (1551 lines), location picker header, search input, active subscription ribbon, banner carousel, category selector, restaurant list with gold highlights.",
            "Light cream theme (#FAF7F2), location dropdown ('LUTYENS' DELHI, Amrita Shergil Marg'), search bar ('Search for meals, restaurants...'), promo banner 'LIMITED TIME OFFER' with WELCOME30 code, category pills, value prop cards ('Free Delivery Above ₹199', 'Fresh & Hygienic Food'), 'Popular Restaurants' with discount badges, and dishes with 'Add to Box' buttons.",
            "Major Reskin (Theme Shift)",
            "1. Complete screen reskin from dark mode (#11110F) to light ivory (#FAF7F2).\n2. Added 2 value proposition cards in horizontal scroll.\n3. Updated Category Pills with modern light background.\n4. Dish cards feature direct 'Add to Box' action buttons.\n5. Modernized restaurant cards with discount tags and ratings.",
            "Existing API: GET /api/v1/customer/dashboard & restaurant listing.",
            "Critical"
        ],
        [
            "c10-popup",
            "Home",
            "Tiffin Subscription Announcement Popup",
            "lib/features/home/presentation/home_screen.dart (New Dialog/Modal)",
            "EATOGGY SVG Layout/c10-home-popup.svg",
            "Not implemented! Currently only shows a small ribbon if the user already has an active subscription.",
            "Dismissible promotional modal/card overlay on Home: 'Tiffin Service Now Available! ×', subtitle 'Enjoy fresh, home-style meals delivered daily to your doorstep. Subscribe to our weekly or monthly tiffin plans!', 'Explore Plans' button, and preview of featured thalis with 'Add to Box' buttons.",
            "New Modal / Component",
            "1. Create new promotional bottom sheet or in-feed banner component.\n2. Include 'Explore Plans' CTA that navigates to Subscription Plans (/subscription).\n3. Add dismiss button (×) that remembers dismissal in SharedPreferences.\n4. Display featured tiffin thalis with 'Add to Box'.",
            "Navigation to subscription module; store dismiss state locally.",
            "High"
        ],
        [
            "c11",
            "Search",
            "Search Screen",
            "lib/features/search/presentation/search_screen.dart",
            "EATOGGY SVG Layout/c11-search.svg",
            "Dark theme with search textfield, debounced search API call, simple results list of food items.",
            "Light cream theme (#FAF7F2), search bar 'Search royal biryani, premium thali...', 'RECENT ENQUIRIES' tag cloud (Butter Chicken, Dal Makhani Thali, Kesar Phirni, Diet Meals), 'TRENDING DISHES' section with dish card (Murgh Makhani Supreme, ₹399, rating 4.9, Add button).",
            "Form / Field Enhancement",
            "1. Added 'RECENT ENQUIRIES' clickable chips for quick past search recall.\n2. Added 'TRENDING DISHES' recommendations when query is blank.\n3. Theming update to light cream (#FAF7F2) and stone cards.",
            "Local history persistence for recent queries; optional trending dishes endpoint.",
            "Medium"
        ],
        [
            "c12",
            "Menu",
            "Menu & Food Categories Screen",
            "lib/features/menu/presentation/menu_screen.dart",
            "EATOGGY SVG Layout/c12-menu-categories.svg",
            "Dark theme (1786 lines), restaurant header banner, search bar, veg/non-veg filter, vertical list of food items with gold add buttons.",
            "Title 'The Royal Menu', sticky horizontal category tabs ('Royal Thali', 'Luxe Curries', 'Heritage Breads'), clean dish cards with image, dish title ('Dal Makhani Heritage'), description, price ('₹289'), and rounded red '+ Add' pill buttons.",
            "Major Reskin (Theme Shift)",
            "1. Theme change to ivory background (#FAF7F2) and white cards.\n2. Header titled 'The Royal Menu' with luxury typography.\n3. Category tabs styled with rounded pills and active indicator.\n4. Add buttons styled as red pills (+ Add).",
            "Existing APIs: GET /api/v1/customer/menu & restaurant menu endpoints.",
            "High"
        ],
        [
            "c13",
            "Food Detail",
            "Food Item Detail Screen",
            "lib/features/food_detail/presentation/food_detail_screen.dart",
            "EATOGGY SVG Layout/c13-food-detail.svg",
            "Dish image, veg indicator, name, price, description, expandable nutrition, add-ons checkboxes (Garlic Naan +₹45, Kesari Phirni +₹120), sticky bottom bar with quantity and add button in dark theme.",
            "Hero food image, dish title 'Murgh Makhani', luxury badges ('Imperial', '★ 4.9 (2.4K royal ratings)', 'Hygiene Verified'), price '₹459', rich description, 'Nutrition & Ingredients' accordion, 'ACCOMPANYING ADD-ONS' list with checkmark/add, sticky bottom bar with [- 1 +] and red button 'Add to Cart • ₹504'.",
            "Minor Reskin & Style Update",
            "1. Business logic (dynamic addons, quantity calculation) matches perfectly!\n2. Change background to ivory (#FAF7F2) and cards to white.\n3. Add luxury badges ('Imperial', 'Hygiene Verified').\n4. Update sticky bottom button to red (#DC2626) showing calculated dynamic total.",
            "Existing Cart Add Item API.",
            "High"
        ],
        [
            "c14",
            "Cart",
            "Shopping Box / Cart Screen",
            "lib/features/cart/presentation/cart_screen.dart",
            "EATOGGY SVG Layout/c14-cart.svg",
            "Title 'Your Box', food item rows with quantity modifiers, coupon banner, bill breakdown (subtotal, delivery fee, taxes, discount, total), dark theme.",
            "Title 'Your Box', dish item card ('Shahi Paneer Thali ₹349'), 'Check Offer' link, 'LUXURY BILL SUMMARY': Subtotal ₹349.00, Insulated Hot-Case Delivery ₹40.00, Surcharge & Taxes ₹18.00, Grand Total ₹407.00, red checkout button.",
            "Minor Reskin & Style Update",
            "1. Renamed 'Delivery Fee' to 'Insulated Hot-Case Delivery'.\n2. Bill summary titled 'LUXURY BILL SUMMARY'.\n3. Light theme with white cards, clean stone borders (#E7E5E4), red CTA button.",
            "Existing Cart APIs.",
            "High"
        ],
        [
            "c15",
            "Checkout",
            "Checkout & Slot Selection",
            "lib/features/checkout/presentation/checkout_screen.dart",
            "EATOGGY SVG Layout/c15-checkout.svg",
            "Address selector with change modal, time slots ('12:30 - 1:15 Gourmet Lunch Slot'), payment method selector (UPI, Card, COD), bill summary, dark theme.",
            "Title 'Checkout', 'DELIVERING TO' card with 'Home (Shergil Marg)' and 'Change' action, 'SELECT PREMIUM LUNCH SLOT' cards ('12:30 - 1:15 Gourmet Slot', '1:30 - 2:15 Gourmet Slot'), 'PREFERRED PAYMENT METHOD' radio tiles, red 'Pay & Place Order' CTA button.",
            "Minor Reskin & Style Update",
            "1. Slot selection styled as prominent selectable cards with active border.\n2. Inverted dark theme to light ivory (#FAF7F2) with white cards.\n3. Red '#DC2626' place order CTA button.",
            "Existing Checkout Summary API & Order placement API.",
            "High"
        ],
        [
            "c16/c17 [Gap]",
            "Payment",
            "Payment Processing & Razorpay",
            "lib/features/payment/presentation/payment_screen.dart",
            "Missing in SVG exports (Numbered sequence gap between c15 & c18)",
            "Razorpay SDK integration, payment retry, verification spinner, order status handling.",
            "N/A (App-only screen, handles 3rd party SDK sheet and payment loading state).",
            "App Only (No SVG Design)",
            "1. Update screen background and loading spinner from dark gold to light ivory (#FAF7F2) and red.\n2. Keep existing Razorpay SDK payment verification logic intact.",
            "Existing Razorpay order verification endpoint.",
            "Medium"
        ],
        [
            "c18",
            "Orders",
            "Order Success / Confirmation",
            "lib/features/orders/presentation/order_success_screen.dart",
            "EATOGGY SVG Layout/c18-order-success.svg",
            "Gold circular checkmark, 'Order Placed Successfully!', order ID confirmation, estimated slot, 'Track Order' gold button, 'Back to Home' button, dark background.",
            "Ivory background (#FAF7F2), green/gold check badge, 'Order Placed Successfully!', subtitle with #EAT84920, detail cards: 'Estimated Delivery Slot: Today, 12:45 PM' & 'Insulated Delivery System: Active Hot-Case', primary red button 'Track Your Order →', text button 'Back to Gourmet Home'.",
            "Minor Reskin & Style Update",
            "1. Theme change to ivory (#FAF7F2).\n2. Added 'Insulated Delivery System: Active Hot-Case' information card.\n3. Button updated to red (#DC2626) with arrow icon.",
            "No backend changes.",
            "Medium"
        ],
        [
            "c19",
            "Orders",
            "Active Orders Tab",
            "lib/features/orders/presentation/orders_screen.dart (Active Tab)",
            "EATOGGY SVG Layout/c19-orders-active.svg",
            "Tabbed orders screen (Active/Past/Cancelled), active orders list with order ID, dishes, status badge, tracking button in dark theme.",
            "Title 'Active Orders', subtitle 'Freshly crafted gourmet meals on route', active order card with ORDER ID '#EAT-94821', 'Out for Delivery' green badge, dish name ('Royal Shahi Paneer Feast Thali, Qty: 1 • Insulated Box Delivery'), ETA countdown box ('14 mins remaining'), red 'Track Live Order' button. Secondary 'Preparing' card.",
            "Minor Reskin & Style Update",
            "1. Added prominent ETA countdown badge ('14 mins remaining').\n2. Added 'Insulated Box Delivery' tag.\n3. Red 'Track Live Order' button.\n4. Light cream background with white elevated cards.",
            "Existing API: GET /api/v1/customer/orders.",
            "High"
        ],
        [
            "c20",
            "Orders",
            "Orders History Tab",
            "lib/features/orders/presentation/orders_screen.dart (Past Tab)",
            "EATOGGY SVG Layout/c20-orders-history.svg",
            "Past orders list with date, delivered status, item names, total price, reorder and rate buttons in dark theme.",
            "Title 'Orders History', subtitle 'Your journey of royal gastronomic experiences', filter tabs [Active, Past, Cancelled], past order cards: Date '18 Oct 2026 • 1:15 PM', 'Delivered' green badge, dishes, total price with payment method ('Total: ₹412 • Pay via UPI'), action buttons: 'Reorder Pack' (outlined) & 'Rate Meal' (solid red).",
            "Minor Reskin & Style Update",
            "1. Action buttons restyled: 'Reorder Pack' (stone border) and 'Rate Meal' (solid red #DC2626).\n2. Added payment method chip ('Pay via UPI' / 'Pay via Card').\n3. Light theme cards with subtle borders.",
            "Existing API: GET /api/v1/customer/orders & reorder flow.",
            "High"
        ],
        [
            "c21 [Gap]",
            "Orders",
            "Order Details Screen",
            "lib/features/orders/presentation/order_details_screen.dart",
            "Missing in SVG exports (Numbered sequence gap between c20 & c22)",
            "Detailed order breakdown (665 lines): tracking stepper, address, item list, invoice receipt, support button, cancel button.",
            "N/A (App-only screen, accessed by clicking any order card).",
            "App Only (No SVG Design)",
            "1. Retain existing comprehensive order breakdown and receipt details.\n2. Update screen background from #11110F to ivory (#FAF7F2) and cards to white with stone borders.\n3. Update status stepper colors to match light theme.",
            "Existing API: GET /api/v1/customer/orders/:id.",
            "Medium"
        ],
        [
            "c22",
            "Tracking",
            "Live Order Tracking",
            "lib/features/tracking/presentation/tracking_screen.dart",
            "EATOGGY SVG Layout/c22-live-tracking.svg",
            "Google Map with dark map style JSON, live rider polling, ETA, rider name, call/chat actions, dark bottom card.",
            "Daytime light map view with delivery route polyline, floating white sheet: 'Live Tracking', 'Rider is on the way', ETA badge 'Arriving in 14 Mins', 'Hot-case Insulated' badge, Valet partner info ('Ramesh Kumar ★ 4.9'), Call/Message buttons, 'View Delivery Instructions', bottom navigation bar.",
            "Major Reskin (Theme Shift)",
            "1. Replace dark Google Maps JSON style with clean daytime light map style.\n2. Update floating card from dark surface to white with stone border.\n3. Added 'Hot-case Insulated' temperature assurance badge.",
            "Existing Tracking WebSocket / polling API.",
            "High"
        ],
        [
            "c23",
            "Subscription",
            "Subscription Plans / Royal Meal Plans",
            "lib/features/subscription/presentation/subscription_plans_screen.dart",
            "EATOGGY SVG Layout/c23-subscription-plans.svg",
            "Screen with 2 tabs ('My Subscriptions' & 'Explore Plans') in dark theme, plan cards with gold gradient accents.",
            "Dedicated 'Royal Meal Plans' screen, subtitle 'Effortless luxury meals, delivered daily', tiered cards: 1. 'Imperial Weekly' (7 Days Trial) - 'SAVE 15%' - '₹2,299 / week' (₹328 per elite meal) - Features bullet points - Red 'View Plan Details' button. 2. 'Maharaja Monthly' (30 Days) - '₹8,499 / month'.",
            "Major Reskin (Theme Shift)",
            "1. Restructure screen into dedicated 'Royal Meal Plans' discovery view.\n2. Add prominent discount badges ('SAVE 15%') and per-meal pricing breakdown ('₹328 per elite meal').\n3. Redesigned plan cards with checkmarked inclusions and red CTA button.",
            "Existing API: GET /api/v1/customer/subscriptions/plans.",
            "Critical"
        ],
        [
            "c24",
            "Subscription",
            "Plan Detail Screen",
            "lib/features/subscription/presentation/plan_detail_screen.dart",
            "EATOGGY SVG Layout/c24-subscription-detail.svg",
            "Plan overview, duration, price, generic benefits list, dark continue button.",
            "Title 'Maharaja Monthly', subtitle '30 Days of bespoke dining', 'PLAN BENEFITS' checkmark list (gold insulated delivery, pause anytime, zero delivery fee), 'Choose Meal Type' selector ([Pure Vegetarian] / [Non-Veg & Mixed]), 'PRICING BREAKDOWN' (Subtotal ₹8,499, Taxes FREE), red CTA 'Continue to Customize'.",
            "Form / Field Enhancement",
            "1. Added explicit 'Choose Meal Type' radio selector (Pure Veg vs Non-Veg & Mixed).\n2. Added formal 'PRICING BREAKDOWN' table.\n3. Updated benefits list to match royal tiffin promises.\n4. Light theme with red CTA button.",
            "Passes selected meal type to customization flow.",
            "High"
        ],
        [
            "c25",
            "Subscription",
            "Customize Subscription Screen",
            "lib/features/subscription/presentation/customize_subscription_screen.dart",
            "EATOGGY SVG Layout/c25-customize-subscription.svg",
            "Day selection chips, start date picker, meal type selector in dark theme.",
            "Title 'Customize Box', subtitle 'Tailor your daily meal calendar', 'Select Delivery Days' circular day pills (M, T, W, T, F, S, S), 'Preferred Time Slot' radio cards ('Lunch Box: 12:00 PM - 1:30 PM', 'Dinner Box: 7:30 PM - 9:00 PM'), 'Allergies & Dietary Notes' text field ('E.g., No peanuts, moderate spice levels only...'), red CTA 'Proceed to Checkout'.",
            "Form / Field Enhancement",
            "1. Added 'Allergies & Dietary Notes' text area input.\n2. Time slot selector formatted as explicit Lunch Box vs Dinner Box cards with delivery windows.\n3. Circular day toggle pills (M, T, W, T, F, S, S).\n4. Light theme and red CTA button.",
            "Passes dietaryNotes / allergies to subscription creation payload.",
            "High"
        ],
        [
            "c26",
            "Subscription",
            "Subscription Checkout / Confirm Plan",
            "lib/features/subscription/presentation/customize_subscription_screen.dart / payment",
            "EATOGGY SVG Layout/c26-subscription-checkout.svg",
            "Currently no dedicated review screen: customizing subscription jumps directly to payment processing.",
            "Dedicated review screen: 'Confirm Plan', subtitle 'Finalize your royal meal pass', 'SELECTED PLAN' card ('Maharaja Monthly (Pure Veg)', 'Mon to Fri • Lunch Slot'), 'SHIPPING ADDRESS' card with change action, Price Breakdown (Subtotal ₹8,499, GST Included, Grand Total ₹8,499), red CTA 'Pay & Start Subscription'.",
            "New Screen to Build",
            "1. Create dedicated pre-payment review step for subscriptions.\n2. Display selected plan summary, delivery schedule, and shipping address card.\n3. Display tax breakdown and primary red button to initiate Razorpay payment.",
            "Submits POST /api/v1/customer/subscriptions and triggers payment session.",
            "High"
        ],
        [
            "c27",
            "Subscription",
            "My Subscription Dashboard",
            "lib/features/subscription/presentation/my_subscription_screen.dart",
            "EATOGGY SVG Layout/c27-my-subscription.svg",
            "Active subscription details, remaining meals, pause/resume buttons in dark theme.",
            "Title 'My Subscription', subtitle 'Manage your bespoke daily diet', active card: 'Maharaja Veg Pass', 'REMAINING MEALS: 24 / 30', 'Active' badge, 'NEXT DELIVERY: Tomorrow, 12:30 PM', action buttons: 'Pause Plan' & 'Change Preferences', 'DELIVERY TIP' guide card ('Going out of town this weekend? Tap Pause Plan...').",
            "Minor Reskin & Style Update",
            "1. Added 'DELIVERY TIP' helpful user card.\n2. Restyled remaining meals progress card with clean light theme.\n3. Pause Plan and Change Preferences buttons styled with stone borders.\n4. Light cream background (#FAF7F2).",
            "Existing APIs: GET /api/v1/customer/subscriptions/my & pause/resume endpoints.",
            "High"
        ],
        [
            "c28 [Gap]",
            "Subscription",
            "Subscription Calendar Screen",
            "lib/features/subscription/presentation/subscription_calendar_screen.dart",
            "Missing in SVG exports (Numbered sequence gap between c27 & c29)",
            "Calendar view (585 lines) of daily meal deliveries, skip day action, meal swap action in dark theme.",
            "N/A (App-only screen, accessed from My Subscription via 'View Calendar').",
            "App Only (No SVG Design)",
            "1. Retain existing full calendar grid and daily meal inspection modal.\n2. Update calendar cells and background from dark theme to light ivory (#FAF7F2).\n3. Use brand red (#DC2626) and green (#22C55E) for delivery status dots.",
            "Existing API: GET /api/v1/customer/subscriptions/:id/calendar.",
            "Medium"
        ],
        [
            "c29",
            "Offers",
            "Offers & Coupons Screen",
            "lib/features/offers/presentation/offers_screen.dart",
            "EATOGGY SVG Layout/c29-offers-coupons.svg",
            "Coupon input field, apply button, list of coupons (ROYALTREAT50, FESTIVE60, FREEDELUXE), dark theme.",
            "Title 'Offers & Coupons', coupon input box with bold 'APPLY' button, applied coupon feedback badge ('ROYALTREAT50 applied! ₹50 saved on your current box'), coupon voucher cards with discount percentage badge ('60% OFF'), coupon code ('FESTIVE60'), terms, expiry countdown, 'Apply' button.",
            "Minor Reskin & Style Update",
            "1. Voucher cards restyled with clean white ticket/coupon border and badge.\n2. Applied voucher feedback banner styled cleanly.\n3. Theme change to light cream (#FAF7F2).",
            "Existing Offers Repository & Cart apply coupon API.",
            "Medium"
        ],
        [
            "c30",
            "Notifications",
            "Notifications Screen",
            "MISSING IN FLUTTER APP! (Only notification_service.dart exists)",
            "EATOGGY SVG Layout/c30-notifications.svg",
            "NO SCREEN EXISTS! Bell icon in AppBar has no dedicated screen or route.",
            "Title 'Notifications', category filter tabs: [All, Orders, Offers, System], 'Mark All Read' action, notification list with timestamps, unread indicator dots, bold title ('Royal Feast Out For Delivery', 'Festive Gift Awaits You!'), description text.",
            "New Screen to Build",
            "1. BUILD BRAND NEW SCREEN: lib/features/notifications/presentation/notifications_screen.dart.\n2. Register route '/notifications' in AppRoutes and AppRouter.\n3. Implement filter tabs [All, Orders, Offers, System] and 'Mark All Read'.\n4. Connect bell icon on Home & Profile to navigate to /notifications.",
            "Requires GET /api/v1/customer/notifications & PATCH /mark-read API or local persistence.",
            "Critical"
        ],
        [
            "c31",
            "Profile",
            "Profile Screen",
            "lib/features/profile/presentation/profile_screen.dart",
            "EATOGGY SVG Layout/c31-profile.svg",
            "Profile view with avatar, customer name, mobile, role, orders/subscriptions count, navigation list in dark theme.",
            "Title 'My Profile', avatar, name 'Raghavendra Dev', phone '+91 98765 43210', luxury badge 'ROYAL PATRON MEMBER', menu tiles with status badges: 'My Orders (3 Active >)', 'My Subscription (Active >)', 'Saved Addresses', 'Help & Support', 'Settings', bottom navigation bar.",
            "Minor Reskin & Style Update",
            "1. Added luxury membership tier badge ('ROYAL PATRON MEMBER').\n2. Menu items display live status badges ('3 Active', 'Active').\n3. Theme updated to light cream (#FAF7F2) and clean white tiles with chevron arrows.",
            "Existing API: GET /api/v1/customer/profile.",
            "High"
        ],
        [
            "c32",
            "Location",
            "Saved Addresses Screen",
            "lib/features/location/presentation/saved_addresses_screen.dart",
            "EATOGGY SVG Layout/c32-saved-addresses.svg",
            "List of addresses with label icon, edit/delete actions, set default option in dark theme.",
            "Title 'Saved Addresses', address cards: 'Home [DEFAULT]' with address text, 'Work' with address text, 3-dot options, prominent red button '+ Add New Address' at bottom, bottom navigation bar.",
            "Minor Reskin & Style Update",
            "1. Address cards styled with clean white container and subtle stone border.\n2. '+ Add New Address' button styled in bold solid red (#DC2626).\n3. Light cream background (#FAF7F2).",
            "Existing Saved Addresses Bloc & APIs.",
            "Medium"
        ],
        [
            "c33 [Gap]",
            "Orders",
            "My Reviews Screen",
            "lib/features/orders/presentation/my_reviews_screen.dart",
            "Missing in SVG exports (Numbered sequence gap between c32 & c34)",
            "Screen listing customer's past submitted reviews and star ratings.",
            "N/A (App-only screen, accessed from Profile or Orders).",
            "App Only (No SVG Design)",
            "1. Update screen background and review cards to light cream (#FAF7F2) and white.\n2. Retain existing review list logic.",
            "Existing API: GET /api/v1/customer/reviews.",
            "Low"
        ],
        [
            "c34",
            "Orders",
            "Write a Review Screen",
            "lib/features/orders/presentation/write_review_screen.dart",
            "EATOGGY SVG Layout/c34-ratings-review.svg",
            "Order header, 3 star rating criteria (overall, food quality, delivery packaging), text feedback with char counter, photo picker in dark theme.",
            "Title 'Write a Review', order context card ('Order #EAT-88902, Delivered on 12 Oct • Raghavendra D.'), 3 star rating rows: Overall Experience, Food Quality, Delivery & Packaging, 'Detailed Feedback' text area with counter ('112 / 500, Min 20 characters'), 'Add Photos (Optional)' box, red 'Submit Royal Review' CTA.",
            "Minor Reskin & Style Update",
            "1. Logic and fields match 100%!\n2. Update background to ivory (#FAF7F2) and text box to stone border.\n3. Star ratings styled with gold (#F59E0B).\n4. Submit button styled in red (#DC2626).",
            "Existing API: POST /api/v1/customer/orders/:id/review.",
            "Medium"
        ],
        [
            "c35",
            "Support",
            "Help & Support Screen",
            "lib/features/support/presentation/support_screen.dart",
            "EATOGGY SVG Layout/c35-help-support.svg",
            "Support ticket list, create ticket modal, category dropdown in dark theme.",
            "Title 'Help & Support', 'Recent Order Assistance' quick card ('Need help with order #EAT-88902? Tap to raise issue • Delivered 12 Oct'), 'FAQ Categories' chips (Order Issues, Payment & Refund, Subscription Inquiries, Delivery Partners, Account Settings), 'Contact Us Directly' options: [Chat Support], [Call Helpline], [Create Support Ticket].",
            "Form / Field Enhancement",
            "1. Added 'Recent Order Assistance' card for 1-tap issue resolution on recent delivery.\n2. Added 'FAQ Categories' filter chips.\n3. Added direct contact tiles: Chat Support, Call Helpline, Create Support Ticket.\n4. Light cream theme (#FAF7F2).",
            "Existing Support Repository & ticket creation endpoints.",
            "Medium"
        ],
        [
            "c36 [Gap]",
            "Support",
            "Support Ticket Detail Screen",
            "lib/features/support/presentation/ticket_detail_screen.dart",
            "Missing in SVG exports (Numbered sequence gap between c35 & c37)",
            "Ticket chat conversation screen between user and support team in dark theme.",
            "N/A (App-only screen, accessed by tapping any ticket).",
            "App Only (No SVG Design)",
            "1. Update screen background and chat bubbles to light theme (#FAF7F2) with white/stone bubbles.\n2. Retain existing ticket message polling.",
            "Existing API: GET /api/v1/customer/support/tickets/:id.",
            "Low"
        ],
        [
            "c37",
            "Settings",
            "Settings Screen",
            "lib/features/profile/presentation/settings_screen.dart",
            "EATOGGY SVG Layout/c37-settings.svg",
            "Push, email, SMS switches, language selector, legal links, delete account button, logout button in dark theme.",
            "Title 'Settings', 'Notifications Preferences' (Push Notifications, Email Notifications, SMS & WhatsApp Alerts), 'App Settings' (App Language: English (US) ▾, Privacy Policy, Terms of Service, About EATOGGY v4.12.0 Premium Gold), red 'Log Out' button at bottom.",
            "Minor Reskin & Style Update",
            "1. Restyle cards to white with stone borders (#E7E5E4).\n2. Update switch toggles to red active track (#DC2626).\n3. Light cream background (#FAF7F2).",
            "Local preferences storage.",
            "Medium"
        ],
        [
            "c38",
            "Settings",
            "Logout Confirmation Modal",
            "lib/features/profile/presentation/settings_screen.dart (_showLogoutConfirmation)",
            "EATOGGY SVG Layout/c38-logout-confirmation.svg",
            "Basic modal bottom sheet with text 'Confirm Logout' and buttons.",
            "Dedicated bottom sheet with logout icon badge [→ in red rounded container, title 'Log Out?', description 'Are you sure you want to log out? You will need to sign in again to access your gourmet active subscription.', solid red button 'Log Out', outlined button 'Cancel'.",
            "New Modal / Component",
            "1. Redesign logout bottom sheet with red exit icon header.\n2. Update copy to match subscription warning text.\n3. Style 'Log Out' button as solid destructive red and 'Cancel' as outlined.",
            "Session Manager: clear token & redirect to login.",
            "Medium"
        ],
        [
            "Supp-01",
            "Home / Web",
            "Home Screen (Extended / Web View)",
            "lib/features/home/presentation/home_screen.dart",
            "EATOGGY SVG Layout/Home Screen.svg & Home Screen-1.svg",
            "Mobile app home view with single column layout.",
            "Extended layout (1872px height) showing full web multi-restaurant grid (McDonald's, Domino's, KFC, Bolt express), discount banners ('Flat ₹200 OFF'), and category grids.",
            "Minor Reskin & Style Update",
            "Used as reference for desktop / wide tablet responsive layout and banner promotions.",
            "Dashboard and restaurant listing endpoints.",
            "Low"
        ],
        [
            "Supp-02",
            "Branding",
            "FeastBox Brand Badge",
            "lib/core/theme/app_colors.dart / assets",
            "EATOGGY SVG Layout/Frame.svg",
            "Eatoggy brand assets.",
            "Vector logo badge for 'FEASTBOX' (the royal meal box service by Eatoggy).",
            "Minor Reskin & Style Update",
            "Add as asset or badge on meal box deliveries and cart screen.",
            "Asset bundle.",
            "Low"
        ]
    ]
    
    # Write Sheet 1 Header
    ws1.append(headers_ws1)
    for col_idx in range(1, len(headers_ws1) + 1):
        cell = ws1.cell(row=1, column=col_idx)
        cell.font = header_font
        cell.fill = navy_header_fill
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = border_all
    ws1.row_dimensions[1].height = 32
    
    # Write Sheet 1 Data
    for row_idx, row_data in enumerate(data_ws1, start=2):
        ws1.append(row_data)
        ws1.row_dimensions[row_idx].height = 68
        
        status_val = row_data[7]
        priority_val = row_data[10]
        
        for col_idx in range(1, len(row_data) + 1):
            cell = ws1.cell(row=row_idx, column=col_idx)
            cell.font = regular_font
            cell.border = border_all
            cell.alignment = Alignment(vertical="center", wrap_text=True)
            
            # Center specific columns
            if col_idx in [1, 2, 8, 11]:
                cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
                
            # Design ID bold
            if col_idx == 1:
                cell.font = bold_font
                
            # Status highlight
            if col_idx == 8 and status_val in status_fills:
                cell.fill = status_fills[status_val]
                cell.font = bold_font
                
            # Priority highlight
            if col_idx == 11 and priority_val in priority_fills:
                cell.fill = priority_fills[priority_val]
                cell.font = bold_font

    # Set column widths for Sheet 1
    col_widths_ws1 = {
        1: 12,  # Design ID
        2: 15,  # Module
        3: 28,  # Screen Name
        4: 48,  # Flutter Dart Screen Path
        5: 42,  # SVG Layout File
        6: 45,  # Current App State
        7: 48,  # New SVG Spec
        8: 25,  # Mapping Status
        9: 50,  # Differences & Changes
        10: 38, # Backend Requirements
        11: 14   # Priority
    }
    for col_idx, width in col_widths_ws1.items():
        ws1.column_dimensions[get_column_letter(col_idx)].width = width
    ws1.freeze_panes = "A2"

    # -------------------------------------------------------------
    # SHEET 2: THEME & DESIGN SYSTEM SHIFT
    # -------------------------------------------------------------
    ws2 = wb.create_sheet(title="Theme & Design System Shift")
    ws2.views.sheetView[0].showGridLines = True
    
    headers_ws2 = [
        "Design Element",
        "Current Flutter App Implementation",
        "New SVG Layout Specification",
        "Impact Level",
        "Key Design Rationale & Guidance"
    ]
    
    data_ws2 = [
        [
            "App Background Color",
            "#11110F (Deep Obsidian Black / Pitch Dark Mode)",
            "#FAF7F2 (Alabaster Ivory / Warm Luxury Cream)",
            "CRITICAL (Global Inversion)",
            "The app is shifting from a dark-mode night aesthetic to a light, clean, appetizing heritage ivory tone. Every screen's Scaffold backgroundColor must be migrated to #FAF7F2."
        ],
        [
            "Primary Accent Color",
            "#D9A24F & #F1CC8A (Gold Gradient / Brass Yellow)",
            "#DC2626 & #B91C1C (Imperial Royal Red / Crimson)",
            "HIGH (Global Brand Accent)",
            "All primary CTA buttons ('Continue', 'Verify', 'Add to Cart', 'Pay & Place Order', 'Explore Plans') are now bold high-contrast royal red (#DC2626) with crisp white text instead of gold gradients."
        ],
        [
            "Secondary / Accent Gold",
            "Dominant on text, borders, icons, and buttons",
            "#F59E0B (Selective Amber/Gold for Ratings ★ & Royal Badges)",
            "MEDIUM",
            "Gold is now reserved exclusively for prestige badges ('ROYAL PATRON MEMBER', 'Imperial'), rating stars (★ 4.9), and luxury emblems, rather than being used for all text."
        ],
        [
            "Primary Typography Color",
            "#FFF1D2 (Pale Vanilla Gold / Off-white)",
            "#1C1917 (Stone-900 / Deep Charcoal Black)",
            "HIGH (Readability)",
            "Headings and titles now use rich deep charcoal (#1C1917) providing 14:1 contrast ratio against the #FAF7F2 ivory background, delivering magazine-grade editorial typography."
        ],
        [
            "Secondary Typography Color",
            "#B8B4AE & #77736D (Muted Ash Gray)",
            "#78716C (Stone-500) & #A8A29E (Stone-400)",
            "MEDIUM",
            "Warm stone gray tones are used for captions, timestamps, ingredients, and form labels, preserving the warm palette feeling."
        ],
        [
            "Cards & Surface Containers",
            "#191714 (Dark Surface with subtle border #2C2721)",
            "#FFFFFF (Pure White) with #E7E5E4 (Stone-200) Border",
            "HIGH",
            "Content cards (food items, order cards, address cards, plan cards) are pure white rounded rectangles with 1px stone borders (#E7E5E4) and soft elevation shadows (4-8 blur)."
        ],
        [
            "Form Text Fields & Inputs",
            "Dark containers with gold borders and dark hint text",
            "#FFFFFF background, #E7E5E4 border, #DC2626 active focus border",
            "MEDIUM",
            "Inputs use uppercase stone-500 labels ('RECEIVER\'S NAME', 'PINCODE') positioned above clean white rounded input boxes with subtle borders."
        ],
        [
            "Badge & Pill Styles",
            "Dark pill with gold outline",
            "Tinted soft backgrounds: Red tint (#FFF1F2), Green tint (#E8F5E9), Amber tint (#FEF3C7)",
            "MEDIUM",
            "Badges now use modern soft pastel fills with deep colored text (e.g. green pill for Veg, red pill for 'SAVE 15%', green pill for 'Delivered')."
        ],
        [
            "Google Maps Theme",
            "Custom dark map JSON style (night-mode roads and buildings)",
            "Daytime light map style with warm cream land and red route polylines",
            "MEDIUM",
            "Tracking screen map style will be updated to match daytime palette."
        ],
        [
            "Branding Concept",
            "Generic Food Delivery / Dark Luxury Lounge",
            "'Authentic Home Cooked Luxury / FeastBox / Royal Tiffin Subscription'",
            "STRATEGIC",
            "Brand messaging elevates Eatoggy as a bespoke daily tiffin pass provider offering artisanal home-cooked cuisine in gold-insulated hot cases."
        ]
    ]
    
    ws2.append(headers_ws2)
    for col_idx in range(1, len(headers_ws2) + 1):
        cell = ws2.cell(row=1, column=col_idx)
        cell.font = header_font
        cell.fill = navy_header_fill
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = border_all
    ws2.row_dimensions[1].height = 30
    
    for row_idx, row_data in enumerate(data_ws2, start=2):
        ws2.append(row_data)
        ws2.row_dimensions[row_idx].height = 48
        for col_idx in range(1, len(row_data) + 1):
            cell = ws2.cell(row=row_idx, column=col_idx)
            cell.font = regular_font
            cell.border = border_all
            cell.alignment = Alignment(vertical="center", wrap_text=True)
            if col_idx in [1, 4]:
                cell.font = bold_font
                cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
                
    col_widths_ws2 = {1: 28, 2: 44, 3: 48, 4: 25, 5: 55}
    for col_idx, width in col_widths_ws2.items():
        ws2.column_dimensions[get_column_letter(col_idx)].width = width
    ws2.freeze_panes = "A2"

    # -------------------------------------------------------------
    # SHEET 3: ACTION ITEMS & ROADMAP
    # -------------------------------------------------------------
    ws3 = wb.create_sheet(title="Action Items & Roadmap")
    ws3.views.sheetView[0].showGridLines = True
    
    headers_ws3 = [
        "Task ID",
        "Phase / Category",
        "Action Item Title",
        "Target File(s)",
        "Description & Execution Details",
        "Complexity",
        "Priority"
    ]
    
    data_ws3 = [
        [
            "TASK-01",
            "Phase 1: Design Tokens",
            "Refactor AppColors & AppTheme to Ivory/Red Theme",
            "lib/core/theme/app_colors.dart, lib/core/theme/app_theme.dart",
            "Update AppColors.background to #FAF7F2, surface to #FFFFFF, primary to #DC2626 (Royal Red), text to #1C1917, border to #E7E5E4, and update theme color schemes.",
            "Medium",
            "Critical"
        ],
        [
            "TASK-02",
            "Phase 2: Missing Screens",
            "Build New Notifications Screen (c30)",
            "lib/features/notifications/presentation/notifications_screen.dart, lib/core/router/app_router.dart",
            "Create dedicated notifications UI with filter tabs [All, Orders, Offers, System], 'Mark All Read' action, unread indicators, and link AppBar bell icon to /notifications.",
            "High",
            "Critical"
        ],
        [
            "TASK-03",
            "Phase 2: Missing Screens",
            "Build Dedicated Subscription Checkout Screen (c26)",
            "lib/features/subscription/presentation/subscription_checkout_screen.dart",
            "Create 'Confirm Plan' review screen with selected plan summary, delivery schedule, address card, tax breakdown, and 'Pay & Start Subscription' button.",
            "Medium",
            "High"
        ],
        [
            "TASK-04",
            "Phase 2: New Components",
            "Implement Tiffin Subscription Promo Modal (c10-popup)",
            "lib/features/home/presentation/widgets/tiffin_promo_popup.dart, lib/features/home/presentation/home_screen.dart",
            "Implement dismissible popup on home screen introducing daily tiffin meal subscriptions with 'Explore Plans' action and local dismiss state persistence.",
            "Medium",
            "High"
        ],
        [
            "TASK-05",
            "Phase 3: Screen Reskin",
            "Reskin Home Dashboard (c10)",
            "lib/features/home/presentation/home_screen.dart",
            "Update Home to #FAF7F2 background, add 2 value proposition cards, category pills, 'Add to Box' quick buttons on featured dishes, and new banner styling.",
            "High",
            "Critical"
        ],
        [
            "TASK-06",
            "Phase 3: Screen Reskin",
            "Reskin Royal Meal Plans & Subscriptions (c23, c24, c25, c27)",
            "lib/features/subscription/presentation/subscription_plans_screen.dart, plan_detail_screen.dart, customize_subscription_screen.dart, my_subscription_screen.dart",
            "Update plan cards with 'SAVE 15%' tags, per-meal cost breakdown, meal type selector (Veg vs Mixed), allergies/dietary text field, and 'Delivery Tip' card on My Subscription.",
            "High",
            "Critical"
        ],
        [
            "TASK-07",
            "Phase 3: Screen Reskin",
            "Reskin Auth Flow: Login & OTP (c05, c06)",
            "lib/features/authentication/presentation/login_screen.dart, otp_screen.dart",
            "Convert login and OTP verification screens to ivory theme, rounded 4-box OTP pin inputs with active red border, and red primary CTA buttons.",
            "Medium",
            "High"
        ],
        [
            "TASK-08",
            "Phase 3: Screen Reskin",
            "Reskin Cart & Checkout Screens (c14, c15, c18)",
            "lib/features/cart/presentation/cart_screen.dart, lib/features/checkout/presentation/checkout_screen.dart, lib/features/orders/presentation/order_success_screen.dart",
            "Update 'Your Box' and Checkout to ivory/white cards with red buttons, time slot selectable cards, 'Insulated Hot-Case Delivery' line item, and order success cards.",
            "Medium",
            "High"
        ],
        [
            "TASK-09",
            "Phase 3: Screen Reskin",
            "Reskin Orders Screen (Active & History) (c19, c20)",
            "lib/features/orders/presentation/orders_screen.dart",
            "Update active order cards with ETA countdown badge ('14 mins remaining'), insulated box delivery tag, and red 'Track Live Order' button; past orders with Reorder and Rate buttons.",
            "Medium",
            "High"
        ],
        [
            "TASK-10",
            "Phase 3: Screen Reskin",
            "Update Live Tracking Map & Sheet (c22)",
            "lib/features/tracking/presentation/tracking_screen.dart",
            "Replace dark Google Maps styling with daytime light style, update bottom card to white with 'Hot-case Insulated' badge.",
            "Medium",
            "High"
        ],
        [
            "TASK-11",
            "Phase 3: Screen Reskin",
            "Reskin Menu & Food Detail (c12, c13)",
            "lib/features/menu/presentation/menu_screen.dart, lib/features/food_detail/presentation/food_detail_screen.dart",
            "Update category tabs, dish cards with red '+ Add' pill buttons, food detail badges ('Imperial', 'Hygiene Verified'), and red CTA button with dynamic total.",
            "Medium",
            "High"
        ],
        [
            "TASK-12",
            "Phase 3: Screen Reskin",
            "Reskin Profile, Addresses, Settings & Logout (c31, c32, c37, c38)",
            "lib/features/profile/presentation/profile_screen.dart, saved_addresses_screen.dart, settings_screen.dart",
            "Add 'ROYAL PATRON MEMBER' badge on profile, live status badges on menu items, red '+ Add New Address' button, and redesign logout bottom sheet with red icon.",
            "Medium",
            "High"
        ],
        [
            "TASK-13",
            "Phase 3: Screen Reskin",
            "Update Support, Reviews & Search (c11, c34, c35)",
            "lib/features/search/presentation/search_screen.dart, write_review_screen.dart, support_screen.dart",
            "Add recent enquiries chips & trending dishes to search; add quick order assistance card and FAQ chips to support; style write review with gold stars and red submit CTA.",
            "Medium",
            "Medium"
        ],
        [
            "TASK-14",
            "Phase 4: App-Only Screens",
            "Align App-Only Screens (c08, c16, c21, c28, c33, c36)",
            "select_location_screen.dart, payment_screen.dart, order_details_screen.dart, subscription_calendar_screen.dart, my_reviews_screen.dart, ticket_detail_screen.dart",
            "Ensure the 6 app-only screens that do not have dedicated SVGs adopt the new ivory (#FAF7F2) and red (#DC2626) theme consistently so the user experience is seamless.",
            "Medium",
            "Medium"
        ]
    ]
    
    ws3.append(headers_ws3)
    for col_idx in range(1, len(headers_ws3) + 1):
        cell = ws3.cell(row=1, column=col_idx)
        cell.font = header_font
        cell.fill = navy_header_fill
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = border_all
    ws3.row_dimensions[1].height = 30
    
    for row_idx, row_data in enumerate(data_ws3, start=2):
        ws3.append(row_data)
        ws3.row_dimensions[row_idx].height = 42
        p_val = row_data[6]
        for col_idx in range(1, len(row_data) + 1):
            cell = ws3.cell(row=row_idx, column=col_idx)
            cell.font = regular_font
            cell.border = border_all
            cell.alignment = Alignment(vertical="center", wrap_text=True)
            if col_idx in [1, 2, 6, 7]:
                cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
            if col_idx == 1:
                cell.font = bold_font
            if col_idx == 7 and p_val in priority_fills:
                cell.fill = priority_fills[p_val]
                cell.font = bold_font

    col_widths_ws3 = {1: 14, 2: 24, 3: 38, 4: 48, 5: 58, 6: 16, 7: 15}
    for col_idx, width in col_widths_ws3.items():
        ws3.column_dimensions[get_column_letter(col_idx)].width = width
    ws3.freeze_panes = "A2"

    # Save to file
    out_path = "EATOGGY_Screens_Mapping_And_Comparison.xlsx"
    wb.save(out_path)
    print(f"Successfully generated: {out_path}")

if __name__ == "__main__":
    build_excel_report()
