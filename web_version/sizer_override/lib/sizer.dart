library sizer;

import 'package:flutter/widgets.dart';

typedef ResponsiveBuild = Widget Function(
  BuildContext context,
  Orientation orientation,
  DeviceType deviceType,
);

class Sizer extends StatelessWidget {
  const Sizer({Key? key, required this.builder}) : super(key: key);
  final ResponsiveBuild builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return OrientationBuilder(builder: (context, orientation) {
        SizerUtil.setScreenSize(constraints, orientation);
        return builder(context, orientation, SizerUtil.deviceType);
      });
    });
  }
}

class SizerUtil {
  static late double width;
  static late double height;
  static late Orientation orientation;
  static late DeviceType deviceType;

  static void setScreenSize(BoxConstraints constraints, Orientation currentOrientation) {
    double rawWidth = constraints.maxWidth;
    double rawHeight = constraints.maxHeight;

    // If screen width is greater than 800 (desktop web), normalize to a clean 400x800 mobile viewport.
    if (rawWidth > 800) {
      width = 400;
      height = 800;
    } else {
      width = rawWidth;
      height = rawHeight;
    }

    orientation = currentOrientation;

    if (width < 600) {
      deviceType = DeviceType.mobile;
    } else {
      deviceType = DeviceType.tablet;
    }
  }

  @deprecated
  static double get boxHeight => height;
  @deprecated
  static double get boxWidth => width;
}

enum DeviceType { mobile, tablet, web, mac, windows, linux, fuchsia }

extension SizerExt on num {
  double get w => this * SizerUtil.width / 100;
  double get h => this * SizerUtil.height / 100;
  double get sp => this * (((SizerUtil.width < 600) ? SizerUtil.width : 600) / 3) / 100;
}
