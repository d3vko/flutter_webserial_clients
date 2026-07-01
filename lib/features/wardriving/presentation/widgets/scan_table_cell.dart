import 'package:flutter/material.dart';

DataCell scanTableCell(String value, {TextStyle? style}) =>
    DataCell(SelectableText(value, style: style));
