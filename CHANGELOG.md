# Changelog

## 1.0.0

* Initial release.
  
## 1.0.1

* Added docs

## 1.0.3

* Position fix

## 1.0.4

* Added docs

## 1.0.5

* Added new SpoilerWidget widget to hide widgets below

## 1.0.6

* Gesture issue fixed
* start with already spoilered state in SpoilerTextWidget
* import refactor
  
## 1.0.7

* perf: Refactored particle rendering to use `drawRawAtlas`, significantly improving performance for rendering large numbers of particles
  
## 1.0.8

* chore: added tags
* small fixes

## 1.0.9

* A new `SpoilerSpotsController` class can schedule "wave" or "ripple" effects, causing particles to move outward from random origins within the spoiler bounds.
* Reusable buffers in `drawRawAtlas` reduce per-frame allocations, providing smoother animations.
* Reorganized Core. Clearer Names & Docs.
