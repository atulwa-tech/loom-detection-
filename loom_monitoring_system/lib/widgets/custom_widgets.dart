import 'package:flutter/material.dart';

/// Hall Sensor Status Card Widget
class HallSensorCard extends StatelessWidget {
  final int sensorId;
  final bool isActive;
  final double? loomLength;

  const HallSensorCard({
    Key? key,
    required this.sensorId,
    required this.isActive,
    this.loomLength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusText = isActive ? 'ACTIVE' : 'INACTIVE';
    
    return Card(
      elevation: isActive ? 4 : 1,
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors,
              size: 18,
              color: isActive ? Colors.green : Colors.black,
            ),
            const SizedBox(height: 3),
            Text(
              'Loom ${sensorId + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            if (loomLength != null)
              Text(
                '${loomLength!.toStringAsFixed(1)} cm',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              )
            else
              const Text(
                'cm',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.black,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Loom Length Display Widget
class LoomLengthCard extends StatelessWidget {
  final double lengthCm;

  const LoomLengthCard({
    Key? key,
    required this.lengthCm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.05),
              Colors.cyan.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.straighten,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loom Length',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              lengthCm.toStringAsFixed(2),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'cm',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Temperature Display Widget
class TemperatureCard extends StatelessWidget {
  final double temperatureCelsius;
  final bool isWarning;

  const TemperatureCard({
    Key? key,
    required this.temperatureCelsius,
    required this.isWarning,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? Colors.red : Colors.green;
    final bgGradient = isWarning 
      ? [Colors.red.withOpacity(0.08), Colors.orange.withOpacity(0.05)]
      : [Colors.green.withOpacity(0.08), Colors.teal.withOpacity(0.05)];
    
    return Card(
      elevation: isWarning ? 3 : 1,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgGradient,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isWarning ? Icons.warning_rounded : Icons.thermostat_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Temperature',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              temperatureCelsius.toStringAsFixed(1),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '°C',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isWarning) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'WARNING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Status Indicator Widget
class StatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String label;

  const StatusIndicator({
    Key? key,
    required this.isConnected,
    this.label = 'System Status',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? Colors.green : Colors.red;
    final status = isConnected ? 'Connected' : 'Disconnected';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loom Control Button
class LoomControlButton extends StatefulWidget {
  final double lengthCm;
  final VoidCallback onPressed;
  final bool isLoading;

  const LoomControlButton({
    Key? key,
    required this.lengthCm,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<LoomControlButton> createState() => _LoomControlButtonState();
}

class _LoomControlButtonState extends State<LoomControlButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: widget.isLoading ? null : widget.onPressed,
      icon: widget.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.send),
      label: Text(
        '${widget.lengthCm.toInt()} cm',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
