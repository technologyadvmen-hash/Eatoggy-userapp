import 'package:equatable/equatable.dart';
import '../../location/data/models/add_address_response.dart';
import '../data/models/checkout_summary_model.dart';
import '../data/models/initiate_checkout_model.dart';

class CheckoutState extends Equatable {
  final List<CustomerAddressData> addresses;
  final CustomerAddressData? selectedAddress;
  final bool isLoadingAddresses;
  final bool isLoadingPricing;
  final bool isInitiatingOrder;
  final CheckoutSummaryModel? pricingSummary;
  final InitiateCheckoutResponse? checkoutSession;
  final int selectedSlotIndex;
  final int selectedPaymentIndex;
  final String? notes;
  final String? error;

  const CheckoutState({
    this.addresses = const [],
    this.selectedAddress,
    this.isLoadingAddresses = false,
    this.isLoadingPricing = false,
    this.isInitiatingOrder = false,
    this.pricingSummary,
    this.checkoutSession,
    this.selectedSlotIndex = 0,
    this.selectedPaymentIndex = 0,
    this.notes,
    this.error,
  });

  CheckoutState copyWith({
    List<CustomerAddressData>? addresses,
    CustomerAddressData? selectedAddress,
    bool? isLoadingAddresses,
    bool? isLoadingPricing,
    bool? isInitiatingOrder,
    CheckoutSummaryModel? pricingSummary,
    InitiateCheckoutResponse? checkoutSession,
    int? selectedSlotIndex,
    int? selectedPaymentIndex,
    String? notes,
    String? error,
    bool clearError = false,
  }) {
    return CheckoutState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isLoadingAddresses: isLoadingAddresses ?? this.isLoadingAddresses,
      isLoadingPricing: isLoadingPricing ?? this.isLoadingPricing,
      isInitiatingOrder: isInitiatingOrder ?? this.isInitiatingOrder,
      pricingSummary: pricingSummary ?? this.pricingSummary,
      checkoutSession: checkoutSession ?? this.checkoutSession,
      selectedSlotIndex: selectedSlotIndex ?? this.selectedSlotIndex,
      selectedPaymentIndex: selectedPaymentIndex ?? this.selectedPaymentIndex,
      notes: notes ?? this.notes,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        addresses,
        selectedAddress,
        isLoadingAddresses,
        isLoadingPricing,
        isInitiatingOrder,
        pricingSummary,
        checkoutSession,
        selectedSlotIndex,
        selectedPaymentIndex,
        notes,
        error,
      ];
}
