# تحسين نصوص وصورة iOS — 2026-10-05

## النطاق المعتمد من المستخدم

- استبدال نصوص الواجهة العامية بفصحى بسيطة، بما يشمل الحالات الفارغة والفلاتر ورسائل الحساب والأخطاء وإمكانية الوصول.
- استبدال صورة الترحيب بصورة مناسبة لهوية «مهامي»، بلا أشخاص أو حيوانات أو أي ذوات أرواح.
- عدم استكمال الميزات الناقصة أو العمل على أندرويد أو تغيير سلوك التخزين والمزامنة.

## معايير القبول والثوابت

- «لنبدأ» بدل «يلا نبدأ»، «اليوم» بدل «النهارده»، «قيد التنفيذ» بدل «شغالة عليها»، وأولويات «منخفضة / عادية / عالية» في جميع مواضع عرضها.
- مراجعة جميع النصوص التي يعرضها iOS، مع الحفاظ على المعرفات والقيم المخزنة والاستيفاء النصي والإجراءات الحالية.
- صورة نهائية شفافة عالية الدقة تتكون من عناصر تنظيم مهام جامدة، بألوان الهوية البنفسجية، ومتصلة فعليًا بأصول iOS.
- تثبيت أبعاد شاشة الترحيب والتخطيط الحالي؛ الصورة الجديدة استثناء معتمد من المرجع الأصلي، وليست نقلًا حرفيًا من Figma.
- التحقق المتاح: مراجعة المصدر والفروق وسلامة الأصل وربطه. البناء والتشغيل والمقارنة من شاشة التطبيق تبقى للمستخدم وفق حدود AGENTS.md؛ لا يُدّعى تحقق بصري للتطبيق.

## خريطة التأثير

شاشات iOS ورسائل الأخطاء/الحساب ونصوص المعاينة، وصورة واحدة في Assets.xcassets. لا تعديلات على عقود البيانات أو dependencies أو أندرويد.

## احتمالات الإخفاق

نص أطول من مساحة chip الحالية، اختلاف أسماء الحالات بين الشاشات، أصل صورة غير مربوط، أو فقد شفافية الصورة. تُراجع بالمصدر وفحص الأصل، ويبقى قبول التخطيط على الجهاز للمستخدم.

## مصدر الصورة النهائية

- الأداة: built-in image_gen، توليد جديد بخلفية شفافة، وليس screenshot للتطبيق.
- الأصل المتصل: `ios/TaskManagement/Resources/Assets.xcassets/onboarding_productivity.imageset/onboarding_productivity.png`.
- النص الكامل المستخدم للتوليد:

Use case: stylized-concept. Asset type: final transparent onboarding hero illustration for an Arabic native iOS task management app called مهامي. Primary request: a sophisticated premium 3D still-life of task organization, consisting only of inanimate objects. Main subject: a slightly tilted sculptural white task checklist card with three horizontal lavender task lines, elegant purple square checkboxes and two completed checkmarks; a small geometric desk calendar block beside it, a floating violet completion check badge, and one subtle lavender progress ring. Style: refined contemporary 3D product illustration, smooth satin ceramic and frosted acrylic, precise bevels, soft ambient shadows, tasteful restrained composition, polished and professional, no cartoon mascots. Palette: primary violet #5F33E1, lavender #EEE9FF, clean white, tiny pale warm peach accent. Composition: square canvas, one cohesive centered balanced compact arrangement, occupies 85 percent of canvas so readable at 200 point width on a phone, comfortable margin, isolated on genuinely transparent background, no surrounding scenery or platform. Text: none, only abstract task lines and check marks, no lettering or numbers. Constraints: absolutely no people, faces, hands, body parts, animals, birds, insects, living beings, plants, anthropomorphic objects, eyes, mouths, logos, watermark, UI screenshot, or phone mockup. Produce final high resolution asset with actual transparency.

## التحقق الفعلي والمقارنة بالمصدر

| العنصر | التغيير / الدليل |
|---|---|
| صورة الترحيب | أصل مولّد جديد ومعاين بصريًا: قائمة مهام وتقويم وعلامة إتمام وحلقة تقدم فقط؛ بلا ذوات أرواح. PNG 1254×1254 مع alpha، وmanifest يشير إليه. أُزيل الأصل القديم من كتالوج التطبيق وبقي مرجع Figma في assets/figma. |
| نصوص iOS | مراجعة الفروق لجميع الملفات المعدّلة ومسح ألفاظ العامية في النصوص المعروضة؛ توحيد الحالة والأولوية عبر الصف والمحرر والتفاصيل والفلاتر. |
| هندسة الترحيب | مقارنة المصدر قبل/بعد: عرض الصورة 200، المسافات 28/16/36، الزر وحوافه، الفقاعات والنقاط دون تغيير. نقل التخطيط القائم كما هو، دون ادعاء قياس runtime. |
| السلوك وعقود البيانات | فحص بنية 15 ملف Swift قبل/بعد مع تجاهل النصوص والتعليقات: متطابقة؛ لا تغييرات في الدومين أو المخزن أو أندرويد. |
| تشغيل الشاشة والمقارنة الجانبية | لم يُنفّذا؛ التشغيل للمستخدم وفق AGENTS.md. هذه مراجعة مصدر وأصل صورة، وليست قبولًا بصريًا نهائيًا للتطبيق. |

الثقة: مرتفعة في نطاق التغيير وربط الصورة، ومتوسطة في ملاءمة النصوص للتخطيط حتى معاينة المستخدم على iPhone، خصوصًا chip «قيد التنفيذ».
