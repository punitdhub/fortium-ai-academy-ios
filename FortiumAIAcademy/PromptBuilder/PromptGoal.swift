import SwiftUI

/// A starting point in the Prompt Builder ("Write an email", "Plan something", ...).
/// Each goal tailors the questions, examples, and the final prompt wording.
struct PromptGoal: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: String
    let isFree: Bool
    /// Opening line that frames Claude's role, e.g. "You are a skilled business writer."
    let role: String
    let taskQuestion: String
    let taskPlaceholder: String
    let taskExamples: [String]
    let contextPlaceholder: String
    let audiences: [String]
    let formats: [String]
    let extras: [String]

    var tint: Color { Color(hex: color) }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum PromptCatalog {
    static let tones = ["Friendly", "Professional", "Warm", "Confident", "Simple & clear",
                        "Persuasive", "Encouraging", "Formal", "Casual", "Funny"]

    static let lengths: [(label: String, phrase: String)] = [
        ("Short", "Keep it short — just the essentials."),
        ("Medium", "Aim for a medium length: complete but not long-winded."),
        ("Detailed", "Be thorough and detailed."),
    ]

    /// Habits that make almost any prompt better. Shown on every goal.
    static let universalExtras = [
        "Ask me questions first if anything is unclear",
        "Give me 2–3 options to choose from",
        "Use plain, everyday language (no jargon)",
        "Explain your thinking briefly at the end",
    ]

    static let goals: [PromptGoal] = [
        PromptGoal(
            id: "email", title: "Write an email", subtitle: "Clear, polished emails in seconds",
            icon: "envelope.fill", color: "#4A6C8C", isFree: true,
            role: "You are an expert at writing clear, effective emails.",
            taskQuestion: "What is the email about?",
            taskPlaceholder: "e.g. Ask my manager for Friday off next week",
            taskExamples: ["Ask my manager for a day off", "Follow up with a client who hasn't replied",
                           "Thank a colleague for their help", "Politely decline a meeting invitation"],
            contextPlaceholder: "e.g. My manager is busy this month, and I've already finished my project early.",
            audiences: ["My manager", "A client", "A colleague", "My team", "A company I'm buying from", "A friend"],
            formats: ["Email with subject line", "Short email (under 120 words)", "Email + a shorter text-message version"],
            extras: ["Include a clear subject line", "End with a clear next step or question"]
        ),
        PromptGoal(
            id: "summarize", title: "Summarize something", subtitle: "Long text → key points",
            icon: "doc.text.magnifyingglass", color: "#2E7D6B", isFree: true,
            role: "You are excellent at turning long information into clear, accurate summaries.",
            taskQuestion: "What do you want summarized?",
            taskPlaceholder: "e.g. The attached 20-page report on our sales results",
            taskExamples: ["A long document I'll attach", "Meeting notes I'll paste below",
                           "A news article", "An email thread"],
            contextPlaceholder: "e.g. I need to brief my boss in 2 minutes. Focus on decisions and numbers.",
            audiences: ["Myself", "My boss", "My team", "Someone with no background", "Customers"],
            formats: ["5 bullet points", "One short paragraph", "Key points + action items", "A simple table"],
            extras: ["Highlight any numbers, dates, or deadlines", "Say clearly if something is unclear or missing"]
        ),
        PromptGoal(
            id: "brainstorm", title: "Brainstorm ideas", subtitle: "Lots of fresh ideas, fast",
            icon: "lightbulb.fill", color: "#C9962E", isFree: true,
            role: "You are a creative, practical brainstorming partner.",
            taskQuestion: "What do you need ideas for?",
            taskPlaceholder: "e.g. Names for my new bakery",
            taskExamples: ["Names for a new business", "Gift ideas for my dad", "Team-building activities",
                           "Ways to get more customers"],
            contextPlaceholder: "e.g. Small budget, a neighborhood bakery known for sourdough.",
            audiences: ["Myself", "My customers", "My team", "My family", "Kids"],
            formats: ["List of 10 ideas", "Ideas grouped by theme", "Top 5 with pros and cons"],
            extras: ["Include a few bold, unusual ideas", "Mark your top pick and say why"]
        ),
        PromptGoal(
            id: "explain", title: "Explain something", subtitle: "Understand any topic simply",
            icon: "questionmark.bubble.fill", color: "#8978AF", isFree: true,
            role: "You are a patient teacher who explains things simply, using everyday examples.",
            taskQuestion: "What would you like explained?",
            taskPlaceholder: "e.g. How a retirement account works",
            taskExamples: ["How a 401(k) works", "What 'the cloud' means", "How inflation affects my savings",
                           "A term from my doctor's report"],
            contextPlaceholder: "e.g. I'm 60 and new to this. I don't know any of the technical terms.",
            audiences: ["Me — a complete beginner", "Me — I know the basics", "My child", "My parents"],
            formats: ["Simple explanation + an everyday example", "Step-by-step", "Questions & answers"],
            extras: ["Use an everyday analogy", "End with a quick check-my-understanding question"]
        ),
        PromptGoal(
            id: "customer", title: "Reply to a customer", subtitle: "Kind, professional responses",
            icon: "person.2.wave.2.fill", color: "#3A7CA5", isFree: false,
            role: "You are a warm, professional customer service expert for a small business.",
            taskQuestion: "What did the customer say or ask?",
            taskPlaceholder: "e.g. A customer is upset their order arrived late",
            taskExamples: ["Upset about a late delivery", "Asking for a refund", "Left a great review",
                           "Asking about our prices"],
            contextPlaceholder: "e.g. We're a family-run shop. We can offer 10% off their next order.",
            audiences: ["An upset customer", "A happy customer", "A potential customer", "A long-time client"],
            formats: ["Email reply", "Short message (chat or text)", "Public reply to an online review"],
            extras: ["Apologize sincerely without over-promising", "Include a clear next step"]
        ),
        PromptGoal(
            id: "social", title: "Social media post", subtitle: "Posts people actually read",
            icon: "megaphone.fill", color: "#D9643A", isFree: false,
            role: "You are a social media writer who creates engaging, authentic posts.",
            taskQuestion: "What is the post about?",
            taskPlaceholder: "e.g. Announcing our new weekend opening hours",
            taskExamples: ["Announce a new product", "Share a milestone or achievement",
                           "Promote an upcoming event", "Share a helpful tip"],
            contextPlaceholder: "e.g. We're a local fitness studio. Our followers are busy parents.",
            audiences: ["Local customers", "Professionals on LinkedIn", "Young adults", "Parents", "Everyone"],
            formats: ["LinkedIn post", "Instagram caption", "Facebook post", "3 versions for different platforms"],
            extras: ["Suggest 3–5 relevant hashtags", "Add a call to action at the end"]
        ),
        PromptGoal(
            id: "plan", title: "Plan something", subtitle: "Trips, events, schedules, projects",
            icon: "calendar.badge.clock", color: "#2E7D52", isFree: false,
            role: "You are an organized, practical planner.",
            taskQuestion: "What do you want to plan?",
            taskPlaceholder: "e.g. A 4-day family trip to San Diego",
            taskExamples: ["A family vacation", "A weekly meal plan", "My week at work",
                           "A small birthday party"],
            contextPlaceholder: "e.g. Two adults and two kids (6 and 9). Budget around $2,000. We love beaches.",
            audiences: ["Myself", "My family", "My team", "A group of friends"],
            formats: ["Day-by-day plan", "Checklist", "Table with times and costs", "Step-by-step timeline"],
            extras: ["Include estimated costs", "Add a backup option in case plans change"]
        ),
        PromptGoal(
            id: "document", title: "Create a document", subtitle: "Reports, letters, proposals",
            icon: "doc.richtext.fill", color: "#5C7B96", isFree: false,
            role: "You are a skilled professional writer who creates well-organized documents.",
            taskQuestion: "What document do you need?",
            taskPlaceholder: "e.g. A one-page proposal for a new office coffee service",
            taskExamples: ["A one-page proposal", "A cover letter", "A policy for my small team",
                           "A formal letter"],
            contextPlaceholder: "e.g. It's for our 15-person office. Main benefit: saves time and money.",
            audiences: ["My boss", "A client", "My team", "A hiring manager", "The public"],
            formats: ["Document with headings", "One-page summary", "Downloadable Word document", "Formal letter"],
            extras: ["Start with a short summary at the top", "Leave [brackets] where I need to fill in details"]
        ),
        PromptGoal(
            id: "presentation", title: "Make a presentation", subtitle: "Slides with a clear story",
            icon: "rectangle.on.rectangle.angled", color: "#A87F40", isFree: false,
            role: "You are an expert presentation designer and storyteller.",
            taskQuestion: "What is your presentation about?",
            taskPlaceholder: "e.g. Our quarterly results for the leadership team",
            taskExamples: ["Quarterly results update", "A pitch for a new idea", "Training for new staff",
                           "A talk at a community event"],
            contextPlaceholder: "e.g. 10 minutes long. Sales grew 12% but costs also rose.",
            audiences: ["Leadership", "My team", "Customers", "Investors", "A general audience"],
            formats: ["Slide-by-slide outline", "A slide deck I can download", "Outline + speaker notes"],
            extras: ["Keep each slide to 3–4 short points", "Suggest a simple visual for each slide"]
        ),
        PromptGoal(
            id: "data", title: "Understand data", subtitle: "Make sense of spreadsheets & numbers",
            icon: "chart.bar.xaxis", color: "#3F8F8C", isFree: false,
            role: "You are a friendly data analyst who explains findings in plain English.",
            taskQuestion: "What data do you want help with?",
            taskPlaceholder: "e.g. My monthly sales spreadsheet (I'll attach it)",
            taskExamples: ["A sales spreadsheet I'll attach", "My household budget",
                           "Survey results", "Website visitor numbers"],
            contextPlaceholder: "e.g. I want to know which products are growing and which are slowing down.",
            audiences: ["Myself", "My boss", "My team", "Investors"],
            formats: ["Key findings in bullet points", "A simple chart", "A table + short summary"],
            extras: ["Point out anything surprising", "Suggest 2–3 actions based on the data"]
        ),
        PromptGoal(
            id: "improve", title: "Improve my writing", subtitle: "Edit, proofread, rephrase",
            icon: "pencil.and.outline", color: "#7A5C96", isFree: false,
            role: "You are a careful, supportive editor.",
            taskQuestion: "What would you like improved?",
            taskPlaceholder: "e.g. My LinkedIn 'About' section (pasted below)",
            taskExamples: ["An email I wrote", "My resume summary", "A report draft", "A speech"],
            contextPlaceholder: "e.g. It sounds too stiff. I want it to sound friendly but still professional.",
            audiences: ["My boss", "Customers", "A hiring manager", "Friends and family", "The public"],
            formats: ["Improved version only", "Improved version + list of changes", "Two alternative versions"],
            extras: ["Keep my voice — don't make it sound robotic", "Fix grammar and spelling"]
        ),
        PromptGoal(
            id: "career", title: "Job & career help", subtitle: "Resumes, interviews, growth",
            icon: "briefcase.fill", color: "#4A6C8C", isFree: false,
            role: "You are an experienced career coach and recruiter.",
            taskQuestion: "What career help do you need?",
            taskPlaceholder: "e.g. Prepare me for an interview for a project manager role",
            taskExamples: ["Practice interview questions", "Tailor my resume to a job post",
                           "Write a cover letter", "Plan my next career move"],
            contextPlaceholder: "e.g. 8 years in retail, moving into project management. The job post is pasted below.",
            audiences: ["A hiring manager", "A recruiter", "My current boss", "Myself"],
            formats: ["Practice Q&A — ask me one question at a time", "Rewritten resume bullets", "Step-by-step plan"],
            extras: ["Give me honest feedback", "Use examples from my experience"]
        ),
        PromptGoal(
            id: "learn", title: "Learn a new skill", subtitle: "A personal tutor, any topic",
            icon: "book.fill", color: "#2E7D6B", isFree: false,
            role: "You are a patient, encouraging tutor.",
            taskQuestion: "What do you want to learn?",
            taskPlaceholder: "e.g. The basics of Excel formulas",
            taskExamples: ["Excel basics", "Conversational Spanish", "Public speaking", "Basic budgeting"],
            contextPlaceholder: "e.g. Total beginner. I have 15 minutes a day for the next two weeks.",
            audiences: ["Me — a total beginner", "Me — some experience", "My child"],
            formats: ["A 2-week learning plan", "Lesson 1 to start right now", "Quiz me one question at a time"],
            extras: ["Check my understanding as we go", "Give me a small practice task"]
        ),
        PromptGoal(
            id: "decide", title: "Make a decision", subtitle: "Think it through clearly",
            icon: "arrow.triangle.branch", color: "#B26A1E", isFree: false,
            role: "You are a thoughtful, balanced advisor who helps people think through decisions.",
            taskQuestion: "What are you deciding?",
            taskPlaceholder: "e.g. Whether to lease or buy a car",
            taskExamples: ["Lease or buy a car", "Which job offer to accept", "Whether to hire help for my business",
                           "Which laptop to buy"],
            contextPlaceholder: "e.g. I drive about 15,000 miles a year and like to keep cars a long time.",
            audiences: ["Myself", "My family", "My business partner"],
            formats: ["Pros and cons table", "Side-by-side comparison", "A recommendation with reasons"],
            extras: ["Ask me about my priorities first", "Point out risks I might be missing"]
        ),
    ]
}
