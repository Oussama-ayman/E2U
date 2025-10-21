import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/models/vendor_type.dart';
import 'package:fuodz/utils/utils.dart';
import 'package:fuodz/view_models/vendor/categories.vm.dart';
import 'package:fuodz/views/pages/category/categories.page.dart';
import 'package:fuodz/widgets/custom_dynamic_grid_view.dart';
import 'package:fuodz/widgets/list_items/category.list_item.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

class VendorTypeCategories extends StatefulWidget {
  const VendorTypeCategories(
    this.vendorType, {
    this.title,
    this.description,
    this.showTitle = true,
    this.showDescription = false,
    this.crossAxisCount,
    this.childAspectRatio,
    this.invertedItemDesign = true,
    this.listPadding,
    this.headerPadding,
    Key? key,
  }) : super(key: key);

  //
  final VendorType? vendorType; // Made nullable
  final String? title;
  final String? description;
  final bool showTitle;
  final bool showDescription;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final bool invertedItemDesign;
  final EdgeInsets? listPadding;
  final EdgeInsets? headerPadding;
  @override
  _VendorTypeCategoriesState createState() => _VendorTypeCategoriesState();
}

class _VendorTypeCategoriesState extends State<VendorTypeCategories> {
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    // Add null safety check
    if (widget.vendorType == null) {
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

    return ViewModelBuilder<CategoriesViewModel>.reactive(
      viewModelBuilder:
          () => CategoriesViewModel(
            context,
            vendorType: widget.vendorType,
            page: 1,
          ),
      onViewModelReady: (model) {
        // Add null safety check before initializing
        if (widget.vendorType != null) {
          model.initialise();
        }
      },
      builder: (context, model, child) {
        // Add additional null safety check
        if (widget.vendorType == null) {
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
          //
          Padding(
            padding:
                widget.headerPadding ?? EdgeInsets.symmetric(horizontal: 12),
            child: HStack([
              VStack([
                if (widget.showTitle)
                  ((widget.title ?? "We are here for you")
                      .tr()
                      .text
                      .xl
                      .medium
                      .make()),
                if (widget.showDescription)
                  ((widget.description ?? "How can we help?")
                      .tr()
                      .text
                      .xl
                      .semiBold
                      .make()),
              ]).expand(),
              //
              (!isOpen ? "See all" : "Show less")
                  .tr()
                  .text
                  .color(AppColor.primaryColor)
                  .make()
                  .onInkTap(() {
                    context.nextPage(
                      CategoriesPage(vendorType: widget.vendorType),
                    );
                  }),
            ]),
          ),
          // .px(20).py(10),

          //categories list
          //gridview
          if (AppStrings.categoryStyleGrid)
            CustomDynamicHeightGridView(
              padding:
                  widget.listPadding ?? EdgeInsets.symmetric(horizontal: 10),
              crossAxisCount: AppStrings.categoryPerRow,
              itemCount: model.categories.length,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              isLoading: model.isBusy,
              noScrollPhysics: true,
              itemBuilder: (ctx, index) {
                return CategoryListItem(
                  category: model.categories[index],
                  onPressed: model.categorySelected,
                  maxLine: true,
                  lines: 1,
                  inverted: false, //widget.invertedItemDesign,
                  textColor: Utils.textColorByBrightness(),
                  h: 90,
                );
              },
            ),

          //list view
          if (!AppStrings.categoryStyleGrid)
            Padding(
              padding:
                  widget.listPadding ?? EdgeInsets.symmetric(horizontal: 10),
              child: HStack(
                [
                  ...model.categories
                      .map(
                        (e) => CategoryListItem(
                          category: e,
                          onPressed: model.categorySelected,
                          // maxLine: AppStrings.categoryStyleGrid,
                          /**START NEW LINE */
                          maxLine: !AppStrings.categoryStyleGrid,
                          lines: 2,
                          h: AppStrings.categoryImageHeight + 41,
                          /**END NEW LINE */
                          inverted: widget.invertedItemDesign,
                        ).w(context.screenWidth / AppStrings.categoryPerRow),
                      )
                      .toList(),
                ],
                crossAlignment: CrossAxisAlignment.start,
                alignment: MainAxisAlignment.start,
                axisSize: MainAxisSize.max,
              ),
            ).scrollHorizontal().wFull(context),
          /*
            CustomListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 10),
              dataSet: model.categories,
              isLoading: model.isBusy,
              itemBuilder: (context, index) {
                return CategoryListItem(
                  category: model.categories[index],
                  onPressed: model.categorySelected,
                ).w(80);
              },
            ).wFull(context),
            */
        ], spacing: 10);
      },
    );
  }
}
