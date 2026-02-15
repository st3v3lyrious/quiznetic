import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';

void main() {
  test('brand theme contrast pairs meet WCAG AA baseline for normal text', () {
    final base = ColorScheme.fromSeed(
      seedColor: BrandConfig.seedColor,
      brightness: Brightness.light,
    );
    final scheme = base.copyWith(
      secondary: BrandConfig.correctAnswerColor,
      onSecondary: Colors.white,
      error: BrandConfig.wrongAnswerColor,
      onError: Colors.white,
      surfaceContainerHighest: BrandConfig.neutralSurfaceColor,
      onSurfaceVariant: Colors.black87,
    );

    expect(
      _contrastRatio(scheme.primary, scheme.onPrimary),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(scheme.secondary, scheme.onSecondary),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(scheme.error, scheme.onError),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(scheme.surface, scheme.onSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      greaterThanOrEqualTo(4.5),
    );
  });
}

double _contrastRatio(Color a, Color b) {
  final luminanceA = _relativeLuminance(a);
  final luminanceB = _relativeLuminance(b);
  final lighter = math.max(luminanceA, luminanceB);
  final darker = math.min(luminanceA, luminanceB);
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  double toLinear(double srgb) {
    if (srgb <= 0.03928) {
      return srgb / 12.92;
    }
    return math.pow((srgb + 0.055) / 1.055, 2.4).toDouble();
  }

  final red = toLinear(color.r);
  final green = toLinear(color.g);
  final blue = toLinear(color.b);
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
}
