
import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../models/driver_profile.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
  });

  @override
  State<VerificationScreen> createState() =>
      _VerificationScreenState();
}

class _VerificationScreenState
    extends State<VerificationScreen> {
  DriverProfile? _profile;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  // ============================================================
  // LOAD VERIFICATION STATUS
  // ============================================================

  Future<void> _loadVerificationStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile =
          await ApiService.getDriverProfile();

      if (!mounted) return;

      setState(() {
        _profile = profile;
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
  // STATUS INFORMATION
  // ============================================================

  String get _statusTitle {
    if (_profile?.isVerified == true) {
      return 'Verified';
    }

    return 'Pending Verification';
  }

  String get _statusDescription {
    if (_profile?.isVerified == true) {
      return 'Your driver account has been verified. You can now continue using RydeX Driver.';
    }

    return 'Your driver account is currently being reviewed by the RydeX administration team.';
  }

  IconData get _statusIcon {
    if (_profile?.isVerified == true) {
      return Icons.verified;
    }

    return Icons.hourglass_top_rounded;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verification',
        ),
      ),

      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_profile == null) {
      return const Center(
        child: Text(
          'Unable to load verification information.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVerificationStatus,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(20),

        children: [
          const SizedBox(height: 20),

          _buildStatusCard(),

          const SizedBox(height: 24),

          _buildProgressSection(),

          const SizedBox(height: 24),

          _buildDriverInformation(),

          const SizedBox(height: 24),

          _buildInformationCard(),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _buildStatusCard() {
    final isVerified =
        _profile!.isVerified;

    return Card(
      elevation: 2,
      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          children: [
            Container(
              height: 80,
              width: 80,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isVerified
                    ? Colors.green.withValues(
                        alpha: 0.12,
                      )
                    : Colors.orange.withValues(
                        alpha: 0.12,
                      ),
              ),

              child: Icon(
                _statusIcon,
                size: 44,
                color: isVerified
                    ? Colors.green
                    : Colors.orange,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              _statusTitle,
              textAlign:
                  TextAlign.center,

              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _statusDescription,
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontSize: 15,
                color:
                    Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VERIFICATION PROGRESS
  // ============================================================

  Widget _buildProgressSection() {
    final isVerified =
        _profile!.isVerified;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Verification Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            _buildStep(
              icon: Icons.person,
              title: 'Driver Registration',
              subtitle:
                  'Driver profile created',
              completed: true,
            ),

            _buildConnector(),

            _buildStep(
              icon: Icons.description_outlined,
              title: 'Document Review',
              subtitle:
                  'Documents submitted for review',
              completed: isVerified,
            ),

            _buildConnector(),

            _buildStep(
              icon: Icons.verified_outlined,
              title: 'Account Verification',
              subtitle: isVerified
                  ? 'Driver account verified'
                  : 'Waiting for administration approval',
              completed: isVerified,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool completed,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          height: 44,
          width: 44,

          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? Colors.green.withValues(
                    alpha: 0.12,
                  )
                : Colors.grey.withValues(
                    alpha: 0.12,
                  ),
          ),

          child: Icon(
            completed
                ? Icons.check
                : icon,
            color: completed
                ? Colors.green
                : Colors.grey[600],
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: TextStyle(
                  color:
                      Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnector() {
    return Container(
      margin: const EdgeInsets.only(
        left: 21,
        top: 4,
        bottom: 4,
      ),

      height: 24,
      width: 2,

      color: Colors.grey[300],
    );
  }

  // ============================================================
  // DRIVER INFORMATION
  // ============================================================

  Widget _buildDriverInformation() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Driver Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildInfoRow(
              Icons.person_outline,
              'Full Name',
              _profile!.fullName,
            ),

            _buildInfoRow(
              Icons.phone_outlined,
              'Phone',
              _profile!.phoneNumber,
            ),

            _buildInfoRow(
              Icons.email_outlined,
              'Email',
              _profile!.email,
            ),

            _buildInfoRow(
              Icons.badge_outlined,
              'License Number',
              _profile!.licenseNumber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            size: 21,
            color: Colors.grey[600],
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value.isEmpty
                      ? 'Not provided'
                      : value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _buildInformationCard() {
    final isVerified =
        _profile!.isVerified;

    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(12),

        color: isVerified
            ? Colors.green.withValues(
                alpha: 0.08,
              )
            : Colors.orange.withValues(
                alpha: 0.08,
              ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            isVerified
                ? Icons.check_circle_outline
                : Icons.info_outline,
            color: isVerified
                ? Colors.green
                : Colors.orange,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              isVerified
                  ? 'Your driver account is verified and ready for use.'
                  : 'Please wait while the RydeX administration team reviews your driver information. You will be notified when your account is verified.',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[400],
            ),

            const SizedBox(height: 16),

            const Text(
              'Could not load verification status',
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage!,
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color:
                    Colors.grey[600],
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed:
                  _loadVerificationStatus,

              icon: const Icon(
                Icons.refresh,
              ),

              label: const Text(
                'TRY AGAIN',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
