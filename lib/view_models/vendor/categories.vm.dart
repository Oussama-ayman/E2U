import 'package:flutter/material.dart';
import 'package:fuodz/models/category.dart';
import 'package:fuodz/models/search.dart';
import 'package:fuodz/models/vendor_type.dart';
import 'package:fuodz/requests/category.request.dart';
import 'package:fuodz/services/navigation.service.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:fuodz/views/pages/category/subcategories.page.dart';
import 'package:velocity_x/velocity_x.dart';

class CategoriesViewModel extends MyBaseViewModel {
  CategoriesViewModel(BuildContext context, {this.vendorType, this.page}) {
    this.viewContext = context;
  }

  int? page;

  //
  CategoryRequest _categoryRequest = CategoryRequest();
  // RefreshController refreshController = RefreshController();

  //
  List<Category> categories = [];
  VendorType? vendorType;

  //
  initialise() {
    loadCategories();
  }

  //
  loadCategories() async {
    print("CategoriesViewModel: Starting to load categories");
    print(
      "CategoriesViewModel: vendorType: ${vendorType?.name} (ID: ${vendorType?.id})",
    );

    categories = [];
    setBusy(true);

    try {
      // Add null safety check
      if (vendorType?.id == null) {
        print("CategoriesViewModel: vendorType or vendorType.id is null");
        setError("No vendor type available");
        setBusy(false);
        return;
      }

      print(
        "CategoriesViewModel: Loading categories for vendor type ID: ${vendorType?.id}",
      );
      categories = await _categoryRequest.categories(
        vendorTypeId: vendorType?.id,
        page: page,
      );
      print("CategoriesViewModel: Loaded ${categories.length} categories");
      clearErrors();
    } catch (error) {
      print("CategoriesViewModel: Error loading categories: $error");
      setError(error);
    }
    setBusy(false);
  }

  //
  categorySelected(Category category) async {
    Widget page;
    if (category.hasSubcategories) {
      page = SubcategoriesPage(category: category);
    } else {
      final search = Search(
        vendorType: category.vendorType,
        category: category,
        showProductsTag: !(category.vendorType?.isService ?? false),
        showVendorsTag: !(category.vendorType?.isService ?? false),
        showServicesTag: (category.vendorType?.isService ?? false),
        showProvidesTag: (category.vendorType?.isService ?? false),
        // showType: (category.vendorType?.isService ?? false) ? 5 : 4,
      );
      page = NavigationService().searchPageWidget(search);
    }
    viewContext.nextPage(page);
  }
}
