import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/services/network_exceptions.dart';
import '../../../core/services/storage_service.dart';
import '../data/models/add_address_response.dart';
import '../data/models/delete_address_response.dart';
import '../data/models/get_addresses_response.dart';
import '../data/models/update_address_request.dart';
import '../data/repositories/get_addresses_repository.dart';
import 'saved_addresses_event.dart';
import 'saved_addresses_state.dart';

class SavedAddressesBloc
    extends Bloc<SavedAddressesEvent, SavedAddressesState> {
  final GetAddressesRepository _getAddressesRepository;

  SavedAddressesBloc({GetAddressesRepository? getAddressesRepository})
      : _getAddressesRepository =
            getAddressesRepository ?? GetAddressesRepositoryImpl(),
        super(const SavedAddressesInitial()) {
    on<FetchSavedAddressesEvent>(_onFetchSavedAddresses);
    on<SelectActiveAddressEvent>(_onSelectActiveAddress);
    on<DeleteSavedAddressEvent>(_onDeleteAddress);
    on<UpdateSavedAddressEvent>(_onUpdateAddress);
  }

  static const String _cacheKey = 'cached_customer_addresses';

  Future<void> _onFetchSavedAddresses(
    FetchSavedAddressesEvent event,
    Emitter<SavedAddressesState> emit,
  ) async {
    emit(const SavedAddressesLoading());

    try {
      final response = await _getAddressesRepository.getAddresses();

      final Map<String, dynamic> responseData =
          response.data is Map
              ? Map<String, dynamic>.from(response.data as Map)
              : (response.data is List
                  ? {'success': true, 'data': response.data}
                  : <String, dynamic>{});

      final addressesResponse = GetAddressesResponse.fromJson(responseData);

      if (addressesResponse.data.isNotEmpty) {
        // Persist to local cache for instant retrieval across sessions
        final prefs = await SharedPreferencesService.getInstance();
        final currentAddr = prefs.getString(AppKeys.currentAddress);

        final list = List<CustomerAddressData>.from(addressesResponse.data);
        if (currentAddr != null && !currentAddr.toLowerCase().contains('gurugram')) {
          list.removeWhere((a) =>
              a.city.toLowerCase() == 'gurugram' &&
              (a.pincode == '122002' || a.id.startsWith('addr_local') || a.id.startsWith('addr_')));
        }

        final jsonList = list.map((a) => a.toJson()).toList();
        await prefs.setString(_cacheKey, jsonEncode(jsonList));

        // Identify default or previously selected
        String? defaultId = prefs.getString('selected_address_id');
        if (defaultId == null || !list.any((a) => a.id == defaultId)) {
          for (final a in list) {
            if (a.isDefault) {
              defaultId = a.id;
              break;
            }
          }
          defaultId ??= list.isNotEmpty ? list.first.id : null;
        }

        emit(SavedAddressesLoaded(
          addresses: list,
          activeAddressId: defaultId,
        ));
        return;
      }

      // If server returned empty, check local cache
      final cached = await _getCachedAddresses();
      if (cached.isNotEmpty) {
        emit(SavedAddressesLoaded(
          addresses: cached,
          activeAddressId: cached.first.id,
        ));
      } else {
        emit(const SavedAddressesEmpty());
      }
    } catch (e) {
      // In case of error (network, token issue), serve cached addresses
      final cached = await _getCachedAddresses();
      if (cached.isNotEmpty) {
        emit(SavedAddressesLoaded(
          addresses: cached,
          activeAddressId: cached.first.id,
        ));
        return;
      }

      String errorMessage = 'Failed to load addresses.';
      if (e is DioException) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'].toString();
        } else {
          errorMessage = NetworkExceptions.getErrorMessage(e);
        }
      }
      emit(SavedAddressesFailure(error: errorMessage));
    }
  }

  Future<List<CustomerAddressData>> _getCachedAddresses() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final currentAddr = prefs.getString(AppKeys.currentAddress);
      final str = prefs.getString(_cacheKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          final list = decoded
              .whereType<Map>()
              .map((e) => CustomerAddressData.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          if (currentAddr != null && !currentAddr.toLowerCase().contains('gurugram')) {
            list.removeWhere((a) =>
                a.city.toLowerCase() == 'gurugram' &&
                (a.pincode == '122002' || a.id.startsWith('addr_local') || a.id.startsWith('addr_')));
          }

          if (list.isNotEmpty) {
            return list;
          }
        }
      }

      // Fallback from AppKeys.currentAddress
      if (currentAddr != null && currentAddr.trim().isNotEmpty) {
        final parts = currentAddr
            .split(',')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
        final street = parts.isNotEmpty ? parts.first : 'Current Location';
        final savedCity = prefs.getString('current_city');
        final savedPin = prefs.getString('current_pincode');

        final city = (savedCity != null && savedCity.isNotEmpty && savedCity != 'Gurugram')
            ? savedCity
            : (parts.length > 2
                ? parts[parts.length - 2].replaceAll(RegExp(r'\b\d{6}\b'), '').trim()
                : (parts.length > 1
                    ? parts[1].replaceAll(RegExp(r'\b\d{6}\b'), '').trim()
                    : 'Local'));

        final pin = (savedPin != null && savedPin.isNotEmpty && savedPin != '122002')
            ? savedPin
            : (RegExp(r'\b\d{6}\b').firstMatch(currentAddr)?.group(0) ?? '');

        final stateName = currentAddr.contains('Maharashtra')
            ? 'Maharashtra'
            : (currentAddr.contains('Karnataka')
                ? 'Karnataka'
                : (currentAddr.contains('Delhi') ? 'Delhi' : ''));

        return [
          CustomerAddressData(
            id: 'addr_local_${DateTime.now().millisecondsSinceEpoch}',
            customerId: '',
            name: prefs.getString(AppKeys.userName) ?? 'Primary Address',
            mobile: prefs.getString(AppKeys.userPhone) ?? '',
            addressLine1: street,
            addressLine2: currentAddr,
            city: city,
            state: stateName,
            pincode: pin,
            label: 'Home',
            isDefault: true,
          ),
        ];
      }
    } catch (_) {}
    return [];
  }

  Future<void> _onSelectActiveAddress(
    SelectActiveAddressEvent event,
    Emitter<SavedAddressesState> emit,
  ) async {
    final prefs = await SharedPreferencesService.getInstance();
    final fullAddress =
        '${event.address.addressLine1}, ${event.address.addressLine2}, ${event.address.city}';
    await prefs.setString(AppKeys.currentAddress, fullAddress);
    if (event.address.city.isNotEmpty) {
      await prefs.setString('current_city', event.address.city);
    }
    if (event.address.pincode.isNotEmpty) {
      await prefs.setString('current_pincode', event.address.pincode);
    }
    await prefs.setString('selected_address_id', event.address.id);

    if (state is SavedAddressesLoaded) {
      final currentList = (state as SavedAddressesLoaded).addresses.map((a) {
        return CustomerAddressData(
          id: a.id,
          customerId: a.customerId,
          name: a.name,
          mobile: a.mobile,
          addressLine1: a.addressLine1,
          addressLine2: a.addressLine2,
          city: a.city,
          state: a.state,
          pincode: a.pincode,
          landmark: a.landmark,
          label: a.label,
          isDefault: a.id == event.address.id,
          createdAt: a.createdAt,
          updatedAt: a.updatedAt,
          v: a.v,
        );
      }).toList();

      await prefs.setString(
        _cacheKey,
        jsonEncode(currentList.map((a) => a.toJson()).toList()),
      );

      emit(SavedAddressesLoaded(
        addresses: currentList,
        activeAddressId: event.address.id,
      ));
    }
  }

  Future<void> _onDeleteAddress(
    DeleteSavedAddressEvent event,
    Emitter<SavedAddressesState> emit,
  ) async {
    try {
      final response =
          await _getAddressesRepository.deleteAddress(event.addressId);

      final Map<String, dynamic> responseData =
          response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : (response.data is Map
                  ? Map<String, dynamic>.from(response.data as Map)
                  : <String, dynamic>{});

      final deleteResponse = DeleteAddressResponse.fromJson(responseData);

      if (deleteResponse.success) {
        emit(AddressDeleteSuccess(
          message: deleteResponse.message.isNotEmpty
              ? deleteResponse.message
              : 'Address deleted successfully',
        ));
        add(const FetchSavedAddressesEvent());
      } else {
        emit(SavedAddressesFailure(
          error: deleteResponse.message.isNotEmpty
              ? deleteResponse.message
              : 'Failed to delete address',
        ));
      }
    } on DioException catch (dioError) {
      String errorMessage = 'Failed to delete address.';
      if (dioError.response?.data is Map &&
          dioError.response?.data['message'] != null) {
        errorMessage = dioError.response!.data['message'].toString();
      } else {
        errorMessage = NetworkExceptions.getErrorMessage(dioError);
      }
      emit(SavedAddressesFailure(error: errorMessage));
    } catch (e) {
      emit(SavedAddressesFailure(error: e.toString()));
    }
  }

  Future<void> _onUpdateAddress(
    UpdateSavedAddressEvent event,
    Emitter<SavedAddressesState> emit,
  ) async {
    try {
      final req = event.request is UpdateAddressRequest
          ? event.request as UpdateAddressRequest
          : UpdateAddressRequest();

      final response = await _getAddressesRepository.updateAddress(
        event.addressId,
        req,
      );

      final Map<String, dynamic> responseData =
          response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : (response.data is Map
                  ? Map<String, dynamic>.from(response.data as Map)
                  : <String, dynamic>{});

      final isSuccess = responseData['success'] == true;
      if (isSuccess) {
        add(const FetchSavedAddressesEvent());
      } else {
        emit(SavedAddressesFailure(
          error: responseData['message']?.toString() ?? 'Failed to update address',
        ));
      }
    } on DioException catch (dioError) {
      String errorMessage = 'Failed to update address.';
      if (dioError.response?.data is Map &&
          dioError.response?.data['message'] != null) {
        errorMessage = dioError.response!.data['message'].toString();
      } else {
        errorMessage = NetworkExceptions.getErrorMessage(dioError);
      }
      emit(SavedAddressesFailure(error: errorMessage));
    } catch (e) {
      emit(SavedAddressesFailure(error: e.toString()));
    }
  }
}

