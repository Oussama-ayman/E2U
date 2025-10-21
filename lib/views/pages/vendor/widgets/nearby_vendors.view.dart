import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/models/vendor_type.dart';
import 'package:fuodz/view_models/vendor/nearby_vendors.vm.dart';
import 'package:fuodz/widgets/cards/custom.visibility.dart';
import 'package:fuodz/widgets/custom_list_view.dart';
import 'package:fuodz/widgets/list_items/vendor.list_item.dart';
import 'package:fuodz/widgets/states/vendor.empty.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

class NearByVendors extends StatelessWidget {
  const NearByVendors(this.vendorType, {Key? key}) : super(key: key);

  final VendorType? vendorType; // Made nullable
  @override
  Widget build(BuildContext context) {
    // Add null safety check
    if (vendorType == null) {
      return Container(
        height: 100,
        child: Center(
          child: Text(
            'No vendor type available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return CustomVisibilty(
      visible: !AppStrings.enableSingleVendor,
      child: ViewModelBuilder<NearbyVendorsViewModel>.reactive(
        viewModelBuilder: () => NearbyVendorsViewModel(context, vendorType!),
        onViewModelReady: (model) {
          // Add null safety check before initializing
          if (vendorType != null) {
            model.initialise();
          }
        },
        builder: (context, model, child) {
          // Add additional null safety check
          if (vendorType == null) {
            return Container(
              height: 100,
              child: Center(
                child: Text(
                  'No vendor type available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          return VStack([
            //vendors list
            CustomListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 10),
              dataSet: model.vendors,
              isLoading: model.isBusy,
              itemBuilder: (context, index) {
                //
                final vendor = model.vendors[index];
                return FittedBox(
                  child: VendorListItem(
                    vendor: vendor,
                    onPressed: model.vendorSelected,
                  ),
                );
              },
              emptyWidget: EmptyVendor(),
            ).h(model.vendors.isEmpty ? 240 : 195),
          ], spacing: 10);
        },
      ),
    );
  }
}
