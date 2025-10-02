import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static double getResponsiveWidth(
    BuildContext context, {
    double mobile = 1.0,
    double tablet = 0.8,
    double desktop = 0.6,
  }) {
    if (isMobile(context)) {
      return MediaQuery.of(context).size.width * mobile;
    } else if (isTablet(context)) {
      return MediaQuery.of(context).size.width * tablet;
    } else {
      return MediaQuery.of(context).size.width * desktop;
    }
  }

  static double getResponsivePadding(
    BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  static int getResponsiveColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  static EdgeInsets getResponsiveEdgeInsets(
    BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    if (isMobile(context)) {
      return mobile ?? const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return tablet ?? const EdgeInsets.all(24.0);
    } else {
      return desktop ?? const EdgeInsets.all(32.0);
    }
  }

  static Widget responsiveBuilder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  static Widget responsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    int? mobileColumns,
    int? tabletColumns,
    int? desktopColumns,
    double? spacing,
    double? runSpacing,
  }) {
    int columns = getResponsiveColumns(
      context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: spacing ?? 16.0,
      mainAxisSpacing: runSpacing ?? 16.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  static Widget responsiveRow({
    required BuildContext context,
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    double? spacing,
  }) {
    if (isMobile(context)) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children
            .map(
              (child) => Padding(
                padding: EdgeInsets.only(bottom: spacing ?? 16.0),
                child: child,
              ),
            )
            .toList(),
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children
            .map(
              (child) => Padding(
                padding: EdgeInsets.only(right: spacing ?? 16.0),
                child: child,
              ),
            )
            .toList(),
      );
    }
  }

  static Widget responsiveContainer({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
    EdgeInsets? padding,
    BoxDecoration? decoration,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? getResponsiveWidth(context),
        ),
        child: Container(
          width: double.infinity,
          padding: padding ?? getResponsiveEdgeInsets(context),
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }

  static Widget responsiveCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    double? elevation,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return Card(
      elevation: elevation ?? 4.0,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius:
            borderRadius ??
            BorderRadius.circular(isMobile(context) ? 12.0 : 16.0),
      ),
      child: Padding(
        padding: padding ?? getResponsiveEdgeInsets(context),
        child: child,
      ),
    );
  }

  static PreferredSizeWidget responsiveAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: getResponsiveFontSize(
            context,
            mobile: 18.0,
            tablet: 20.0,
            desktop: 22.0,
          ),
        ),
      ),
      actions: actions,
      leading: leading,
      bottom: bottom,
      elevation: 0,
    );
  }

  static Widget responsiveBottomNavigationBar({
    required BuildContext context,
    required int currentIndex,
    required ValueChanged<int> onTap,
    required List<BottomNavigationBarItem> items,
  }) {
    if (isDesktop(context)) {
      return NavigationRail(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        labelType: NavigationRailLabelType.all,
        destinations: items
            .map(
              (item) => NavigationRailDestination(
                icon: item.icon,
                label: Text(item.label ?? ''),
              ),
            )
            .toList(),
      );
    } else {
      return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items,
        type: BottomNavigationBarType.fixed,
      );
    }
  }
}
