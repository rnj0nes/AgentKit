# Proposal writing style (adjunct to the academic writing style)

This file is a generated copy. The master is the `grant-proposal-writing` Claude
skill, where changes are made. Regenerate this copy from the skill rather than
editing it here.

Deployment: this is the grant adjunct to `.github/copilot-instructions.md`.
GitHub Copilot auto-loads only `copilot-instructions.md` and `AGENTS.md`, so
this file does not load by itself. For a project that involves grant writing,
either append its contents to `.github/copilot-instructions.md` or name it
explicitly in chat when drafting proposal text.

The base standard in `.github/copilot-instructions.md` remains in force. This
file adds the grant-specific task and overrides a few base rules for grant
documents only, which it names as it goes. Part numbers below refer to the base
standard.

Grant proposal writing for Rich Jones. This is an adjunct, not a replacement.

# What this adjunct does and does not change

It does not relax the tone rules. The base ban on promotional language stands. Reviewers are not persuaded by adjectives, and study sections read hundreds of applications that all claim to be transformative.

What changes is that a grant requires explicit claims about significance, innovation, impact, and feasibility, where a manuscript does not. The permission is narrow: a value claim is allowed when the sentence names the basis for the claim. Persuasion comes from specificity rather than from intensity.

Do not let the prose become defensive, ornate, or inflated. A reviewer should conclude the proposal is ambitious because the work matches the problem, not because the adjectives are strong.

Treat reviewer psychology as part of scientific communication. Reviewers do not infer value from technical detail. Say why each design choice matters.

# Carve-outs from the base standard

These override specific rules in `my-writing-style` for grant documents only.

Review criteria names are terms of art. Significance, Innovation, Approach, Investigators, Environment, and Impact are the names of NIH review criteria and appear as headings and in running text. The base bans on "significant" and "key" do not apply to these uses. Any other use of them is still banned.

Headings are required. Base Part 3.4 sets no-headers as the default for short pieces. Grants are formatted documents with prescribed sections, and reviewers navigate by heading. Label sections clearly.

Payoff statements are required. Base Part 5.6 bans the challenges-and-future-prospects formula. That ban covers the vague closing paragraph that names obstacles and then offers optimism. It does not cover aim payoffs, which every aim needs, or the significance paragraph that closes an Aims page. Write those as specific consequences.

Everything else in the base standard applies unchanged, including the ban on the AI vocabulary list, negative parallelism, trailing participles, and triads, and including all of Part 1 on reasoning and Part 5.18 on citation integrity.

# Core instruction

Write grant prose that is scientifically disciplined and deliberately persuasive. State why the work matters, why the team can do it, what premise or model organizes the work, and how the proposed methods solve the stated problem.

The goal is to help a favorable reviewer advocate for the proposal in study section, because the problem, the solution, the feasibility, and the payoff are all easy to restate from memory.

# Operating rules

Keep it simple. Assume reviewers are scientifically trained but may have little prior knowledge of delirium, cognitive aging, claims linkage, cognitive harmonization, or repository infrastructure.

Tell reviewers what they need in order to review the application favorably. Use the review criteria as the guide: significance, investigators, innovation, approach, environment, feasibility, rigor, expected products.

Do not make reviewers hunt for the argument. Main point first in each paragraph, then the evidence or design feature or reasoning that supports it.

Treat every paragraph as a reviewer aid. A favorable reviewer should find the relevant fact, understand why it matters, and restate the point without reconstructing the logic.

# Reviewer logic

Every proposal, section, paragraph, and aim answers four questions in a usable order.

Why. What problem, limitation, unmet need, or scientific decision motivates the work?

Who. Why is this team, cohort, dataset, method, or environment credible for it?

What. What premise, model, hypothesis, estimand, or conceptual framework organizes it?

How. What will be done, and why is that the right way to answer the question?

The order matters, and each omission has a characteristic failure. A methods-heavy paragraph with no "why" reads as busy rather than necessary. A strong "why" with no credible "who" reads as aspirational. A strong "why" and "who" with no clear "what" reads as unfocused. A strong "what" with no feasible "how" reads as speculative.

# Value claims

Use a value claim when the sentence names its own basis.

These work, because each one states what becomes possible and why:

The proposed repository will allow investigators to analyze postoperative delirium, repeated cognitive testing, adjudicated dementia outcomes, linked Medicare claims, and biomarker data within a single documented resource.

This design separates the effect of rehospitalization from the delirium episode that occurs during rehospitalization.

The time-varying exposure structure reduces immortal time bias that would arise from comparing participants classified as ever versus never rehospitalized.

These do not work, unless concrete detail follows immediately: this project will transform the field; this project fills a critical gap; this repository is unique and novel; this work will accelerate scientific discovery; this study will have a major impact.

Where a broad claim is needed, earn it in the same sentence or the next.

Weak: This project will create a unique resource that will accelerate discovery.

Better: This project will create a documented repository that links daily delirium assessments, repeated cognitive testing, adjudicated dementia outcomes, Medicare claims, and biomarker data. Investigators will be able to test whether delirium changes cognitive slope, dementia timing, health care use, and mortality in analyses that were not possible with the unlinked cohort files.

Note what makes the second version better. It is longer and more concrete. Length spent on specifics is the mechanism of persuasion here.

# Paragraph pattern

State the reviewer-relevant claim. Explain the problem or limitation that makes it matter. Give the evidence, design feature, preliminary result, or method. State what the proposed work will make possible.

End on a specific consequence for the aim, the field, a clinical decision, the data resource, or the interpretation. Do not end on a generic benefit statement.

# Specific Aims page

A reviewer should be able to summarize the proposal after one reading.

Start with the problem and its consequence, not with the dataset. Introduce the resource only once the reviewer understands why the problem matters. State the central unresolved question in plain language.

Make each aim a complete unit: question, approach, hypothesis or expected result, payoff. Avoid making one aim depend on another succeeding unless the dependency is structurally unavoidable.

Close with a short significance paragraph restating what the aims will clarify or make possible.

For each aim, answer: why do this aim; what will be estimated, tested, built, or adjudicated; what data and method will be used; what will the result allow reviewers, clinicians, researchers, or data users to do or interpret.

# Significance

Heavy on why, light on technical detail.

Define the scientific or public health problem. Explain why current evidence is insufficient. State the consequence of that insufficiency. Show why the proposed cohort, design, or repository is positioned to address the limitation. Connect the work to clinical, public health, agency, or field-level decisions.

Avoid a literature review that does not change the argument. Avoid generic statements that dementia, delirium, or data sharing matter. Do not claim that preventing delirium will reduce dementia unless the causal assumptions are stated, which is a Part 1 requirement in the base standard.

# Innovation

Name the useful departure from current practice. Do not rely on the label.

These work: we will adjudicate delirium during recurrent hospitalizations and link those episodes to repeated cognitive assessments before and after each event; we will harmonize cognitive outcomes to HRS/HCAP using documented psychometric scoring procedures; we will provide enclave-ready data products that allow secure analysis of sensitive biomarker, genetic, geocoded, and claims-linked variables.

These do not: this study is innovative because it is novel; this project uses cutting-edge methods; this resource is unprecedented.

# Approach

Heavy on how, but every method still needs a local why.

For each major method, specify what it estimates, classifies, links, harmonizes, or adjudicates; why it is appropriate for the aim; what assumptions or limitations affect interpretation; who will carry it out where expertise matters; and what quality control, sensitivity analysis, or alternative plan addresses the predictable reviewer concern.

Leave no method unjustified. A reviewer should not have to infer why claims data, chart-derived CAM, expert adjudication, harmonization, time-varying exposure states, spline models, or competing-risk analyses are being used.

# Preliminary studies

Build confidence in the team and the design. Do not catalog prior publications.

For each one, state what was done, what was observed, what capability or premise it establishes for the proposed work, and which aim it supports.

Use explicit relevance statements sparingly, and keep them where they make a specific connection.

# Team and environment

Establish credibility for this work, with concrete capability statements naming the expertise: clinical expertise in delirium, dementia diagnosis, medical record review, and consensus adjudication; expertise in cognitive aging, psychometrics, longitudinal modeling, and harmonization; expertise in claims linkage and claims-based dementia ascertainment.

Avoid generic praise: the team is world-class; the environment is outstanding; the investigators are uniquely qualified.

Where a credibility claim matters, name the experience, role, method, dataset, publication record, or infrastructure behind it.

# Common revision moves

Replace generic importance with a specific consequence.

Replace "innovative" with the feature that changes what can be estimated, tested, linked, adjudicated, or shared.

Replace abstract agency with real actors: investigators, clinicians, reviewers, data users, the study team. This is base Part 2.3.

Add a why sentence before methods that otherwise read as a list.

Add a who clause where feasibility depends on expertise.

Add a what-this-makes-possible sentence after a technical deliverable.

Cut literature review that does not change the reviewer-facing argument.

Stabilize terminology. The same concept keeps the same word across aims, significance, innovation, and approach. This is base Part 2.2.

Make causal assumptions explicit when describing delirium as a modifiable risk factor.

Keep ambition visible, and tie it to data, design, team, and feasibility.

# Diagnostic checklist

Run this before treating proposal text as ready, in addition to the base standard's Part 9 self-check.

Can a reviewer state the main problem in one sentence?

Can a reviewer state why the problem matters to the funding agency?

Can a reviewer state why the team and dataset are credible for this work?

Can a reviewer state the organizing model or hypothesis?

Can a reviewer state how each aim answers the problem?

Does each aim have its own payoff?

Does each major method have a reason?

Are value claims specific enough to survive with the adjectives deleted?

Are limitations acknowledged without weakening the central argument?

Do significance, innovation, and approach reinforce each other rather than repeat the same generic claim?

Does the proposal help a favorable reviewer advocate for the work in study section?

# Project-specific facts

This file holds writing rules only. Facts about a particular study, its cohorts, its measures, and its linkages live in a separate project reference. For SAGES, read `SAGES-assets.md` in Rich's reference folder, and treat it as possibly stale: confirm current assets with him before building a value claim on one.

# Maintenance

Any correction Rich makes to a rule here means this file is wrong. Offer, in one line, to save the change.

A copy of the base standard is deployed by hand as `.github/copilot-instructions.md` in individual projects. If this adjunct changes, those copies do not.

