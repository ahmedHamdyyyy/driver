import 'package:flutter/material.dart';
import 'package:taxi_driver/Services/DriverZegoService.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';

class CallRiderWidget extends StatelessWidget {
  final String riderPhoneNumber;
  final String? riderName;
  final VoidCallback? onCallStarted;
  final VoidCallback? onCallFailed;
  final bool showBothOptions;

  const CallRiderWidget({
    Key? key,
    required this.riderPhoneNumber,
    this.riderName,
    this.onCallStarted,
    this.onCallFailed,
    this.showBothOptions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                "اتصال بالراكب",
                style: boldTextStyle(size: 16, color: primaryColor),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (riderName != null) ...[
            Text(
              "الراكب: $riderName",
              style: primaryTextStyle(size: 14),
            ),
            SizedBox(height: 8),
          ],
          Text(
            "رقم الهاتف: $riderPhoneNumber",
            style: secondaryTextStyle(size: 12),
          ),
          SizedBox(height: 16),
          if (showBothOptions) ...[
            Row(
              children: [
                Expanded(
                  child: _buildCallButton(
                    context: context,
                    isVideoCall: false,
                    icon: Icons.phone,
                    label: "مكالمة صوتية",
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildCallButton(
                    context: context,
                    isVideoCall: true,
                    icon: Icons.videocam,
                    label: "مكالمة فيديو",
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: _buildCallButton(
                context: context,
                isVideoCall: true,
                icon: Icons.call,
                label: "اتصال",
                color: primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required BuildContext context,
    required bool isVideoCall,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: () => _initiateCall(context, isVideoCall),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
        style: boldTextStyle(color: Colors.white, size: 14),
      ),
    );
  }

  Future<void> _initiateCall(BuildContext context, bool isVideoCall) async {
    try {
      // Check if driver is logged in to Zego
      if (!DriverZegoService.isLoggedIn) {
        toast("جاري تجهيز خدمة المكالمات...");

        // Try to login automatically
        bool loginResult = await DriverZegoService.autoLoginDriver();
        if (!loginResult) {
          toast("فشل في تفعيل خدمة المكالمات");
          onCallFailed?.call();
          return;
        }
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryColor),
                SizedBox(height: 16),
                Text(
                  "جاري الاتصال...",
                  style: boldTextStyle(size: 16),
                ),
              ],
            ),
          ),
        ),
      );

      // Call the rider
      bool callResult = await DriverZegoService.callRider(
        riderPhoneNumber: riderPhoneNumber,
        context: context,
        riderName: riderName,
        isVideoCall: isVideoCall,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (callResult) {
        toast("تم إرسال طلب الاتصال بنجاح! 📞");
        onCallStarted?.call();
      } else {
        toast("فشل في الاتصال بالراكب");
        onCallFailed?.call();
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      toast("حدث خطأ أثناء الاتصال: ${e.toString()}");
      onCallFailed?.call();
    }
  }
}

// Quick access buttons for common use cases
class QuickCallButtons extends StatelessWidget {
  final String riderPhoneNumber;
  final String? riderName;
  final VoidCallback? onCallStarted;
  final VoidCallback? onCallFailed;

  const QuickCallButtons({
    Key? key,
    required this.riderPhoneNumber,
    this.riderName,
    this.onCallStarted,
    this.onCallFailed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickCallButton(
            context: context,
            isVideoCall: false,
            icon: Icons.phone,
            color: Colors.green,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildQuickCallButton(
            context: context,
            isVideoCall: true,
            icon: Icons.videocam,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCallButton({
    required BuildContext context,
    required bool isVideoCall,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 40,
      child: ElevatedButton(
        onPressed: () => _initiateCall(context, isVideoCall),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Future<void> _initiateCall(BuildContext context, bool isVideoCall) async {
    try {
      // Check if driver is logged in to Zego
      if (!DriverZegoService.isLoggedIn) {
        // Try to login automatically silently
        await DriverZegoService.autoLoginDriver();
      }

      // Call the rider
      bool callResult = await DriverZegoService.callRider(
        riderPhoneNumber: riderPhoneNumber,
        context: context,
        riderName: riderName,
        isVideoCall: isVideoCall,
      );

      if (callResult) {
        toast("تم إرسال طلب الاتصال! 📞");
        onCallStarted?.call();
      } else {
        toast("فشل في الاتصال");
        onCallFailed?.call();
      }
    } catch (e) {
      toast("خطأ في الاتصال");
      onCallFailed?.call();
    }
  }
}

// Floating Action Button for quick calling
class CallRiderFAB extends StatelessWidget {
  final String riderPhoneNumber;
  final String? riderName;
  final bool isVideoCall;
  final VoidCallback? onCallStarted;
  final VoidCallback? onCallFailed;

  const CallRiderFAB({
    Key? key,
    required this.riderPhoneNumber,
    this.riderName,
    this.isVideoCall = true,
    this.onCallStarted,
    this.onCallFailed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _initiateCall(context),
      backgroundColor: isVideoCall ? primaryColor : Colors.green,
      child: Icon(
        isVideoCall ? Icons.videocam : Icons.phone,
        color: Colors.white,
      ),
      heroTag: "call_rider_fab_${DateTime.now().millisecondsSinceEpoch}",
    );
  }

  Future<void> _initiateCall(BuildContext context) async {
    try {
      // Check if driver is logged in to Zego
      if (!DriverZegoService.isLoggedIn) {
        await DriverZegoService.autoLoginDriver();
      }

      // Call the rider
      bool callResult = await DriverZegoService.callRider(
        riderPhoneNumber: riderPhoneNumber,
        context: context,
        riderName: riderName,
        isVideoCall: isVideoCall,
      );

      if (callResult) {
        toast("تم إرسال طلب الاتصال! 📞");
        onCallStarted?.call();
      } else {
        toast("فشل في الاتصال");
        onCallFailed?.call();
      }
    } catch (e) {
      toast("خطأ في الاتصال");
      onCallFailed?.call();
    }
  }
}
