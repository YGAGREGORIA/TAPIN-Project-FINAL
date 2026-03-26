# TAPIN-Project-FINAL
TAPIN AI Software Development-  Le wagon final project.
# TapIn 🏋️

A full-stack loyalty and engagement platform for fitness studios — built with Rails 8, Hotwire, and modern web technologies.

## Overview

TapIn helps fitness studios build stronger relationships with their members through a smart loyalty system, seamless check-ins, class bookings, and personalized AI-powered experiences.

## Features

### 🏷️ Loyalty & Rewards
- Points and stamp-card based reward system
- Members earn rewards based on visit milestones
- QR code reward redemption at the studio

### 📲 Check-In System
- **NFC tag check-in** — members tap their phone to check in instantly
- **QR code check-in** — fallback for all devices
- Real-time check-in confirmation via WebSockets (Action Cable)

### 📅 Class Bookings
- Browse and book studio classes
- MindBody API integration for class and client sync
- Automated booking reminders sent 2 hours before class

### 🔔 Push Notifications (PWA)
- Progressive Web App with full push notification support
- Smart notification triggers:
  - Close to a reward (1–2 visits away)
  - Booking reminders (2 hours before class)
  - Deal expiry alerts (3 days before)
  - Re-engagement after 14 days of inactivity

### 🤖 AI Assistant
- Conversational assistant powered by **GPT-4o-mini**
- Personalized responses using live member context (visit history, points balance, active bookings, referral status)
- Supports streaming responses (SSE), multimodal input (text + images), and persistent chat history

### 🎨 AI Branding Engine
- Scrapes studio websites to extract brand colors and visual identity
- Feeds signals to **Claude Sonnet** to generate 3 tailored brand proposals
- Each proposal includes: color palette, typography, and tagline — returned as structured JSON

### 🛠️ Admin Dashboard
- Full member management and visit tracking
- Analytics overview
- Studio branding customization
- Deal and reward configuration

## Tech Stack

|
 Layer 
|
 Technology 
|
|
---
|
---
|
|
 Backend 
|
 Ruby on Rails 8 
|
|
 Frontend 
|
 Hotwire (Turbo + Stimulus) 
|
|
 Database 
|
 PostgreSQL 
|
|
 Real-time 
|
 Action Cable (WebSockets) 
|
|
 Background Jobs 
|
 Sidekiq 
|
|
 AI 
|
 OpenAI GPT-4o-mini, Anthropic Claude Sonnet, RubyLLM 
|
|
 Push Notifications 
|
 Web Push API (PWA) 
|
|
 External APIs 
|
 MindBody API 
|
|
 Auth 
|
 Devise + OAuth (Google, Facebook, Apple) 
|

## AI Features Detail

### Conversational Assistant
Uses dynamic system prompts that inject real-time member data into every conversation, making the assistant context-aware and personalized per user.

### Branding Proposal Engine
1. Scrapes studio URL using `Net::HTTP`
2. Parses CSS stylesheets and HTML meta tags to extract brand signals
3. Sends structured prompt to Claude Sonnet
4. Returns 3 brand proposals as structured JSON

## Getting Started

```bash
# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Start the server
bin/dev

Environment Variables
DATABASE_URL=
OPENAI_API_KEY=
ANTHROPIC_API_KEY=
MINDBODY_API_KEY=
VAPID_PUBLIC_KEY=
VAPID_PRIVATE_KEY=
