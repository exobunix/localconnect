import 'package:sizer/sizer.dart';

extension WebSizerExt on num {
  // If the web screen width is larger than 800px (desktop), we lock the calculations to a mock 400px wide viewport.
  // If the screen width is smaller (mobile web), we fallback to the native responsive sizer calculations.
  double get w => SizerUtil.width > 800 ? this * 400 / 100 : this * SizerUtil.width / 100;
  double get h => SizerUtil.width > 800 ? this * 800 / 100 : this * SizerUtil.height / 100;
  double get sp => SizerUtil.width > 800 
      ? this * (400 / 3) / 100 
      : this * (((SizerUtil.width < 600) ? SizerUtil.width : 600) / 3) / 100;
}
