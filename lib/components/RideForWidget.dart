import 'package:flutter/material.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taxi_driver/Services/DriverZegoService.dart';
import 'package:taxi_driver/components/ModernCallDialog.dart';

import '../main.dart';
import '../utils/Common.dart';
import '../utils/Colors.dart';
import '../utils/Extensions/app_common.dart';

class Rideforwidget extends StatefulWidget {
  String name, contact;

  Rideforwidget({super.key, required this.name, required this.contact});

  @override
  State<Rideforwidget> createState() => _RideforwidgetState();
}

class _RideforwidgetState extends State<Rideforwidget> {
  bool _isCallingInProgress = false;

  // Modern Zego call functionality for additional riders
  Future<void> _callAdditionalRider(bool isVideoCall) async {
    // Prevent multiple simultaneous calls
    if (_isCallingInProgress) {
      toast("مكالمة قيد التقدم بالفعل...");
      return;
    }

    if (widget.contact.isEmpty) {
      toast("رقم هاتف الراكب غير متوفر");
      return;
    }

    setState(() {
      _isCallingInProgress = true;
    });

    try {
      // Ensure Zego service is active
      if (!DriverZegoService.isLoggedIn) {
        toast("جاري تجهيز خدمة المكالمات...");
        bool loginResult = await DriverZegoService.autoLoginDriver();

        if (!loginResult) {
          toast("فشل في تفعيل خدمة المكالمات");
          return;
        }
      }

      // Show modern professional call dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ModernCallDialog(
          riderName: widget.name,
          riderPhone: widget.contact,
          isVideoCall: isVideoCall,
          onCancel: () {
            Navigator.of(context).pop();
            setState(() {
              _isCallingInProgress = false;
            });
            toast("تم إلغاء المكالمة");
          },
        ),
      );

      // Add slight delay for better UX
      await Future.delayed(Duration(milliseconds: 1500));

      // Call the additional rider
      bool callResult = await DriverZegoService.callRider(
        riderPhoneNumber: widget.contact,
        context: context,
        riderName: widget.name,
        isVideoCall: isVideoCall,
      );

      // Close modern loading dialog
      Navigator.pop(context);

      if (callResult) {
        // Show modern success dialog
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => CallSuccessDialog(
            riderName: widget.name,
            isVideoCall: isVideoCall,
            onClose: () => Navigator.of(context).pop(),
          ),
        );
      } else {
        // Show modern error dialog with retry option
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => CallErrorDialog(
            errorMessage: "فشل في إرسال طلب الاتصال. يرجى المحاولة مرة أخرى.",
            onRetry: () {
              Navigator.of(context).pop();
              _callAdditionalRider(isVideoCall);
            },
            onClose: () => Navigator.of(context).pop(),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show modern error dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CallErrorDialog(
          errorMessage: "حدث خطأ أثناء الاتصال: ${e.toString()}",
          onRetry: () {
            Navigator.of(context).pop();
            _callAdditionalRider(isVideoCall);
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      );

      print("🔴 Additional rider call error: $e");
    } finally {
      // Reset call state
      setState(() {
        _isCallingInProgress = false;
      });
    }
  }

  // Show call options dialog for additional riders
  void _showCallOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.phone, color: primaryColor),
              SizedBox(width: 12),
              Text(
                "إجراء مكالمة",
                style: boldTextStyle(size: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "هل تريد الاتصال بـ ${widget.name}؟",
                style: secondaryTextStyle(size: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _callAdditionalRider(false); // Voice call only
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.phone, color: Colors.white),
                  label: Text(
                    "اتصال صوتي",
                    style: boldTextStyle(color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "إلغاء",
                style: secondaryTextStyle(size: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${language.ridingPerson}',
                    style: secondaryTextStyle(size: 14)),
                Text('${widget.name.validate().capitalizeFirstLetter()}',
                    style: boldTextStyle()),
              ],
            ),
          ),
          inkWellWidget(
            onTap: _isCallingInProgress
                ? null
                : () {
                    _showCallOptionsDialog();
                  },
            child: Container(
              decoration: BoxDecoration(
                color: _isCallingInProgress
                    ? Colors.grey.withOpacity(0.3)
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isCallingInProgress
                  ? Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                    )
                  : chatCallWidget(Icons.call),
            ),
          ),
        ],
      ),
    );
  }
}
