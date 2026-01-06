# Shady

A Metal shader playground for iOS, built with SwiftUI and MetalKit. Explore 16 procedural visual effects rendered in real-time on the GPU.

## Features

- **16 Shader Effects** – From simple sine waves to complex particle systems
- **Pure Metal/SwiftUI** – No external dependencies
- **Touch Interaction** – Shader 12 responds to touch input
- **Portfolio-Ready** – Clean, well-documented codebase

## Shader Gallery

| # | Effect | Description |
|---|--------|-------------|
| 01 | Sine Wave | Animated color pattern |
| 02 | Swirl | Color distortion effect |
| 03 | Metallic Liquid | Reflective distortion |
| 04 | Bouncing Wave | Dynamic wave colors |
| 05 | Metaballs | Animated blob shapes (SDF) |
| 06 | Glowing Star | Metaball star effect |
| 07 | Northern Lights | Noise-based aurora |
| 08 | Rotating Stars | Spinning star shapes |
| 09 | Checker Strobe | Animated checker pattern |
| 10 | Raindrops | Glass raindrop effect |
| 11 | Fireworks | Particle explosions |
| 12 | Liquid Wave | Interactive silvery liquid |
| 13 | Clouds | Procedural drifting clouds (fBm) |
| 14 | Lava Lamp | Metaball simulation |
| 15 | Lightning | Dynamic bolt effect |
| 16 | Warp Drive | Hyperspace starfield |

## Requirements

- iOS 18.0+
- Xcode 16+
- Device with Metal support

## Getting Started

1. Clone the repository
2. Open `Shady.xcodeproj` in Xcode
3. Build and run on a device or simulator
4. Tap **Next Shader** to cycle through effects

## Architecture

The app uses three rendering patterns to demonstrate different Metal/SwiftUI integration approaches:

### Pattern A: Simple MTKView Subclass
Shaders 01–05, 08–09 override `draw(_ rect:)` directly.

### Pattern B: Coordinator-Based
Shaders 06, 07, 12 use a `UIViewRepresentable` with a `Coordinator` class as `MTKViewDelegate`.

### Pattern C: Self-Delegating MTKView
Shaders 10–11, 13–16 have the MTKView subclass conform to `MTKViewDelegate` itself.

For detailed architecture documentation, see [`Docs/shady-architecture-overview.md`](Docs/shady-architecture-overview.md).

## Project Structure

```
Shady/
├── ShadyApp.swift           # App entry point
├── Views/
│   ├── ContentView.swift    # Main navigation (shader carousel)
│   └── ShaderView01–16.swift # Individual shader views
├── Shaders/
│   └── Shaders1–16.metal    # Metal shader files
└── Docs/
    ├── shady-architecture-overview.md
    └── shady-cleanup-plan.md
```

## License

Unlicensed experiment.

## Author

Junaid Dawud
