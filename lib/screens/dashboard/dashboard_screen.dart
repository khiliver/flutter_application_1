import 'package:flutter/material.dart';

import '../../models/reservation.dart';
import '../../widgets/app_header.dart';
import 'dashboard_controller.dart';
import 'widgets/announcement_section.dart';
import 'widgets/reservation_line_chart.dart';
import 'widgets/stat_widgets.dart';
import 'widgets/user_management_section.dart';

/// A simple dashboard used for librarian and admin roles.
///
/// Demonstrates analytics sections and, for admin, a user management list.
class DashboardScreen extends StatefulWidget {
  final String role;

  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(role: widget.role)..loadInitialData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (!_controller.isManager) {
          return _buildReadOnlyDashboard(context);
        }

        return Scaffold(
          appBar: const AppHeader(),
          body: Column(
            children: [
              AnnouncementSection(
                bodyController: _controller.announcementBodyController,
                isPostingAnnouncement: _controller.isPostingAnnouncement,
                selectedMedia: _controller.selectedMedia,
                selectedMediaType: _controller.selectedMediaType,
                selectedFeeling: _controller.selectedFeeling,
                feelings: DashboardController.feelings,
                onPickMedia: () => _controller.pickMedia(context),
                onPickFeeling: () => _controller.pickFeeling(context),
                onPost: () => _controller.postAnnouncement(context),
                onRemoveMedia: _controller.removeSelectedMedia,
                onRemoveFeeling: _controller.removeSelectedFeeling,
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FutureBuilder<List<ReservationItem>>(
                        future: _controller.reservationsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final reservations =
                              snapshot.data ?? <ReservationItem>[];
                          _controller.syncSelectedCollegeFilter(reservations);
                          final types = ReservationType.values.toList();
                          final weekDates = _controller.buildWeekDates();
                          final spotsByType = _controller.buildSpotsByType(
                            reservations,
                          );
                          final colorsByType = _controller.buildColorsByType(
                            types,
                          );
                          final chartMaxY = _controller.computeChartMaxY(
                            spotsByType,
                          );

                          return ReservationLineChart(
                            weekDates: weekDates,
                            types: types,
                            spotsByType: spotsByType,
                            colorsByType: colorsByType,
                            chartMaxY: chartMaxY,
                            yInterval: _controller.computeYInterval(chartMaxY),
                            onPickCollegeFilter: () => _controller
                                .pickCollegeFilter(context, reservations),
                            onPickDate: () =>
                                _controller.pickGraphDate(context),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const SectionTitle('User Management'),
                      UserManagementSection(
                        accountsFuture: _controller.accountsFuture,
                        isSuperAdmin: _controller.isSuperAdmin,
                        onEditRole: (account) =>
                            _controller.editAccountRole(context, account),
                        onDeleteAccount: (account) =>
                            _controller.deleteAccount(context, account),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildReadOnlyDashboard(BuildContext context) {
    final title = '${widget.role} Dashboard';
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          const SectionTitle('Top Reserved Books'),
          ...DashboardController.topBooks.map((book) => BookTile(book: book)),
          const SizedBox(height: 24),
          const SectionTitle('Reservation Activity (per hour)'),
          const StatRow(
            data: DashboardController.hourlyStudents,
            labelKey: 'hour',
          ),
          const SizedBox(height: 24),
          const SectionTitle('Reservation Activity (per day)'),
          const StatRow(
            data: DashboardController.dailyStudents,
            labelKey: 'day',
          ),
        ],
      ),
    );
  }
}
