# Task-Momma — iOS App (SwiftUI + Firebase)

The app source code lives in `TaskMomma/`. Start with `TaskMomma/README_TaskMomma.md` for Firebase + Xcode setup.

---

# Task Randomizer — Today's Work Session Guide

Here's a breakdown of what to tackle today, organized by priority.

---

## 1. Lock In Group Info (Do This First)

Email your professor and TA with everyone's names and a team name. This is a deliverable and it's easy — just do it now.

---
## 2. Nail Down the App Concept

Before touching any code or slides, make sure everyone agrees on exactly what the app is. For Task Randomizer, the core loop is:

- User creates "tasks" tagged with a duration (30s, 1min, 5min, 10min, etc.)
- When they have a spare moment, they open the app and it surfaces a random task matching that time window
- They complete it (or skip), and it logs the result

The "communication component" you'll need — think about which makes sense. The easiest win here is **HTTP/JSON to/from a server**: tasks are stored remotely, and the app fetches a random one from your backend. This also satisfies the "delivered from a remote location" requirement for mocked data.

---

## 3. Define Your Screens (5–10 required)

Here's a natural set for this app:

1. **Onboarding / Welcome** — first-time setup
2. **Home / Dashboard** — shows current streak, last completed task, a "I have X minutes" button
3. **Time Selector** — pick your available time window
4. **Task Reveal** — the randomized task for that time slot, with a Start / Skip button
5. **Active Task / Timer** — countdown timer while doing the task
6. **Task Complete** — confirmation/celebration screen, log the completion
7. **Task Library** — browse all your tasks
8. **Add / Edit Task** — create a task with name, duration, category
9. **History / Stats** — log of completed tasks, streaks
10. **Settings** — notification preferences, account stuff

That's exactly 10. You can cut Settings or History to simplify if needed.

---

## 4. Write Your Core User Stories

Write these out today — they're the backbone of your pitch deck. Here's a starter set:

**Core (commit to these):**
- "As a user, I want to set my available time so that I get a task that fits my schedule."
- "As a user, I want to be shown a random task so that I don't have to decide what to do."
- "As a user, I want a countdown timer so that I know when my task is done."
- "As a user, I want to create and save tasks so that I can build a personal task library."
- "As a user, I want to mark a task complete so that my progress is tracked."
- "As a user, I want my tasks stored remotely so that they sync across devices."

**Optional / Extra Credit:**
- "As a user, I want push notifications so that I'm reminded to use idle time productively."
- "As a user, I want to see my completion history so that I can track my habits over time."
- "As a user, I want to categorize tasks (health, learning, etc.) so that I can filter by type."
- "As a user, I want to share a task with a friend so that we can do challenges together." *(this could be your P2P/SMS communication angle)*

---

## 5. Decide on Tech Stack

Since you normally use Claude Code, you're probably on **iOS (Swift/SwiftUI)** or **Android (Kotlin/Jetpack Compose)** — confirm this as a group today. Also decide:

- **Backend**: A simple REST API (even a free tier on Railway, Render, or Supabase) to store and serve tasks as JSON. This is your communication component.
- **Who owns what screen**: Divide the 8–10 screens across 3–5 people now, not later.

---

## 6. Start the Pitch Deck

The PDF is due before pitch day. Get a skeleton going today with:

- App name + one-line description
- The problem (doom scrolling in dead time)
- Your solution (randomized micro-tasks)
- Your core user stories list
- A rough screen flow / wireframe sketch (even hand-drawn is fine for now)
- Team names and roles

---

## Today's Checklist Summary

- [ ] Send group info email to professor + TA
- [ ] Agree on final app concept and tech stack as a group
- [ ] Finalize your screen list (pick 8–10)
- [ ] Write out all core user stories (aim for 5–6)
- [ ] Assign screens/features to team members
- [ ] Start pitch deck skeleton
- [ ] Spin up a repo and share access with everyone
