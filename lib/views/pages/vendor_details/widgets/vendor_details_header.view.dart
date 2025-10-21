import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fuodz/constants/app_ui_settings.dart';
import 'package:fuodz/constants/sizes.dart';
import 'package:fuodz/models/vendor.dart';
import 'package:fuodz/utils/ui_spacer.dart';
import 'package:fuodz/utils/utils.dart';
import 'package:fuodz/view_models/vendor_details.vm.dart';
import 'package:fuodz/views/pages/vendor/vendor_reviews.page.dart';
import 'package:fuodz/views/pages/vendor_details/widgets/bottomsheets/vendor_full_profie.bottomsheet.dart';
import 'package:fuodz/views/pages/vendor_details/widgets/upload_prescription.btn.dart';
import 'package:fuodz/widgets/cards/custom.visibility.dart';
import 'package:fuodz/widgets/custom_image.view.dart';
import 'package:fuodz/widgets/inputs/search_bar.input.dart';
import 'package:fuodz/widgets/tags/close.tag.dart';
import 'package:fuodz/widgets/tags/delivery.tag.dart';
import 'package:fuodz/widgets/tags/fav_vendor.tag.dart';
import 'package:fuodz/widgets/tags/open.tag.dart';
import 'package:fuodz/widgets/tags/pickup.tag.dart';
import 'package:fuodz/widgets/tags/time.tag.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:velocity_x/velocity_x.dart';

class VendorDetailsHeader extends StatelessWidget {
  const VendorDetailsHeader(
    this.model, {
    this.showFeatureImage = true,
    this.featureImageHeight = 220,
    this.showPrescription = false,
    this.showSearch = true,
    Key? key,
  }) : super(key: key);

  final VendorDetailsViewModel model;
  final bool showFeatureImage;
  final double featureImageHeight;
  final bool showPrescription;
  final bool showSearch;
  @override
  Widget build(BuildContext context) {
    final Vendor? vendor = model.vendor;
    final cardBg = context.theme.colorScheme.surfaceVariant;
    final secondaryText = Utils.textColorByBrightness(context, true);
    return VStack([
      VStack([
        //vendor image
        CustomVisibilty(
          visible: showFeatureImage,
          child: CustomImage(
            imageUrl: vendor?.featureImage ?? "",
            height: featureImageHeight,
            canZoom: true,
          ).wFull(context),
        ),

        //vendor header
        VStack([
          //vendor important details
          HStack([
            //logo
            CustomImage(
              imageUrl: vendor?.logo ?? "",
              width: Vx.dp56,
              height: Vx.dp56,
              canZoom: true,
            ).box.clip(Clip.antiAlias).withRounded(value: 5).make(),
            //
            VStack([
              (vendor?.name ?? "").text.semiBold.lg.color(context.theme.colorScheme.onSurface).make(),
              CustomVisibilty(
                visible:
                    (vendor?.address.isNotEmptyAndNotNull ?? false) &&
                    AppUISettings.showVendorAddress,
                child: "${vendor?.address ?? ''}".text.color(secondaryText).sm.maxLines(1).make(),
              ),
              Visibility(
                visible: AppUISettings.showVendorPhone,
                child: (vendor?.phone ?? "").text.color(secondaryText).sm.make(),
              ),

              //rating
              HStack([
                RatingBar(
                  itemSize: 12,
                  initialRating: (vendor?.rating ?? 0).toDouble(),
                  ignoreGestures: true,
                  ratingWidget: RatingWidget(
                    full: Icon(
                      FlutterIcons.ios_star_ion,
                      size: 12,
                      color: Colors.yellow[800],
                    ),
                    half: Icon(
                      FlutterIcons.ios_star_half_ion,
                      size: 12,
                      color: Colors.yellow[800],
                    ),
                    empty: Icon(
                      FlutterIcons.ios_star_ion,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  onRatingUpdate: (value) {},
                ).pOnly(right: 2),
                "(${vendor?.reviews_count ?? 0} ${'Reviews'.tr()})"
                    .text
                    .sm
                    .thin
                    .color(secondaryText)
                    .make(),
              ]).py2().onTap(() {
                if (vendor != null) {
                  context.nextPage(VendorReviewsPage(vendor));
                }
              }),
            ]).pOnly(left: Vx.dp12).expand(),
            //icons
            HStack([
              //
              if (vendor != null) FavVendorTag(vendor),

              // details icon
              Icon(
                FlutterIcons.info_circle_faw,
                size: 22,
                color: context.theme.primaryColor,
              ).p(Sizes.paddingSizeSmall).onTap(() {
                //open vendor details bottom sheet
                if (vendor != null) {
                  openVendorDetailsBottomSheet(context, vendor);
                }
              }),
            ], spacing: 5).pOnly(left: Vx.dp12),
          ]),
        ]).p8().card.color(cardBg).make().p12(),
      ]),

      //
      //
      VStack([
        //tags
        Wrap(
          children: [
            //is open
            (vendor?.isOpen ?? false) ? OpenTag() : CloseTag(),

            //can deliveree
            if ((vendor?.delivery ?? 0) == 1) DeliveryTag(),

            //can pickup
            if ((vendor?.pickup ?? 0) == 1) PickupTag(),

            //prepare time
            TimeTag(
              "${vendor?.prepareTime ?? ''} ${vendor?.prepareTimeUnit ?? ''}",
              iconData: FlutterIcons.clock_outline_mco,
            ),
            //delivery time
            TimeTag(
              "${vendor?.deliveryTime ?? ''} ${vendor?.deliveryTimeUnit ?? ''}",
              iconData: FlutterIcons.ios_bicycle_ion,
            ),
          ],
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
        ),
        UiSpacer.verticalSpace(space: 10),

        // //description
        // "Description".tr().text.sm.bold.uppercase.make(),
        // HtmlTextView(
        //   model.vendor!.description,
        //   padding: EdgeInsets.zero,
        // ),
        // UiSpacer.verticalSpace(space: 10),
      ]).px20().py(0),
      UiSpacer.divider(),
      10.heightBox,
      //search bar
      if (showSearch)
        SearchBarInput(onTap: model.openVendorSearch, showFilter: false).px20(),
      10.heightBox,
      if (showPrescription) UploadPrescriptionFab(model).centered(),
      10.heightBox,
      if (showPrescription || showSearch) UiSpacer.divider(),
    ]);
  }

  //
  openVendorDetailsBottomSheet(BuildContext context, Vendor vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return VendorFullProfileBottomSheet(vendor);
      },
    );
  }
}
