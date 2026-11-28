# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Stack

SwiftUI + SwiftData, iOS 17+, iPhone only. Offline, no backend, no accounts.

## Users

Groups of Argentine friends and families who play Generala, Burako or Truco at the table (barbecues, get-togethers, after-dinner conversations, often at night). One person acts as the **scorekeeper**: holding the phone or leaving it on the table and scoring while playing and chatting. Everyone else glances at the screen now and then to see how the Match is going.

## Product Purpose

Replace pen and paper (or the beans and the matchsticks) for keeping score in Generala, Burako and Truco. It succeeds when the scorekeeper enters each Hand in seconds, without mistakes and without taking attention away from the table, and when it is clear who won at the end of the Match.

## Positioning

- **Real Argentine rules**: the standard Argentine Variant of each Game and its local vocabulary (malas and buenas, servido, tachar), not translated generic rules.
- **Zero friction**: open and score in seconds. Free, no accounts, no ads, no in-app purchases and no internet.
- **Remembers the crew**: saved, reusable Players, plus a History of Matches with the usual people.

## Operating Context

- Used at the table, with one hand and between plays, sometimes in low light.
- Truco: one scorekeeper tracks the points of two Teams with Matchsticks (malas and buenas). Each call is not recorded.
- Generala: classic Scoresheet with Players in columns, Served and Scratch.
- Burako: scoring per Hand, individual or in pairs.
- Domain glossary: `GLOSSARY.md`.

## Capabilities and Constraints

- MVP: Match in progress, a simple History and saved Players.
- The whole app is in Spanish, with a warm Rioplatense tone.
- The model must allow adding more Games later.
- Distribution: TestFlight for the MVP and the App Store later.
- Out of scope: statistics, iCloud sync, iPad, Apple Watch and other Games.
- The rules of the three Games, the model and the screens are settled in `docs/SPEC.md`.

## Brand Commitments

- Name: **Porotos**. App Store subtitle: "Anotador de juegos de mesa" (board-game scorekeeper). Bundle ID: `com.facundocapua.porotos`.
- "Porotos" (beans) alludes to the beans used in Argentina to count points.
- There are no previous visual assets or visual constraints.

## Evidence on Hand

None yet. There are no users, testimonials or screenshots. They must not be invented.

## Product Principles

1. **The table first**: the scorekeeper looks at the screen for a second and goes back to the conversation.
2. **Talk like at the table**: use the terms people already say, not app jargon.
3. **Nothing between opening and scoring**: no accounts, no notices, no avoidable steps.
4. **Each Game in its own way**: each Game is scored in its own way, not with a generic table for all of them.

## Accessibility & Inclusion

Readable at arm's length and in low light, and usable with one hand. WCAG AA, Dynamic Type, full VoiceOver and always-dark Game worlds. Details are in `DESIGN.md`.
