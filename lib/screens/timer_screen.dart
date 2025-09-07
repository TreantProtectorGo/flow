import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../utils/snackbar_util.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  // Timer status
  Timer? _timer;
  int _timeLeftInSeconds = 25 * 60; // 25mins
  int _totalTimeInSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isRestMode = false;
  int _currentSession = 2; // Pomodoro technique
  int _completedSessions = 1; // Completed pomodoro technique count

  // Animation controller
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Current task
  final String _currentTask = "撰寫產品需求文件 - 第一章節";

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _progressController = AnimationController(
      duration: Duration(seconds: _totalTimeInSeconds),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Set initial progress
    _updateProgress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _pulseController.dispose(); 
    super.dispose();
  }

  void _updateProgress() {
    double progress = 1 - (_timeLeftInSeconds / _totalTimeInSeconds);
    _progressController.animateTo(progress, duration: const Duration(milliseconds: 100));
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    
    _pulseController.repeat(reverse: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftInSeconds > 0) {
        setState(() {
          _timeLeftInSeconds--;
        });
        _updateProgress();
      } else {
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
    _pulseController.stop();
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
      _timeLeftInSeconds = _totalTimeInSeconds;
    });
    _timer?.cancel();
    _pulseController.stop();
    _progressController.reset();
  }

  void _skipTimer() {
    _onTimerComplete();
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _pulseController.stop();
    
    setState(() {
      _isRunning = false;
      
      if (!_isRestMode) {
        // Complete a dedicated pomodoro technique
        _completedSessions++;
        _currentSession++;
        
        // Check if you should have a long rest
        if (_completedSessions % 4 == 0) {
          // Long rest 15 minutes
          _isRestMode = true;
          _timeLeftInSeconds = 15 * 60;
          _totalTimeInSeconds = 15 * 60;
        } else {
          // Short rest 5 minutes
          _isRestMode = true;
          _timeLeftInSeconds = 5 * 60;
          _totalTimeInSeconds = 5 * 60;
        }
      } else {
        // Rest period ended, start a new focus time
        _isRestMode = false;
        _timeLeftInSeconds = 25 * 60;
        _totalTimeInSeconds = 25 * 60;
      }
    });
    
    _updateProgress();

    // Show completion snackbar instead of dialog
    _showCompletionSnackBar();
  }

  void _showCompletionSnackBar() {
    final message = _isRestMode ? '番茄鐘完成！休息一下吧' : '休息結束！準備開始下一個專注時間';
    final iconData = _isRestMode ? Icons.spa : Icons.timer;
    
    SnackBarUtil.showInfoSnackBar(
      context,
      message: message,
      icon: iconData,
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: '確定',
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // head
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '專注番茄',
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '第 $_currentSession 個番茄鐘',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                          maxWidth: 400, // 限制最大寬度，避免在平板上過寬
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                    // Current task card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isRestMode ? '休息時間' : '當前任務',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _isRestMode ? '放鬆一下吧 ☕' : _currentTask,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // Timer circle
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRunning ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.surface,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 32,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Progress ring
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _progressController,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: ProgressRingPainter(
                                          progress: _progressController.value,
                                          strokeWidth: 8,
                                          progressColor: theme.colorScheme.primary,
                                          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                
                                // Time display
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _formatTime(_timeLeftInSeconds),
                                        style: theme.textTheme.displayLarge?.copyWith(
                                          fontFamily: 'RobotoMono',
                                          fontSize: 48,
                                          fontWeight: FontWeight.w300,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _isRestMode ? '休息時間' : '專注時間',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Pomodoro technique indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index < _completedSessions 
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 30), // Reduced spacing
                    
                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Stop button
                        _buildControlButton(
                          icon: Icons.stop,
                          onPressed: _isRunning ? _stopTimer : null,
                          isSecondary: true,
                        ),
                        
                        const SizedBox(width: 20),
                        
                        // Main button (play/pause)
                        _buildControlButton(
                          icon: _isRunning ? Icons.pause : Icons.play_arrow,
                          onPressed: _isRunning ? _pauseTimer : _startTimer,
                          isPrimary: true,
                        ),
                        
                        const SizedBox(width: 20),
                        
                        // Skip button
                        _buildControlButton(
                          icon: Icons.skip_next,
                          onPressed: _isRunning ? _skipTimer : null,
                          isSecondary: true,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 80), // Add bottom padding to prevent overflow
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isSecondary = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      width: isPrimary ? 84 : 70,
      height: isPrimary ? 84 : 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPrimary 
            ? theme.colorScheme.primary
            : isSecondary 
                ? theme.colorScheme.surface
                : theme.colorScheme.surface,
        border: isSecondary 
            ? Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isPrimary 
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.15),
            blurRadius: isPrimary ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: isPrimary ? 32 : 24,
          color: isPrimary 
              ? theme.colorScheme.onPrimary
              : onPressed != null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    // Background ring
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at the top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.progressColor != progressColor ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}