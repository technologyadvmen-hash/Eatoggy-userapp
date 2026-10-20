import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../widgets/custom_widgets.dart';
import '../bloc/add_address_bloc.dart';
import '../bloc/add_address_event.dart';
import '../bloc/add_address_state.dart';

class AddAddressScreen extends StatelessWidget {
  const AddAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddAddressBloc(),
      child: const _AddAddressView(),
    );
  }
}

class _AddAddressView extends StatefulWidget {
  const _AddAddressView();

  @override
  State<_AddAddressView> createState() => _AddAddressViewState();
}

class _AddAddressViewState extends State<_AddAddressView> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _flatController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefillFromCurrentLocation();
  }

  Future<void> _prefillFromCurrentLocation() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final currentAddr = prefs.getString(AppKeys.currentAddress);
      final currentCity = prefs.getString('current_city');
      final currentPin = prefs.getString('current_pincode');
      final userPhone = prefs.getString(AppKeys.userPhone);
      final userName = prefs.getString(AppKeys.userName);

      String detectedCity = (currentCity != null &&
              currentCity.trim().isNotEmpty &&
              currentCity.trim().toLowerCase() != 'gurugram')
          ? currentCity.trim()
          : '';
      String detectedPin = (currentPin != null &&
              currentPin.trim().isNotEmpty &&
              currentPin.trim() != '122002')
          ? currentPin.trim()
          : '';
      String detectedState = '';

      if (currentAddr != null && currentAddr.trim().isNotEmpty) {
        final parts = currentAddr
            .split(',')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        if (detectedPin.isEmpty) {
          final pinMatch = RegExp(r'\b\d{6}\b').firstMatch(currentAddr);
          if (pinMatch != null) {
            detectedPin = pinMatch.group(0)!;
          }
        }

        if (currentAddr.toLowerCase().contains('maharashtra')) {
          detectedState = 'Maharashtra';
        } else if (currentAddr.toLowerCase().contains('karnataka')) {
          detectedState = 'Karnataka';
        } else if (currentAddr.toLowerCase().contains('delhi')) {
          detectedState = 'Delhi';
        } else if (currentAddr.toLowerCase().contains('haryana')) {
          detectedState = 'Haryana';
        } else if (currentAddr.toLowerCase().contains('uttar pradesh')) {
          detectedState = 'Uttar Pradesh';
        } else if (parts.length > 2) {
          final possibleState = parts[parts.length - 1]
              .replaceAll(RegExp(r'\b\d{6}\b'), '')
              .trim();
          if (possibleState.isNotEmpty &&
              !possibleState.toLowerCase().contains('india')) {
            detectedState = possibleState;
          }
        }

        if (detectedCity.isEmpty) {
          if (parts.length >= 3) {
            detectedCity = parts[parts.length - 2]
                .replaceAll(RegExp(r'\b\d{6}\b'), '')
                .trim();
          } else if (parts.length == 2) {
            detectedCity = parts[1]
                .replaceAll(RegExp(r'\b\d{6}\b'), '')
                .trim();
          } else if (parts.isNotEmpty) {
            detectedCity = parts[0]
                .replaceAll(RegExp(r'\b\d{6}\b'), '')
                .trim();
          }
        }

        if (mounted) {
          setState(() {
            if (_flatController.text.isEmpty && parts.isNotEmpty) {
              _flatController.text = parts.first;
            }
            if (_streetController.text.isEmpty) {
              _streetController.text =
                  parts.length > 1 ? parts.sublist(1).join(', ') : parts.first;
            }
            if (_cityController.text.isEmpty && detectedCity.isNotEmpty) {
              _cityController.text = detectedCity;
            }
            if (_stateController.text.isEmpty && detectedState.isNotEmpty) {
              _stateController.text = detectedState;
            }
            if (_pincodeController.text.isEmpty && detectedPin.isNotEmpty) {
              _pincodeController.text = detectedPin;
            }
            if (_nameController.text.isEmpty) {
              _nameController.text = (userName != null && userName.trim().isNotEmpty)
                  ? userName.trim()
                  : 'Home';
            }
            if (_mobileController.text.isEmpty) {
              _mobileController.text = (userPhone != null && userPhone.trim().isNotEmpty)
                  ? userPhone.trim()
                  : '';
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            if (_nameController.text.isEmpty) {
              _nameController.text = (userName != null && userName.trim().isNotEmpty)
                  ? userName.trim()
                  : 'Home';
            }
            if (_mobileController.text.isEmpty) {
              _mobileController.text = (userPhone != null && userPhone.trim().isNotEmpty)
                  ? userPhone.trim()
                  : '';
            }
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _flatController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Delivery Details',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: BlocConsumer<AddAddressBloc, AddAddressState>(
        listener: (context, state) {
          if (state is AddAddressSuccess) {
            Helpers.showSuccessSnackbar(
              'Address Saved',
              state.response.message.isNotEmpty
                  ? state.response.message
                  : 'Address added successfully',
            );
            if (context.canPop()) {
              context.pop(true);
            } else {
              context.go(AppRoutes.home);
            }
          } else if (state is AddAddressFailure) {
            Helpers.showErrorSnackbar('Error', state.error);
          }
        },
        builder: (context, state) {
          final isLoading = state is AddAddressLoading;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Receiver Contact
                  Text(
                    'Contact Details',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    labelText: 'RECEIVER NAME',
                    hintText: 'e.g. Rahul Sharma',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    labelText: 'MOBILE NUMBER',
                    hintText: 'e.g. 9876543210',
                    keyboardType: TextInputType.phone,
                    controller: _mobileController,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Address Details
                  Text(
                    'Address Details',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    labelText: 'FLAT / HOUSE NO / FLOOR',
                    hintText: 'e.g. Flat 402, Sunshine Heights',
                    controller: _flatController,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    labelText: 'STREET / AREA / SECTOR',
                    hintText: 'e.g. Sector 62',
                    controller: _streetController,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    labelText: 'LANDMARK (OPTIONAL)',
                    hintText: 'e.g. Near Fortis Hospital',
                    controller: _landmarkController,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          labelText: 'CITY',
                          hintText: 'e.g. Noida',
                          controller: _cityController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          labelText: 'STATE',
                          hintText: 'e.g. Uttar Pradesh',
                          controller: _stateController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    labelText: 'PINCODE',
                    hintText: 'e.g. 201301',
                    keyboardType: TextInputType.number,
                    controller: _pincodeController,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Address Label / Type
                  Text(
                    'Save As',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['Home', 'Work', 'Other'].map((type) {
                      final isSelected = state.selectedLabel == type;
                      return GestureDetector(
                        onTap: isLoading
                            ? null
                            : () {
                                context
                                    .read<AddAddressBloc>()
                                    .add(AddressTypeChangedEvent(type));
                              },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.surface,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            type,
                            style: GoogleFonts.outfit(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.secondaryText,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Default Address Switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Set as default address',
                          style: GoogleFonts.inter(
                            color: AppColors.primaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: state.isDefault,
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                          onChanged: isLoading
                              ? null
                              : (val) {
                                  context
                                      .read<AddAddressBloc>()
                                      .add(AddressDefaultToggledEvent(val));
                                },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Save & Proceed Button
                  PrimaryGoldButton(
                    text: 'Save Address & Proceed',
                    isLoading: isLoading,
                    onPressed: () {
                      context.read<AddAddressBloc>().add(
                            SubmitAddressEvent(
                              name: _nameController.text,
                              mobile: _mobileController.text,
                              addressLine1: _flatController.text,
                              addressLine2: _streetController.text,
                              city: _cityController.text,
                              state: _stateController.text,
                              pincode: _pincodeController.text,
                              landmark: _landmarkController.text,
                              label: state.selectedLabel,
                              isDefault: state.isDefault,
                            ),
                          );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
