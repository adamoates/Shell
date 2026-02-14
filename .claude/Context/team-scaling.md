# Team Scaling Guide

**How to grow your engineering team without slowing down**

This guide applies to products built on Shell architecture.

---

## Core Principles

### 1. Product-First Culture
Engineers own outcomes, not just code.

### 2. Vertical Ownership
Each engineer/team owns a complete domain, not a layer.

### 3. Small Teams
2-3 engineers per domain. More doesn't help.

### 4. Testing Culture
Tests enable fast, safe iteration at scale.

### 5. Clear Accountability
Every domain has one owner. No shared ownership.

---

## Scaling Stages

### Stage 1: Founder + 1 Engineer (2 people)

**Structure:**
- Founder: Product + Strategy
- Engineer: Everything technical

**Workflow:**
- Build one feature at a time
- Weekly releases
- Direct communication

**Challenges:**
- Founder becomes bottleneck
- Engineer context-switches constantly

**When to scale:**
- Backlog of validated features
- Revenue justifies cost
- Engineer at capacity

---

### Stage 2: Small Team (3-5 engineers)

**Structure:**
- Product Owner (founder or PM)
- 2-3 Full-Stack Engineers
- 1 Platform Engineer (optional)

**Domain Split:**

**Engineer 1: Identity & Trust**
- Auth
- Permissions
- Security
- Account management

**Engineer 2: Core Domain**
- Main feature (dogs, notes, habits)
- Business logic
- Domain-specific UI

**Engineer 3: Growth & Infrastructure**
- Onboarding
- Notifications
- Analytics
- CI/CD

**Workflow:**
- Weekly sprint planning
- Daily standups (15 min)
- Feature ownership
- Bi-weekly demos

**Challenges:**
- Overlapping work
- Blocked dependencies
- Context switching

**When to scale:**
- Multiple product streams
- Established PMF
- Clear revenue growth

---

### Stage 3: Feature Teams (6-10 engineers)

**Structure:**
- Product Manager
- 2-3 Feature Teams (2-3 engineers each)
- 1 Platform Team (1-2 engineers)

**Domain Ownership Model:**

**Team 1: Identity & Trust**
- Auth and security
- User management
- Roles and permissions
- Account lifecycle

**Team 2: Core Product (e.g., Dog Care)**
- Dog profiles
- Care routines
- Scheduling
- Relationships

**Team 3: Transactions (e.g., Bookings & Payments)**
- Booking engine
- Payment processing
- Invoicing
- Refunds

**Platform Team:**
- CI/CD
- Infrastructure
- Shared libraries
- Developer tools

**Workflow:**
- Each team owns their OKRs
- Weekly team planning
- Bi-weekly cross-team sync
- Monthly demos

**Challenges:**
- Coordination overhead
- Dependency management
- Platform bottlenecks
- Knowledge silos

**When to scale:**
- Multiple product lines
- International expansion
- Platform stability required

---

### Stage 4: Multiple Products (10+ engineers)

**Structure:**
- Multiple product teams
- Shared platform team
- Dedicated DevOps/SRE

**Not covered here. Hire a VP of Engineering.**

---

## Domain Ownership Examples

### Example: Dog Care App

**Identity & Trust Team**
- User registration
- Login/logout
- Password reset
- Profile management
- Family accounts
- Permissions
- Background checks (sitters)

**Dogs & Care Team**
- Dog profiles
- Medical records
- Vaccination tracking
- Care routines
- Feeding schedules
- Medication reminders

**Booking & Scheduling Team**
- Booking requests
- Availability
- Pickup/dropoff
- Status tracking
- Calendar integration
- Recurring bookings

**Payments & Billing Team**
- Payment processing
- Invoicing
- Refunds
- Payouts (sitters)
- Subscription management

**Growth Team**
- Onboarding flows
- Notifications
- Referrals
- In-app messaging
- Analytics

---

## Vertical Ownership Model

Each team owns:

### End-to-End
- Domain layer
- Infrastructure layer
- Presentation layer
- Tests
- Deployment

### Quality
- Code quality
- Test coverage
- Performance
- Bug fixes

### Product Outcomes
- Feature delivery
- User metrics
- A/B tests
- Customer feedback

**Not:**
- ❌ Frontend team + Backend team
- ❌ iOS team + Android team
- ❌ Infrastructure team for all domains

**Why:**
- Eliminates handoffs
- Reduces coordination overhead
- Increases ownership
- Speeds up delivery

---

## Hiring Strategy

### Early Stage (0-5 engineers)

**Hire: Product Engineers**

Skills:
- Full-stack mindset
- Comfortable with ambiguity
- Strong ownership
- Fast learners
- Pragmatic, not dogmatic

**Avoid:**
- Specialists (iOS-only, backend-only)
- Architecture astronauts
- Process-heavy engineers

**Interview for:**
- Can they ship features end-to-end?
- Do they prioritize user value?
- Are they comfortable with testing?
- Can they work independently?

---

### Growth Stage (5-15 engineers)

**Hire: Domain Experts**

As domains mature, hire specialists:
- Payments expert (Stripe, compliance)
- Security engineer (auth, encryption)
- Performance engineer (if needed)

**Still prefer:**
- Product engineers who can own full domains

---

### Scale Stage (15+ engineers)

**Hire: Platform Engineers**

Focus on:
- Infrastructure (CI/CD, monitoring)
- Shared libraries (design systems, SDK)
- DevOps/SRE
- Developer productivity

---

## Testing Culture

### Why Tests Matter at Scale

Without tests:
- Fear of changing code
- Slow releases
- Manual QA bottleneck
- Regressions

With tests:
- Confidence to refactor
- Fast releases
- Automated QA
- Catch regressions

### Test Ownership

Each team owns:
- Unit tests (domain, ViewModels)
- Integration tests (repositories, APIs)
- UI tests (critical paths only)

Platform team owns:
- Test infrastructure
- CI/CD pipeline
- Test performance

---

## Communication Model

### Async-First

**Default to async:**
- Slack/written updates
- Design docs
- RFCs for big decisions

**Synchronous only when:**
- Brainstorming needed
- Conflict resolution
- Urgent blockers

### Weekly Rituals

**Team Level (15-30 min):**
- Monday: Sprint planning
- Friday: Demo and retro

**Company Level (30 min):**
- Friday: All-hands demo

**Avoid:**
- Daily status meetings (use Slack)
- Weekly 1:1s for status (async instead)

---

## Knowledge Sharing

### Documentation

Each team maintains:
- Domain README (what they own)
- API documentation
- Architecture decisions (ADRs)

### Cross-Team Learning

Monthly:
- Tech talks (30 min)
- Architecture review
- Post-mortems

Quarterly:
- Hackathon or innovation week
- Team offsites

---

## Scaling Anti-Patterns

### ❌ Hire Before Product-Market Fit

**Problem:**
- Premature scaling
- High burn rate
- Wrong skills hired

**Solution:**
- Wait until backlog is clear
- Revenue justifies cost

---

### ❌ Hire Specialists Too Early

**Problem:**
- Narrow skill sets
- Coordination overhead
- Slow iteration

**Solution:**
- Hire product engineers first
- Specialists only when domain is mature

---

### ❌ Split by Technology (Frontend/Backend)

**Problem:**
- Handoffs slow delivery
- Blame games
- No end-to-end ownership

**Solution:**
- Split by domain, not technology
- Full-stack teams

---

### ❌ Too Much Process

**Problem:**
- Slow decision making
- Bureaucracy
- Frustrates engineers

**Solution:**
- Lightweight process
- Async-first communication
- Trust and autonomy

---

### ❌ Shared Code Ownership

**Problem:**
- No accountability
- Code degrades
- Nobody owns quality

**Solution:**
- Clear domain ownership
- Code reviews, not shared ownership

---

## Decision-Making Framework

### Team-Level Decisions

Teams decide:
- Technical implementation
- Architecture within domain
- Library choices
- Testing strategy

**No approval needed.**

### Cross-Team Decisions

Requires consensus:
- Shared data models
- API contracts
- Infrastructure changes

**Process:**
- Write RFC
- Get feedback async
- Decide in 1 week max

### Company-Level Decisions

Requires leadership approval:
- New product lines
- Major tech stack changes
- Security/compliance

**Process:**
- Proposal document
- Leadership review
- Decision in 2 weeks max

---

## Tools Recommendations

### Small Team (1-5)
- GitHub/GitLab
- Slack
- Linear/GitHub Issues
- Vercel/Heroku (simple deploys)

### Growing Team (5-15)
- GitHub Actions or CircleCI
- Slack + Notion/Confluence
- Linear or Jira
- AWS/GCP (infrastructure control)
- PagerDuty or OnCall

### Scale (15+)
- Full CI/CD pipeline
- Monitoring (Datadog, New Relic)
- Feature flags (LaunchDarkly)
- APM and observability

---

## Red Flags (You're Scaling Wrong)

### Warning Signs

🚨 **Meetings dominate calendars**
→ Too much synchronous communication

🚨 **Engineers blocked frequently**
→ Too many dependencies

🚨 **Deployment takes hours/days**
→ CI/CD is broken

🚨 **Fear of changing code**
→ Not enough tests

🚨 **Unclear ownership**
→ No domain boundaries

🚨 **Constant firefighting**
→ Technical debt or quality issues

🚨 **Engineers frustrated**
→ Too much process or unclear goals

---

## Summary

### Key Principles

1. **Vertical ownership** - Teams own domains, not layers
2. **Product engineers first** - Full-stack, pragmatic, ship-focused
3. **Testing culture** - Enables speed at scale
4. **Async-first** - Minimizes coordination overhead
5. **Clear accountability** - One owner per domain

### Scaling Path

- **Stage 1:** Founder + 1 engineer
- **Stage 2:** 3-5 product engineers (domain split)
- **Stage 3:** 6-10 engineers (feature teams)
- **Stage 4:** 10+ engineers (platform team, multiple products)

### Avoid

- ❌ Scaling before PMF
- ❌ Specialists too early
- ❌ Frontend/backend split
- ❌ Too much process
- ❌ Shared ownership

---

**Last Updated:** 2026-02-14
**Use this guide:** When growing your team from 1 to 15 engineers
