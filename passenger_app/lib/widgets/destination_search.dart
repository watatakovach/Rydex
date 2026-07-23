import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services/search_service.dart';
import '../models/place.dart';

class DestinationSearch extends StatefulWidget {
  final Function(Place place) onPlaceSelected;

  const DestinationSearch({
    super.key,
    required this.onPlaceSelected,
  });

  @override
  State<DestinationSearch> createState() =>
      _DestinationSearchState();
}

class _DestinationSearchState
    extends State<DestinationSearch> {
  final TextEditingController _controller =
      TextEditingController();

  Timer? _debounce;

  List<Place> _results = [];

  bool _isLoading = false;

  // ==========================================
  // SEARCH
  // ==========================================

  void _search(String query) {
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
          debugPrint(
            'Searching OpenStreetMap: $query',
          );

          final results =
              await SearchService.searchPlaces(
            query,
          );

          if (!mounted) return;

          setState(() {
            _results = results;
            _isLoading = false;
          });

          debugPrint(
            'Found ${results.length} locations',
          );
        } catch (e) {
          if (!mounted) return;

          setState(() {
            _results = [];
            _isLoading = false;
          });

          debugPrint(
            'Search error: $e',
          );

          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                'Search failed: $e',
              ),
              backgroundColor:
                  Colors.red,
            ),
          );
        }
      },
    );
  }

  // ==========================================
  // SELECT DESTINATION
  // ==========================================

  void _selectPlace(Place place) {
    debugPrint(
      '====================================',
    );

    debugPrint(
      'Destination selected: ${place.name}',
    );

    debugPrint(
      'Latitude: ${place.latitude}',
    );

    debugPrint(
      'Longitude: ${place.longitude}',
    );

    debugPrint(
      '====================================',
    );

    // Show selected destination
    // inside search field
    _controller.text = place.name;

    // Hide search results
    setState(() {
      _results = [];
    });

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Send selected destination
    // to HomeScreen
    widget.onPlaceSelected(place);
  }

  // ==========================================
  // CLEAR SEARCH
  // ==========================================

  void _clearSearch() {
    _controller.clear();

    setState(() {
      _results = [];
      _isLoading = false;
    });
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  @override
  void dispose() {
    _debounce?.cancel();

    _controller.dispose();

    super.dispose();
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      mainAxisSize:
          MainAxisSize.min,
      children: [

        // ======================================
        // SEARCH FIELD
        // ======================================

        Material(
          color: Colors.white,
          elevation: 8,
          borderRadius:
              BorderRadius.circular(15),
          clipBehavior:
              Clip.antiAlias,

          child: TextField(
            controller:
                _controller,

            onChanged:
                _search,

            decoration:
                InputDecoration(
              hintText:
                  'Search destination...',

              prefixIcon:
                  const Icon(
                Icons.search,
              ),

              suffixIcon:
                  _isLoading
                      ? const Padding(
                          padding:
                              EdgeInsets.all(
                            12,
                          ),

                          child:
                              SizedBox(
                            width: 20,
                            height: 20,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : (_controller
                              .text
                              .isNotEmpty
                          ? IconButton(
                              icon:
                                  const Icon(
                                Icons.close,
                              ),

                              onPressed:
                                  _clearSearch,
                            )
                          : null),

              filled: true,

              fillColor:
                  Colors.white,

              contentPadding:
                  const EdgeInsets
                      .symmetric(
                vertical: 16,
                horizontal: 16,
              ),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),

                borderSide:
                    BorderSide.none,
              ),
            ),
          ),
        ),

        // ======================================
        // SEARCH RESULTS
        // ======================================

        if (_results.isNotEmpty)
          Container(
            margin:
                const EdgeInsets.only(
              top: 8,
            ),

            constraints:
                const BoxConstraints(
              maxHeight: 300,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.white,

              borderRadius:
                  BorderRadius.circular(
                15,
              ),

              boxShadow:
                  const [
                BoxShadow(
                  color:
                      Colors.black26,

                  blurRadius:
                      12,

                  offset:
                      Offset(0, 4),
                ),
              ],
            ),

            child:
                Material(
              color:
                  Colors.white,

              borderRadius:
                  BorderRadius.circular(
                15,
              ),

              clipBehavior:
                  Clip.antiAlias,

              child:
                  ListView.separated(
                shrinkWrap:
                    true,

                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 5,
                ),

                itemCount:
                    _results.length,

                separatorBuilder:
                    (
                  context,
                  index,
                ) {
                  return const Divider(
                    height: 1,
                  );
                },

                itemBuilder:
                    (
                  context,
                  index,
                ) {
                  final place =
                      _results[index];

                  return Material(
                    color:
                        Colors.white,

                    child:
                        InkWell(
                      onTap: () {
                        _selectPlace(
                          place,
                        );
                      },

                      child:
                          ListTile(
                        tileColor:
                            Colors.white,

                        leading:
                            const CircleAvatar(
                          backgroundColor:
                              Colors.black,

                          child:
                              Icon(
                            Icons
                                .location_on,

                            color:
                                Colors.white,

                            size: 20,
                          ),
                        ),

                        // =================================
                        // LOCATION NAME
                        // =================================

                        title:
                            Text(
                          place.name,

                          maxLines:
                              2,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w600,

                            fontSize:
                                16,
                          ),
                        ),

                        // =================================
                        // SUBTITLE
                        // =================================

                        subtitle: Text(
                          
                          place.displayName,

                          maxLines:
                              2,

                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),

                        trailing:
                            const Icon(
                          Icons
                              .arrow_forward_ios,

                          size:
                              16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}