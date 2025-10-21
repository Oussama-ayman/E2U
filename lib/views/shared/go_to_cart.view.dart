import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/extensions/dynamic.dart';
import 'package:fuodz/services/cart.service.dart';
import 'package:fuodz/views/pages/cart/cart.page.dart';
import 'package:fuodz/widgets/buttons/custom_button.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:fuodz/extensions/context.dart';

class GoToCartView extends StatelessWidget {
  const GoToCartView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      initialData: CartServices.productsInCart.length,
      stream: CartServices.cartItemsCountStream.stream,
      builder: (context, snapshot) {
        print(
          "GoToCartView - Stream data: ${snapshot.data}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}",
        );
        print(
          "GoToCartView - Cart items count: ${CartServices.productsInCart.length}",
        );

        return Visibility(
          visible: snapshot.hasData && snapshot.data! > 0,
          child:
              HStack([
                    //
                    "You have %s in your cart"
                        .tr()
                        .fill([snapshot.data])
                        .text
                        .white
                        .make()
                        .expand(),
                    //
                    CustomButton(
                      title: "View Cart".tr(),
                      icon: FlutterIcons.shopping_cart_fea,
                      iconSize: 16,
                      height: 30,
                      color: AppColor.accentColor,
                      elevation: 1,
                      onPressed: () {
                        context.push((context) => CartPage());
                      },
                    ),
                    //
                  ])
                  .p20()
                  .safeArea(top: false)
                  .box
                  .color(AppColor.primaryColor)
                  .topRounded()
                  .make(),
        );
      },
    );
  }
}
