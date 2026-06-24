import 'package:flutter/material.dart';
import '../services/session_timeout_manager.dart';

class SessionInactivityIndicator extends StatelessWidget {
  const SessionInactivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = SessionTimeoutManager();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        if (!manager.isSessionActive) {
          return const SizedBox.shrink();
        }

        final progress = manager.inactivityProgress;
        final remainingSeconds = manager.remainingSeconds;
        final elapsedSeconds = manager.elapsedInactivity.inSeconds;
        final limitSeconds = manager.inactivityLimit.inSeconds;

        Color progressColor;
        if (progress > 0.50) {
          progressColor = colorScheme.primary;
        } else if (progress > 0.20) {
          progressColor = colorScheme.tertiary;
        } else {
          progressColor = colorScheme.error;
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant, width: 1),
          ),
          color: colorScheme.surfaceContainerLow,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        remainingSeconds <= 5 ? Icons.timer_outlined : Icons.security,
                        color: progressColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tiempo de inactividad',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'La sesión se cerrará en $remainingSeconds segundos',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${remainingSeconds} s',
                          style: textTheme.titleMedium?.copyWith(
                            color: remainingSeconds <= 5 ? colorScheme.error : colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Inactividad: ${elapsedSeconds}s de ${limitSeconds}s',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: 'Tiempo restante de la sesión',
                  value: '$remainingSeconds segundos',
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.linear,
                    tween: Tween<double>(begin: progress, end: progress),
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: colorScheme.surfaceVariant,
                        color: progressColor,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
