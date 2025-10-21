import 'package:flutter/material.dart';
import 'package:fuodz/utils/ui_spacer.dart';
import 'package:fuodz/view_models/profile.vm.dart';
import 'package:fuodz/widgets/base.page.dart';
import 'package:fuodz/widgets/cards/profile.card.dart';
import 'package:fuodz/widgets/menu_item.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ViewModelBuilder<ProfileViewModel>.reactive(
      viewModelBuilder: () => ProfileViewModel(context),
      onViewModelReady: (model) => model.initialise(),
      disposeViewModel: false,
      builder: (context, model, child) {
        return BasePage(
          showCartView: false,
          body:
              VStack([
                //
                "Settings".tr().text.xl2.semiBold.make(),
                "Profile & App Settings".tr().text.lg.light.make(),

                //profile card
                ProfileCard(model).py12(),

                //menu
                VStack([
                  //
                  MenuItem(
                    title: "Language".tr(),
                    divider: false,
                    prefix: Icon(HugeIcons.strokeRoundedGlobal),
                    onPressed: model.changeLanguage,
                  ),

                  20.heightBox,
                  //
                  MenuItem(
                    title: "Notifications".tr(),
                    prefix: Icon(HugeIcons.strokeRoundedNotification01),
                    onPressed: model.openNotification,
                  ),

                  //
                  MenuItem(
                    title: "Rate & Review".tr(),
                    onPressed: model.openReviewApp,
                    prefix: Icon(HugeIcons.strokeRoundedStar),
                  ),

                  //
                  MenuItem(
                    title: "Faqs".tr(),
                    onPressed: model.openFaqs,
                    prefix: Icon(HugeIcons.strokeRoundedQuestion),
                  ),
                  //
                  MenuItem(
                    title: "Privacy Policy".tr(),
                    onPressed: model.openPrivacyPolicy,
                    prefix: Icon(HugeIcons.strokeRoundedBook02),
                  ),
                  //
                  MenuItem(
                    title: "Terms & Conditions".tr(),
                    onPressed: model.openTerms,
                    prefix: Icon(HugeIcons.strokeRoundedShield01),
                  ),
                  //START NEW LINKS
                  MenuItem(
                    title: "Refund Policy".tr(),
                    onPressed: model.openRefundPolicy,
                    prefix: Icon(HugeIcons.strokeRoundedReturnRequest),
                  ),
                  MenuItem(
                    title: "Cancellation Policy".tr(),
                    onPressed: model.openCancellationPolicy,
                    prefix: Icon(HugeIcons.strokeRoundedCancel01),
                  ),
                  MenuItem(
                    title: "Delivery/Shipping Policy".tr(),
                    onPressed: model.openShippingPolicy,
                    prefix: Icon(HugeIcons.strokeRoundedShoppingBag01),
                  ),
                  //END NEW LINKS
                  //
                  MenuItem(
                    title: "Contact Us".tr(),
                    onPressed: model.openContactUs,
                    prefix: Icon(HugeIcons.strokeRoundedMail01),
                  ),
                  //
                  MenuItem(
                    title: "Live Support".tr(),
                    onPressed: model.openLivesupport,
                    prefix: Icon(HugeIcons.strokeRoundedBubbleChat),
                  ),

                  // Enhanced Chat Demo (for testing)
                  MenuItem(
                    title: "Enhanced Chat Demo",
                    onPressed: () {
                      Navigator.of(context).pushNamed('enhanced_chat_demo');
                    },
                    prefix: Icon(HugeIcons.strokeRoundedTranslate),
                  ),
                ]),
                model.appVersionInfo.text.sm.medium.gray400
                    .makeCentered()
                    .py20(),
                //
                UiSpacer.verticalSpace(space: context.percentHeight * 10),
              ]).p20().scrollVertical(),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
