# Frontend Upgrade Plan — Glass Texture + Dynamic Effects + Theme System

## 目標

三維升級：
1. **玻璃質感** — 從單層 ultraThinMaterial 升級為多層疊加的真實玻璃渲染
2. **動態效果** — 光線流動、粒子背景、數字動畫、互動反饋
3. **主題系統** — 可在設置中切換顏色深淺、玻璃風格

---

## 架構變更概覽

```
新增/修改文件：
Models/
  Theme.swift                 ← NEW    主題定義、顏色系統、持久化
Views/
  GlassCard.swift             ← NEW    多層玻璃組件（復用）
  AnimatedGradientBackground.swift ← NEW  動態光線背景
  FloatingCardView.swift      ← MODIFY 接入新組件 + 粒子層
  NumberTile.swift            ← MODIFY 數字彈跳動畫 + 光暈
  SettingsView.swift          ← MODIFY 加入主題選擇區塊
  ParticleField.swift         ← NEW    輕量粒子系統
ViewModels/
  AppState.swift              ← MODIFY 加入 theme 狀態 + 動畫控制
  ThemeManager.swift          ← NEW    主題切換與過渡管理
Utilities/
  Animations.swift            ← NEW    共享動畫曲線與參數
App/
  AppDelegate.swift           ← MODIFY 全局主題注入
```

---

## 細節設計

### 1. 主題系統 (`Theme.swift`)

定義 6 套主題，每套包含完整配色參數：

| 主題 | 風格 | 玻璃底色 | 強調色 | 適用場景 |
|------|------|----------|--------|----------|
| `deepOcean` (default) | 深海暗色 | 深青藍漸變 | 冰藍 #A0D8EF | 現有風格升級版 |
| `auroraNight` | 極光暗色 | 深紫藍漸變 | 螢光綠 #7FFFD4 | 暗色第二選擇 |
| `starlight` | 星光淺色 | 乳白暖灰漸變 | 琥珀 #F5A623 | 淺色模式 |
| `frostMorning` | 晨霜淺色 | 冰藍白漸變 | 天藍 #4A90D9 | 淺色第二選擇 |
| `ember` | 餘燼暗色 | 深棕橙漸變 | 橙金 #FF8C42 | 暖色調 |
| `midnight` | 純黑 | 純黑藍漸變 | 銀灰 #C0C0D0 | 極簡暗色 |

每套主題結構：
```swift
struct AppTheme {
    let name: String
    let mode: ThemeMode           // .dark / .light
    let glass: GlassConfig        // 多層玻璃參數
    let accent: Color
    let textPrimary: Color
    let textSecondary: Color
    let tileBackground: Color
    let shadowColor: Color
    let shadowRadius: CGFloat
    let borderGlow: Color
}

struct GlassConfig {
    let baseMaterial: Material    // .ultraThinMaterial / .regularMaterial / .thickMaterial
    let gradientColors: [Color]
    let gradientOpacity: Double
    let noiseOpacity: Double      // 噪點紋理強度
    let innerGlowColor: Color
    let innerGlowRadius: CGFloat
    let borderLightColor: Color
    let borderLightOpacity: Double
    let sweepColor: Color         // 光線掃描顏色
}
```

### 2. 多層玻璃組件 (`GlassCard.swift`)

渲染層級（從底到頂）：

```
Layer 1: Material background    (.ultraThinMaterial 或指定 material)
Layer 2: Gradient fill          (主題漸變色，帶 opacity)
Layer 3: Noise texture          (Canvas 生成的 Perlin-like 噪點，極低 opacity 0.03-0.06)
Layer 4: Inner glow             (框內邊緣柔光，使用 .stroke 的 inner shadow 模擬)
Layer 5: Light sweep            (對角線光線緩慢移動，用 TimelineView + 漸變 mask)
Layer 6: Border                 (雙層邊框：外層主題色 0.4 opacity，內層白色 0.12)
Layer 7: Shadow                 (柔和擴散陰影)
```

光線掃描效果（Light Sweep）：
- 使用 `TimelineView(.animation)` 驅動
- 一條對角線光帶以 8-12 秒周期從左上滑到右下
- 光帶是白色到透明的 LinearGradient，寬度約卡片對角線的 40%
- `.mask` 限制在 RoundedRectangle 內

### 3. 動態背景 (`AnimatedGradientBackground.swift`)

在玻璃卡片背後（window 層級）渲染：

- **光暈球體** — 2-3 個模糊圓形，緩慢漂移
  - 使用 `Timer` + `withAnimation(.easeInOut(duration: 6-8))` 定期更換位置
  - 半徑 80-160pt，blur 60-100pt
  - 顏色跟隨主題強調色
  
- **粒子場** (`ParticleField.swift`) — 可選的低開銷粒子
  - 10-20 個微小亮點，緩慢上升或漂移
  - 使用 Canvas 繪製，避免大量 View 開銷
  - 每個粒子：隨機位置、1.5-3pt 大小、0.3-0.6 opacity、8-15s 動畫週期
  - 粒子顏色：主題強調色 + 白色混合

### 4. 數字動畫升級 (`NumberTile`)

現狀分析：使用 `.contentTransition(.numericText())` 做基本的數字過渡。

升級方案：
- **數值變化時** — 使用 `.spring(response: 0.35, dampingFraction: 0.65)` 的 scale 彈跳
  - 先放大到 1.08 → 回彈到 1.0
  - 配合短暫的 glow pulse（白色光暈 0.15s 閃爍）
  
- **進位翻牌效果（可選）** — 較複雜，可能用 matchedGeometryEffect 做數字翻轉
  - 第一階段先做 scale+glow
  - 翻牌效果留作 roadmap

- **數字 tile 本身**：
  - 加入微妙的內發光（`.innerShadow` 模擬）
  - hover 時邊框發亮

### 5. 互動效果增強

**Hover Glow（滑鼠懸停光暈）：**
- 使用 `.onHover` 觸發
- 卡片邊框光亮提升（border opacity 從 0.4→0.7）
- 光線掃描加速（週期從 12s→4s）
- 鼠標位置附近的局部亮點（可選，較複雜）

**Click Ripple（點擊漣漪）：**
- press 時在點擊位置產生一個快速擴散的圓形波紋
- 使用 overlay + scale + opacity 動畫
- 0.4s 內從半徑 0 擴張到 80pt，opacity 從 0.35→0

**Drag Feedback（拖動反饋）：**
- 拖動時卡片跟隨鼠標微傾斜（3D perspective effect）
- 鬆手後彈回

### 6. 設置窗升級 (`SettingsView`)

新增「外觀」區塊：

```
┌─────────────────────────────────────────┐
│  外觀                                    │
│  ┌──────┐ ┌──────┐ ┌──────┐            │
│  │ 🌊   │ │ 🌌   │ │ ⭐   │            │
│  │ 深海  │ │ 極光  │ │ 星光  │            │
│  └──────┘ └──────┘ └──────┘            │
│  ┌──────┐ ┌──────┐ ┌──────┐            │
│  │ ❄️   │ │ 🔥   │ │ 🌙   │            │
│  │ 晨霜  │ │ 餘燼  │ │ 午夜  │            │
│  └──────┘ └──────┘ └──────┘            │
└─────────────────────────────────────────┘
```

- 6 個主題預覽卡片，點擊即時切換
- 切換時用 `.spring` 動畫過渡所有顏色
- 預覽卡片顯示縮小版的玻璃效果

### 7. 粒子系統 (`ParticleField.swift`)

輕量級 Canvas 實現：

```swift
struct Particle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
    var phase: Double
}

struct ParticleField: View {
    let theme: AppTheme
    @State private var particles: [Particle] = []
    @State private var tick: Double = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let pos = computePosition(particle, time: timeline.date, size: size)
                    context.fill(
                        Path(ellipseIn: CGRect(x: pos.x, y: pos.y, width: particle.size, height: particle.size)),
                        with: .color(theme.accent.opacity(particle.opacity))
                    )
                }
            }
        }
        .onAppear { generateParticles() }
    }
}
```

### 8. 動畫參數統一 (`Animations.swift`)

```swift
enum AppAnimation {
    static let glassSweepPeriod: Double = 10.0      // 光線掃描週期
    static let glassSweepHoverPeriod: Double = 4.0   // hover 加速
    static let numberSpring = Animation.spring(response: 0.35, dampingFraction: 0.65)
    static let themeTransition = Animation.spring(response: 0.45, dampingFraction: 0.78)
    static let orbDriftPeriod: ClosedRange<Double> = 6...10
    static let particleLifespan: ClosedRange<Double> = 8...15
    static let rippleDuration: Double = 0.4
}
```

---

## 實施順序

| 階段 | 內容 | 文件 | 預估 |
|------|------|------|------|
| **Phase 1** | 主題模型 + 持久化 + AppState 整合 | `Theme.swift`, `AppState.swift` | 基礎 |
| **Phase 2** | GlassCard 多層玻璃組件 | `GlassCard.swift` | 核心 |
| **Phase 3** | 動態背景 + 粒子 | `AnimatedGradientBackground.swift`, `ParticleField.swift` | 視覺 |
| **Phase 4** | FloatingCardView 重構接入 | `FloatingCardView.swift` | 整合 |
| **Phase 5** | 數字動畫 + 互動效果 | `NumberTile`, `FloatingCardView` | 細節 |
| **Phase 6** | 設置窗升級 + 主題選擇 | `SettingsView.swift` | 用戶 |
| **Phase 7** | ThemeManager + 過渡動畫 | `ThemeManager.swift`, `Animations.swift` | 潤色 |

---

## 風險與取捨

- **性能** — 粒子 + 光線掃描 + 光暈球體同時運行，需要確保 macOS 上 Canvas 渲染高效
  - 緩解：粒子數上限 20，球體上限 3，使用 `drawingGroup()` 做離屏渲染
  
- **SwiftUI 限制** — native 內陰影 (inner shadow) 在 SwiftUI 中沒有原生 API
  - 方案：使用 `.overlay` + blur + offset 模擬，或使用 `VisualEffect` 

- **淺色主題的玻璃效果** — `.ultraThinMaterial` 在淺色背景上效果較弱
  - 方案：淺色主題改用 `.regularMaterial` + 更高 opacity 的 gradient

- **無障礙** — 動態效果需要響應「減少動態效果」系統設置
  - 檢測 `UIAccessibility.isReduceMotionEnabled` (macOS 對應 API)
