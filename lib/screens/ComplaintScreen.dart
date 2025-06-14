import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../main.dart';
import '../model/ComplaintModel.dart';
import '../model/DriverRatting.dart';
import '../model/RiderModel.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import 'ComplaintListScreen.dart';

class ComplaintScreen extends StatefulWidget {
  final DriverRatting driverRatting;
  final RiderModel? riderModel;
  final ComplaintModel? complaintModel;

  ComplaintScreen(
      {required this.driverRatting,
      required this.complaintModel,
      required this.riderModel});

  @override
  ComplaintScreenState createState() => ComplaintScreenState();
}

class ComplaintScreenState extends State<ComplaintScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController subController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if (widget.complaintModel != null) {
      subController.text = widget.complaintModel!.subject.validate();
      descriptionController.text =
          widget.complaintModel!.description.validate();
    }
  }

  Future<void> saveComplainDriver() async {
    if (formKey.currentState!.validate()) {
      appStore.setLoading(true);
      Map req = {
        "driver_id": sharedPref.getInt(USER_ID),
        "rider_id": widget.riderModel!.riderId,
        "ride_request_id": widget.riderModel!.id,
        "complaint_by": "driver",
        "subject": subController.text.trim(),
        "description": descriptionController.text.trim(),
        "status": PENDING,
      };
      await saveComplain(request: req).then((value) {
        appStore.setLoading(false);
        toast(value.message);
        Navigator.pop(context);
        Navigator.pop(context);
      }).catchError((error) {
        appStore.setLoading(false);

        log(error.toString());
      });
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(language.complain, style: boldTextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: appStore.isDarkMode
                          ? scaffoldSecondaryDark
                          : primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(35),
                              child: commonCachedNetworkImage(
                                  widget.riderModel!.riderProfileImage,
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover),
                            ),
                            SizedBox(width: 16),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8),
                                Text(widget.riderModel!.riderName.validate(),
                                    style: boldTextStyle()),
                                SizedBox(height: 8),
                                if (widget.driverRatting.rating != null)
                                  RatingBar.builder(
                                    direction: Axis.horizontal,
                                    glow: false,
                                    allowHalfRating: false,
                                    ignoreGestures: true,
                                    wrapAlignment: WrapAlignment.spaceBetween,
                                    itemCount: 5,
                                    itemSize: 20,
                                    initialRating: double.parse(
                                        widget.driverRatting.rating.toString()),
                                    itemPadding:
                                        EdgeInsets.symmetric(horizontal: 0),
                                    itemBuilder: (context, _) =>
                                        Icon(Icons.star, color: Colors.amber),
                                    onRatingUpdate: (rating) {
                                      //
                                    },
                                  ),
                                if (widget.complaintModel != null)
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      margin: EdgeInsets.only(top: 8),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(
                                              defaultRadius)),
                                      alignment: Alignment.topRight,
                                      child: Text(
                                          widget.complaintModel!.status
                                              .capitalizeFirstLetter()
                                              .validate(),
                                          style: secondaryTextStyle(
                                              color: Colors.white)),
                                    ),
                                  )
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  AppTextField(
                    controller: subController,
                    decoration: inputDecoration(context, label: "اختر الموضوع"),
                    textFieldType: TextFieldType.NAME,
                    readOnly: widget.complaintModel != null ? true : false,
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    controller: descriptionController,
                    readOnly: widget.complaintModel != null ? true : false,
                    decoration: inputDecoration(
                      context,
                      label: "اكتب تفسير ......",
                    ),
                    textFieldType: TextFieldType.NAME,
                    minLines: 5,
                    maxLines: 10,
                  ),
                  SizedBox(height: 16),
                  if (widget.complaintModel == null)
                    AppButtonWidget(
                      text: " ارسال",
                      width: MediaQuery.of(context).size.width,
                      onTap: () {
                        hideKeyboard(context);
                        saveComplainDriver();
                      },
                    ),
                  SizedBox(height: 16),
                  if (widget.complaintModel != null)
                    AppButtonWidget(
                      text: "التحدث مع الادمن",
                      width: MediaQuery.of(context).size.width,
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ComplaintListScreen(
                                    complaint: widget.complaintModel!.id!)));
                      },
                    ),
                ],
              ),
            ),
          ),
          Observer(builder: (context) {
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          })
        ],
      ),
    );
  }
}
