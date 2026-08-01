# App images

Drop bundled image files here (JPG/PNG/WebP). They are referenced in code by
path, e.g. `assets/images/priya_before.jpg`.

## Onboarding / intro carousel banners

The four intro banners load from these exact filenames (PNG). Save your branded
banner images here with these names, in this order:

1. `onboarding_1_welcome.png` — Welcome
2. `onboarding_2_streak.png` — Build an Unbreakable Streak
3. `onboarding_3_rituals.png` — Six Daily Rituals
4. `onboarding_4_coach.png` — Coach & Doctor on Call

If a file is missing, that slide falls back to a simple text layout, so the app
always builds. Names/order are set in
`lib/features/onboarding/onboarding_screen.dart` (`kOnboardSlides`).

## Home-screen sliding banners

The auto-sliding banner strip at the top of Home loads these images (landscape).
The strip is ~138 px tall and full width, so use a **wide** banner — around
**1000 × 420 px** (≈ 2.4:1) works well:

- `home_banner_1.png`
- `home_banner_2.png`
- `home_banner_3.png`
- `home_banner_4.png`
- `home_banner_5.png`
- `home_banner_6.png`

If a file is missing, that banner falls back to the gradient + text card. List
lives in `lib/features/home/home_banner_carousel.dart` (`kHomeBanners`).

## Post-login transformation stories

Shown once right after a participant logs in (before Home), ending on a "the
next transformation could be yours" slide. Save 5–6 story images here:

- `transformation_story_1.png`
- `transformation_story_2.png`
- `transformation_story_3.png`
- `transformation_story_4.png`
- `transformation_story_5.png`
- `transformation_story_6.png`  (optional — delete the last line in
  `kTransformationIntroBanners` if you only have 5)

Final call-to-action banner (your own image too):
- `transformation_next_is_you.png` — the "next transformation could be yours"
  slide. If missing, a built-in card is shown as a fallback only.

Missing images show a placeholder/fallback until added. Lists live in
`lib/features/onboarding/transformation_intro_screen.dart`
(`kTransformationIntroBanners` and `kTransformationNextBanner`).

## Transformation "Success stories" photos

To show real before/after photos instead of the drawn silhouettes:

1. Add each pair of images to this folder, e.g.
   - `priya_before.jpg` / `priya_after.jpg`
   - `rahul_before.jpg` / `rahul_after.jpg`

2. In `lib/features/progress/transformation_stories.dart`, set the paths on the
   matching story:

   ```dart
   TransformationStory(
     name: 'Priya',
     ...
     beforeImage: 'assets/images/priya_before.jpg',
     afterImage: 'assets/images/priya_after.jpg',
     blurFace: true, // blurs the face region to protect identity (default)
   ),
   ```

3. Commit, push, and rebuild. The card shows the photo (face blurred) whenever
   an image path is set, and falls back to the silhouette otherwise.

## ⚠️ Only use images you have the right to use

- Your own members' photos **with their written consent**, or
- Stock/AI images whose licence **permits commercial use**.

Do **not** use photos copied from the web (Google Images, social media, etc.).
Blurring a face does **not** remove the copyright in someone else's photo, and
using it can breach copyright, likeness/privacy, and advertising rules.

Recommended size: ~800×1000 px, portrait, under ~300 KB each for fast loading.
