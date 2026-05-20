import 'package:flutter/material.dart';

extension PaddingExtension on Widget {
  Widget withPadding(double left, double top, double right, double bottom) {
    return Padding(
      padding: EdgeInsets.fromLTRB(left, top, right, bottom),
      child: this,
    );
  }

  Widget withPaddingTop(double padding) {
    return Padding(
      padding: EdgeInsets.only(top: padding),
      child: this,
    );
  }

  Widget withPaddingBottom(double padding) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: this,
    );
  }

  Widget withPaddingLeft(double padding) {
    return Padding(
      padding: EdgeInsets.only(left: padding),
      child: this,
    );
  }

  Widget withPaddingRight(double padding) {
    return Padding(
      padding: EdgeInsets.only(right: padding),
      child: this,
    );
  }

  Widget withPaddingX(double padding) {
    return Padding(
      padding: EdgeInsets.only(right: padding, left: padding),
      child: this,
    );
  }

  Widget withPaddingY(double padding) {
    return Padding(
      padding: EdgeInsets.only(top: padding, bottom: padding),
      child: this,
    );
  }
}
