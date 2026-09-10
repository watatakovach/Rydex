// import 'package:flutter/material.dart';

// import '../../core/services/api_service.dart';
// import '../../models/driver_profile.dart';

// const String backendUrl = 'http://192.168.2.104:8000';

// class DriverProfileScreen extends StatefulWidget {
//   const DriverProfileScreen({super.key});

//   @override
//   State<DriverProfileScreen> createState() =>
//       _DriverProfileScreenState();
// }

// class _DriverProfileScreenState
//     extends State<DriverProfileScreen> {
//   DriverProfile? profile;

//   bool isLoading = true;
//   String? errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     loadProfile();
//   }

//   // ============================================================
//   // LOAD DRIVER PROFILE
//   // ============================================================

//   Future<void> loadProfile() async {
//     if (mounted) {
//       setState(() {
//         isLoading = true;
//         errorMessage = null;
//       });
//     }

//     try {
//       final result =
//           await ApiService.getDriverProfile();

//       if (!mounted) return;

//       setState(() {
//         profile = result;
//         isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//         errorMessage =
//             e.toString().replaceFirst(
//                   'Exception: ',
//                   '',
//                 );
//       });
//     }
//   }

//   // ============================================================
//   // IMAGE URL
//   // ============================================================

//   String? getImageUrl(String? imagePath) {
//     if (imagePath == null) {
//       return null;
//     }

//     final path = imagePath.trim();

//     if (path.isEmpty) {
//       return null;
//     }

//     if (path.startsWith('http://') ||
//         path.startsWith('https://')) {
//       return path;
//     }

//     return '$backendUrl$path';
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Profile'),
//         actions: [
//           IconButton(
//             tooltip: 'Refresh',
//             onPressed: isLoading
//                 ? null
//                 : loadProfile,
//             icon: const Icon(Icons.refresh),
//           ),
//         ],
//       ),

//       body: _buildBody(),
//     );
//   }

//   // ============================================================
//   // BODY
//   // ============================================================

//   Widget _buildBody() {
//     if (isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     if (errorMessage != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment:
//                 MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.error_outline,
//                 size: 70,
//                 color: Colors.red,
//               ),

//               const SizedBox(height: 20),

//               Text(
//                 errorMessage!,
//                 textAlign: TextAlign.center,
//               ),

//               const SizedBox(height: 20),

//               ElevatedButton.icon(
//                 onPressed: loadProfile,
//                 icon: const Icon(
//                   Icons.refresh,
//                 ),
//                 label: const Text(
//                   'Retry',
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     if (profile == null) {
//       return const Center(
//         child: Text(
//           'Driver profile not found.',
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: loadProfile,

//       child: ListView(
//         padding:
//             const EdgeInsets.all(20),

//         children: [
//           _buildProfileHeader(),

//           const SizedBox(height: 20),

//           _buildStatusCard(),

//           const SizedBox(height: 20),

//           _buildPersonalInformation(),

//           const SizedBox(height: 20),

//           _buildVehicleInformation(),

//           const SizedBox(height: 20),

//           _buildVehiclePhoto(),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // PROFILE HEADER
//   // ============================================================

//   Widget _buildProfileHeader() {
//     final imageUrl =
//         getImageUrl(
//       profile!.profilePhoto,
//     );

//     final name =
//         profile!.fullName.isEmpty
//             ? 'Driver'
//             : profile!.fullName;

//     return Card(
//       child: Padding(
//         padding:
//             const EdgeInsets.all(24),

//         child: Column(
//           children: [
//             CircleAvatar(
//               radius: 60,

//               backgroundColor:
//                   Colors.grey.shade200,

//               backgroundImage:
//                   imageUrl != null
//                       ? NetworkImage(
//                           imageUrl,
//                         )
//                       : null,

//               child: imageUrl == null
//                   ? Text(
//                       name
//                           .substring(
//                             0,
//                             1,
//                           )
//                           .toUpperCase(),

//                       style:
//                           const TextStyle(
//                         fontSize: 42,
//                         fontWeight:
//                             FontWeight.bold,
//                       ),
//                     )
//                   : null,
//             ),

//             const SizedBox(height: 15),

//             Text(
//               name,

//               style:
//                   const TextStyle(
//                 fontSize: 24,
//                 fontWeight:
//                     FontWeight.bold,
//               ),
//             ),

//             const SizedBox(height: 5),

//             Text(
//               profile!.email,
//               style:
//                   const TextStyle(
//                 color: Colors.grey,
//               ),
//             ),

//             const SizedBox(height: 15),

//             _buildVerificationBadge(),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // VERIFICATION BADGE
//   // ============================================================

//   Widget _buildVerificationBadge() {
//     return Container(
//       padding:
//           const EdgeInsets.symmetric(
//         horizontal: 14,
//         vertical: 8,
//       ),

//       decoration: BoxDecoration(
//         color: profile!.isVerified
//             ? Colors.green
//                 .withValues(alpha: 0.1)
//             : Colors.orange
//                 .withValues(alpha: 0.1),

//         borderRadius:
//             BorderRadius.circular(20),
//       ),

//       child: Row(
//         mainAxisSize:
//             MainAxisSize.min,

//         children: [
//           Icon(
//             profile!.isVerified
//                 ? Icons.verified
//                 : Icons.warning_amber,

//             size: 18,

//             color:
//                 profile!.isVerified
//                     ? Colors.green
//                     : Colors.orange,
//           ),

//           const SizedBox(width: 6),

//           Text(
//             profile!.isVerified
//                 ? 'Verified Driver'
//                 : 'Verification Pending',

//             style:
//                 TextStyle(
//               fontWeight:
//                   FontWeight.bold,

//               color:
//                   profile!.isVerified
//                       ? Colors.green
//                       : Colors.orange,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // STATUS CARD
//   // ============================================================

//   Widget _buildStatusCard() {
//     return Card(
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor:
//               profile!.isOnline
//                   ? Colors.green
//                       .withValues(
//                     alpha: 0.1,
//                   )
//                   : Colors.grey
//                       .withValues(
//                     alpha: 0.1,
//                   ),

//           child: Icon(
//             profile!.isOnline
//                 ? Icons.circle
//                 : Icons.circle_outlined,

//             color:
//                 profile!.isOnline
//                     ? Colors.green
//                     : Colors.grey,
//           ),
//         ),

//         title: const Text(
//           'Driver Status',
//           style:
//               TextStyle(
//             fontWeight:
//                 FontWeight.bold,
//           ),
//         ),

//         subtitle: Text(
//           profile!.isOnline
//               ? 'You are currently online'
//               : 'You are currently offline',
//         ),

//         trailing: Text(
//           profile!.isOnline
//               ? 'ONLINE'
//               : 'OFFLINE',

//           style:
//               TextStyle(
//             fontWeight:
//                 FontWeight.bold,

//             color:
//                 profile!.isOnline
//                     ? Colors.green
//                     : Colors.grey,
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // PERSONAL INFORMATION
//   // ============================================================

//   Widget _buildPersonalInformation() {
//     return Card(
//       child: Padding(
//         padding:
//             const EdgeInsets.all(20),

//         child: Column(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,

//           children: [
//             const Text(
//               'Personal Information',

//               style:
//                   TextStyle(
//                 fontSize: 20,
//                 fontWeight:
//                     FontWeight.bold,
//               ),
//             ),

//             const SizedBox(height: 15),

//             _detailRow(
//               Icons.person,
//               'Full Name',
//               profile!.fullName,
//             ),

//             _detailRow(
//               Icons.phone,
//               'Phone Number',
//               profile!.phoneNumber,
//             ),

//             _detailRow(
//               Icons.email,
//               'Email',
//               profile!.email,
//             ),

//             _detailRow(
//               Icons.badge,
//               'License Number',
//               profile!.licenseNumber,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // VEHICLE INFORMATION
//   // ============================================================

//   Widget _buildVehicleInformation() {
//     final vehicle =
//         '${profile!.vehicleMake ?? ''} '
//         '${profile!.vehicleModel ?? ''}'
//             .trim();

//     return Card(
//       child: Padding(
//         padding:
//             const EdgeInsets.all(20),

//         child: Column(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,

//           children: [
//             const Text(
//               'Vehicle Information',

//               style:
//                   TextStyle(
//                 fontSize: 20,
//                 fontWeight:
//                     FontWeight.bold,
//               ),
//             ),

//             const SizedBox(height: 15),

//             _detailRow(
//               Icons.directions_car,
//               'Vehicle',
//               vehicle.isEmpty
//                   ? 'Not provided'
//                   : vehicle,
//             ),

//             _detailRow(
//               Icons.palette,
//               'Color',
//               profile!.vehicleColor ??
//                   'Not provided',
//             ),

//             _detailRow(
//               Icons.confirmation_number,
//               'Number Plate',
//               profile!.vehiclePlate ??
//                   'Not provided',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // VEHICLE PHOTO
//   // ============================================================

//   Widget _buildVehiclePhoto() {
//     final imageUrl =
//         getImageUrl(
//       profile!.vehiclePhoto,
//     );

//     return Card(
//       child: Padding(
//         padding:
//             const EdgeInsets.all(20),

//         child: Column(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,

//           children: [
//             const Text(
//               'Vehicle Photo',

//               style:
//                   TextStyle(
//                 fontSize: 20,
//                 fontWeight:
//                     FontWeight.bold,
//               ),
//             ),

//             const SizedBox(height: 15),

//             if (imageUrl != null)
//               ClipRRect(
//                 borderRadius:
//                     BorderRadius.circular(
//                   12,
//                 ),

//                 child: Image.network(
//                   imageUrl,

//                   width:
//                       double.infinity,

//                   height: 220,

//                   fit: BoxFit.cover,

//                   errorBuilder:
//                       (
//                     context,
//                     error,
//                     stackTrace,
//                   ) {
//                     return _vehiclePlaceholder();
//                   },
//                 ),
//               )
//             else
//               _vehiclePlaceholder(),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // VEHICLE PLACEHOLDER
//   // ============================================================

//   Widget _vehiclePlaceholder() {
//     return Container(
//       width:
//           double.infinity,

//       height: 220,

//       decoration:
//           BoxDecoration(
//         color:
//             Colors.grey.shade200,

//         borderRadius:
//             BorderRadius.circular(
//           12,
//         ),
//       ),

//       child: const Center(
//         child: Icon(
//           Icons.directions_car,
//           size: 80,
//           color: Colors.grey,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // DETAIL ROW
//   // ============================================================

//   Widget _detailRow(
//     IconData icon,
//     String label,
//     String value,
//   ) {
//     return Padding(
//       padding:
//           const EdgeInsets.only(
//         bottom: 15,
//       ),

//       child: Row(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,

//         children: [
//           Icon(
//             icon,
//             size: 22,
//             color: Colors.grey,
//           ),

//           const SizedBox(width: 12),

//           SizedBox(
//             width: 120,

//             child: Text(
//               label,

//               style:
//                   const TextStyle(
//                 fontWeight:
//                     FontWeight.bold,
//               ),
//             ),
//           ),

//           Expanded(
//             child: Text(
//               value.isEmpty
//                   ? 'Not provided'
//                   : value,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../models/driver_profile.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({
    super.key,
  });

  @override
  State<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState
    extends State<DriverProfileScreen> {
  DriverProfile? _driver;

  bool _isLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final driver =
          await ApiService.getDriverProfile();

      if (!mounted) return;

      setState(() {
        _driver = driver;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
        ),

        actions: [
          IconButton(
            onPressed:
                _isLoading
                    ? null
                    : _loadProfile,

            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                _errorMessage!,

                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 20,
              ),

              ElevatedButton.icon(
                onPressed:
                    _loadProfile,

                icon: const Icon(
                  Icons.refresh,
                ),

                label:
                    const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_driver == null) {
      return const Center(
        child: Text(
          'Driver profile not found.',
        ),
      );
    }

    final driver = _driver!;

    return RefreshIndicator(
      onRefresh:
          _loadProfile,

      child: ListView(
        padding:
            const EdgeInsets.all(20),

        children: [
          // ======================================================
          // PROFILE HEADER
          // ======================================================

          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 55,

                  child: Text(
                    driver.fullName
                        .isNotEmpty
                        ? driver.fullName
                            .substring(
                              0,
                              1,
                            )
                            .toUpperCase()
                        : '?',

                    style:
                        const TextStyle(
                      fontSize: 40,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                Text(
                  driver.fullName,

                  style:
                      const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  'Driver ID: ${driver.id}',

                  style:
                      TextStyle(
                    color:
                        Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 30,
          ),

          // ======================================================
          // VERIFICATION STATUS
          // ======================================================

          Card(
            child: ListTile(
              leading: Icon(
                driver.isVerified
                    ? Icons.verified
                    : Icons.pending,

                color:
                    driver.isVerified
                        ? Colors.green
                        : Colors.orange,
              ),

              title: const Text(
                'Verification Status',
              ),

              subtitle: Text(
                driver.isVerified
                    ? 'Verified Driver'
                    : 'Verification Pending',
              ),

              trailing: Chip(
                label: Text(
                  driver.isVerified
                      ? 'Verified'
                      : 'Pending',
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.star,
                color: Colors.amber,
              ),

              title: const Text(
                'Passenger Rating',
              ),

              subtitle: Text(
                driver.ratingCount == 0
                    ? 'No ratings yet'
                    : '${driver.averageRating?.toStringAsFixed(2) ?? 'N/A'} from ${driver.ratingCount} ratings',
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // PERSONAL INFORMATION
          // ======================================================

          const Text(
            'Personal Information',

            style:
                TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Card(
            child: Column(
              children: [
                _profileItem(
                  icon:
                      Icons.person_outline,

                  title:
                      'Full Name',

                  value:
                      driver.fullName,
                ),

                const Divider(
                  height: 1,
                ),

                _profileItem(
                  icon:
                      Icons.phone_outlined,

                  title:
                      'Phone Number',

                  value:
                      driver.phoneNumber,
                ),

                const Divider(
                  height: 1,
                ),

                _profileItem(
                  icon:
                      Icons.email_outlined,

                  title:
                      'Email',

                  value:
                      driver.email,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ======================================================
          // DRIVER INFORMATION
          // ======================================================

          const Text(
            'Driver Information',

            style:
                TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Card(
            child: Column(
              children: [
                _profileItem(
                  icon:
                      Icons.badge_outlined,

                  title:
                      'Driver ID',

                  value:
                      driver.id.toString(),
                ),

                const Divider(
                  height: 1,
                ),

                _profileItem(
                  icon:
                      Icons.credit_card_outlined,

                  title:
                      'License Number',

                  value:
                      driver.licenseNumber,
                ),

                const Divider(
                  height: 1,
                ),

                _profileItem(
                  icon:
                      Icons.circle,

                  title:
                      'Online Status',

                  value:
                      driver.isOnline
                          ? 'Online'
                          : 'Offline',
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ======================================================
          // ACCOUNT STATUS
          // ======================================================

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),

              child: Row(
                children: [
                  Icon(
                    driver.isOnline
                        ? Icons.wifi
                        : Icons.wifi_off,

                    size: 32,
                  ),

                  const SizedBox(
                    width: 16,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          driver.isOnline
                              ? 'You are Online'
                              : 'You are Offline',

                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          driver.isOnline
                              ? 'You are currently available for rides.'
                              : 'You are not currently receiving rides.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE ITEM
  // ============================================================

  Widget _profileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(
        icon,
      ),

      title: Text(
        title,

        style:
            const TextStyle(
          fontWeight:
              FontWeight.bold,
        ),
      ),

      subtitle: Padding(
        padding:
            const EdgeInsets.only(
          top: 4,
        ),

        child: Text(
          value,
        ),
      ),
    );
  }
}
