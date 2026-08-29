# Candle article — research notes for the author (not for publication)

Draft date: 2026-08-29. Companion to `candle-article.md`.

## 1. Decisions I need from you

These are the places where the literature and your instructions pulled in different directions. I wrote the article the way I think is truthful; each one is easy to change.

### A. Inhale:exhale ratio — the evidence is mixed, not absent

You said no study shows extra benefit from prolonged exhalation. That's not quite what I found:

- **For longer exhalation:** Laborde 2021 (N=64 athletes, 6 cpm, ratios 0.8/1.0/1.2) — RMSSD higher with longer exhale; Bae 2021 (Psychophysiology) — higher E:I raised HF-HRV; Van Diest 2014 — longer exhale gave higher RSA/HF and more self-reported relaxation, *but* participants actually breathed ~7.5 bpm, not 6.
- **No difference:** Meehan & Shaffer 2024 — 1:1 vs 1:2 at exactly 6 bpm, N=26, replicated N=16, no effect on time- or frequency-domain HRV.
- **For 1:1:** Lin 2014 — 5.5 bpm with 5:5 beat 4:6 and both 6 bpm patterns on SDNN and LF (N=47).
- **Original manual (Lehrer 2000)** prescribes exhale-longer-than-inhale and pursed-lip exhale, based on clinical practice.

How I wrote it: "the evidence is mixed, the effect is not large, 1:1 buys rejoin-anywhere and one-number simplicity, send me a paper." I think that's stronger than "no study exists" because a reader who knows Laborde 2021 will trust the rest of the article more, not less. Your call — say the word and I'll shorten it to the minimalism line.

**Decision (author, 2026-08-29):** 1:1 is a design preference (comfort, one identical pulse, rejoin anywhere, one number), not an evidence claim. Study-by-study paragraph removed from the article; the FAQ acknowledges the protocol teaches a longer exhale and invites papers. Holds/pauses answer made consistent (design, no evidence claim). Refs Laborde 2021, Van Diest 2014, Meehan & Shaffer 2024, Lin 2014 dropped from the article (kept in the ledger below).

**Revised decision (author, 2026-08-29, after verification pass):** one alternative mode with a prolonged exhale will be added; exact ratio to be settled in a separate research chat. Default stays 1:1. Article FAQ now says so and cites Laborde 2021 and Meehan & Shaffer 2024; store blurb mentions the planned mode.

Numbers from the verification pass, for the ratio decision:
- Laborde 2021 (N=64 athletes 18–30, within-subject, 6 cpm, 5 min per condition): RMSSD 161.1 ± 42.8 ms at I:E 0.8 (≈4.4 s in / 5.6 s out) vs 128.3 ± 38.7 at 1.0 vs 138.1 ± 54.9 at 1.2. Main effect partial η² = 0.12; 0.8 vs 1.0: d = 0.37, p = 0.012. Authors' own limits: athletes only, narrow ratio range, 5 min washout may be short.
- Meehan & Shaffer 2024: 1:1 vs 1:2 at 6.0 bpm (confirmed rate), N=26 + replication N=16 — no difference on time- or frequency-domain HRV.
- Bae 2021 (Psychophysiology, N=28): at each person's natural rate, 2:1 cue (achieved ≈1.33) raised RMSSD and HF-HRV vs 1:1; effect persisted ~4 min. Not at 6 bpm.
- Balban 2023 (Cell Rep Med RCT, 5 min/day × 1 month): exhale-emphasized cyclic sighing beat mindfulness on mood and respiratory rate. Different exercise; outcome-level evidence for exhale emphasis.
- Design implication: evidence favors a mild bias (~0.8), not 1:2; unequal phases need distinguishable pulses or the rejoin-anywhere property is lost for that mode.


### B. Breath depth — "100% filled" vs the protocol

The Lehrer/Vaschillo protocol repeatedly warns *against* deep breathing during RF practice: "breathe shallowly and naturally, in order to avoid hyperventilation"; dizziness or tingling = too deep. Vaschillo 2006 says slow pacing "often produces hyperventilation" because tidal volume rises more than rate falls, and that it takes ~3 sessions to learn RF breathing without hyperventilating.

Reconciliation I used in the draft: at 6 bpm a breath is naturally about twice a resting breath (same minute ventilation over fewer breaths); "full, not forced"; symptoms mean smaller breaths at the same pace. Your "middle path / it clicks" language is in there verbatim in spirit. I did **not** write "lungs 100% filled / 0% on exhale" — physiologically you can't empty to 0% (residual volume), and the phrase reads as an instruction to over-breathe. If you want the kata framing stronger, I'd keep it as effort/attention language rather than volume language.

Note also: an incomplete exhale leads to breath stacking, not hyperventilation; hyperventilation is too much air exchange per minute. The draft avoids that mix-up.

**Decision (author, 2026-08-29):** follow the published protocol only. "How to breathe with it" now lists the Lehrer 2000 manual's instructions (nasal, abdominal, easy, not deep, symptoms = smaller breaths) with attribution, notes the manual teaches a longer exhale, and no longer contains the author's own kata/middle-path paragraph or the "twice a resting breath" inference.

### C. Does the second decimal matter? — honest framing

- For precision: Steffen 2017 (RF vs RF+1 — better mood, lower stress-test BP for RF); Yudemon's developer says 0.2 bpm off cost him >10% HRV response (n=1).
- Against: Physiol Rep 2019 acute study (RF vs RF+1, N=10 men, no difference in HRV/MSNA); **Sci Rep, 19 May 2026** RCT (N=88, 4 weeks): individual RF vs fixed 0.1 Hz — same symptom benefits, no difference, no change in resting HRV either group; Lehrer 2020 meta-analysis explicitly suggests ~6 bpm may work as well as exact RF.

I wrote it as "cuts both ways; my bet is it matters more the more you practice." That's your actual position and it's defensible. If you'd rather not show the counter-evidence, I'd at least keep the 2026 RCT out of the article only if you're comfortable with a commenter posting it.

**Decision (author, 2026-08-29):** be honest that it's uncharted at these volumes; precision is optional (hence on the settings screen, not main); reasons for using it are a small chance it matters plus Yudemon's reported ~10% acute effect from 0.2 off; 0.01 is what Yudemon supplies; and it makes the practice stick. FAQ answer rewritten accordingly.

### D. "The motion itself stimulates the vagus nerve (needs proofs)"

Best support: Noble & Hochman 2019 (Front Physiol) — hypothesis paper: prolonged inhalation recruits slowly-adapting pulmonary stretch receptors (vagal afferents → NTS); exhalation activates baroreceptors. Gerritsen & Band 2018 (rVNS model) argues similarly. Both are theory papers, not trials. The best-supported mechanism remains baroreflex resonance (Lehrer & Gevirtz 2014). Draft says "plausible, but still a hypothesis." I would not say "a lot of research shows."

**Decision (author, 2026-08-29):** not included. Sentence and refs (Noble & Hochman 2019, Gerritsen & Band 2018) removed from the article; kept in the ledger.

### E. Backstory explicitness

Draft mentions "daily missile attacks" without naming the country. Options: keep; replace with "living through a war"; or cut to "while my family at home was in danger." Tell me which.

**Decision (author, 2026-08-29):** name Ukraine. Draft now reads "…in Ukraine, were living under daily missile attacks. They still are."

### F. Title

**Decision (author, 2026-08-29):** title is now **A free, open-source haptic resonance breathing pacer for Garmin watches**. Earlier working title was "Candle: a haptic resonance breathing pacer for Garmin watches". Other alternatives considered:
- Candle — a vibration pacer for resonance breathing, on your Garmin
- A free, open-source resonance breathing pacer for Garmin watches
- Resonance breathing with your eyes closed: Candle for Garmin

### G. Things I stated as fact from your answers (please confirm)

- Final v1.0 UI (simulator screenshots 2026-08-29): settings screen shows a candle icon, EVERY 5s, 6 BPM (the PACE label is gone), v1.0; main screen shows clock, POWER 50%, BUZZ 50ms, BATTERY. Article labels updated to EVERY / BPM. Defaults 6.00 bpm / 5.00 s / 50% / 50 ms (PULSE renamed BUZZ); POWER 1–100% (1% steps below 5%); BUZZ 10–250 ms in 10 ms steps.
- Top button toggles screens; hold bottom button exits; single press shows hint; settings persist; hold +/– to scroll.
- Battery: "one to two weeks in battery saver with several hours of Candle a day; not measured precisely."
- Your Journey Mode number 5.71; your practice settings (10%/30ms, 40%/60ms, 50%/70ms).

### H. Default rate and bounds (2026-08-29)

Default stays 6.00 (closer to the whole-population centre than 5.5 once women, shorter people, older adults and children are counted; convention; 2026 RCT found no difference vs individual RF). Article now adds "taller men: 5.5 is a better first guess" and children's range 6.5–9.5 bpm (Shaffer & Meehan 2020).

Bounds: my recommendation is 3–10 bpm (10 s to 3 s per phase). Ceiling 10 covers beginners ramping down from a normal rate and sits at the edge of the slow-breathing regime (<9 cpm per Laborde 2022); floor 3 stops where Vaschillo 2002 saw the resonance effect invert (~3 bpm) and keeps 15-second phases out. (The ceiling also happens to cover the 6.5–9.5 range Shaffer & Meehan give for children — keep that reasoning private; see item I.) Author has not yet confirmed — settings table still shows no range for PACE/EVERY. **Pending: confirm bounds and I'll fill the table.**

Safety FAQ rewritten: adverse effects few (Laborde 2022); pacemaker and acidosis contraindications (Shaffer & Meehan 2020); over-breathing signs incl. pounding heart; plus a plain "listen to your body" paragraph.

### I. Garmin Connect IQ review guidelines (2026-08-29)

Verified on developer.garmin.com/connect-iq/app-review-guidelines/ (Firecrawl, cached 2026-08-26):

- **Medical Apps** — "If your app is intended for use in the diagnosis, cure, mitigation, treatment or prevention of disease or other conditions, you must be prepared to submit documentation from any relevant regulatory agencies… Otherwise, you must update the app's description, features and functionality to ensure it does not indicate any use for the purposes of diagnosis, cure, prevention, mitigation or treatment of disease or other conditions and is intended for informational purposes only."
- **No Apps for Children under 13** — "We prohibit apps that are designed to be used by children under the age of 13. This prohibition does not apply to any general audience apps, unless you are aware that the app is used by children under the age of 13."

Actions taken:
- Store blurb: no health or condition claims (already the case); removed "the science" from the link line; added "Not a medical device; for informational purposes only."
- Article: removed the children's-range sentence from "Which number to set" (the store listing links to the article, and a sentence about children's resonance frequencies could read as designing for under-13s). Shaffer & Meehan 2020 stays cited in the safety FAQ.
- Do not state "usable by children" anywhere public — listing, article, README, Reddit posts.

Residual risk, for awareness: the article's three-legs section and FAQ cite outcome studies on anxiety, depression and stress. That's literature summary, not an app claim, and it lives off-store. If a reviewer follows the link and objects, the fallback is to soften those two paragraphs to "used in research on…" wording. The app UI itself shows only rate, buzz, clock and battery — no stress/health language — which is the strongest protection.

### J. Store listing (2026-08-29)

Store description moved out of the article into `candle-store-listing.md` (paste-ready: fields, description, What's New, rationale, compliance checklist). Built from: Garmin App Review Guidelines (verified), forum guidance on screenshots/donation flag/developer verification, and the structure of the better breathing-app listings on the store (Breathing Timer, HRV Breathing, Breathing Exercises, Breathe). Competitor two-star reviews cluster on: vibration too strong, no end-of-session warning, wanting adjustable phase durations — the listing pre-empts all three by stating what Candle doesn't do.

## 2. Open placeholders in the draft

`[STORE URL]`, `[GITHUB URL]`, `[EMAIL]`, `[MEDIUM URL]` (store blurb), `[PHOTO: watch on wrist, main screen]`, `[PHOTO: settings screen]`, `[SCREENSHOT: Journey Mode result, 5.71]`, app icon (not placed yet — suggest above the title or in the store section).

## 3. Things I could not verify

- The term-frequency claim ("resonance breathing" > "resonance frequency breathing" in everyday search). Consistent with what I saw (Yudemon's own marketing uses "resonance breathing"; papers use "resonance frequency breathing" / "slow-paced breathing") but I didn't quantify it.
- Elite HRV has no built-in RF finder that I could confirm; the draft describes it as app + manual stepped protocol. Correct me if the app now has one.
- Battery cost per hour.

## 4. Developer note (for the GitHub README, if useful)

POWER and BUZZ map directly onto Connect IQ's `Attention.VibeProfile(dutyCycle, length)` — dutyCycle 0–100 (perceived as strength), length in ms. Source: https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention/VibeProfile.html

## 5. Evidence ledger

| # | Claim | Source | URL | Date | Connector | Status |
|---|---|---|---|---|---|---|
| 1 | Mechanism = baroreflex resonance ~0.1 Hz; avg peak ~5.5 bpm (Vaschillo 2002); taller people & men lower RF; high-amplitude HR oscillation appears within a fraction of a minute in almost everyone; 3 months twice-daily practice raised resting baroreflex gain (Lehrer 2003) | Lehrer & Gevirtz 2014, Front Psychol 5:756 | https://doi.org/10.3389/fpsyg.2014.00756 | 2014 | Exa | full text read |
| 2 | Original protocol: breathe "shallowly and naturally" to avoid hyperventilation; lightheadedness/dizziness = breathing too deeply; abdominal breathing, nasal inhale, pursed-lip exhale, exhale longer than inhale; RF determination 6.5/6/5.5/5/4.5 bpm x 2 min; home practice 20 min x2/day | Lehrer, Vaschillo & Vaschillo 2000, Appl Psychophysiol Biofeedback 25:177–191 | https://doi.org/10.1023/A:1009554825745 (PDF: cdn.heartmath.com/support/Resonant_Frequency_with_HRV.pdf) | 2000 | Exa | full text read |
| 3 | Slow breathing often raises tidal volume enough to cause hyperventilation; "must train people not to breathe too deeply"; >=3 sessions needed to breathe at RF without hyperventilating; RF inversely related to height, lower in men, stable across 10 sessions, unrelated to age/weight | Vaschillo, Vaschillo & Lehrer 2006, Appl Psychophysiol Biofeedback 31(2):129–142 | https://hartfocus.nl/wp-content/uploads/2021/10/2006-Vaschillo-Characteristics-of-Resonance-in-Heart-Rate-Variability-Stimulated-by-Biofeedback.pdf | 2006 | Exa | full text read |
| 4 | I:E ratio at 6 bpm: 1:1 vs 1:2 made no difference to HRV (N=26, replicated N=16); review notes literature disagrees; Van Diest 2014 participants actually breathed ~7.3–7.7 bpm | Meehan & Shaffer 2024, Appl Psychophysiol Biofeedback | https://pubmed.ncbi.nlm.nih.gov/38507210/ ; PMC11310264 | 2024 | Firecrawl | abstract + extracts read (PMC blocked to fetch) |
| 5 | 5.5 bpm with 5:5 I:E produced higher SDNN and LF power than 6 bpm or 4:6 (N=47, Latin square) | Lin, Tai & Fan 2014, Int J Psychophysiol 91:206–211 | https://doi.org/10.1016/j.ijpsycho.2013.12.006 | 2014 | Exa | abstract read |
| 6 | At 6 cpm, RMSSD higher when exhalation longer than inhalation (ratios 0.8/1.0/1.2, N=64 athletes); 0.4 s pauses no effect | Laborde et al. 2021, Sustainability 13:7775 | https://doi.org/10.3390/su13147775 | 2021 | web_search | abstract read |
| 7 | Van Diest 2014: low I/E ratio -> higher RSA/HF & more self-reported relaxation, but at ~7.5 bpm not 6 | Van Diest et al. 2014, Appl Psychophysiol Biofeedback 39:171–180 | https://doi.org/10.1007/s10484-014-9253-x | 2014 | Firecrawl (via Meehan review) | secondary |
| 8 | Bae et al. 2021: increased E:I ratio enhances HF HRV | Psychophysiology 58:e13905 | cited in Laborde 2021b | 2021 | web_search | secondary only |
| 9 | Meta-analysis, 58 RCTs: HRVB small-to-moderate effect; largest for anxiety, depression, anger, performance; suggests ~6 bpm may work as well as exact RF; almost everyone masters within 1–4 sessions; can then pace by clock | Lehrer et al. 2020, Appl Psychophysiol Biofeedback 45:109–129 | https://doi.org/10.1007/s10484-020-09466-z | 2020 | Exa | full text extracts read |
| 10 | Meta-analysis, 223 studies: voluntary slow breathing raises vmHRV DURING (moderate RMSSD, large LF), small increase immediately after one session, small increase in resting RMSSD after multi-session interventions; few adverse effects | Laborde et al. 2022, Neurosci Biobehav Rev 138:104711 | https://doi.org/10.1016/j.neubiorev.2022.104711 | 2022 | Exa | full text extracts read |
| 11 | HRVB for stress/anxiety g≈0.8; long-term efficacy uncertain (few follow-ups) | Goessl, Curtiss & Hofmann 2017, Psychol Med 47:2578–2586 | https://www.heartmath-europe.com/doc/Goessl%20Hofmann%202017%20HRV_BF%20meta_stress_anxiety.pdf | 2017 | Exa | full text extracts |
| 12 | HRVB and depressive symptoms g=0.38 (14 RCTs) | Pizzoli et al. 2021, Sci Rep 11:6650 | https://www.nature.com/articles/s41598-021-86149-7 | 2021 | Exa | abstract |
| 13 | RCT N=88, 4 weeks: individual RF vs fixed 0.1 Hz — both reduced stress/anxiety/depression vs control, no difference between them; no change in resting HRV | Sci Rep 2026 "Resonance frequency versus fixed 0.1 Hz breathing" | https://www.nature.com/articles/s41598-026-53333-6 | 2026-05-19 | Exa | full text extracts |
| 14 | Steffen 2017: RF vs RF+1 — RF group lower SBP under stress + better mood; Lin 2012: RF > 6 bpm on HRV/BP over 5 weeks in prehypertension; Fonkoue-type acute study: RF vs RF+1 no acute difference (N=10) | PMC6882954 (Psychophysiology 2019) + 2023 methods review | https://pmc.ncbi.nlm.nih.gov/articles/PMC6882954/ ; https://doi.org/10.1007/s10484-023-09582-6 | 2019/2023 | Exa | secondary; Steffen abstract to verify |
| 15 | Methods review of 143 HRVB studies: three protocol families (individual RF / live biofeedback / preset 6 bpm); 2/3 of studies didn't report I:E ratio etc.; RF stability debated; sliding protocol 4.25–6.75 bpm (Fisher & Lehrer 2022) | Appl Psychophysiol Biofeedback 2023 | https://doi.org/10.1007/s10484-023-09582-6 | 2023 | Exa | extracts |
| 16 | Steffen 2017: RF group higher positive mood, higher LF/HF, lower SBP under stress vs RF+1 and control | Front Public Health 5:222 | https://doi.org/10.3389/fpubh.2017.00222 | 2017 | Firecrawl | abstract |
| 17 | Hypothesis: prolonged inhalation recruits slowly-adapting pulmonary stretch afferents (vagal) to NTS; exhalation activates baroreceptors — "motion itself" pathway | Noble & Hochman 2019, Front Physiol 10:1176 | https://doi.org/10.3389/fphys.2019.01176 | 2019 | Exa | full text extracts (hypothesis paper) |
| 18 | Respiratory vagal nerve stimulation model (rVNS) for contemplative practices | Gerritsen & Band 2018, Front Hum Neurosci 12:397 | https://doi.org/10.3389/fnhum.2018.00397 | 2018 | Exa | full text extracts (theoretical) |
| 19 | Haptic guidance at 0.1 Hz: haptic-only achieved coherence comparable to visual+biofeedback; lowest breathing-rate RMS error (0.34 s vs 0.82 s visual); visuo-haptic best P0.1; haptic effect may depend on individual tactile sensitivity (N=32) | Bouny et al. 2023, Sensors 23:4494 | https://doi.org/10.3390/s23094494 | 2023 | Exa | full text extracts |
| 20 | Vibrotactile breathing pacer: tactor placement and personalization matter | PIV, ACM TOCHI | https://doi.org/10.1145/3365107 | 2019 | Exa | abstract |
| 21 | Simple paced breathing vs HRV biofeedback, N=28, 10 min: no difference in acute breathing-rate slowing or HRV increase | Univ. Southampton eprint 500137 (2022) | https://eprints.soton.ac.uk/500137/ | 2022 | Exa | abstract |
| 22 | Yudemon HRV: Journey Mode = 10-min sessions testing small range of rates in randomized order, multiple HRV metrics; solid estimate after 5–10 sessions; iOS+Android; Polar H10 recommended; dev claims 0.2 bpm off cost >10% HRV response (own data) | yudemon.com/app; Frenzel Medium posts | https://www.yudemon.com/app ; https://medium.com/yudemon/a-completely-novel-way-to-establish-your-optimal-breathing-rate-57ce9ec32ebd | 2025 | web_search | page read |
| 23 | Elite HRV + Polar H10 valid vs ECG during 6 bpm paced breathing (time-domain very large agreement; freq-domain wider LOA) | Sensors 2023, PMC10708620 | https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10708620/ | 2023 | web_search | abstract |
| 24 | Connect IQ VibeProfile(dutyCycle, length ms); dutyCycle perceived as strength | Garmin developer docs + forum | https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention/VibeProfile.html | current | Firecrawl | doc read |
| 25 | vivoactive 5: Action (top) + Back (bottom) buttons; Breathwork = 4 preset programs (Coherence, Relax and Focus, R&F Short, Tranquility) with on-screen guidance and optional vibration alerts; DND turns off vibrations/display for alerts & notifications; Lock Screen locks buttons+touch, hold any button to unlock | Garmin vivoactive 5 Owner's Manual | https://www8.garmin.com/manuals/webhelp/GUID-5D183A14-BB43-4A9B-B441-5F824214CE40/EN-US/vivoactive_5_OM_EN-US.pdf | current | Exa | manual read |
| 27 | Adult RF 4.5–6.5 bpm; children 6.5–9.5 bpm (smaller vascular tree); RF assessment contraindicated with pacemaker-driven rhythm and acidosis-producing conditions (e.g. kidney disease); faint/pounding heart = breathe shallower and smoother; longer exhalation recommended in assessment | Shaffer & Meehan 2020, Front Neurosci 14:570400 | https://doi.org/10.3389/fnins.2020.570400 | 2020 | Exa | full text extracts |
| 26 | FA vs open-monitoring meditation taxonomy | Lutz, Slagter, Dunne & Davidson 2008, Trends Cogn Sci 12:163–169 | https://doi.org/10.1016/j.tics.2008.01.005 | 2008 | memory (well-known) | not re-fetched |
