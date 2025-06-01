/* import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/app_injections/app_injections.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/features/home/presentation/cubit/naviagtion_cubit.dart';

class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
        builder: (context, state) => NavigationBarTheme(
              data: NavigationBarThemeData(
                indicatorColor: AppColors.transparent,
                labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                  (Set<WidgetState> states) =>
                      states.contains(WidgetState.selected)
                          ? TextStyle(
                              color: AppColors.darkPrimary,
                              fontSize: 12.spMin,
                              fontWeight: FontWeight.bold)
                          : TextStyle(
                              color: AppColors.primary,
                              fontSize: 12.spMin,
                            ),
                ),
              ),
              child: NavigationBar(
                shadowColor: AppColors.textColor,
                backgroundColor: AppColors.white,
                elevation: 5.0,
                selectedIndex: state.pageIndex,
                onDestinationSelected: (int index) {
                  getIt<NavigationCubit>()
                      .changeNavIndex(index, requiredNav: true);
                },
                destinations: getIt<NavigationCubit>().destinations,
              ),
            ));
  }
}
 */
