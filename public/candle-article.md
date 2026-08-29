# A free, open-source haptic resonance breathing pacer for Garmin watches

*Candle has one job: a short pulse on your wrist every time it's time to inhale or exhale.*

[PHOTO: watch on wrist, main screen]

Candle is a Connect IQ app for people who already practice resonance frequency breathing and want to do it with their eyes closed, in any room, without anyone noticing. It pulses at your rate — 6.00 breaths per minute by default, or your own measured number down to 0.01 — and it keeps pulsing until you exit. There is no timer, no score, no sensor, no session. You breathe, it keeps time.

It runs on the vívoactive 5 today. Other Garmin watches with a vibration motor will follow as people test it. It costs nothing and the code is public.

- Connect IQ Store: [STORE URL]
- Source: [GITHUB URL]

The first half of this article is everything you need to start. The second half is why it's built the way it is, for anyone who wants to know.

---

## Get started

### 1. Install and open

Install Candle from the Connect IQ Store, then open it from the apps menu. It starts pulsing immediately. There is no start button.

### 2. Breathe with the pulse

Each pulse marks a change of phase: inhale on one pulse, exhale on the next. Both phases are the same length. At the default 6.00 breaths per minute that's a pulse every 5 seconds.

That's the whole practice. Close your eyes if you can.

### 3. The two screens

**Main screen** — the time, the buzz settings, and the battery. This is what you see while practicing.

- **POWER** — vibration strength. Default 50%.
- **BUZZ** — vibration length in milliseconds. Default 50 ms.

**Settings screen** — press the top button to reach it, and again to come back.

- **EVERY** — seconds between pulses, i.e. the length of one phase. Steps of 0.05 s.
- **BPM** — the same thing expressed in breaths per minute. Steps of 0.01.

EVERY and BPM are one number in two units (BPM = 60 ÷ (2 × EVERY)), so changing one changes the other. Tap + or – to adjust, or hold to scroll. Everything you set is remembered the next time you open the app.

[PHOTO: settings screen showing EVERY / BPM]

### 4. Exit

Hold the bottom button. A single press shows a reminder to hold — this is deliberate, so a brushed button doesn't end a long practice.

### 5. Two watch settings worth turning on

- **Do Not Disturb** — so a phone notification doesn't land between two pulses and confuse the rhythm. Hold the top button for the controls menu and select Do Not Disturb.
- **Lock Screen** — optional. If you wear the watch anywhere other than the wrist (more on that below), skin covering the screen can register as touches. Locking the touchscreen stops that; hold any button to unlock.

Candle doesn't add its own versions of these. The watch already does them well.

### Settings at a glance

| Setting | Default | Range | Step |
|---|---|---|---|
| BPM (breaths/min) | 6.00 | — | 0.01 |
| EVERY (seconds per phase) | 5.00 | — | 0.05 |
| POWER (vibration strength) | 50% | 1–100% | 1% below 5%, then 5% |
| BUZZ (vibration length) | 50 ms | 10–250 ms | 10 ms |

---

## How to breathe with it

I'm not going to invent breathing instructions. The method has a published training manual — Lehrer, Vaschillo and Vaschillo, 2000 — and this is what it teaches, in short. [2][3]

- Breathe in through the nose.
- Breathe with the abdomen: the belly moves out on the inhale and back in on the exhale, the chest stays still.
- Breathe easily and comfortably. Don't try too hard.
- Don't breathe deeply. Slowing down tends to make breaths bigger than they need to be, and that's over-breathing. If you feel lightheaded, dizzy, or tingly, that's the signal: keep the pace and make the breaths smaller. The manual says it takes a few sessions to learn slow breathing without over-breathing, so give it that.

The manual also teaches a longer exhale than inhale. Candle keeps both phases equal for now; a longer-exhale mode is planned — see the FAQ.

**Lost the rhythm? Take the next pulse.** Every pulse is identical and both phases are the same length, so it doesn't matter which phase you rejoin on. You don't need to work out where you were. You just start again on the next one.

**One breath at a time.** The task is never "do twenty minutes." The task is to land the next inhale, or the next exhale, exactly on the pulse — to anticipate it rather than react to it. That is a small, concrete thing to do, and you can do it right now.

---

## Which number to set

If you don't know your resonance frequency, leave it at 6.00. That's the conventional rate — the most common fixed pace in the research — and for most adults it's inside the range where the effect happens, about 4.5 to 6.5 breaths per minute. [1][4] The adult average sits nearer 5.5; men and taller people tend to be lower, women and shorter people higher. [1][3] If you're a taller man, 5.5 is a better first guess than 6.0. Whatever you start with, if a nearby rate feels more comfortable, use it.

If you do know your number, set it. BPM moves in steps of 0.01 — hold + or – to scroll. Mine is 5.71.

### How to find your number

You need a chest strap. Wrist optical sensors aren't built for beat-to-beat precision, and the standard setup in this field is a Polar H10 paired with a phone app — a combination that has been validated against ECG during paced breathing at 6 breaths per minute. [5]

**The tool I recommend: Yudemon HRV, Journey Mode** (iOS and Android). Instead of a single six-minute scan in half-breath steps, each 10-minute Journey session tests a small range of rates in random order and measures your response across several HRV metrics. The estimate refines session by session; after five to ten sessions you have a number you can trust to two decimals. [6] Every Journey session is also a full breathing session, so nothing is wasted.

[SCREENSHOT: Journey Mode result, 5.71]

**The alternative: Elite HRV** and the classic stepped protocol — breathe at 6.5, 6, 5.5, 5, 4.5 for a few minutes each and compare. [2] It works, but a day or two of readings is nowhere near enough for real precision. Plan on weeks.

**Without a strap:** don't try to measure. Pick 6.0 or 5.5, whichever feels better, and practice. You can go down the rabbit hole later, or never.

---

## The buzz: turn it down as you improve

POWER and BUZZ live on the main screen, not in settings, because you'll change them often. The rule is simple: use the weakest pulse you can still catch. Stronger when you're distracted, weaker when you're not.

A few of my own settings, for scale:

- Lying in a dark room, eyes closed: 10% / 30 ms
- In a barbershop chair: 40% / 60 ms
- Walking slowly, yoga-style: 50% / 70 ms

The default 50% / 50 ms is a comfortable starting point. Over weeks, the goal is to move down, not up — a faint tap you have to listen for does more for your attention than a buzz you can't miss.

---

## Where to wear it

The wrist is fine for most people, most of the time. A soft nylon strap helps: you can set the tightness finely, and it's kinder to the skin over long stretches.

If you practice for hours a day, you'll notice the skin under the motor gets tired of the sensation after about an hour. That's a signal to move the watch: forearm, upper arm, ankle. Turn on Lock Screen when skin covers the display. Moving it around has a side effect I've come to value — you learn to hold attention at different edges of your body, not just the one you're used to.

---

## Not a session

Candle runs until you exit it. No countdown, no end screen. This is the point.

The practice isn't twenty minutes on a cushion; it's a default state for the parts of the day when your body should be resting — lying on the couch, waiting, sitting through a meeting you don't have to speak in. Not while running. Not while eating or talking. Whenever you're idle, the pulse is there, and you come back to it.

Two things happen with time. First, the cue-to-breath link becomes automatic — the pulse arrives and the breath changes without you deciding it. Second, on top of that, you can add attention deliberately: say "inhale" and "exhale" silently instead of whatever the mind was saying. That short-circuits the usual chatter, one breath at a time.

If you want a bounded session, use the watch's own timer or alarm. Candle doesn't need to know.

---

## Why one pulse does three jobs

Candle sits where three practices overlap.

### 1. Resonance frequency breathing

Breathing at roughly 0.1 Hz — around six breaths a minute — lines your breath up with the natural rhythm of the baroreflex, the loop that adjusts heart rate to blood pressure. The two oscillations reinforce each other and your heart rate begins to swing widely and smoothly with each breath. Almost everyone shows this within the first minutes of trying. [1][4]

The immediate effect is well established: vagally mediated HRV rises during slow breathing, in a meta-analysis of over 200 studies. [8] Across randomized trials, regular practice produces small-to-moderate improvements in anxiety, depression, and stress, with the largest effects on anxiety. [4][9][10] Whether it permanently raises your resting HRV is less clear: the pooled effect after multi-week training is small, and a 2026 trial of four weeks' practice found the symptom benefits without any change in resting HRV. [8][11]

So: it reliably changes your physiology while you do it, and regular practice reliably helps how you feel. The rest is still being worked out.

### 2. Focused attention

To keep a breath on an external rhythm you have to keep your attention on the rhythm, notice when it has drifted, and bring it back. That is the definition of focused-attention meditation — the family of practices where a single object (a breath, a mantra, a candle flame) is the anchor, and the training is in returning. [12] Monks used candles for this. The pulse is a candle you can carry into a meeting.

The POWER knob is how you scale the difficulty. When attention is scattered, a stronger pulse holds it. As the skill grows, a weaker pulse asks more of it.

### 3. Interoception

The pulse is felt, not seen or heard. Following it means attending to a small sensation on your skin and how it registers — which is a form of body-monitoring practice in its own right, close to what body-scan traditions train. Lowering POWER over time turns this into progressive overload for that skill: the fainter the signal, the finer the attention needed to catch it.

There's some evidence that haptic pacing does this job well: in a study of 0.1 Hz breathing guidance, participants following vibration alone kept their breathing rate closer to target than those following a visual pacer, and reached cardiac coherence about as well. [13]

None of the three is new. What's new is that a watch motor can deliver all three for as many hours a day as you like.

---

## FAQ: the design decisions

**Why equal inhale and exhale?**

Because I find it comfortable, and because it keeps the app small.

With equal phases every pulse is the same, so there's nothing to tell apart — no long buzz for inhale and short buzz for exhale, no pattern to learn. You can rejoin the rhythm on any pulse without knowing which phase you were in. And the whole app stays one number: your rate. That's the default, and it's staying the default.

But the published protocol teaches a longer exhale, and there is evidence for it. In a study of 64 young athletes breathing at 6 breaths per minute, a mildly longer exhale — roughly 44:56 — produced about 25% higher RMSSD than equal phases. [14] Another study, with a replication, found no difference for a stronger 1:2 split. [15] Not settled, but enough to take seriously. So Candle will get exactly one alternative mode with a prolonged exhale: opt-in, on the settings screen, default untouched. I'll settle the exact ratio after more reading. Until then, 1:1.

**Why no holds or pauses?**

A pause is another thing to feel, count, and get wrong, and I haven't seen a reason to add one. Box breathing and 4-7-8 are fine practices; they're a different practice.

**Why doesn't it measure anything?**

Because it wouldn't be good at it. In my judgment a wrist optical sensor isn't precise enough to find a resonance frequency to two decimals, and I'd rather point you to tools built for measurement — a Polar H10 and Yudemon HRV — than build a worse one into a pacer. [5][6]

There's also evidence that for the practice itself, once you have your rate, simple paced breathing produced the same immediate HRV response as live biofeedback, at least in one small study. [16] Measure with a strap; practice with a pulse.

**Why no session timer?**

Because it isn't a session. See above. The watch has a timer if you need one.

**Why 0.01 breaths-per-minute precision? Nobody breathes that accurately.**

Nobody does, on any single breath. Over a thousand breaths the average lands where the pacer points — and if you practice for hours a day, a difference of 0.2 breaths per minute is one you'll accumulate.

Whether that accumulation matters is uncharted. The evidence cuts both ways. One trial found that breathing at your exact resonance frequency beat a rate one breath away on stress reactivity and mood; [7] a small acute study found no difference in HRV or sympathetic activity between the two; [17] and a 2026 trial found no difference between an individual rate and a flat 6.0 over four weeks. [11] None of those studies looked at the volumes I have in mind, so nobody knows. What tipped it for me: the developer of Yudemon reports that in his own measurements, being 0.2 off cost more than 10% of the acute HRV response. [6] Ten percent is not nothing. And 0.01 is simply the precision Yudemon hands you, so Candle accepts it rather than making you round.

It's optional, which is why the BPM setting lives on the settings screen and not the main one. 6.00 works. But there's a plainer reason I use my own number: it makes the practice stick. The concept on its own is almost too simple. Measure it, breathe at your own rhythm, and it becomes something you want to come back to. 6.00 is a default; 5.71 is mine.

**Why vibration and not sound or a screen?**

Because you can close your eyes, and because no one else knows. A visual pacer needs your eyes; audio needs headphones or a quiet room. A pulse on the wrist needs neither and is invisible in a meeting, a queue, or a barbershop chair. Haptic guidance also holds breathing rate to target at least as well as visual guidance. [13]

**Why not Garmin's built-in Breathwork activity?**

It's a good activity for what it is. It offers four preset programs, runs as a timed activity, and guides you on-screen with optional vibration. [18] It can't be set to 5.71, and it isn't built to run for four hours in the background of your day. Candle is.

**Why only the vívoactive 5?**

Because that's the watch I own. The vibration API is shared across Connect IQ watches that have a motor, but I can't see how the layout looks on other screens without the hardware. If you have a different Garmin, try it and write to me at [EMAIL] if something doesn't fit or doesn't work. Technical contributions go to [GITHUB URL].

**Why "Candle"?**

Meditators have used a candle flame as an object to hold attention on for a very long time. This is that object, made of vibration, for people who spend their days in offices and on trains.

**What does it cost in battery?**

Little. I run my watch in battery saver and get one to two weeks including several hours of Candle a day. Stronger and longer pulses cost more; I haven't measured it precisely.

**Is it safe?**

Here is what the literature says. Reported adverse effects from slow breathing are few. [8] Two contraindications are documented: a heart rhythm driven by a pacemaker (the device controls the rhythm, so the breathing can't do its job), and conditions that cause blood acidosis — kidney disease is the textbook example — where slowing your breathing raises CO₂ and can make things worse. [19] The everyday risk is over-breathing: if you feel faint, tingly, or your heart is pounding, take smaller, smoother breaths at the same pace. [2][19]

Here is what I say. This changes your physiology in real time, and I'm a person with a watch, not a doctor. Listen to your body. If something feels wrong, stop; if it keeps feeling wrong, ask someone qualified. This article is not medical advice.

**Why did you build it?**

I became a father in a country that wasn't mine, in my fourth language, while my family and everyone I grew up with, in Ukraine, were living under daily missile attacks. They still are. I did the bureaucracy, the flat hunts, the kindergarten search, and a full-time job with a smile, because nobody had time for the backstory. One evening my wife told me I wasn't there — I was in the room but not present. I was in pain, the way a lot of people are. So I went looking for the mechanism, learned what I could about the vagus nerve and resonance breathing, and built the smallest possible tool to practice it all day. That's Candle.

**Will you add [feature]?**

Maybe. I don't want to be categorical. But every "no" so far has a reason behind it, and the reason for most of them is the same: the app is finished when there's nothing left to remove. If you think something's missing, write me and tell me why.

---

## Links

- Install: [STORE URL]
- Source and issues: [GITHUB URL]
- Questions about the design: [EMAIL]
- Find your number: [Yudemon HRV](https://www.yudemon.com/app)

---

## References

1. Lehrer PM, Gevirtz R. Heart rate variability biofeedback: how and why does it work? *Front Psychol.* 2014;5:756. https://doi.org/10.3389/fpsyg.2014.00756
2. Lehrer PM, Vaschillo E, Vaschillo B. Resonant frequency biofeedback training to increase cardiac variability: rationale and manual for training. *Appl Psychophysiol Biofeedback.* 2000;25(3):177–191. https://doi.org/10.1023/A:1009554825745
3. Vaschillo EG, Vaschillo B, Lehrer PM. Characteristics of resonance in heart rate variability stimulated by biofeedback. *Appl Psychophysiol Biofeedback.* 2006;31(2):129–142. https://doi.org/10.1007/s10484-006-9009-3
4. Lehrer P, Kaur K, Sharma A, et al. Heart rate variability biofeedback improves emotional and physical health and performance: a systematic review and meta analysis. *Appl Psychophysiol Biofeedback.* 2020;45(3):109–129. https://doi.org/10.1007/s10484-020-09466-z
5. Validity and efficacy of the Elite HRV smartphone application during slow-paced breathing. 2023. https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10708620/
6. Yudemon HRV — Journey Mode. https://www.yudemon.com/app · Frenzel M. A novel way to establish your optimal breathing rate. https://medium.com/yudemon/a-completely-novel-way-to-establish-your-optimal-breathing-rate-57ce9ec32ebd
7. Steffen PR, Austin T, DeBarros A, Brown T. The impact of resonance frequency breathing on measures of heart rate variability, blood pressure, and mood. *Front Public Health.* 2017;5:222. https://doi.org/10.3389/fpubh.2017.00222
8. Laborde S, Allen MS, Borges U, et al. Effects of voluntary slow breathing on heart rate and heart rate variability: a systematic review and a meta-analysis. *Neurosci Biobehav Rev.* 2022;138:104711. https://doi.org/10.1016/j.neubiorev.2022.104711
9. Goessl VC, Curtiss JE, Hofmann SG. The effect of heart rate variability biofeedback training on stress and anxiety: a meta-analysis. *Psychol Med.* 2017;47(15):2578–2586. https://doi.org/10.1017/S0033291717001003
10. Pizzoli SFM, Marzorati C, Gatti D, et al. A meta-analysis on heart rate variability biofeedback and depressive symptoms. *Sci Rep.* 2021;11:6650. https://doi.org/10.1038/s41598-021-86149-7
11. Resonance frequency versus fixed 0.1 Hz breathing in heart rate variability biofeedback: a randomized trial. *Sci Rep.* 2026. https://www.nature.com/articles/s41598-026-53333-6
12. Lutz A, Slagter HA, Dunne JD, Davidson RJ. Attention regulation and monitoring in meditation. *Trends Cogn Sci.* 2008;12(4):163–169. https://doi.org/10.1016/j.tics.2008.01.005
13. Bouny P, Arsac LM, Guérin A, Nerincx G, Deschodt-Arsac V. Guiding breathing at the resonance frequency with haptic sensors potentiates cardiac coherence. *Sensors.* 2023;23(9):4494. https://doi.org/10.3390/s23094494
14. Laborde S, Iskra M, Zammit N, et al. Slow-paced breathing: influence of inhalation/exhalation ratio and of respiratory pauses on cardiac vagal activity. *Sustainability.* 2021;13(14):7775. https://doi.org/10.3390/su13147775
15. Meehan ZM, Shaffer F. Do longer exhalations increase HRV during slow-paced breathing? *Appl Psychophysiol Biofeedback.* 2024. https://pubmed.ncbi.nlm.nih.gov/38507210/
16. Comparing heart rate variability biofeedback and simple paced breathing to inform the design of guided breathing technologies. University of Southampton, 2022. https://eprints.soton.ac.uk/500137/
17. Acute effects of resonance frequency breathing on cardiovascular regulation. *Physiol Rep.* 2019. https://pmc.ncbi.nlm.nih.gov/articles/PMC6882954/
18. Garmin. vívoactive 5 Owner's Manual — Recording a Breathwork Activity; Using Do Not Disturb Mode; Locking and Unlocking the Touchscreen. https://www8.garmin.com/manuals/webhelp/GUID-5D183A14-BB43-4A9B-B441-5F824214CE40/EN-US/vivoactive_5_OM_EN-US.pdf
19. Shaffer F, Meehan ZM. A practical guide to resonance frequency assessment for heart rate variability biofeedback. *Front Neurosci.* 2020;14:570400. https://doi.org/10.3389/fnins.2020.570400
