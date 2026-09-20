import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';

class LocationMapPickerDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const LocationMapPickerDialog({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  static Future<LocationData?> show(
    BuildContext context, {
    double? initialLat,
    double? initialLng,
    String? initialAddress,
  }) {
    return showDialog<LocationData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LocationMapPickerDialog(
        initialLat: initialLat,
        initialLng: initialLng,
        initialAddress: initialAddress,
      ),
    );
  }

  @override
  State<LocationMapPickerDialog> createState() => _LocationMapPickerDialogState();
}

class _LocationMapPickerDialogState extends State<LocationMapPickerDialog> {
  late final MapController _mapController;
  late LatLng _selectedPoint;
  String _resolvedAddress = '';
  String _resolvedCity = '';
  String _resolvedDistrict = '';
  String _resolvedPincode = '';
  bool _isGeocoding = false;
  bool _isGpsLoading = false;

  static const LatLng _defaultLocation = LatLng(18.5204, 73.8567); // Pune default

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLat != null &&
        widget.initialLng != null &&
        widget.initialLat != 0 &&
        widget.initialLng != 0) {
      _selectedPoint = LatLng(widget.initialLat!, widget.initialLng!);
      _resolvedAddress = widget.initialAddress ?? '';
    } else {
      _selectedPoint = _defaultLocation;
      if (widget.initialAddress != null) {
        _resolvedAddress = widget.initialAddress!;
      }
    }

    if (_resolvedAddress.isEmpty) {
      _reverseGeocodePoint(_selectedPoint);
    }
  }

  Future<void> _reverseGeocodePoint(LatLng point) async {
    setState(() => _isGeocoding = true);
    try {
      final loc = await LocationService.instance.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (mounted) {
        setState(() {
          if (loc != null) {
            _resolvedAddress = loc.fullAddress;
            _resolvedCity = loc.city;
            _resolvedDistrict = loc.district;
            _resolvedPincode = loc.pincode;
          } else {
            _resolvedAddress =
                'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
          }
          _isGeocoding = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedAddress =
              'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
          _isGeocoding = false;
        });
      }
    }
  }

  Future<void> _useCurrentGps() async {
    setState(() => _isGpsLoading = true);
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null && mounted) {
        final newPoint = LatLng(pos.latitude, pos.longitude);
        setState(() => _selectedPoint = newPoint);
        _mapController.move(newPoint, 15);
        await _reverseGeocodePoint(newPoint);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access GPS. Please check location permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGpsLoading = false);
    }
  }

  void _onTapMap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedPoint = point);
    _reverseGeocodePoint(point);
  }

  void _confirmSelection() {
    final location = LocationData(
      latitude: _selectedPoint.latitude,
      longitude: _selectedPoint.longitude,
      fullAddress: _resolvedAddress.isNotEmpty
          ? _resolvedAddress
          : 'Selected Pin Location',
      city: _resolvedCity,
      district: _resolvedDistrict,
      pincode: _resolvedPincode,
      method: 'map',
    );
    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = math.min(size.width * 0.95, 620.0);
    final dialogHeight = math.min(size.height * 0.85, 680.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pin Shop Location',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Tap anywhere on map or use GPS to set exact coordinates',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Interactive Map ──────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedPoint,
                      initialZoom: 14,
                      onTap: _onTapMap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.avdar.localconnect',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.redAccent,
                              size: 48,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // GPS button floating on map
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: _isGpsLoading ? null : _useCurrentGps,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isGpsLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location_rounded,
                                      color: AppTheme.primary,
                                      size: 18,
                                    ),
                              const SizedBox(width: 6),
                              Text(
                                'Use My GPS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Zoom in/out controls
                  Positioned(
                    bottom: 14,
                    right: 14,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'zoomInWeb',
                          backgroundColor: Colors.white,
                          onPressed: () {
                            final zoom = _mapController.camera.zoom;
                            _mapController.move(_selectedPoint, zoom + 1);
                          },
                          child: const Icon(Icons.add, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'zoomOutWeb',
                          backgroundColor: Colors.white,
                          onPressed: () {
                            final zoom = _mapController.camera.zoom;
                            _mapController.move(_selectedPoint, zoom - 1);
                          },
                          child: const Icon(Icons.remove, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Location Details & Confirmation ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.store_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isGeocoding
                                  ? 'Fetching address...'
                                  : (_resolvedCity.isNotEmpty
                                      ? '$_resolvedCity, ${_resolvedDistrict.isNotEmpty ? _resolvedDistrict : "Maharashtra"}'
                                      : 'Selected Coordinates'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isGeocoding
                                  ? 'Resolving area details via OpenStreetMap Nominatim...'
                                  : _resolvedAddress,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _confirmSelection,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Confirm Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
