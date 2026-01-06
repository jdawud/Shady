# Shady – Architecture Overview

Metal shader playground for iOS. 16 procedural effects rendered via `MTKView` subclasses bridged into SwiftUI.

---

## Structure

```
Shady/
├── ShadyApp.swift              # @main entry
├── Views/
│   ├── ContentView.swift       # Carousel navigation (index-based switch)
│   └── ShaderView01–16.swift   # UIViewRepresentable wrappers + MTKView subclasses
├── Shaders/
│   └── Shaders[1-16].metal     # Vertex/fragment pairs per effect
└── Assets.xcassets/
```

---

## Navigation

`ContentView` maintains `currentViewIndex` (0–15) and swaps shader views via `@ViewBuilder` switch. Single-screen carousel, no navigation stack.

---

## Rendering

Each effect: **SwiftUI View → UIViewRepresentable → MTKView subclass → .metal file**

All shaders render a full-screen quad (triangle strip, 4 verts) with `time` and `resolution` uniforms. Frame delta uses `1.0 / Float(preferredFramesPerSecond)`.

---

## Shader Catalog

| # | Swift View | Metal File | Effect Description |
|---|------------|------------|--------------------|
| 01 | `ShaderView01` | `Shaders.metal` | Animated sine wave color pattern |
| 02 | `ShaderView02` | `Shaders2.metal` | Swirling color distortion |
| 03 | `ShaderView03` | `Shaders3.metal` | Metallic liquid distortion |
| 04 | `ShaderView04` | `Shaders4.metal` | Bouncing wave color effect |
| 05 | `ShaderView05` | `Shaders5.metal` | Animated metaball blobs (SDF) |
| 06 | `ShaderView06` | `Shaders6.metal` | Glowing metaball star effect |
| 07 | `ShaderView07` | `Shaders7.metal` | Northern lights noise effect |
| 08 | `ShaderView08` | `Shaders8.metal` | Rotating star shapes |
| 09 | `ShaderView09` | `Shaders9.metal` | Animated checker pattern strobe |
| 10 | `ShaderView10` | `Shaders10.metal` | Raindrops on glass |
| 11 | `ShaderView11` | `Shaders11.metal` | Animated fireworks explosion |
| 12 | `ShaderView12` | `Shaders12.metal` | Interactive silvery liquid wave (touch) |
| 13 | `ShaderView13` | `Shaders13.metal` | Procedural drifting clouds (fBm) |
| 14 | `ShaderView14` | `Shaders14.metal` | Lava lamp metaballs |
| 15 | `ShaderView15` | `Shaders15.metal` | Dynamic lightning bolt |
| 16 | `ShaderView16` | `Shaders16.metal` | Warp drive / hyperspace starfield |

---

## Patterns

| Pattern | Shaders | Approach |
|---------|---------|----------|
| **A** | 01–05, 08–09 | `MTKView` subclass overrides `draw(_ rect:)` |
| **B** | 06, 07, 12 | `UIViewRepresentable` + `Coordinator` as `MTKViewDelegate` |
| **C** | 10–11, 13–16 | `MTKView` subclass overrides `draw(_ rect:)`, minimal wrapper |

**Uniforms:** Buffer 0/1 for `time`/`resolution`. Structs like `Uniforms07`, `Uniforms12` handle alignment where needed.

---

## Naming Conventions

- **Metal functions:** `vertex_mainXX` / `fragment_mainXX` or `vertexShaderXX` / `fragmentShaderXX`
- **Structs:** `VertexOutXX`, `UniformsXX` / `ShaderDataXX` (numbered to avoid linker collisions)

All `.metal` files compile into a single default library—names must be globally unique.

---

## Notable Files

| File | Notes |
|------|-------|
| `ShaderView12` | Touch input via `UIPanGestureRecognizer` |
| `Shaders13.metal` | fBm cloud noise |
| `Shaders16.metal` | Warp drive starfield |

---

## Build

- iOS 18.0+ / Xcode 16+
- `objectVersion = 77` (fileSystemSynchronizedGroups)
- No external dependencies

---

*Updated: January 2026*
