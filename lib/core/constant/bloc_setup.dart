import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:masarak_driver/core/app_injections/app_injections.dart';
// import 'package:masarak_driver/features/home/presentation/cubit/naviagtion_cubit.dart';

class BuildMultiProvider extends StatelessWidget {
  const BuildMultiProvider({
    super.key,
    required this.child,
  });
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // BlocProvider.value(
        //   value: getIt<NavigationCubit>(),
        // ),
      ],
      child: child,
    );
  }
}
