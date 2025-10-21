import 'package:flutter/material.dart';
import 'package:fuodz/models/vendor.dart';
import 'package:fuodz/utils/ui_spacer.dart';
import 'package:fuodz/utils/utils.dart';
import 'package:fuodz/view_models/vendor_menu_details.vm.dart';
import 'package:fuodz/views/pages/vendor_details/widgets/vendor_details_header.view.dart';
import 'package:fuodz/widgets/bottomsheets/cart.bottomsheet.dart';
import 'package:fuodz/widgets/busy_indicator.dart';
import 'package:fuodz/widgets/buttons/custom_rounded_leading.dart';
import 'package:fuodz/widgets/buttons/share.btn.dart';
import 'package:fuodz/widgets/cart_page_action.dart';
import 'package:fuodz/widgets/custom_easy_refresh_view.dart';
import 'package:fuodz/widgets/custom_image.view.dart';
import 'package:fuodz/widgets/list_items/vendor_menu_product.list_item.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

class VendorDetailsWithMenuPage extends StatefulWidget {
  VendorDetailsWithMenuPage({
    required this.vendor,
    Key? key,
  }) : super(key: key);

  final Vendor vendor;

  @override
  _VendorDetailsWithMenuPageState createState() =>
      _VendorDetailsWithMenuPageState();
}

class _VendorDetailsWithMenuPageState extends State<VendorDetailsWithMenuPage>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<VendorDetailsWithMenuViewModel>.reactive(
      viewModelBuilder: () => VendorDetailsWithMenuViewModel(
        context,
        widget.vendor,
        tickerProvider: this,
      ),
      onViewModelReady: (model) {
        // Defer TabController creation; ViewModel will create it after data loads
        model.getVendorDetails();
      },
      builder: (context, model, child) {
        // If loading or vendor is not ready, show loading
        if (model.vendor == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        //feature image height
        double featureImageHeight = context.percentHeight * 20;
        //limit to 250 for most
        if (featureImageHeight > 250) {
          featureImageHeight = 250;
        }
        //
        return Scaffold(
          backgroundColor: context.theme.colorScheme.surface,
          // floatingActionButton: UploadPrescriptionFab(model),
          body: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool scrolled) {
              return <Widget>[
                SliverAppBar(
                  expandedHeight: featureImageHeight,
                  floating: false,
                  pinned: true,
                  leading: CustomRoundedLeading(),
                  backgroundColor: context.backgroundColor,
                  actions: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: FittedBox(
                        child: ShareButton(
                          model: model,
                        ),
                      ),
                    ),
                    UiSpacer.hSpace(10),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 2),
                      child: PageCartAction(),
                    )
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    // title: Text(""),
                    //vendor image
                    background: CustomImage(
                      imageUrl: model.vendor?.featureImage ?? "",
                      height: featureImageHeight,
                      canZoom: true,
                    ).wFull(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: VendorDetailsHeader(
                    model,
                    showFeatureImage: false,
                    featureImageHeight: featureImageHeight,
                    showPrescription: true,
                  ),
                ),
                if ((model.vendor?.menus.length ?? 0) > 0)
                  SliverAppBar(
                    title: "".text.make(),
                    floating: false,
                    pinned: true,
                    snap: false,
                    primary: false,
                    automaticallyImplyLeading: false,
                    flexibleSpace: TabBar(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      isScrollable: true,
                      // Avoid Utils.primaryOrTheme to prevent null context; use theme directly
                      labelColor: context.theme.colorScheme.primary,
                      unselectedLabelColor: Utils.textColorByBrightness(context),
                      indicatorWeight: 4,
                      indicator: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: context.theme.primaryColor,
                            width: 3,
                          ),
                        ),
                      ),
                      controller: model.tabBarController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabAlignment: TabAlignment.start,
                      dividerHeight: 0,
                      tabs: (model.vendor?.menus ?? []).map(
                        (menu) {
                          return Tab(
                            text: menu.name,
                            iconMargin: EdgeInsets.zero,
                          );
                        },
                      ).toList(),
                    ),
                  ),
              ];
            },
            body: Container(
              child: model.isBusy
                  ? BusyIndicator().p20().centered()
                  : (model.vendor?.menus.isNotEmpty ?? false)
                      ? TabBarView(
                          controller: model.tabBarController,
                          children: (model.vendor?.menus ?? []).map(
                            (menu) {
                              final mProducts = model.menuProducts[menu.id] ?? [];
                              //
                              return CustomEasyRefreshView(
                                // headerView: MaterialHeader(),
                                padding: EdgeInsets.symmetric(vertical: 10),
                                onRefresh: () => model.loadMoreProducts(menu.id),
                                onLoad: () => model.loadMoreProducts(
                                  menu.id,
                                  initialLoad: false,
                                ),
                                loading: model.busy(menu.id),
                                dataset: mProducts,
                                separator: 5.heightBox,
                                listView: mProducts.map(
                                  (product) {
                                    return VendorMenuProductListItem(
                                      product,
                                      onPressed: model.productSelected,
                                      qtyUpdated: model.addToCartDirectly,
                                    );
                                  },
                                ).toList(),
                              );
                            },
                          ).toList(),
                        )
                      : const Center(child: Text('No menus')),
            ),
          ),
          bottomSheet: CartViewBottomSheet(),
        );
      },
    );
  }
}
