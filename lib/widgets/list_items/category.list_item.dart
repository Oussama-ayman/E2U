import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/models/category.dart';
import 'package:fuodz/utils/utils.dart';
import 'package:fuodz/widgets/custom_image.view.dart';
import 'package:velocity_x/velocity_x.dart';

class CategoryListItem extends StatelessWidget {
  const CategoryListItem({
    required this.category,
    required this.onPressed,
    this.maxLine = true,
    this.h,
    this.inverted = false,
    this.textColor,
    this.lines = 1,
    this.textSize,
    Key? key,
  }) : super(key: key);

  final Function(Category) onPressed;
  final Category category;
  final bool maxLine;
  final double? h;
  final bool inverted;
  final Color? textColor;
  final int lines;
  final double? textSize;
  @override
  Widget build(BuildContext context) {
    Widget child = 5.heightBox;
    if (inverted) {
      Color bgColor = Vx.hexToColor(category.color ?? "#ffffff");
      Color mTextColor = Utils.textColorByColor(bgColor);
      child = _buildCategoryViewBase(
        maxLine,
        inverted,
        textColor ?? mTextColor,
      );
      child = child.p(8).box.roundedSM.color(bgColor).make();
    } else {
      Color mTextColor = Utils.textColorByColor(Colors.transparent);
      child = _buildCategoryViewBase(
        maxLine,
        inverted,
        textColor ?? mTextColor,
      );
    }

    //
    if (maxLine) {
      child =
          child
              .w(
                (AppStrings.categoryImageWidth * 2.2) +
                    AppStrings.categoryTextSize,
              )
              .h(
                h ??
                    ((AppStrings.categoryImageHeight * 2.2) +
                        AppStrings.categoryImageHeight),
              )
              .onInkTap(() => this.onPressed(this.category))
              .px4();
    } else {
      child =
          child
              // .w((AppStrings.categoryImageWidth * 1.8) +
              //     AppStrings.categoryTextSize)
              .onInkTap(() => this.onPressed(this.category))
              .px4();
    }
    return child;
    /*
    return VStack(
      [
        //max line applied
        CustomVisibilty(
          visible: maxLine,
          child: VStack(
            [
              //
              CustomImage(
                imageUrl: category.imageUrl ?? "",
                boxFit: BoxFit.fill,
                width: AppStrings.categoryImageWidth,
                height: AppStrings.categoryImageHeight,
              )
                  .box
                  .roundedSM
                  .clip(Clip.antiAlias)
                  .color(Vx.hexToColor(category.color ?? "#ffffff"))
                  .make()
                  .py2(),

              category.name.text
                  .minFontSize(AppStrings.categoryTextSize)
                  .size(AppStrings.categoryTextSize)
                  .center
                  .maxLines(1)
                  .overflow(TextOverflow.ellipsis)
                  .make()
                  .p2()
                  .expand(),
            ],
            crossAlignment: CrossAxisAlignment.center,
            alignment: MainAxisAlignment.start,
          )
              .w((AppStrings.categoryImageWidth * 1.8) +
                  AppStrings.categoryTextSize)
              .h(h ??
                  ((AppStrings.categoryImageHeight * 1.8) +
                      AppStrings.categoryImageHeight))
              .onInkTap(
                () => this.onPressed(this.category),
              )
              .px4(),
        ),

        //no max line applied
        CustomVisibilty(
          visible: !maxLine,
          child: VStack(
            [
              //
              CustomImage(
                imageUrl: category.imageUrl ?? "",
                boxFit: BoxFit.fill,
                width: AppStrings.categoryImageWidth,
                height: AppStrings.categoryImageHeight,
              )
                  .box
                  .roundedSM
                  .clip(Clip.antiAlias)
                  .color(Vx.hexToColor(category.color ?? "#ffffff"))
                  .make()
                  .py2(),

              //
              category.name.text
                  .size(AppStrings.categoryTextSize)
                  .wrapWords(true)
                  .center
                  .make()
                  .p2(),
            ],
            crossAlignment: CrossAxisAlignment.center,
            alignment: MainAxisAlignment.start,
          )
              .w((AppStrings.categoryImageWidth * 1.8) +
                  AppStrings.categoryTextSize)
              .onInkTap(
                () => this.onPressed(this.category),
              )
              .px4(),
        )

        //
      ],
    );
    */
  }

  //
  Widget _buildCategoryViewBase(bool maxLine, bool inverted, Color textColor) {
    final double currentTextSize = textSize ?? AppStrings.categoryTextSize;
    Widget nameView = category.name.text
        .size(currentTextSize)
        .wrapWords(true)
        .center
        .color(textColor)
        .maxLines(2)
        .ellipsis
        .make()
        .py(1);
    if (maxLine) {
      nameView = category.name.text
          .minFontSize(currentTextSize)
          .size(currentTextSize)
          .center
          .color(textColor)
          .maxLines(lines)
          .ellipsis
          .make()
          .py(1);
    }
    return FittedBox(
      child: VStack(
        [
          //
          CustomImage(
                imageUrl: category.imageUrl ?? "",
                boxFit: BoxFit.cover,
                width: AppStrings.categoryImageWidth * 2,
                height: AppStrings.categoryImageWidth * 2,
              ).box.roundedSM
              .clip(Clip.antiAlias)
              .color(
                inverted
                    ? Colors.transparent
                    : Vx.hexToColor(category.color ?? "#ffffff"),
              )
              .make()
              .py2(),

          //
          nameView,
        ],
        crossAlignment: CrossAxisAlignment.center,
        alignment: MainAxisAlignment.start,
      ),
    );
  }
}
