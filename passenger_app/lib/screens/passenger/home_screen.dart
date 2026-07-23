import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/api_service.dart';
import '../../widgets/map_widget.dart';
import '../../widgets/destination_search.dart';
import '../../models/place.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {

  // ============================================================
  // MAP KEY
  // ============================================================

  final GlobalKey<MapWidgetState>
      _mapKey =
      GlobalKey<MapWidgetState>();

  // ============================================================
  // SELECTED DESTINATION
  // ============================================================

  Place? _selectedDestination;

  // ============================================================
  // SELECTED PICKUP
  // ============================================================

  LatLng? _selectedPickup;

  // ============================================================
  // LOADING STATES
  // ============================================================

  bool _isRequestingRide = false;

  bool _isLoggingOut = false;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      extendBody: true,

      body: Stack(
        children: [

          // ======================================================
          // FULL SCREEN MAP
          // ======================================================

          Positioned.fill(
            child: MapWidget(
              key: _mapKey,

              destination:
                  _selectedDestination,

              pickupLocation:
                  _selectedPickup,

              onPickupSelected:
                  (location) {

                setState(() {
                  _selectedPickup =
                      location;
                });

                debugPrint(
                  "PICKUP UPDATED: "
                  "${location.latitude}, "
                  "${location.longitude}",
                );
              },
            ),
          ),

          // ======================================================
          // TOP CONTROLS
          // ======================================================

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),

              child: Row(
                children: [

                  // MENU
                  Material(
                    color: Colors.white,
                    elevation: 5,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),

                    child:
                        IconButton(
                      onPressed: () {
                        _showMenu();
                      },

                      icon:
                          const Icon(
                        Icons.menu,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // NOTIFICATIONS
                  Material(
                    color: Colors.white,
                    elevation: 5,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),

                    child:
                        IconButton(
                      onPressed: () {},

                      icon:
                          const Icon(
                        Icons.notifications_none,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  // PROFILE
                  Material(
                    color: Colors.white,
                    elevation: 5,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),

                    child:
                        IconButton(
                      onPressed: () {
                        _showMenu();
                      },

                      icon:
                          const Icon(
                        Icons.person,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // BOOKING PANEL
          // ======================================================

          DraggableScrollableSheet(
            initialChildSize:
                0.38,

            minChildSize:
                0.14,

            maxChildSize:
                0.85,

            snap: true,

            snapSizes:
                const [
              0.14,
              0.38,
              0.80,
            ],

            builder: (
              context,
              scrollController,
            ) {

              return Container(
                decoration:
                    const BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.vertical(
                    top:
                        Radius.circular(
                      30,
                    ),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black26,

                      blurRadius:
                          20,

                      offset:
                          Offset(
                        0,
                        -5,
                      ),
                    ),
                  ],
                ),

                child:
                    ListView(
                  controller:
                      scrollController,

                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    30,
                  ),

                  children: [

                    // HANDLE
                    Center(
                      child:
                          Container(
                        width: 45,
                        height: 5,

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey.shade400,

                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    // TITLE
                    const Text(
                      "Where are you going?",

                      style:
                          TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    // DESTINATION SEARCH
                    DestinationSearch(
                      onPlaceSelected:
                          (place) {

                        setState(() {
                          _selectedDestination =
                              place;
                        });

                        debugPrint(
                          "DESTINATION: "
                          "${place.name}",
                        );

                        debugPrint(
                          "LAT: "
                          "${place.latitude}",
                        );

                        debugPrint(
                          "LON: "
                          "${place.longitude}",
                        );
                      },
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // PICKUP TITLE
                    const Text(
                      "Pickup Location",

                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // CURRENT LOCATION
                    _actionTile(
                      icon:
                          Icons.my_location,

                      title:
                          "Use My Location",

                      subtitle:
                          "Use your current GPS location",

                      onTap:
                          () async {

                        try {

                          await _mapKey
                              .currentState
                              ?.useMyLocation();

                        } catch (e) {

                          _showError(
                            e.toString(),
                          );

                        }
                      },
                    ),

                    // PICKUP ON MAP
                    _actionTile(
                      icon:
                          Icons.location_on,

                      title:
                          "Set Pickup on Map",

                      subtitle:
                          "Tap the map to choose pickup",

                      onTap: () {

                        _mapKey
                            .currentState
                            ?.enablePickupSelection();

                        ScaffoldMessenger
                            .of(context)
                            .showSnackBar(
                          const SnackBar(
                            content:
                                Text(
                              "Tap anywhere on the map to set your pickup location.",
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // SAVED PLACES
                    const Text(
                      "Saved Places",

                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _savedPlace(
                      icon:
                          Icons.home,

                      title:
                          "Home",

                      subtitle:
                          "Saved Place",
                    ),

                    _savedPlace(
                      icon:
                          Icons.school,

                      title:
                          "Campus",

                      subtitle:
                          "Maseno University",
                    ),

                    _savedPlace(
                      icon:
                          Icons.work,

                      title:
                          "Work",

                      subtitle:
                          "Saved Place",
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // REQUEST RIDE BUTTON
                    // ==================================================

                    SizedBox(
                      width:
                          double.infinity,

                      height:
                          55,

                      child:
                          ElevatedButton(
                        onPressed:
                            _isRequestingRide
                                ? null
                                : _requestRide,

                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors.green,

                          foregroundColor:
                              Colors.white,

                          disabledBackgroundColor:
                              Colors.grey,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              15,
                            ),
                          ),
                        ),

                        child:
                            _isRequestingRide

                                ? const SizedBox(
                                    width: 25,
                                    height: 25,

                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          Colors.white,

                                      strokeWidth:
                                          3,
                                    ),
                                  )

                                : const Text(
                                    "REQUEST RIDE",

                                    style:
                                        TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar:
          NavigationBar(
        selectedIndex: 0,

        destinations:
            const [

          NavigationDestination(
            icon:
                Icon(
              Icons.home_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.home,
            ),

            label:
                "Home",
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.history,
            ),

            label:
                "Trips",
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.message_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.message,
            ),

            label:
                "Messages",
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.person_outline,
            ),

            selectedIcon:
                Icon(
              Icons.person,
            ),

            label:
                "Profile",
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REQUEST RIDE
  // ============================================================

  Future<void> _requestRide() async {

    // Check destination
    if (_selectedDestination == null) {

      _showError(
        "Please select a destination first.",
      );

      return;
    }

    // Check pickup
    if (_selectedPickup == null) {

      _showError(
        "Please select your pickup location first.",
      );

      return;
    }

    setState(() {
      _isRequestingRide = true;
    });

    try {

      debugPrint(
        "================================",
      );

      debugPrint(
        "REQUESTING RIDE",
      );

      debugPrint(
        "Pickup: "
        "${_selectedPickup!.latitude}, "
        "${_selectedPickup!.longitude}",
      );

      debugPrint(
        "Destination: "
        "${_selectedDestination!.name}",
      );

      debugPrint(
        "Destination coordinates: "
        "${_selectedDestination!.latitude}, "
        "${_selectedDestination!.longitude}",
      );

      debugPrint(
        "================================",
      );

      final ride =
          await ApiService.requestRide(

        pickupLatitude:
            _selectedPickup!
                .latitude,

        pickupLongitude:
            _selectedPickup!
                .longitude,

        destinationLatitude:
            _selectedDestination!
                .latitude,

        destinationLongitude:
            _selectedDestination!
                .longitude,
      );

      if (!mounted) return;

      final estimatedFare =
          ride["estimated_fare"];

      final status =
          ride["status"];

      _showRideSuccess(
        estimatedFare:
            estimatedFare,

        status:
            status,
      );

    } catch (e) {

      if (!mounted) return;

      debugPrint(
        "RIDE REQUEST ERROR: $e",
      );

      _showError(
        e.toString()
            .replaceFirst(
          "Exception: ",
          "",
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          _isRequestingRide =
              false;
        });
      }
    }
  }

  // ============================================================
  // RIDE SUCCESS
  // ============================================================

  void _showRideSuccess({
    dynamic estimatedFare,
    dynamic status,
  }) {

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor:
          Colors.transparent,

      builder:
          (context) {

        return Container(
          padding:
              const EdgeInsets.all(
            25,
          ),

          decoration:
              const BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.vertical(
              top:
                  Radius.circular(
                30,
              ),
            ),
          ),

          child:
              SafeArea(
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [

                const Icon(
                  Icons.check_circle,

                  color:
                      Colors.green,

                  size:
                      70,
                ),

                const SizedBox(
                  height: 15,
                ),

                const Text(
                  "Ride Requested!",

                  style:
                      TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  status == "assigned"
                      ? "A driver has been assigned to your ride."
                      : "We are looking for a nearby driver.",

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    color:
                        Colors.grey.shade600,

                    fontSize:
                        16,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.all(
                    18,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey.shade100,

                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),

                  child:
                      Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [

                      const Text(
                        "Estimated Fare",

                        style:
                            TextStyle(
                          fontSize:
                              16,

                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      Text(
                        "KES ${estimatedFare ?? 'N/A'}",

                        style:
                            const TextStyle(
                          fontSize:
                              20,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                SizedBox(
                  width:
                      double.infinity,

                  height:
                      52,

                  child:
                      ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    child:
                        const Text(
                      "OK",
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MENU / LOGOUT
  // ============================================================

  void _showMenu() {

    showModalBottomSheet(
      context: context,

      builder:
          (context) {

        return SafeArea(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [

              const ListTile(
                title:
                    Text(
                  "RYDEX",
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,

                    fontSize:
                        20,
                  ),
                ),
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.person,
                ),

                title:
                    const Text(
                  "Profile",
                ),

                onTap: () {
                  Navigator.pop(
                    context,
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.history,
                ),

                title:
                    const Text(
                  "My Trips",
                ),

                onTap: () {
                  Navigator.pop(
                    context,
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.logout,
                ),

                title:
                    const Text(
                  "Logout",
                ),

                onTap: () {

                  Navigator.pop(
                    context,
                  );

                  _confirmLogout();
                },
              ),

              const SizedBox(
                height: 10,
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CONFIRM LOGOUT
  // ============================================================

  void _confirmLogout() {

    showDialog(
      context: context,

      builder:
          (context) {

        return AlertDialog(
          title:
              const Text(
            "Logout",
          ),

          content:
              const Text(
            "Are you sure you want to logout?",
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },

              child:
                  const Text(
                "CANCEL",
              ),
            ),

            ElevatedButton(
              onPressed:
                  _isLoggingOut
                      ? null
                      : () async {

                          Navigator.pop(
                            context,
                          );

                          await _logout();
                        },

              child:
                  _isLoggingOut

                      ? const SizedBox(
                          width: 20,
                          height: 20,

                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                          ),
                        )

                      : const Text(
                          "LOGOUT",
                        ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {

    setState(() {
      _isLoggingOut = true;
    });

    try {

      await ApiService.logout();

      if (!mounted) return;

      Navigator.of(context)
          .pushNamedAndRemoveUntil(
        "/login",
        (route) => false,
      );

    } catch (e) {

      if (!mounted) return;

      _showError(
        e.toString()
            .replaceFirst(
          "Exception: ",
          "",
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          _isLoggingOut =
              false;
        });
      }
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(
    String message,
  ) {

    ScaffoldMessenger
        .of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),

        backgroundColor:
            Colors.red,
      ),
    );
  }

  // ============================================================
  // ACTION TILE
  // ============================================================

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {

    return Card(
      elevation:
          0,

      color:
          Colors.grey.shade100,

      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),

      child:
          ListTile(
        onTap:
            onTap,

        leading:
            CircleAvatar(
          backgroundColor:
              Colors.white,

          child:
              Icon(
            icon,
            color:
                Colors.black,
          ),
        ),

        title:
            Text(
          title,

          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle:
            Text(
          subtitle,
        ),

        trailing:
            const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }

  // ============================================================
  // SAVED PLACE
  // ============================================================

  Widget _savedPlace({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {

    return Material(
      color:
          Colors.white,

      child:
          InkWell(
        borderRadius:
            BorderRadius.circular(
          15,
        ),

        onTap: () {

          debugPrint(
            "Selected saved place: "
            "$title",
          );
        },

        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 12,
          ),

          child:
              Row(
            children: [

              CircleAvatar(
                backgroundColor:
                    Colors.grey.shade100,

                child:
                    Icon(
                  icon,
                  color:
                      Colors.black,
                ),
              ),

              const SizedBox(
                width: 15,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      title,

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      subtitle,

                      style:
                          TextStyle(
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}