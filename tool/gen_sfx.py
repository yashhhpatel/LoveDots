"""Synthesizes the game's original sound effects and music loop into assets/sfx."""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sfx')
os.makedirs(OUT, exist_ok=True)
random.seed(7)


def write(name, samples):
    peak = max(1e-6, max(abs(s) for s in samples))
    k = 0.9 / peak if peak > 0.9 else 1.0
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1, min(1, s * k)) * 32767)) for s in samples))


def env(i, n, a=0.005, r=None):
    t = i / SR
    dur = n / SR
    r = dur if r is None else r
    att = min(1.0, t / a) if a > 0 else 1.0
    rel = max(0.0, 1.0 - t / r)
    return att * rel


def tone(freq, dur, vol=0.5, shape='sine', decay=None, vib=0.0):
    n = int(SR * dur)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = freq * (1 + vib * math.sin(2 * math.pi * 6 * t))
        ph += 2 * math.pi * f / SR
        if shape == 'sine':
            v = math.sin(ph)
        elif shape == 'tri':
            v = 2 / math.pi * math.asin(math.sin(ph))
        else:
            v = math.sin(ph) + 0.35 * math.sin(2 * ph) + 0.15 * math.sin(3 * ph)
        e = math.exp(-t / decay) if decay else env(i, n)
        out.append(v * vol * e * min(1, t / 0.004))
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


def delay(track, sec):
    return [0.0] * int(SR * sec) + track


# click: short soft tick
write('click', tone(1400, 0.05, 0.6, 'tri', decay=0.012))

# pop: bubbly pop
pop = []
n = int(SR * 0.12)
ph = 0
for i in range(n):
    t = i / SR
    f = 300 + 900 * math.exp(-t / 0.02)
    ph += 2 * math.pi * f / SR
    pop.append(math.sin(ph) * math.exp(-t / 0.04))
write('pop', pop)

# star: bright ding
write('star', mix(tone(1318, 0.45, 0.45, 'sine', decay=0.15),
                  tone(2637, 0.45, 0.15, 'sine', decay=0.08)))

# coin: two-note bling
write('coin', mix(tone(1568, 0.12, 0.4, 'tri', decay=0.05),
                  delay(tone(2093, 0.3, 0.4, 'tri', decay=0.1), 0.07)))

# tick: wheel peg tick
write('tick', tone(2200, 0.03, 0.4, 'tri', decay=0.006))

# wheel: reward fanfare
notes = [523, 659, 784, 1047]
write('wheel', mix(*[delay(tone(f, 0.35, 0.35, 'rich', decay=0.12), i * 0.09)
                     for i, f in enumerate(notes)]))

# win: kiss "mwah" sweep followed by a sparkly arpeggio
kiss = []
n = int(SR * 0.22)
ph = 0
for i in range(n):
    t = i / SR
    f = 500 + 700 * (t / 0.22)
    ph += 2 * math.pi * f / SR
    kiss.append(math.sin(ph) * math.sin(math.pi * t / 0.22) * 0.5)
arp = [784, 988, 1175, 1568, 1976]
win = mix(kiss, *[delay(tone(f, 0.5, 0.3, 'sine', decay=0.2), 0.18 + i * 0.07)
                  for i, f in enumerate(arp)])
write('win', win)

# page: paper whoosh (filtered noise swell)
pg = []
n = int(SR * 0.45)
lp = 0.0
for i in range(n):
    t = i / SR
    x = random.uniform(-1, 1)
    lp += (x - lp) * 0.18
    pg.append(lp * math.sin(math.pi * t / 0.45) * 1.4)
write('page', pg)

# draw: pen-on-paper scratch, seamless loop
dr = []
n = int(SR * 0.6)
lp = 0.0
hp_prev = 0.0
for i in range(n):
    t = i / SR
    x = random.uniform(-1, 1)
    lp += (x - lp) * 0.5
    hp = lp - hp_prev * 0.3
    hp_prev = lp
    mod = 0.6 + 0.4 * math.sin(2 * math.pi * t / 0.15) ** 2
    dr.append(hp * mod * 0.35)
fade = int(SR * 0.02)
for i in range(fade):
    dr[i] *= i / fade
    dr[-1 - i] *= i / fade
write('draw', dr)

# music: gentle plucked loop (C - Am - F - G), 8 bars at 100 bpm
beat = 60 / 100
prog = [(261.6, 329.6, 392.0), (220.0, 261.6, 329.6),
        (174.6, 220.0, 261.6), (196.0, 246.9, 293.7)]
melody = [659, 784, 880, 784, 659, 587, 523, 587,
          523, 659, 587, 523, 440, 523, 587, 659,
          698, 659, 587, 523, 587, 659, 698, 880,
          784, 698, 659, 587, 523, 494, 523, 587]
total = int(SR * beat * 32)
music = [0.0] * total


def add(track, start):
    s = int(start * SR)
    for i, v in enumerate(track):
        if s + i < total:
            music[s + i] += v


for bar in range(8):
    chord = prog[bar % 4]
    for b in range(4):
        tb = (bar * 4 + b) * beat
        add(tone(chord[0] / 2, beat * 0.9, 0.18, 'tri', decay=0.35), tb)
        for k, f in enumerate(chord):
            add(tone(f, beat * 0.5, 0.06, 'sine', decay=0.15), tb + beat * 0.5 + k * 0.02)
for i, f in enumerate(melody):
    add(tone(f, beat * 0.95, 0.12, 'rich', decay=0.25), i * beat)
write('music', music)
print('ok')
