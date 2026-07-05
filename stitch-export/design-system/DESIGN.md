# Warm & Gentle Domesticity

## Tokens

### Colors

- surface: `#fff8f6`
- surface-dim: `#ecd5d0`
- surface-bright: `#fff8f6`
- surface-container-lowest: `#ffffff`
- surface-container-low: `#fff0ed`
- surface-container: `#ffe9e5`
- surface-container-high: `#fbe3de`
- surface-container-highest: `#f5ddd9`
- on-surface: `#251916`
- on-surface-variant: `#58413c`
- inverse-surface: `#3b2d2a`
- inverse-on-surface: `#ffede9`
- outline: `#8c716b`
- outline-variant: `#dfbfb9`
- surface-tint: `#a9371f`
- primary: `#a9371f`
- on-primary: `#ffffff`
- primary-container: `#f06a4d`
- on-primary-container: `#5c0c00`
- inverse-primary: `#ffb4a4`
- secondary: `#505f76`
- on-secondary: `#ffffff`
- secondary-container: `#d0e1fb`
- on-secondary-container: `#54647a`
- tertiary: `#4e635a`
- on-tertiary: `#ffffff`
- tertiary-container: `#82988e`
- on-tertiary-container: `#1c3029`
- error: `#ba1a1a`
- on-error: `#ffffff`
- error-container: `#ffdad6`
- on-error-container: `#93000a`
- background: `#fff8f6`
- on-background: `#251916`
- surface-variant: `#f5ddd9`

### Typography

- display-lg: Inter, PingFang SC, 32px, 600, 44px
- headline-lg: Inter, PingFang SC, 24px, 600, 32px
- headline-md: Inter, PingFang SC, 20px, 600, 28px
- body-lg: Inter, PingFang SC, 18px, 400, 28px
- body-md: Inter, PingFang SC, 16px, 400, 24px
- body-sm: Inter, PingFang SC, 14px, 400, 20px
- label-md: Inter, PingFang SC, 12px, 500, 16px, 0.05em

### Radius

- sm: `0.25rem`
- default: `0.5rem`
- md: `0.75rem`
- lg: `1rem`
- xl: `1.5rem`
- full: `9999px`

### Spacing

- base: `8px`
- xs: `4px`
- sm: `8px`
- md: `16px`
- lg: `24px`
- xl: `32px`
- margin-mobile: `16px`
- margin-desktop: `40px`
- gutter: `12px`

## 品牌与风格

本设计系统的核心在于捕捉“家”的温度。这是一款为伴侣设计的社交工具，旨在将日常的“吃什么”从一项家务负担转化为一种情感联结。品牌性格定位为：**体贴、宁静、高品质且充满生活气息**。

我们采用**现代极简主义（Minimalism）**结合**温暖影调**的风格，摒弃外卖平台常见的紧迫感与高饱和色调。视觉设计应当像早晨洒在餐桌上的阳光，克制而轻盈。通过大量的留白、温润的色彩过渡和细腻的排版，传达“被看见”与“被照顾”的情绪价值。

## 色彩体系

色彩选择旨在唤起厨房与餐桌的温馨感。

- **暖珊瑚橙 (Primary):** 作为核心品牌色，象征火焰的温暖与食物的诱惑。它不应过于刺眼，而是带有一定的灰度，呈现出陶瓷般的质感。
- **奶油白 (Surface):** 用于容器和卡片，相比纯白更显柔和，减少视觉疲劳。
- **柔和米色 (Background):** 作为全局底色，营造出类似棉麻织物的舒适氛围。
- **鼠尾草绿 (Success):** 用于表达健康、食材新鲜及“已达成”的正面反馈。
- **静谧蓝灰 (Secondary/Text):** 用于正文与副标题，提供稳重、深邃的阅读体验，替代生硬的纯黑。

## 字体排版

字体系统优先考虑中文阅读的呼吸感。我们选择 **Inter** 作为英文与数字字体，因其卓越的可读性与现代感；中文字体建议搭配 **PingFang SC** 或类似的无衬线系统字体。

- **层级处理:** 通过字重（Weight）而非仅仅通过字号（Size）来区分层级。重要标题使用 Semibold (600)，正文使用 Regular (400)。
- **行高:** 保持较宽松的行高（1.5x - 1.6x），增加页面透明度，营造“不费力”的阅读感。
- **移动端适配:** 在手机端，Display 字号应缩减至 28px 以确保长标题不会折行过多。

## 布局与间距

本设计系统采用基于 **8px** 的网格步进系统，确保视觉逻辑的一致性。

- **布局模型:** 采用流式布局（Fluid Grid）。在移动端，侧边距固定为 16px，卡片之间的间隙（Gutter）为 12px。
- **响应式策略:** Mobile 单列布局为主，强调垂直流动的愿望清单；Tablet/Desktop 切换为多列瀑布流或网格布局，侧边栏承载导航，主内容区最大宽度限制在 1200px 以防信息过载。
- **节奏感:** 在愿望卡片之间使用较大的纵向间距（24px+），让每个“愿望”都能独立呼吸，不显拥挤。

## 高度与深度

我们避免使用厚重的阴影，转而利用**色块堆叠（Tonal Layers）**和**极其微弱的弥散阴影**来表现层级。

- **投影特性:** 投影应具有极大的模糊半径（Blur > 20px）和极低的透明度（3% - 5%），且阴影颜色应带有微量的暖色调（Primary Color Tint），使其看起来像是环境光的自然遮挡，而非浮在纸面上的硬物。
- **表面层级:** 第一层为底色（Soft Beige），第二层为容器卡片（Creamy White），第三层为悬浮态/弹出框。

## 形状语言

本系统的形状语言定位为“温润”。统一采用 **8px (0.5rem)** 的圆角作为基础逻辑。这一弧度既能体现现代感，又比直角更具亲和力，同时避免了过大圆角可能带来的幼稚感。

- **按钮与输入框:** 统一 8px 圆角。
- **卡片:** 基础圆角 8px，若卡片内嵌套小元素，内元素圆角应减小为 4px。
- **状态图标:** 包裹背景采用圆形（Pill-shaped），用以打破矩形的单调。

## 组件设计

组件应保持极简的线性风格，减少不必要的装饰。

- **按钮 (Buttons):** 主按钮使用暖珊瑚橙背景 + 白色文字；次按钮使用奶油白背景 + 1px 静谧蓝灰细边框。
- **愿望卡片 (Wish Cards):** 左侧或顶部留出大幅留白空间展示食物示意图，右侧/底部显示愿望名称、发起人头像及时间。点击时伴随轻微的缩放反馈。
- **线性图标 (Icons):** 统一使用 2px 线条粗细，末端圆润。图标集应包含餐具、日历、爱心、清单、时钟及对话气泡。
- **输入框 (Inputs):** 仅在聚焦时显示 primary 颜色的边框，默认状态下仅以轻微的色彩深浅与背景区分。
- **Chips:** 用于标记“想吃”、“能做”、“缺食材”等标签，使用半透明 Primary 或 Tertiary 色彩填充，营造轻盈感。
