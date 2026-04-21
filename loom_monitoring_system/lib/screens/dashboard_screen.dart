import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../widgets/index.dart';

/// Main Dashboard Screen
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showFailedSensorsOnly = false;

  @override
  Widget build(BuildContext context) {
    final loomData = ref.watch(loomDataProvider);
    final isConnected = ref.watch(connectionStatusProvider);
    final temperatureWarning = ref.watch(temperatureWarningProvider);
    final failedSensors = ref.watch(failedSensorsProvider);

    if (loomData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loom Monitoring System'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loom Monitoring System'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: StatusIndicator(isConnected: isConnected),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Row
            _buildQuickStats(context, loomData),
            const SizedBox(height: 24),

            // Alert Section
            if (failedSensors.isNotEmpty || temperatureWarning)
              _buildAlertSection(context, failedSensors, temperatureWarning),
            if (failedSensors.isNotEmpty || temperatureWarning)
              const SizedBox(height: 24),

            // Hall Sensors Section
            _buildSensorsSection(context, loomData),
            const SizedBox(height: 24),

            // Loom Control Buttons
            _buildLoomControlSection(context),
            const SizedBox(height: 24),

            // System Statistics
            _buildSystemStats(context, loomData),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, LoomData data) {
    return Row(
      children: [
        Expanded(
          child: LoomLengthCard(lengthCm: data.loomLength),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.thermostat,
                        color: Colors.red[500],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Temperature',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data.temperature.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: data.temperature > 50 ? Colors.red[600] : Colors.green[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '°C',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertSection(
    BuildContext context,
    List<int> failedSensors,
    bool temperatureWarning,
  ) {
    return Card(
      color: Colors.red.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  'System Alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (failedSensors.isNotEmpty) ...[
              Text(
                'Failed Sensors: ${failedSensors.map((i) => 'Loom ${i + 1}').join(', ')}',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
            ],
            if (temperatureWarning)
              const Text(
                'Temperature exceeds threshold (50°C)',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorsSection(BuildContext context, LoomData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Sensors Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            childAspectRatio: 0.9,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemCount: data.hallSensors.length,
          itemBuilder: (context, index) {
            final loomLen = data.sensorLoomLengths.length > index
                ? data.sensorLoomLengths[index]
                : 0.0;
            return HallSensorCard(
              sensorId: index,
              isActive: data.hallSensors[index],
              loomLength: loomLen,
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoomControlSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Loom Control',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            LoomControlButton(
              lengthCm: 2,
              onPressed: () => _releaseLoom(2),
            ),
            LoomControlButton(
              lengthCm: 4,
              onPressed: () => _releaseLoom(4),
            ),
            LoomControlButton(
              lengthCm: 8,
              onPressed: () => _releaseLoom(8),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildSystemStats(BuildContext context, LoomData data) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Loom Produced', '${data.totalLoomProduced.toStringAsFixed(2)} cm'),
            const SizedBox(height: 12),
            _buildStatRow('Current Temperature', '${data.temperature.toStringAsFixed(1)}°C'),
            const SizedBox(height: 12),
            _buildStatRow('Last Updated', _formatTime(data.lastUpdated)),
            const SizedBox(height: 12),
            _buildStatRow('Sensors Status', '${data.hallSensors.where((s) => s).length}/${data.hallSensors.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  void _releaseLoom(double lengthCm) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loom release command: $lengthCm cm'),
        duration: const Duration(seconds: 2),
      ),
    );
  }



  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
