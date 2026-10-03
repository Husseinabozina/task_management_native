# DESIGN_SYSTEM — tokens مستخرجة من فيجما المرجعية

المصدر: [Figma — Task management & to-do list app (Community)](https://www.figma.com/design/oja3AAf5WtxELKlXH0v4dn/) — فريمات 101:100، 101:125، 101:265، 101:358. قياسات الفريمات على أساس عرض 375pt.

## الألوان

| Token | القيمة | الاستخدام |
|---|---|---|
| primary | `#5F33E1` | الأزرار، FAB، الكارت الرئيسي، النص المؤكد، chip المحدد |
| textPrimary | `#24252C` | العناوين ونص المهام |
| textSecondary | `#6E6A7C` | الـ metadata والوصف |
| background | `#FFFFFF` | خلفية الشاشات |
| lavender | `#EEE9FF` | الـ bottom bar، pill «View Task»، عدّاد المقاطع، chips غير المحددة |
| lavenderAlt | `#EDE8FF` | chips، pill Done، Change Logo |
| pastels | `#FFE4F2` `#EDE4FF` `#FFE6D4` `#FFF6D4` `#E7F3FF` `#FFE9E1` `#E3F2FF` | خلفيات أيقونات المشاريع والكروت الثانوية |
| statusDone | bg `#EDE8FF` / نص primary | pill «Done» |
| statusTodo | bg `#E3F2FF` / نص `#0087FF` | pill «To-do» |
| statusInProgress | bg `#FFE9E1` / نص `#FF7D53` | مؤجل خارج V1 (D11) |
| timeText | `#AB94FF` | نص الوقت/الموعد في الصف |
| progressBlue / progressOrange | `#0087FF` / `#FF7D53` | أشرطة تقدم المشاريع |
| donutTrack | `#EEE9FF` + `#8764FF` | دائرة تقدم الكارت الرئيسي |
| decorativeDots | `#EAED2A` `#FFD7E4` `#92DEFF` `#BE9FFF` `#7FFCAA` `#A4E7F9` | نقاط زخرفية فقط |

## الظلال

| العنصر | القيمة |
|---|---|
| كارت أبيض (صفوف/حقول) | `0 4 32 rgba(0,0,0,0.04)` |
| الكارت الرئيسي | `0 0 20 rgba(0,0,0,0.03)` |
| FAB | `2 10 18 rgba(95,51,225,0.49)` |
| أيقونة التاب النشط | `0 6 6 rgba(95,51,225,0.35)` |
| توهج زر primary | ellipse 310×7 بلون primary + blur 15 تحت الزر |

## Typography — Lexend Deca

| الدور | الوزن/الحجم | أمثلة |
|---|---|---|
| عنوان Hero (شاشة البداية) | SemiBold 24 | «Task Management & To-Do List» |
| عنوان شاشة / زر primary / عنوان مقطع | SemiBold 19 | «Today’s Tasks»، «Let’s Start»، «Add Project» |
| chip محدد / زر pill | SemiBold 14 | «All»، «View Task» |
| عنوان مهمة / نص أساسي | Regular 14 | «Market Research» |
| metadata | Regular 11 | «23 Tasks»، «10:00 AM»، اسم المشروع بالصف |
| label حقل / نص pill الحالة | Regular 9 | «Project Name»، «Done» |

- العربية: Lexend Deca لا يغطي المحارف العربية — الخط المرافق المقترح **Cairo** بنفس الأوزان (600/400) للنص العربي (قرار D9، بانتظار المعاينة).
- دعم Dynamic Type إلزامي؛ الأحجام فوق نقاط انطلاق لا سقف.

## الأشكال والمقاسات

| العنصر | القيمة |
|---|---|
| زر primary | 331×52 **مستنسخ من SVG path** (`PrimaryButtonShape`): حافتان منحنيتان بقمّة عند المنتصف — ليست RoundedRectangle؛ bg primary، نص أبيض SemiBold 19، مع glow تحته |
| كارت صف/حقل | 331 عرض، radius 15، أبيض + ظل الكارت |
| الكارت الرئيسي (Home hero) | 331×146، radius 24، bg primary |
| كارت مشروع بارز | 202×116، radius 19، pastel bg |
| صف Task Group | 331×66، radius 15، أبيض + ظل |
| صف مهمة | 331×94، radius 15، أبيض + ظل |
| chip فلتر | ارتفاع 34، radius 9، عرض حسب النص + 20 padding |
| كارت يوم (الشريط الأسبوعي) | 64×84، radius 15؛ المحدد bg primary نص أبيض، غير المحدد أبيض + ظل |
| icon chip كبير | 34×34 radius 9 (pastel) + أيقونة 20×20 |
| icon chip صغير | 24×24 radius 7 (pastel) + أيقونة 14×14 |
| pill حالة | radius 7، نص Regular 9 |
| pill View Task | 111×38 radius 9، bg lavender، نص primary SemiBold 14 |
| FAB | 44×44 دائرة primary + glyph add بأصلها (~20pt) — ليس بمقاس صندوق المكوّن |
| Bottom bar | **مستنسخ من SVG** (`NotchedBarShape`): شريط 56 بلون lavender، رأس دائري 22، **notch منحدر مركزي يحتضن الـ FAB** |

## Bottom App Bar (بالظبط من الفيجما — مستنسخ من الـ SVG)

- الشكل كله `NotchedBarShape` من path فيجما 101:216: ارتفاع 56، رأس دائري 22، **notch منحدر بنعومة في المنتصف**.
- **FAB في المنتصف**: دائرة 44 primary بارزة فوق الـ notch بظل بنفسجي، أيقونة add بيضاء بحجم glyph الأصلي (~20pt).
- التابات (حقيقية فقط — D17): الرئيسية (home bold)، مهامي (calendar bold)، المشاريع (briefcase bold) — 24×24.
- التاب النشط: أيقونة بلون primary + ظل بنفسجي خفيف.

## الأصول الجاهزة

`assets/figma/icons/*.svg` (16 أيقونة vuesax/Iconly) و`assets/figma/images/*.png` (7 صور شاشة البداية بدقة 2x) — منزّلة من الفيجما ومتحقق منها.

## الحركة

قصيرة (150–250ms): إتمام مهمة (checkmark + تلاشٍ)، ظهور sheet المحرر بنمط النظام، نبضة FAB عند الضغط. تحترم reduced motion.
