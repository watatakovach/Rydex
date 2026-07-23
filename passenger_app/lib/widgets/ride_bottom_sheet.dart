import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services/search_service.dart';
import '../models/place.dart';

class RideBottomSheet extends StatefulWidget {
  final Function(Place place) onPlaceSelected;

  const RideBottomSheet({
    super.key,
    required this.onPlaceSelected,
  });

  @override
  State<RideBottomSheet> createState() =>
      _RideBottomSheetState();
}

class _RideBottomSheetState
    extends State<RideBottomSheet> {
  final TextEditingController _searchController =
      TextEditingController();

  Timer? _debounce;

  List<Place> _results = [];

  bool _isLoading = false;

  void _searchPlaces(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 500),
      () async {
        if (!mounted) return;

        setState(() {
          _isLoading = true;
        });

        try {
          final results =
              await SearchService.searchPlaces(query);

          if (!mounted) return;

          setState(() {
            _results = results;
            _isLoading = false;
          });
        } catch (e) {
          if (!mounted) return;

          setState(() {
            _results = [];
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Search failed: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  void _selectPlace(Place place) {
    _searchController.text = place.name;

    setState(() {
      _results = [];
    });

    FocusScope.of(context).unfocus();

    widget.onPlaceSelected(place);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Where are you going?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Search box
            TextField(
              controller: _searchController,
              onChanged: _searchPlaces,
              decoration: InputDecoration(
                hintText:
                    'Search destination...',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding:
                            EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : _searchController
                            .text
                            .isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                            ),
                            onPressed: () {
                              _searchController
                                  .clear();

                              setState(() {
                                _results = [];
                              });
                            },
                          )
                        : null,
                filled: true,
                fillColor:
                    Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            // Search results
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 10),

              Container(
                constraints:
                    const BoxConstraints(
                  maxHeight: 220,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder:
                      (context, index) =>
                          const Divider(
                    height: 1,
                  ),
                  itemBuilder:
                      (context, index) {
                    final place =
                        _results[index];

                    return ListTile(
                      leading:
                          const CircleAvatar(
                        child: Icon(
                          Icons.location_on,
                        ),
                      ),
                      title: Text(
                        place.name,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                      subtitle:
                          const Text(
                        'OpenStreetMap',
                      ),
                      trailing:
                          const Icon(
                        Icons
                            .arrow_forward_ios,
                        size: 16,
                      ),
                      onTap: () {
                        _selectPlace(place);
                      },
                    );
                  },
                ),
              ),
            ],

            // Show saved places only
            // when there are no search results
            if (_results.isEmpty) ...[
              const SizedBox(height: 20),

              ListTile(
                leading:
                    const CircleAvatar(
                  child: Icon(
                    Icons.home,
                  ),
                ),
                title:
                    const Text('Home'),
                subtitle:
                    const Text(
                  'Saved Place',
                ),
              ),

              ListTile(
                leading:
                    const CircleAvatar(
                  child: Icon(
                    Icons.school,
                  ),
                ),
                title:
                    const Text('Campus'),
                subtitle:
                    const Text(
                  'Maseno University',
                ),
              ),

              ListTile(
                leading:
                    const CircleAvatar(
                  child: Icon(
                    Icons.work,
                  ),
                ),
                title:
                    const Text('Work'),
                subtitle:
                    const Text(
                  'Saved Place',
                ),
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Ride request will be
                  // implemented next.
                },
                child: const Text(
                  'REQUEST RIDE',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}