import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/models/category.dart';
import 'package:fuodz/view_models/vendor/sub_categories.vm.dart';
import 'package:fuodz/widgets/base.page.dart';
import 'package:fuodz/widgets/custom_dynamic_grid_view.dart';
import 'package:fuodz/widgets/list_items/category.list_item.dart';
import 'package:fuodz/widgets/states/subcategories.empty.dart';
import 'package:stacked/stacked.dart';

class SubcategoriesPage extends StatelessWidget {
  const SubcategoriesPage({required this.category, Key? key}) : super(key: key);

  final Category category;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SubcategoriesViewModel>.reactive(
      viewModelBuilder: () => SubcategoriesViewModel(context, category),
      onViewModelReady: (vm) => vm.initialise(),
      builder: (context, vm, child) {
        return BasePage(
          showAppBar: true,
          showCart: true,
          showLeadingAction: true,
          title: category.name,
          body: CustomDynamicHeightGridView(
            noScrollPhysics: true,
            crossAxisCount: AppStrings.categoryPerRow,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            isLoading: vm.isBusy,
            itemCount: vm.subcategories.length,
            canRefresh: true,
            refreshController: vm.refreshController,
            onRefresh: () => vm.loadSubcategories(),
            padding: EdgeInsets.all(12),
            emptyWidget: EmptySubcategoriesView(),
            itemBuilder: (context, index) {
              return AspectRatio(
                aspectRatio: 1.0,
                child: ClipRect(
                  child: CategoryListItem(
                    category: vm.subcategories[index],
                    onPressed: vm.categorySelected,
                    maxLine: false,
                    textColor: Colors.white,
                    textSize: AppStrings.categoryTextSize * 2,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
