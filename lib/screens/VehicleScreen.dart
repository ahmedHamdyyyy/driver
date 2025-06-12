import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Extensions/AppButtonWidget.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../core/widget/appbar/back_app_bar.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_textfield.dart';

class VehicleScreen extends StatefulWidget {
  final Map<String, String>? vehicleData;

  VehicleScreen({this.vehicleData});

  @override
  VehicleScreenState createState() => VehicleScreenState();
}

class VehicleScreenState extends State<VehicleScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController carModelController = TextEditingController();
  TextEditingController carColorController = TextEditingController();
  TextEditingController carPlateNumberController = TextEditingController();
  TextEditingController carProductionYearController = TextEditingController();
  TextEditingController vehicleService = TextEditingController();

  UserDetail userDetail = UserDetail();
  String? serviceName;
  String? serviceDescription;
  bool isInitializing = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appStore.setLoading(true);

    // If we have vehicle data from DocumentsScreen, use it
    if (widget.vehicleData != null) {
      carModelController.text = widget.vehicleData!['carModel'] ?? '';
      carColorController.text = widget.vehicleData!['carColor'] ?? '';
      carPlateNumberController.text =
          widget.vehicleData!['carPlateNumber'] ?? '';
      carProductionYearController.text =
          widget.vehicleData!['carProductionYear'] ?? '';

      isInitializing = false;
      appStore.setLoading(false);
      setState(() {});
    } else {
      // Otherwise fetch from API
      await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
        userDetail = value.data!.userDetail!;
        carModelController.text = userDetail.carModel.validate();
        carColorController.text = userDetail.carColor.validate();
        carPlateNumberController.text = userDetail.carPlateNumber.validate();
        carProductionYearController.text =
            userDetail.carProductionYear.validate();

        serviceName = value.data!.driverService?.name.validate();
        serviceDescription = null;
        vehicleService.text = serviceName ?? '';

        isInitializing = false;
        appStore.setLoading(false);
        setState(() {});
      }).catchError((error) {
        appStore.setLoading(false);
        isInitializing = false;
        log(error.toString());
      });
    }
  }

  Future<void> updateVehicle() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      appStore.setLoading(true);
      updateVehicleDetail(
        carColor: carColorController.text.trim(),
        carModel: carModelController.text.trim(),
        carPlateNumber: carPlateNumberController.text.trim(),
        carProduction: carProductionYearController.text.trim(),
      ).then((value) {
        appStore.setLoading(false);
        toast(language.vehicleInfoUpdateSucessfully);
      }).catchError((error) {
        appStore.setLoading(false);
        log(error.toString());
      });
    }
  }

  Widget _buildServiceInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: primaryColor),
              SizedBox(width: 8),
              Text(
                language.serviceInfo,
                style: boldTextStyle(size: 16, color: primaryColor),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  serviceName ?? 'خدمة النقل',
                  style: boldTextStyle(),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      "لا يمكن تغييرها",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "نوع الخدمة المسجل في النظام. إذا كنت بحاجة إلى تغيير نوع الخدمة، يرجى التواصل مع خدمة العملاء.",
            style: secondaryTextStyle(),
          ),
          SizedBox(height: 8),
          Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "معلومات السيارة يجب أن تتطابق مع نوع الخدمة المسجلة",
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailsItem(
      {required String label, required String value}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: boldTextStyle(size: 14),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: primaryTextStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentDetailsCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "معلومات السيارة الحالية",
            style: boldTextStyle(size: 16),
          ),
          Divider(),
          _buildVehicleDetailsItem(
            label: language.carModel,
            value: userDetail.carModel.validate(),
          ),
          _buildVehicleDetailsItem(
            label: language.carColor,
            value: userDetail.carColor.validate(),
          ),
          _buildVehicleDetailsItem(
            label: language.carPlateNumber,
            value: userDetail.carPlateNumber.validate(),
          ),
          _buildVehicleDetailsItem(
            label: language.carProductionYear,
            value: userDetail.carProductionYear.validate(),
          ),
        ],
      ),
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              BackAppBar(
                title: "تحديث السيارة",
              ),
              Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isInitializing) _buildServiceInfoSection(),
                        SizedBox(height: 24),
                        Text(
                          "معلومات السيارة",
                          style: boldTextStyle(size: 18),
                        ),
                        SizedBox(height: 8),
                        if (!isInitializing && !appStore.isLoading)
                          _buildCurrentDetailsCard(),
                        SizedBox(height: 24),
                        Text(
                          "تحديث السيارة",
                          style: boldTextStyle(size: 18),
                        ),
                        SizedBox(height: 16),
                        AppTextField(
                          controller: carModelController,
                          textFieldType: TextFieldType.NAME,
                          errorThisFieldRequired: language.thisFieldRequired,
                          decoration: inputDecoration(context,
                              label: language.carModel),
                        ),
                        SizedBox(height: 16),
                        AppTextField(
                          controller: carColorController,
                          textFieldType: TextFieldType.NAME,
                          errorThisFieldRequired: language.thisFieldRequired,
                          decoration: inputDecoration(context,
                              label: language.carColor),
                        ),
                        SizedBox(height: 16),
                        AppTextField(
                          controller: carPlateNumberController,
                          textFieldType: TextFieldType.NAME,
                          errorThisFieldRequired: language.thisFieldRequired,
                          decoration: inputDecoration(context,
                              label: language.carPlateNumber),
                        ),
                        SizedBox(height: 16),
                        AppTextField(
                          controller: carProductionYearController,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textFieldType: TextFieldType.PHONE,
                          errorThisFieldRequired: language.thisFieldRequired,
                          decoration: inputDecoration(context,
                              label: language.carProductionYear),
                        ),
                        SizedBox(height: 16),
                      ],
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: AppButtonWidget(
          text: language.updateVehicle,
          color: primaryColor,
          textStyle: boldTextStyle(color: Colors.white),
          onTap: () {
            updateVehicle();
          },
        ),
      ),
    );
  }
}
