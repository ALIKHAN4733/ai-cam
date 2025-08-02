// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// import 'coordinates_translator.dart';

// class PosePainter extends CustomPainter {
//   PosePainter(
//     this.poses,
//     this.imageSize,
//     this.rotation,
//     this.cameraLensDirection,
//   );

//   final List<Pose> poses;
//   final Size imageSize;
//   final InputImageRotation rotation;
//   final CameraLensDirection cameraLensDirection;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4.0
//       ..color = Colors.green;

//     final leftPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0
//       ..color = Colors.yellow;

//     final rightPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0
//       ..color = Colors.blueAccent;

//     for (final pose in poses) {
//       pose.landmarks.forEach((_, landmark) {
//         canvas.drawCircle(
//             Offset(
//               translateX(
//                 landmark.x,
//                 size,
//                 imageSize,
//                 rotation,
//                 cameraLensDirection,
//               ),
//               translateY(
//                 landmark.y,
//                 size,
//                 imageSize,
//                 rotation,
//                 cameraLensDirection,
//               ),
//             ),
//             1,
//             paint);
//       });

//       void paintLine(
//           PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
//         final PoseLandmark joint1 = pose.landmarks[type1]!;
//         final PoseLandmark joint2 = pose.landmarks[type2]!;
//         canvas.drawLine(
//             Offset(
//                 translateX(
//                   joint1.x,
//                   size,
//                   imageSize,
//                   rotation,
//                   cameraLensDirection,
//                 ),
//                 translateY(
//                   joint1.y,
//                   size,
//                   imageSize,
//                   rotation,
//                   cameraLensDirection,
//                 )),
//             Offset(
//                 translateX(
//                   joint2.x,
//                   size,
//                   imageSize,
//                   rotation,
//                   cameraLensDirection,
//                 ),
//                 translateY(
//                   joint2.y,
//                   size,
//                   imageSize,
//                   rotation,
//                   cameraLensDirection,
//                 )),
//             paintType);
//       }

//       //Draw arms
//       paintLine(
//           PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
//       paintLine(
//           PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);
//       paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow,
//           rightPaint);
//       paintLine(
//           PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);

//       //Draw Body
//       paintLine(
//           PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint);
//       paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip,
//           rightPaint);

//       //Draw legs
//       paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
//       paintLine(
//           PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);
//       paintLine(
//           PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
//       paintLine(
//           PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant PosePainter oldDelegate) {
//     return oldDelegate.imageSize != imageSize || oldDelegate.poses != poses;
//   }
// }
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'coordinates_translator.dart'; // Assuming this file exists and is correct

/// A custom painter to draw detected poses and the push-up count on the canvas.
class PosePainter extends CustomPainter {
  /// Constructor for PosePainter.
  ///
  /// [poses]: A list of detected poses to be drawn.
  /// [imageSize]: The original size of the image from which poses were detected.
  /// [rotation]: The rotation of the input image.
  /// [cameraLensDirection]: The direction of the camera lens (front or back).
  /// [pushupCount]: The current count of detected push-ups.
  PosePainter(
    this.poses,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
    this.pushupCount, // New parameter for push-up count
  );

  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final int pushupCount; // Stored push-up count

  @override
  void paint(Canvas canvas, Size size) {
    // Define paint styles for drawing landmarks and lines
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green; // General color for torso lines

    final whitePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors
          .white; // For drawing landmark circles (optional, but good for visibility)

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.yellow; // Color for left side body parts

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blueAccent; // Color for right side body parts

    // Iterate through each detected pose
    for (final pose in poses) {
      // Draw circles for each landmark (optional, but helps visualize points)
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
          Offset(
            // Translate X coordinate from image to canvas coordinates
            translateX(
              landmark.x,
              size, // Canvas size
              imageSize, // Original image size
              rotation,
              cameraLensDirection,
            ),
            // Translate Y coordinate from image to canvas coordinates
            translateY(
              landmark.y,
              size, // Canvas size
              imageSize, // Original image size
              rotation,
              cameraLensDirection,
            ),
          ),
          1, // Radius of the circle
          whitePaint, // Paint for the circles
        );
      });

      /// Helper function to draw a line between two pose landmarks.
      /// Ensures landmarks are not null before drawing.
      void paintLine(
          PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        final PoseLandmark? joint1 = pose.landmarks[type1];
        final PoseLandmark? joint2 = pose.landmarks[type2];

        if (joint1 != null && joint2 != null) {
          canvas.drawLine(
            Offset(
              translateX(
                joint1.x,
                size, // Canvas size
                imageSize, // Original image size
                rotation,
                cameraLensDirection,
              ),
              translateY(
                joint1.y,
                size, // Canvas size
                imageSize, // Original image size
                rotation,
                cameraLensDirection,
              ),
            ),
            Offset(
              translateX(
                joint2.x,
                size, // Canvas size
                imageSize, // Original image size
                rotation,
                cameraLensDirection,
              ),
              translateY(
                joint2.y,
                size, // Canvas size
                imageSize, // Original image size
                rotation,
                cameraLensDirection,
              ),
            ),
            paintType,
          );
        }
      }

      // --- Draw Body Segments ---

      // Arms
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
      paintLine(
          PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow,
          rightPaint);
      paintLine(
          PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);

      // Torso
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, paint);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paint);
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip,
          rightPaint);

      // Legs
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      paintLine(
          PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);
      paintLine(
          PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
      paintLine(
          PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);

      // Feet (optional, but good for full skeletal visualization)
      paintLine(
          PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel, leftPaint);
      paintLine(
          PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex, leftPaint);
      paintLine(
          PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel, rightPaint);
      paintLine(PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex,
          rightPaint);
    }

    // --- Draw Push-up Count Text ---
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Push-ups: $pushupCount', // Display the push-up count
        style: const TextStyle(
          color: Colors.red,
          fontSize: 30.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr, // Required for text layout
    );
    textPainter.layout(); // Calculate the size of the text
    // Position the text at the top-left corner with some padding
    textPainter.paint(canvas, Offset(size.width * 0.05, size.height * 0.05));
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    // Repaint only if the image size, poses list, or push-up count has changed
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.poses != poses ||
        oldDelegate.pushupCount != pushupCount;
  }
}
