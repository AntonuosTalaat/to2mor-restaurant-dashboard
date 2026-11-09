import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:restaurantdashboard/Services/geoapify_service.dart';

const _mapPickerStrings = {
  'select_location_title': 'حدد الموقع',
  'search_location_hint': 'ابحث عن موقع',
  'tap_to_select': 'انقر على الخريطة لتحديد الموقع',
  'getting_address': 'جاري الحصول على العنوان...',
  'loading_location': 'جاري تحديد موقعك...',
  'no_search_results': 'لا توجد نتائج',
  'searching': 'جاري البحث...',
  'search_location_failed': 'تعذر البحث عن الموقع. حاول مرة أخرى.',
  'address_not_available': 'العنوان غير متاح',
  'enable_location_to_continue': 'قم بتفعيل تحديد الموقع للمتابعة',
  'location_permission_denied': 'تم رفض إذن الموقع',
  'location_permission_permanent_denied': 'تم رفض إذن الموقع بشكل دائم',
  'location_fallback_hint':
      'تعذّر الحصول على الموقع الحالي. يمكنك اختيار الموقع يدوياً على الخريطة.',
  'cancel': 'إلغاء',
  'select': 'اختيار',
  'retry': 'إعادة المحاولة',
};

Future<Map<String, dynamic>?> showMapLocationPickerDialog(
  BuildContext context, {
  LatLng initialLocation = const LatLng(30.0444, 31.2357),
}) async {
  final size = MediaQuery.of(context).size;
  final isWide = size.width > 600;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: isWide ? size.width * 0.7 : null,
        height: isWide ? size.height * 0.8 : 520,
        child: _FlutterMapDialogContent(initialLocation: initialLocation),
      ),
    ),
  );
}

class _FlutterMapDialogContent extends StatefulWidget {
  final LatLng initialLocation;

  const _FlutterMapDialogContent({required this.initialLocation});

  @override
  State<_FlutterMapDialogContent> createState() =>
      _FlutterMapDialogContentState();
}

class _FlutterMapDialogContentState extends State<_FlutterMapDialogContent> {
  static const String _osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _userAgentPackageName = 'com.example.restaurantdashboard';
  static const Duration _searchDebounce = Duration(milliseconds: 450);
  static const int _minQueryLength = 2;

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GeoapifyService _geoapify = GeoapifyService();

  LatLng? _selectedLocation;
  String _address = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = true;
  bool _locationServiceEnabled = true;
  bool _isSearching = false;
  List<GeoapifyPlaceSuggestion> _suggestions = [];
  String? _searchErrorKey;

  Timer? _debounceTimer;
  CancelToken? _searchCancelToken;
  CancelToken? _reverseCancelToken;
  int _searchRequestId = 0;
  int _reverseRequestId = 0;
  Key _mapKey = UniqueKey();
  bool _suppressSearchListener = false;

  String _text(String key) => _mapPickerStrings[key] ?? key;

  @override
  void initState() {
    super.initState();
    _address = _text('tap_to_select');
    _searchController.addListener(_onSearchTextChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndGetLocation();
    });
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchTextChanged() {
    if (!mounted) return;
    setState(() {});
    if (_suppressSearchListener) return;
    _scheduleAutocomplete();
  }

  void _scheduleAutocomplete() {
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();

    if (query.length < _minQueryLength) {
      _searchCancelToken?.cancel();
      _searchCancelToken = null;
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
          _searchErrorKey = null;
        });
      }
      return;
    }

    _debounceTimer = Timer(_searchDebounce, () {
      _runAutocomplete(query);
    });
  }

  Future<void> _runAutocomplete(String query) async {
    if (!mounted) return;

    final requestId = ++_searchRequestId;
    _searchCancelToken?.cancel();
    final cancelToken = CancelToken();
    _searchCancelToken = cancelToken;

    setState(() {
      _isSearching = true;
      _searchErrorKey = null;
    });

    try {
      final results = await _geoapify.autocomplete(
        query: query,
        lang: 'ar',
        limit: 8,
        biasLat: _selectedLocation?.latitude,
        biasLon: _selectedLocation?.longitude,
        cancelToken: cancelToken,
      );

      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _suggestions = results;
        _isSearching = false;
        _searchErrorKey = results.isEmpty ? 'no_search_results' : null;
      });
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted || requestId != _searchRequestId) return;
      debugPrint('Autocomplete error: $e');
      setState(() {
        _suggestions = [];
        _isSearching = false;
        _searchErrorKey = 'search_location_failed';
      });
    } on GeoapifyException catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      debugPrint('Autocomplete Geoapify: $e');
      setState(() {
        _suggestions = [];
        _isSearching = false;
        _searchErrorKey = 'search_location_failed';
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      debugPrint('Autocomplete unexpected: $e');
      setState(() {
        _suggestions = [];
        _isSearching = false;
        _searchErrorKey = 'search_location_failed';
      });
    }
  }

  void _onSuggestionSelected(GeoapifyPlaceSuggestion place) {
    _debounceTimer?.cancel();
    _searchCancelToken?.cancel();
    _searchRequestId++;

    final latLng = LatLng(place.latitude, place.longitude);

    FocusScope.of(context).unfocus();

    _suppressSearchListener = true;
    _searchController.text = place.formattedAddress;
    _suppressSearchListener = false;

    setState(() {
      _selectedLocation = latLng;
      _address = place.formattedAddress;
      _isLoadingAddress = false;
      _suggestions = [];
      _isSearching = false;
      _searchErrorKey = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(latLng, 15.0);
      } catch (e) {
        debugPrint('Error moving map: $e');
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchCancelToken?.cancel();
    _searchRequestId++;
    _suppressSearchListener = true;
    _searchController.clear();
    _suppressSearchListener = false;
    setState(() {
      _suggestions = [];
      _isSearching = false;
      _searchErrorKey = null;
    });
  }

  void _useInitialLocationFallback({String? message}) {
    if (!mounted) return;

    setState(() {
      _selectedLocation = widget.initialLocation;
      _isLoadingLocation = false;
      _locationServiceEnabled = true;
      _address = _text('tap_to_select');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(widget.initialLocation, 13.0);
      } catch (e) {
        debugPrint('Error moving map: $e');
      }
    });

    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _checkAndGetLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
      _selectedLocation = null;
      _address = _text('tap_to_select');
    });

    try {
      if (kIsWeb) {
        await _getCurrentLocationWeb();
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _useInitialLocationFallback(
            message: _text('location_fallback_hint'),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => _locationServiceEnabled = true);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          _useInitialLocationFallback(
            message: _text('location_permission_denied'),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _useInitialLocationFallback(
          message: _text('location_permission_permanent_denied'),
        );
        return;
      }

      await _getCurrentLocation();
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) return;
      _useInitialLocationFallback(message: _text('location_fallback_hint'));
    }
  }

  Future<void> _getCurrentLocationWeb() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;

      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLocation;
        _isLoadingLocation = false;
        _locationServiceEnabled = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(newLocation, 15.0);
        } catch (e) {
          debugPrint('Error moving map: $e');
        }
      });

      await _reverseGeocode(newLocation);
    } catch (e) {
      debugPrint('Web location error: $e');
      if (!mounted) return;
      _useInitialLocationFallback(message: _text('location_fallback_hint'));
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;

      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLocation;
        _isLoadingLocation = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(newLocation, 15.0);
        } catch (e) {
          debugPrint('Error moving map: $e');
        }
      });

      await _reverseGeocode(newLocation);
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        _useInitialLocationFallback(message: _text('location_fallback_hint'));
      }
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    if (!mounted) return;

    final requestId = ++_reverseRequestId;
    _reverseCancelToken?.cancel();
    final cancelToken = CancelToken();
    _reverseCancelToken = cancelToken;

    setState(() {
      _isLoadingAddress = true;
      _address = _text('getting_address');
    });

    try {
      final formatted = await _geoapify.reverseGeocode(
        latitude: location.latitude,
        longitude: location.longitude,
        lang: 'ar',
        cancelToken: cancelToken,
      );

      if (!mounted || requestId != _reverseRequestId) return;

      setState(() {
        _address = formatted.isNotEmpty
            ? formatted
            : _text('address_not_available');
        _isLoadingAddress = false;
      });
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted || requestId != _reverseRequestId) return;
      debugPrint('Reverse geocode error: $e');
      setState(() {
        _address =
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        _isLoadingAddress = false;
      });
    } on GeoapifyException catch (e) {
      if (!mounted || requestId != _reverseRequestId) return;
      debugPrint('Reverse geocode Geoapify: $e');
      setState(() {
        _address =
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        _isLoadingAddress = false;
      });
    } catch (e) {
      if (!mounted || requestId != _reverseRequestId) return;
      debugPrint('Reverse geocode unexpected: $e');
      setState(() {
        _address =
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        _isLoadingAddress = false;
      });
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng latLng) {
    setState(() => _selectedLocation = latLng);
    _reverseGeocode(latLng);
  }

  Map<String, dynamic> _buildResult() {
    final loc = _selectedLocation!;
    return {
      'latlng': loc,
      'address': _address,
      'latitude': loc.latitude,
      'longitude': loc.longitude,
    };
  }

  @override
  Widget build(BuildContext context) {
    const textDirection = TextDirection.rtl;

    final bool canSelect = _selectedLocation != null &&
        !_isLoadingLocation &&
        !_isLoadingAddress;

    final showSuggestionsPanel = _searchFocusNode.hasFocus &&
        (_isSearching ||
            _suggestions.isNotEmpty ||
            _searchErrorKey != null) &&
        _searchController.text.trim().length >= _minQueryLength;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _text('select_location_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Directionality(
          textDirection: textDirection,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  enabled: !_isLoadingLocation,
                  textDirection: textDirection,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: _text('search_location_hint'),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.search, size: 22),
                    suffixIcon: _buildSearchSuffix(),
                  ),
                ),
                if (showSuggestionsPanel) _buildSuggestionsPanel(textDirection),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: _isLoadingLocation
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(_text('loading_location')),
                  ],
                )
              : _isLoadingAddress
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(_text('getting_address')),
                      ],
                    )
                  : Text(
                      _address,
                      textAlign: TextAlign.center,
                      textDirection: textDirection,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedLocation == null
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
        ),
        Expanded(
          child: _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    FlutterMap(
                      key: _mapKey,
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _selectedLocation ?? widget.initialLocation,
                        initialZoom: 15.0,
                        onTap: _onMapTapped,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _osmTileUrl,
                          userAgentPackageName: _userAgentPackageName,
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              'OpenStreetMap contributors',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        if (!_locationServiceEnabled && !_isLoadingLocation)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _text('enable_location_to_continue'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _mapKey = UniqueKey();
                    });
                    _checkAndGetLocation();
                  },
                  child: Text(_text('retry')),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_text('cancel')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      canSelect ? () => Navigator.pop(context, _buildResult()) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSelect
                        ? const Color(0xFFFFD800)
                        : Colors.grey.shade300,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    _text('select'),
                    style: TextStyle(
                      color: canSelect ? Colors.black : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildSearchSuffix() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_searchController.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear, size: 20),
        onPressed: _clearSearch,
        tooltip: _text('cancel'),
      );
    }
    return null;
  }

  Widget _buildSuggestionsPanel(TextDirection textDirection) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isSearching && _suggestions.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(_text('searching')),
                ],
              ),
            )
          : _searchErrorKey != null && _suggestions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _text(_searchErrorKey!),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final place = _suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined, size: 20),
                      title: Text(
                        place.formattedAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: textDirection,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => _onSuggestionSelected(place),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCancelToken?.cancel();
    _reverseCancelToken?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
