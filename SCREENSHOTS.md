# Screenshot shot list

Lessons have **23 screenshot slots**. Until a screenshot is added, debug builds show a dashed "Screenshot needed" placeholder and App Store builds hide the card, so the app works at any stage.

## Before you start (5 minutes)

1. **Use a clean account or a fresh chat.** Every screenshot will be seen by every learner. Make sure no real names, emails, client details or private chats are visible. Rename or hide sidebar chats that are personal (or use a separate demo account).
2. **Light mode** for consistency: in Claude, go to *Settings → Appearance → Light*. On iPhone, also turn off Dark Mode.
3. **Use friendly example content**, like the prompts from the lessons (birthday party plan, email to a manager, chore chart).
4. **Web screenshots:** use a browser window about 1400 px wide, zoom at 100%, and capture just the window (Mac: **⌘ ⇧ 4**, then press **Space**, then click the window).
5. **iPhone screenshots:** press **Side button + Volume Up**.

## How to add them

**Option A (easiest):** upload the screenshots in our chat. I'll name, resize, crop and add the numbered callouts for you.

**Option B (do it yourself):**
1. Name each file exactly as below and put them all in one folder.
2. Run `python3 scripts/add_screenshots.py path/to/that/folder`.
3. Run `python3 scripts/validate_content.py` to see what's still missing.
4. Commit and push. CI builds the app and refreshes the simulator screenshots.

Callouts (the numbered gold boxes) are set in `course.json` under each card's `highlights`, with positions given as fractions of the image (`x`, `y`, `w`, `h` from 0 to 1) and a `label`. If you go with Option A, I'll add these.

## The list

| # | File name | Where | What to capture | Callouts to add |
|---|---|---|---|---|
| 1 | `claude-first-reply.png` | iPhone app | A short chat: your "Hi Claude, I'm new to AI…" message and Claude's reply | Your message · Claude's reply · message box |
| 2 | `claude-app-store.png` | iPhone App Store | The Claude app's App Store page, showing **Anthropic** as the developer | Developer name · Get button |
| 3 | `claude-new-chat.png` | iPhone app | A brand-new empty chat | Message box · send button · menu/past chats |
| 4 | `claude-new-chat-web.png` | Web (claude.ai) | A new chat on claude.ai with the sidebar visible | Sidebar with chats · message box · New chat |
| 5 | `claude-edit-retry.png` | Web | A chat where you're hovering over your message, showing the edit (pencil) icon, plus the retry icon under Claude's reply | Edit icon · retry icon |
| 6 | `claude-plus-menu.png` | Web | The message box with the **+** menu open | + button · Upload a file · tools |
| 7 | `claude-camera-option.png` | iPhone app | The **+** menu open, showing camera and photos | Camera · Photos |
| 8 | `claude-file-download.png` | Web | A chat where Claude created a spreadsheet or document, showing the file and download option | The file · download button |
| 9 | `claude-projects-list.png` | Web | The Projects page with 2–3 example projects (e.g. "Job Search", "Family Meals") | New project button · a project |
| 10 | `claude-project-knowledge.png` | Web | Inside a project, showing instructions and knowledge files | Instructions · knowledge files · start a chat |
| 11 | `claude-artifact-panel.png` | Web | A chat with an artifact (like the chore chart) open in the side panel | The chat · the artifact panel |
| 12 | `claude-artifact-edit.png` | Web | A Doc artifact with some text highlighted and the edit option showing | Highlighted text · edit box |
| 13 | `claude-artifact-share.png` | Web | The Share/Publish dialog for an artifact | Visibility setting · copy link |
| 14 | `claude-search-sources.png` | Web | An answer that used web search, with source citations visible | A citation · the sources list |
| 15 | `claude-research-report.png` | Web | A Research request in progress or the finished report | Progress/steps · citations |
| 16 | `claude-connectors-settings.png` | Web | *Settings → Connectors* page | A connector · Connect button |
| 17 | `claude-cowork-task.png` | Desktop app | A Cowork task in progress, showing its steps | Task steps · stop/pause control |
| 18 | `claude-memory-settings.png` | Web | *Settings → Memory* (with harmless example memories) | Memory toggle · a memory topic |
| 19 | `claude-incognito.png` | Web | A new chat with incognito mode turned on | Incognito icon/indicator |
| 20 | `claude-style-picker.png` | Web | The styles menu open | Style list · create a style |
| 21 | `claude-model-picker.png` | Web | The model picker open | Model menu · default model |
| 22 | `claude-voice-mode.png` | iPhone app | Voice mode active | Voice button · end button |
| 23 | `claude-privacy-settings.png` | Web | *Settings → Privacy* | The "help improve Claude" setting · delete/export options |

## A note on using Claude's screens

Showing a product's screens in order to teach people how to use it is common practice for tutorials. To stay on safe ground:
- keep the "independent, not affiliated with Anthropic" disclaimer
- don't use Claude's logo as your app's branding
- keep screenshots unedited apart from cropping and the callouts

Claude's design changes from time to time, so plan to refresh these screenshots every few months. The validator shows which ones are missing.
