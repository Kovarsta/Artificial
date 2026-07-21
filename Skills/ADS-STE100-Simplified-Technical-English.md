---
name: technical-writing-ste100
description: Write or rewrite technical documentation (manuals, procedures, SOPs, how-to guides, API docs, help articles, runbooks, installation instructions, troubleshooting guides) so it reads like plain, precise, professional technical writing instead of generic AI-generated prose. Applies the core discipline of ASD-STE100 Simplified Technical English (STE) — one word per meaning, short sentences, active voice, one instruction per step, concrete nouns and approved verbs. Use this whenever the user asks for documentation, a user guide, a manual, step-by-step instructions, a knowledge-base article, or asks to make existing writing "clearer," "simpler," "less bloated," or "not sound like AI." Also use when the user explicitly mentions STE, Simplified Technical English, ASD-STE100, or controlled language.
---

# Technical Writing with Simplified Technical English (STE) Discipline

## Why this works

Most "AI-sounding" technical writing has a specific, fixable failure pattern: it hedges with adverbs, stacks synonyms for the same idea, buries one instruction inside a 40-word sentence, switches between "click," "select," "choose," and "press" for the same action, and narrates in passive voice ("the file should be saved") instead of saying who does what ("save the file").

ASD-STE100 is the aerospace/defense industry's real, decades-old standard for eliminating exactly this kind of ambiguity in maintenance manuals — because confusing instructions on an aircraft get people killed. It is not a style suggestion; it's a controlled language with ~900 approved words and roughly 50 grammar/style rules. Claude does not need to reproduce the actual proprietary word list to get the benefit. Applying the *discipline* underneath it — one term per concept, short sentences, active voice, literal instructions — is what kills AI-slop phrasing. This skill distills that discipline into rules Claude can apply directly.

## When to apply this

- Any request for a manual, guide, SOP, runbook, README, onboarding doc, or step-by-step instructions
- Rewriting existing text to be "clearer," "simpler," "more professional," or "less like ChatGPT wrote it"
- API or developer documentation, troubleshooting guides, installation instructions
- Explicit mentions of STE / Simplified Technical English / ASD-STE100 / controlled language

Not a fit for marketing copy, narrative writing, creative content, or anything meant to persuade or entertain rather than instruct — STE actively removes the color and variety those forms need.

## The core rules to apply

### 1. One term, one meaning — pick a word and never swap it
Decide on one verb or noun for each recurring action or thing, and reuse that exact word every time. Do not vary vocabulary for "interest." If the first step says "select the menu," every later step says "select," never "click," "choose," or "pick." If a report calls it a "connector," never later call it a "plug," "port," or "adapter."

Before writing, make a short internal list of the key nouns and verbs in the task and commit to one spelling of each. Watch especially for these common synonym clusters and pick one:
- start / begin / initiate / commence → pick one (usually "start")
- verify / check / confirm / ensure / validate → pick one (usually "check" or "make sure")
- remove / delete / take out / eliminate → pick one
- click / select / choose / press → pick one per input type (e.g., "click" for mouse, "press" for physical/keyboard)

### 2. One instruction per sentence
Never join two actions with "and" or a comma into one instruction. Split them.

- Not this: "Open the panel, select the network tab, and then enter your password before clicking connect."
- This:
  1. Open the panel.
  2. Select the Network tab.
  3. Type your password.
  4. Click Connect.

### 3. Short sentences — hard ceiling around 20 words
If a sentence runs past ~20 words, it almost always contains two ideas. Split it into two sentences or a list. Descriptive/explanatory sentences can run slightly longer than instructions, but instructions should be as short as the action allows.

### 4. Active voice, and name the actor
Say who or what does the action. Avoid passive constructions that hide the actor.

- Not this: "The configuration file should be updated before the service is restarted."
- This: "Update the configuration file. Then restart the service."

### 5. Simple, consistent tense
Default to simple present for facts and simple imperative for instructions ("Press the button" not "You should press the button" or "The button will need to be pressed"). Avoid present perfect, future perfect, and conditional hedging ("would," "should," "might") in instructions — either the step is required or it isn't.

### 6. Concrete nouns, no vague pronouns
Repeat the noun instead of using "it," "this," or "that" when the referent could be ambiguous across a sentence or step boundary. Repetition of a plain noun is correct STE practice, not bad style — clarity beats variety.

### 7. No stacked modifiers or hedge words
Cut adverbs and qualifiers that add no operational meaning: "simply," "just," "easily," "basically," "essentially," "quite," "very," "in order to." If a step is not actually simple or easy, the word is also misleading.

### 8. One instruction, one expected result
Where it matters (troubleshooting, setup, safety-relevant steps), state the expected outcome right after the action so the reader can confirm they're on track: "Press the power button. The status light turns green."

### 9. Structure over prose
Prefer numbered steps for sequences, bullet lists for options, and short paragraphs (2-4 sentences) for explanation. Use headers to let readers jump to the step they need instead of reading linearly. Avoid narrating the same information in prose right after presenting it as a list.

### 10. Define specialized terms once, then reuse them
If a domain term is unavoidable and not common knowledge, define it in one short sentence at first use, then use only that term afterward.

## Workflow

1. **Identify the recurring nouns/verbs** in the source material or task and fix one term for each before drafting.
2. **Draft in imperative, active voice**, one action per sentence/step.
3. **Pass over the draft and cut**: synonyms for the same term, hedge words, passive constructions, sentences over ~20 words, joined instructions.
4. **Check consistency**: search the draft for any word you decided to standardize and confirm no synonym slipped in.
5. **If the user wants strict/formal STE compliance** (e.g., aerospace, defense, regulated industry deliverables), tell them this skill applies STE's writing discipline but is not a certified STE compliance check against the full approved-word dictionary, and that formal certification requires the licensed ASD-STE100 specification and checking tools.

## Quick self-check before delivering

- Does any action-word have more than one synonym in use for the same action? → fix
- Any sentence over ~20 words? → split it
- Any passive-voice instruction ("should be," "is required to be," "will be")? → rewrite active
- Any step doing two things at once? → split into two steps
- Any "simply," "just," "easily," "in order to"? → delete
