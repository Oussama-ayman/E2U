import 'package:flutter/material.dart';
import 'package:fuodz/models/category.dart';
import 'package:fuodz/models/search.dart';
import 'package:fuodz/requests/category.request.dart';
import 'package:fuodz/services/navigation.service.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:velocity_x/velocity_x.dart';

class SubcategoriesViewModel extends MyBaseViewModel {
  SubcategoriesViewModel(BuildContext context, this.category) {
    this.viewContext = context;
  }

  //
  CategoryRequest _categoryRequest = CategoryRequest();
  RefreshController refreshController = RefreshController();

  //
  List<Category> subcategories = [];
  final Category category;

  //
  initialise() async {
    loadSubcategories();
  }

  //
  loadSubcategories() async {
    setBusy(true);
    try {
      subcategories = await _categoryRequest.subcategories(
        categoryId: category.id,
      );
      clearErrors();
    } catch (error) {
      setError(error);
    }
    setBusy(false);
  }

  //
  categorySelected(Category category) async {
    final search = Search(
      vendorType: category.vendorType,
      subcategory: category,
      showProductsTag: !(category.vendorType?.isService ?? false),
      showVendorsTag: !(category.vendorType?.isService ?? false),
      showServicesTag: (category.vendorType?.isService ?? false),
      showProvidesTag: (category.vendorType?.isService ?? false),
      // category: category,
      // showType: (category.vendorType?.isService ?? false) ? 5 : 4,
    );
    final page = NavigationService().searchPageWidget(search);

    viewContext.nextPage(page);
  }
}
