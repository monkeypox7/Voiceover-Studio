# Voiceover Tool - How To Use It

This is our own voiceover generator. You type text, pick a voice, and it
makes a spoken audio file you can drop straight into a video timeline.

It runs on the office computer. Nothing is sent to the internet, and there
is no login and no usage limit.

---

## 1. Two ways in

**In the office, on the office wifi:**

    http://10.10.20.64:8880/web/studio.html

Bookmark that. No password needed. Will not work from home or on mobile data.

**From anywhere else (home, mobile data, another office):**

The office manager runs a script that produces a link ending in
`.trycloudflare.com` and sends it to you. That link asks for a login:

    Username: editors
    Password: (the office manager will give it to you)

Two things to know about that link:

- **It is different every time.** If yesterday's link stops working, it is
  not broken, it has simply expired. Ask for the current one.
- **It only works while the office manager has the window open** on the
  office computer. If it says the site cannot be reached, ask them to start
  it again.

Do not post that link or the password in any public place. It reaches
straight into the office computer.

The page works on a laptop and on a phone. On a phone the voice list starts
folded up, so tap **Show** to open it.

---

## 2. Read this first - the two things that fix bad sounding audio

**a) End every line with a full stop.**

If a line of your script has no `.` `!` or `?` at the end, this server cuts
the audio short and you silently lose whole lines. We tested it: three
lines with no full stops produced 1.6 seconds of audio instead of 4.6.

The page now adds the missing full stops for you and tells you when it did.
If you see the orange box saying a full stop was added, that is normal and
it just saved you a broken file.

**b) Put stars around the words you want stressed.**

Type stars around a word, like this:

    This is *not* a small change

That is the single biggest thing you can do to stop a read sounding flat
and robotic.

What it does: it puts a short pause in front of that word before sending
the script to the voice. A voice that pauses before a word lands on it.
Without any marked stress, every word gets the same weight, and that is
exactly what "robotic" sounds like.

The orange box above the script tells you how many starred words it found,
so you can tell it worked.

Do not overdo it. One or two stressed words per sentence is plenty.

---

## 2a. Choosing where the pauses go

Write or paste your script into the box as normal.

Underneath it, **Pause after each sentence** appears. Your script is split into
sentences and each one gets a row:

- The **play button** speaks *just that sentence*, so you can check one line
  without remaking the whole thing.
- **~1.6s** is roughly how long that sentence will take.
- **pause** is the exact silence that follows it, in milliseconds.
  **350** is a normal sentence gap, **900** is a real beat, **0** runs straight
  on into the next sentence.
- **none / beat / long** are one-click shortcuts for 0, 700 and 1200.

The last sentence has no pause box, because nothing follows it.

**Back to normal** puts every pause back to 350.

At the bottom is the total length. In testing it landed within about five
percent of the finished file, so you can match a video before generating.

Pauses are remembered against the sentence itself, so editing one sentence does
not disturb the pauses on the others.

**One thing to know**: if you leave every pause alone, the whole script is made
in one go and you can pick any file type. As soon as you change a pause, or use
pitch, each sentence is made separately and joined here in the browser, and the
file comes out as **WAV**. That is the format you want for editing anyway.

---

## 3. Making a voiceover, step by step

1. Open the bookmark. Top right should say **Server online** with a green
   dot. If it says **Server offline**, jump to section 8.

2. **Find a voice.** The left panel lists all 45 voices. Use the three
   dropdowns to narrow it down:

   - **Language** - All English, American English, British English, Hindi,
     Nepali, Older English voices, or Every voice. See section 4a.
   - **Gender** - female or male.
   - **Voice tone** - see section 4 for what these mean.

   Every voice has a **play button**. Press it to hear that voice read a
   short sample. The first sample takes a few seconds to make, then that
   voice plays instantly. Press again to stop.

3. **Pick the voice** by clicking anywhere on its row. The circle on the
   left fills in, the row turns light purple, and the voice appears in the
   **Selected voice** box on the right so you always know which is active.

   If the list looks short, a filter is still on from last time. Press
   **Show all 28 voices** just under the search box.

4. **Type or paste your script.** Add stars around anything you want
   stressed.

5. **Choose a Delivery style** - see section 5. This changes the speed and
   how much pausing goes into the read.

6. **Audio file type**: leave it on **WAV** for anything going into a video
   edit. See section 6.

7. Optional: drag **Speaking speed** if the style's default is not right.

8. Click **Generate voiceover**, or press Ctrl and Enter together.

9. When it finishes, press the big **Download audio file** button. The
   file is named after the first few words of your script and the voice,
   for example `welcome-to-the-tour-aoede.wav`.

**Reset** next to the Generate button wipes the script and puts every
setting back to the start. It asks first, so you cannot lose work by
accident.

---

## 4. What the voice tones mean

These are not opinions. Every English voice was measured on this server
reading one identical sentence, and the labels come from those numbers.

| Tone | What was measured |
| --- | --- |
| **Expressive** | Pitch moves a lot while speaking (12 semitones or more). These sound the most alive. Flat voices are the ones that sound robotic. |
| **Balanced** | Moderate pitch movement (8 to 12 semitones). Safe for most work. |
| **Even** | Very little pitch movement (under 8). Level and calm, but can sound flat on a long read. |
| **Deep** | Low pitch, under 120 Hz. |
| **Warm** | Low to mid pitch, 120 to 160 Hz. |
| **Clear** | Mid pitch, 160 to 185 Hz. |
| **Bright** | Higher pitch, over 185 Hz. |
| **Soft** | Quiet and breathy. Good for calm reads, weak over music. |
| **Measured** | Naturally speaks slower than the rest. |
| **Brisk** | Naturally speaks faster than the rest. |

The list is ordered with the most expressive voices at the top, because
flat delivery is the usual reason a voiceover sounds fake. Very breathy or
very slow voices are pushed to the bottom.

**Good starting points**: Aoede, Kore and Jadzia (American female,
expressive), Fenrir and Eric (American male, expressive), Heart and Bella
(American female, clean and steady), Alice and Lily (British female),
Michael and Puck (American male, deep).

---

## 3a. Words that come out wrong

Under the controls there is **How to say certain words**.

Put the word on the left and a spelling that sounds right on the right, then
that swap happens on every line, every time, for good.

The one you almost certainly want:

| Word | Spell it as |
| --- | --- |
| Calilio | try `Kuh lee lee oh` or `Ka lee lee oh` |

Left alone, the voice reads Calilio as **"KAL-ih-lee-oh"** with a short a and a
short i. Add the entry, press the play button on a line, and keep adjusting the
spelling until it sounds right. Spaces between the syllables help.

Use it for client names and product names too.

---

## 4a. The Language dropdown

| Option | What you get |
| --- | --- |
| **All English** | The 28 current English voices. This is the default. |
| **American English** | 21 of them. |
| **British English** | 7 of them. |
| **Hindi** | 4 Hindi voices. Write the script in Devanagari. English typed here gets read out letter by letter. |
| **Nepali** | The same 4 Hindi voices. Read section 4b before using this. |
| **Older English voices** | 13 extra voices from the earlier version of the model. Different, not better. |
| **Every voice** | All 45 at once. |

## 4b. About Nepali - read this before using it

**There is no Nepali voice.** The model this runs on does not have one, and
we cannot add one.

What the Nepali option actually does is show you the **Hindi** voices. If
you write your script in Devanagari they will read it, because Nepali and
Hindi share the script. But they will read it with **Hindi pronunciation
and a Hindi accent**, so Nepali-specific words and sounds will come out
wrong in places.

Whether that is good enough is your call, not something we can measure.
Play a sample, then generate one short paragraph and listen to it properly
before you commit a whole script to it.

The same applies to Nepali-accented or Indian-accented English: the model
does not have those voices either.

---

## 5. Delivery styles

| Style | What it does |
| --- | --- |
| **Natural** | Normal speed, light pausing. Good default. |
| **Conversational** | Slightly faster, fewer pauses. Social clips, vlogs. |
| **Professional** | A touch slower with more breathing room. Explainers, demos. |
| **Formal** | Slowest, long pauses, strong stress. Announcements, legal reads. |
| **Narration** | Slow with long pauses between clauses. Voiceover over footage. |
| **Energetic** | Fast and punchy with hard stress. Ads, trailers. |

Picking a style fills in all four controls below it. The moment you change
any of them by hand the style switches to **Custom**, which just means "you
are driving now". **Back to the preset** puts the style's own numbers back.

### The four controls you can drive yourself

- **Speed** - 0.50x to 1.60x. How fast it talks.
- **Pitch** - minus 6 to plus 6 semitones. How high or low the voice is.
  The model itself has no pitch control, so this is done by re-timing the
  audio after it is made. Two things follow from that:
  - it also moves the **length** by roughly a tenth, so nudge Speed if the
    timing matters;
  - the file comes out as **WAV** while pitch is anything other than 0.
  Small moves (2 to 3 semitones) sound natural. Big moves start to sound
  like a cartoon, so listen before you commit.
- **Pause length** - None, Light, Medium or Long. How aggressively long
  sentences get broken up with commas or `...`.
- **Word stress** - Light, Medium or Strong. How big a pause goes in front
  of a word you put `*stars*` around.

---

## 6. Which file type to pick

**Always choose WAV** for anything going into a video edit.

- **WAV** - full quality, uncompressed. This is what you want.
- **FLAC** - also full quality but smaller. Fine if your editor accepts it.
- **MP3** - compressed, loses quality. Only for sending someone a rough
  version to listen to, never in a final edit.
- **OPUS** - smallest file, compressed. Same warning as MP3.

**Never** screen-record or re-record the player on the page to get your
audio. Always use the Download button.

---

## 7. Tips

- **Punctuation is your control panel.** A comma is a short pause, a full
  stop is a longer one, and `...` is longer still. If a line sounds rushed,
  add punctuation. This is more effective than changing the speed slider.
- **Numbers and abbreviations** are sometimes read oddly. If "CEO" or
  "2026" comes out wrong, spell it how it should sound
  (for example "C E O", "twenty twenty six").
- **Do a short test first** on a long script. Generate one paragraph, check
  the voice and stress are right, then do the whole thing.
- **Long scripts work**, they just take longer. The timer shows how long it
  has been running. Leave the tab open.
- **Your work is remembered.** Close the tab and come back, and your
  script, voice, style, speed and file type are still there.
- **Be honest about the limit.** This is a small model running on a normal
  office computer. It will not match ElevenLabs or other paid cloud tools.
  What it will do is sound clearly better when you pick an expressive
  voice, mark your stresses, and let the page fix the punctuation.

---

## 8. If something looks wrong

**The voice will not change / it is stuck on one voice.**
Your browser is running an old copy of the page. Hold **Ctrl** and press
**F5** to force a fresh one. At the very bottom of the page there is a
"Page version" number, which should read `2026-08-07a` or later.

**The voice list only shows a few voices.**
A filter is still on from last time. Press **Show all 28 voices** under the
search box.

**Anything else looks stuck.**
Press **Reset** next to the Generate button. That clears every saved
setting and starts fresh.

## 9. If the page will not load at all

Do not try to fix it yourself and do not reinstall anything.

If you are using the **office wifi address**, check:

1. Are you on the **office wifi**? Not guest wifi, not a phone hotspot.
2. Did you type the address exactly, including `http://` at the front and
   `/web/studio.html` at the end?

If you are using the **internet link**, it has almost certainly expired.
Those links are temporary by design.

Either way, **contact the office manager** and say:
*"The voiceover tool is not loading, can you send me a fresh link."*

That is all you need to do. It is fixed at their end, not yours.

---

## 10. The old page

The original player is still there at:

    http://10.10.20.64:8880/web/

You do not need it. It is kept only as a backup. Note that it does **not**
add the missing full stops for you, so scripts pasted into it can come out
cut short.
