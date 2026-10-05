# Fortium AI Academy (iOS)

A beginner-friendly, Udemy-style course app that teaches non-technical people how to use **Claude** (web, desktop and mobile), with a built-in **Prompt Builder** at the top of the experience.

> Independent educational app. Not affiliated with or endorsed by Anthropic. Claude is a trademark of Anthropic, PBC.

---

## What's inside

| Area | What it does |
|---|---|
| **Prompt Builder** (hero feature) | Pinned to the top of Home and has its own tab. Pick one of 14 goals (email, summarize, plan, presentation, career…), answer 6 short steps (task → context → audience → tone → format → finishing touches) and get a ready-to-paste prompt. Includes a live **prompt-strength meter**, **Copy & open Claude**, Share, and a **saved prompts** library. 4 goals free, 10 Pro. |
| **Course** | 12 sections · 36 lessons · 108 quiz questions, written for beginners. Swipeable lesson cards (explanations, step lists, tips, warnings, vague-vs-clear prompt comparisons, "Your turn" exercises that copy a prompt and open Claude). Sections 1–2 are free. |
| **Quizzes** | 3 questions per lesson, instant feedback with friendly explanations. Pass mark is 50%. Below that, the learner gets "So close!" with review/retry options, never a failure screen. |
| **Progress & wins** | XP, daily streaks, per-section progress bars, an overall progress ring, 10 badges, friendly XP "levels", confetti celebrations after every lesson (bigger ones for sections), and a shareable **certificate** on completion. |
| **Subscription** | StoreKit 2, "Academy Pro" monthly ($4.99) and yearly ($29.99 with a 7-day free trial). Prices are placeholders you set in App Store Connect. Includes restore, manage subscription, and the legal text Apple requires. |
| **Accessibility** | A "Larger text" comfort mode (offered during onboarding), full Dynamic Type, VoiceOver labels, Reduce Motion support (confetti is turned off), haptics toggle, and light/dark mode. |

### Course outline
1. **Meet Claude** *(free)*: what Claude is, getting it on your devices, your first chat
2. **Asking Claude Well** *(free)*: the 5-ingredient prompt recipe, follow-ups and retries, getting accurate answers
3. **Files, Photos & Documents**: uploading files, photos and screenshots, getting Word/Excel/PowerPoint files back
4. **Projects**: what they are, setting up knowledge and instructions, real-life ideas
5. **Artifacts**: Docs, Slides and Designs, editing in place, sharing and publishing
6. **Web Search & Research**: web search, Research mode, checking sources
7. **Connectors & Apps**: Gmail/Drive/Calendar/Slack, connecting safely, Claude in Chrome/Excel/PowerPoint
8. **Cowork**: delegating multi-step tasks, scheduled tasks, staying in control
9. **Make Claude Yours**: memory, preferences and styles, models and thinking time
10. **Voice & Claude on the Go**: voice mode, phone power tips, daily habits
11. **Safety, Privacy & Good Habits**: privacy settings, what not to share, responsible use
12. **Real-World Playbooks**: work, small business, everyday life

---

## Run it on your Mac (no paid Apple account needed)

Requirements: **Xcode 16 or newer** (free from the Mac App Store). The app targets **iOS 17+**.

1. Open `FortiumAIAcademy.xcodeproj` in Xcode.
2. Pick a simulator at the top (e.g. *iPhone 16*) and press **▶ Run** (⌘R).

**On your own iPhone (free):** plug it in, select it as the run destination, then go to *FortiumAIAcademy target → Signing & Capabilities → Team* and choose your personal Apple ID. Free signing lasts 7 days per install. That's fine for testing.

### Testing the subscription without a developer account
The shared scheme uses `FortiumAIAcademy/Products.storekit`, so purchases are **simulated locally** when you run from Xcode. You can buy, cancel and refund test purchases from *Debug → StoreKit → Manage Transactions*.
If the paywall says "options unavailable", check *Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration* is set to `Products.storekit`.

Debug builds also have **Settings → Developer → Unlock Pro (testing only)** to preview locked content instantly. This switch is compiled out of App Store builds.

---

## Editing the course

All lesson content lives in **`FortiumAIAcademy/Content/course.json`**. You don't need to touch Swift to fix a typo, add a lesson, or update a feature that Claude changed.

- Card kinds: `text`, `tip`, `warning`, `steps` (with `items`), `example` (with `prompt`), `compare` (with `bad`/`good`), `tryIt` (with optional `prompt`), `screenshot` (with `image`, `platform` and optional numbered `highlights`). See **SCREENSHOTS.md** for the 23-shot list and how to add them.
- Inline `**bold**` and `_italic_` work in any text.
- After editing, run `python3 scripts/validate_content.py` to catch mistakes (also runs in CI).
- Don't rename a lesson `id` after launch. Learner progress is stored by id.

Prompt Builder goals are in `FortiumAIAcademy/PromptBuilder/PromptGoal.swift`.

---

## Project structure

```
FortiumAIAcademy/
  App/            App entry, tabs, AppConfig (product IDs, URLs, disclaimer)
  Theme/          Fortium colors, typography, cards, buttons, chips, progress views
  Models/         Course model + loader, ProgressStore (XP/streaks/badges), Badge
  Store/          SubscriptionStore (StoreKit 2)
  PromptBuilder/  Goals catalog, prompt assembly + strength scoring, wizard UI, saved prompts
  Views/          Learn (home, sections), Lesson (cards, quiz), Celebration (confetti),
                  Progress (badges, certificate), Paywall, Settings, Onboarding
  Content/        course.json
  Products.storekit   Local StoreKit test configuration (not shipped in the app)
scripts/          validate_content.py, make_icon.py
.github/workflows CI: validates content + builds for the iOS Simulator on macOS
```

Everything is stored **on-device** (Application Support JSON + UserDefaults). There are no accounts, analytics or servers, so the App Store privacy label can be **"Data Not Collected"**.

---

## Launch checklist

1. **Apple Developer Program** ($99/yr), then set your *Team* in Signing & Capabilities.
2. In **App Store Connect**, create the app with bundle ID `com.fortiumgroup.aiacademy` (or change it in the target settings).
3. Create a subscription group **Academy Pro** with product IDs matching `AppConfig.swift`:
   `com.fortiumgroup.aiacademy.pro.monthly` and `com.fortiumgroup.aiacademy.pro.yearly` (add the 1-week free trial as an introductory offer).
4. Host a **privacy policy** and update `AppConfig.privacyPolicyURL` (it currently points to a placeholder). Update `supportEmail`.
5. Replace the placeholder icon (`Assets.xcassets/AppIcon.appiconset/AppIcon.png`, 1024×1024, no transparency) if you want a designer version.
6. Screenshots, description, keywords. App privacy: *Data Not Collected*.
7. **Trademark caution:** Apple reviews third-party trademarks closely. Keep "Claude" out of the app *name and icon*. Describe the app as an *independent guide* in the subtitle/description, and keep the in-app disclaimer.
8. Archive (*Product → Archive*) → Distribute → App Store Connect → submit for review.

---

## Ideas for v1.1
- Load `course.json` from a server so lessons update without an app release
- Real screenshots/short videos per lesson
- Daily reminder notifications to protect streaks
- "Prompt of the day" and more Prompt Builder goals tailored to the learner's onboarding interests
- Localization (Spanish, Hindi, …)
