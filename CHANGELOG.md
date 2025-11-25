# Changelog

## 1.0.15

* Added `SpoilerTextFormField` to keep native text field behaviors (cursor, context menu) while applying spoiler masks to selected ranges.
* Added `SpoilerTextWrapper` to wrap existing text widgets/subtrees with the spoiler effect.
* Unified path/signature helpers for selections; small gesture and clipping fixes.

## 1.0.14

* new `onSpoilerVisibilityChanged` method to listen visibility

## 1.0.13

* Support `maxLines` and `isEllipsis` for TextPainter

## 1.0.12

* `SpoilerOverlay` first blur render issue
* `enableFadeAnimation` false issue

## 1.0.11

### **Breaking Changes**

* **Class Renames:**
  * `SpoilerConfiguration` renamed to `SpoilerConfig`
  * `WidgetSpoilerConfiguration` renamed to `WidgetSpoilerConfig`
  * `TextSpoilerConfiguration` renamed to `TextSpoilerConfig`

* **Parameter Renaming:**
  * `speedOfParticles` renamed to `particleSpeed`
  * `fadeAnimation` renamed to `enableFadeAnimation`
  * `enableGesture` renamed to `enableGestureReveal`
  * `style` renamed to `textStyle` in `TextSpoilerConfig`
  * `selection` renamed to `textSelection` in `TextSpoilerConfig`

* **New Features:**
  * Added `maskConfig` to support advanced masking with `Path`, `PathOperation`, and `offset`.
  * Added `textAlign` to `TextSpoilerConfig` for custom text alignment control.

## 1.0.10

### **Breaking Changes**

* **Class Renames:**
  * `SpoilerWidget` renamed to `SpoilerOverlay`
  * `SpoilerTextWidget` renamed to `SpoilerText`
* **Parameter Renaming:**
  * `configuration` parameter changed to `config`
* **Rendering Update:**
  * Replaced `RenderParagraph` with `TextPainter` for better canvas performance

## 1.0.9

* A new `SpoilerSpotsController` class can schedule "wave" or "ripple" effects, causing particles to move outward from random origins within the spoiler bounds.
* Reusable buffers in `drawRawAtlas` reduce per-frame allocations, providing smoother animations.
* Reorganized Core. Clearer Names & Docs.

## 1.0.8

* chore: added tags
* small fixes

## 1.0.7

* perf: Refactored particle rendering to use `drawRawAtlas`, significantly improving performance for rendering large numbers of particles

## 1.0.6

* Gesture issue fixed
* start with already spoilered state in SpoilerTextWidget
* import refactor

## 1.0.5

* Added new SpoilerWidget widget to hide widgets below

## 1.0.4

* Added docs

## 1.0.3

* Position fix

## 1.0.1

* Added docs

## 1.0.0

* Initial release.
