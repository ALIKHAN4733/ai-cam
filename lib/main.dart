// import 'package:aitest/detector_view.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// import 'painters/pose_painter.dart';

// late List<CameraDescription> cameras;

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   cameras = await availableCameras();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Pose Detector',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: PoseDetectorView(),
//     );
//   }
// }

// class PoseDetectorView extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() => _PoseDetectorViewState();
// }

// class _PoseDetectorViewState extends State<PoseDetectorView> {
//   final PoseDetector _poseDetector =
//       PoseDetector(options: PoseDetectorOptions());
//   bool _canProcess = true;
//   bool _isBusy = false;
//   CustomPaint? _customPaint;
//   String? _text;
//   var _cameraLensDirection = CameraLensDirection.back;

//   @override
//   void dispose() {
//     _canProcess = false;
//     _poseDetector.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DetectorView(
//       title: 'Pose Detector',
//       customPaint: _customPaint,
//       text: _text,
//       onImage: _processImage,
//       initialCameraLensDirection: _cameraLensDirection,
//       onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
//     );
//   }

//   Future<void> _processImage(InputImage inputImage) async {
//     if (!_canProcess || _isBusy) return;

//     _isBusy = true;
//     setState(() {
//       _text = '';
//     });

//     final poses = await _poseDetector.processImage(inputImage);

//     if (inputImage.metadata?.size != null &&
//         inputImage.metadata?.rotation != null) {
//       final painter = PosePainter(
//         poses,
//         inputImage.metadata!.size,
//         inputImage.metadata!.rotation,
//         _cameraLensDirection,
//       );
//       _customPaint = CustomPaint(painter: painter);
//     } else {
//       _text = 'Poses found: ${poses.length}\n\n';
//       _customPaint = null;
//     }

//     _isBusy = false;
//     if (mounted) {
//       setState(() {});
//     }
//   }
// }
import 'package:aitestnew/detector_view.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math'; // For calculating angles

import 'painters/pose_painter.dart';

// Global variable to store available cameras
late List<CameraDescription> cameras;

/// Main entry point of the Flutter application.
void main() async {
  // Ensure Flutter engine is initialized before accessing cameras
  WidgetsFlutterBinding.ensureInitialized();
  // Fetch available cameras on the device
  cameras = await availableCameras();
  // Run the application
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pose Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PoseDetectorView(),
    );
  }
}

/// Enum to represent the different states of a push-up.
enum PoseState {
  up, // Arms are extended, body is up
  down, // Elbows are bent, body is down
  unknown, // Initial or indeterminate state
}

/// A StatefulWidget for detecting and counting push-ups using ML Kit Pose Detection.
class PoseDetectorView extends StatefulWidget {
  const PoseDetectorView({super.key});

  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

/// The state class for PoseDetectorView.
class _PoseDetectorViewState extends State<PoseDetectorView> {
  // ML Kit Pose Detector instance
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(),
  );

  // Flags to control image processing
  bool _canProcess = true; // Can the detector process new images?
  bool _isBusy = false; // Is the detector currently busy processing an image?

  // CustomPaint widget to draw landmarks on the camera feed
  CustomPaint? _customPaint;
  // Text to display information (e.g., push-up count, angles)
  String? _text;
  // Current camera lens direction (front/back)
  CameraLensDirection _cameraLensDirection = CameraLensDirection.back;

  // --- Push-up Counting Variables ---
  int _pushupCount = 0; // Counter for completed push-ups
  PoseState _poseState = PoseState.unknown; // Current state of the push-up

  // Thresholds for angle detection (tune these values based on testing)
  // Angle when the arm is mostly straight (e.g., at the top of a push-up)
  final double _elbowUpThreshold = 160.0;
  // Angle when the elbow is sufficiently bent (e.g., at the bottom of a push-up)
  final double _elbowDownThreshold = 90.0;
  // Angle to ensure the body is lowering for a proper push-up (shoulder relative to hip/elbow)
  final double _shoulderDownThreshold =
      45.0; // Example: angle between Hip-Shoulder-Elbow

  @override
  void dispose() {
    // Stop processing images and close the detector when the widget is disposed
    _canProcess = false;
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetectorView(
      title: 'Pose Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
    );
  }

  /// Processes each image frame from the camera or gallery for pose detection.
  Future<void> _processImage(InputImage inputImage) async {
    // Prevent processing if not allowed or already busy
    if (!_canProcess || _isBusy) return;

    _isBusy = true; // Set busy flag
    _text = ''; // Clear previous text for current frame

    // Process the image with the pose detector
    final poses = await _poseDetector.processImage(inputImage);

    if (poses.isNotEmpty) {
      // Assuming single person detection, process the first detected pose
      _processPoseForPushups(poses.first);
    } else {
      // If no poses are detected, reset the pose state
      _text = 'No poses detected.\n';
      _poseState = PoseState.unknown;
    }

    // Update the custom paint for drawing landmarks
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      _customPaint = CustomPaint(
        painter: PosePainter(
          poses,
          inputImage.metadata!.size,
          inputImage.metadata!.rotation,
          _cameraLensDirection,
          _pushupCount, // Pass the push-up count to the painter
        ),
      );
    } else {
      _customPaint = null;
    }

    // --- Update Text Display ---
    _text = 'Push-ups: $_pushupCount\n';
    _text = 'Pose State: ${_poseState.toString().split('.').last}\n';

    // Add detailed angle information for debugging if a pose is detected
    if (poses.isNotEmpty) {
      final pose = poses.first;
      _addDebugAnglesToText(pose);
    }

    _isBusy = false; // Reset busy flag
    if (mounted) {
      setState(() {}); // Trigger a UI rebuild
    }
  }

  /// Calculates and appends landmark angles to the display text for debugging.
  void _addDebugAnglesToText(Pose pose) {
    // Helper to get landmark safely
    PoseLandmark? getLandmark(PoseLandmarkType type) => pose.landmarks[type];

    // Left arm angles
    final leftShoulder = getLandmark(PoseLandmarkType.leftShoulder);
    final leftElbow = getLandmark(PoseLandmarkType.leftElbow);
    final leftWrist = getLandmark(PoseLandmarkType.leftWrist);
    final leftHip = getLandmark(PoseLandmarkType.leftHip);

    if (leftShoulder != null && leftElbow != null && leftWrist != null) {
      final leftElbowAngle = _getAngle(leftShoulder, leftElbow, leftWrist);
      _text =
          '${_text!}L. Elbow: ${leftElbowAngle?.toStringAsFixed(1) ?? 'N/A'}°\n';
    } else {
      _text = '${_text!}L. Elbow: N/A (Missing landmarks)\n';
    }

    if (leftHip != null && leftShoulder != null && leftElbow != null) {
      final leftShoulderAngle = _getAngle(leftHip, leftShoulder, leftElbow);
      _text =
          '${_text!}L. Shoulder: ${leftShoulderAngle?.toStringAsFixed(1) ?? 'N/A'}°\n';
    } else {
      _text = '${_text!}L. Shoulder: N/A (Missing landmarks)\n';
    }

    // Right arm angles
    final rightShoulder = getLandmark(PoseLandmarkType.rightShoulder);
    final rightElbow = getLandmark(PoseLandmarkType.rightElbow);
    final rightWrist = getLandmark(PoseLandmarkType.rightWrist);
    final rightHip = getLandmark(PoseLandmarkType.rightHip);

    if (rightShoulder != null && rightElbow != null && rightWrist != null) {
      final rightElbowAngle = _getAngle(rightShoulder, rightElbow, rightWrist);
      _text =
          '${_text!}R. Elbow: ${rightElbowAngle?.toStringAsFixed(1) ?? 'N/A'}°\n';
    } else {
      _text = '${_text!}R. Elbow: N/A (Missing landmarks)\n';
    }

    if (rightHip != null && rightShoulder != null && rightElbow != null) {
      final rightShoulderAngle = _getAngle(rightHip, rightShoulder, rightElbow);
      _text =
          '${_text!}R. Shoulder: ${rightShoulderAngle?.toStringAsFixed(1) ?? 'N/A'}°\n';
    } else {
      _text = '${_text!}R. Shoulder: N/A (Missing landmarks)\n';
    }
  }

  /// Processes the detected pose to determine push-up state and count.
  void _processPoseForPushups(Pose pose) {
    // Get relevant landmarks, handling potential nulls
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Ensure all necessary landmarks are detected before proceeding
    if (leftElbow == null ||
        leftShoulder == null ||
        leftWrist == null ||
        rightElbow == null ||
        rightShoulder == null ||
        rightWrist == null ||
        leftHip == null ||
        rightHip == null) {
      _poseState = PoseState.unknown; // Not enough data to determine pose
      return;
    }

    // Calculate elbow angles for both arms
    final double? leftElbowAngle = _getAngle(
      leftShoulder,
      leftElbow,
      leftWrist,
    );
    final double? rightElbowAngle = _getAngle(
      rightShoulder,
      rightElbow,
      rightWrist,
    );

    // Calculate shoulder angles (hip-shoulder-elbow) for both sides
    final double? leftShoulderAngle = _getAngle(
      leftHip,
      leftShoulder,
      leftElbow,
    );
    final double? rightShoulderAngle = _getAngle(
      rightHip,
      rightShoulder,
      rightElbow,
    );

    // If any required angle cannot be calculated, reset state and return
    if (leftElbowAngle == null ||
        rightElbowAngle == null ||
        leftShoulderAngle == null ||
        rightShoulderAngle == null) {
      _poseState = PoseState.unknown;
      return;
    }

    // Calculate average angles for robustness
    final double avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;
    final double avgShoulderAngle =
        (leftShoulderAngle + rightShoulderAngle) / 2;

    // --- Push-up State Machine Logic ---
    if (_poseState == PoseState.unknown || _poseState == PoseState.up) {
      // Transition to DOWN state if elbows are sufficiently bent AND
      // shoulders are sufficiently lowered (body is going down)
      if (avgElbowAngle < _elbowDownThreshold &&
          avgShoulderAngle < _shoulderDownThreshold) {
        _poseState = PoseState.down;
      }
    } else if (_poseState == PoseState.down) {
      // Transition to UP state if elbows are straightened AND
      // shoulders are raised (body is coming up), then increment count
      if (avgElbowAngle > _elbowUpThreshold) {
        _pushupCount++;
        _poseState = PoseState.up;
      }
    }
  }

  /// Helper function to calculate the angle (in degrees) between three points.
  /// `midPoint` is the vertex of the angle.
  double? _getAngle(
    PoseLandmark? firstPoint,
    PoseLandmark? midPoint,
    PoseLandmark? lastPoint,
  ) {
    if (firstPoint == null || midPoint == null || lastPoint == null) {
      return null;
    }

    // Calculate vectors
    final double v1x = firstPoint.x - midPoint.x;
    final double v1y = firstPoint.y - midPoint.y;
    final double v2x = lastPoint.x - midPoint.x;
    final double v2y = lastPoint.y - midPoint.y;

    // Calculate angle using atan2 and convert to degrees
    double angle = atan2(v2y, v2x) - atan2(v1y, v1x);
    angle = (angle * 180.0 / pi)
        .abs(); // Convert to degrees and get absolute value

    // Ensure angle is within 0-180 range
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }
}
