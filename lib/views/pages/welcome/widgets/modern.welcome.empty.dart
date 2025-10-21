import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/constants/home_screen.config.dart';
import 'package:fuodz/enums/product_fetch_data_type.enum.dart';
import 'package:fuodz/view_models/welcome.vm.dart';
import 'package:fuodz/views/pages/vendor/widgets/banners.view.dart';
import 'package:fuodz/views/pages/vendor/widgets/section_products.view.dart';
import 'package:fuodz/views/pages/welcome/widgets/welcome_header.section.dart';
import 'package:fuodz/views/pages/vendor/widgets/nearby_vendors.view.dart';
import 'package:fuodz/views/pages/vendor/widgets/categories.view.dart';
import 'package:velocity_x/velocity_x.dart';

class ModernEmptyWelcome extends StatelessWidget {
  const ModernEmptyWelcome({required this.vm, Key? key}) : super(key: key);

  final WelcomeViewModel vm;
  @override
  Widget build(BuildContext context) {
    return VStack([
      // Header (location, notifications, etc.)
      WelcomeHeaderSection(vm),
      // Main content with overflow protection
      Expanded(
        child: VStack([
          // Banners (keep as is)
          if ((HomeScreenConfig.showBannerOnHomeScreen &&
              HomeScreenConfig.isBannerPositionTop))
            Banners(null, featured: true, padding: 0),

          // Categories section (show actual categories)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 0),
            child: vm.isBusy
                ? Container(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  )
                : vm.hasError
                    ? Container(
                        height: 100,
                        child: Center(
                          child: Text(
                            'Error loading categories: ${vm.error}',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : vm.currentVendorType != null
                        ? Categories(vm.currentVendorType!)
                        : Container(
                            height: 100,
                            child: Center(
                              child: Text(
                                'No vendor types available',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
          ),

          // Featured items section
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(left: 20, top: 24, bottom: 8),
            child: Text(
              'Featured items',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SectionProductsView(
            null,
            title: '',
            scrollDirection: Axis.horizontal,
            type: ProductFetchDataType.featured,
            itemWidth: context.percentWidth * 40,
            byLocation: AppStrings.enableFatchByLocation,
            hideEmpty: true,
            itemsPadding: EdgeInsets.symmetric(horizontal: 20),
            titlePadding: EdgeInsets.zero,
            listHeight: 240, // Increased from 220 to prevent overflow
            separator: SizedBox(width: 16),
          ),

          // Nearby vendors section
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(left: 20, top: 24, bottom: 8),
            child: Text(
              'Nearby Shops',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          vm.isBusy
              ? Container(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                )
              : vm.hasError
                  ? Container(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Error loading nearby vendors: ${vm.error}',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  : vm.currentVendorType != null
                      ? NearByVendors(vm.currentVendorType!)
                      : Container(
                          height: 100,
                          child: Center(
                            child: Text(
                              'No vendor types available',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
          40.heightBox,
        ], spacing: 0)
            .scrollVertical()
            .box
            .color(context.theme.colorScheme.surface)
            .make(),
      ),
    ]);
  }
}
