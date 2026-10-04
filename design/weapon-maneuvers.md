# Waffenmanöver — Chronicle Sim

Extrakt aus DSA-Kampfmanöver, angepasst für Chronicle Sim.
Jede Waffe erlaubt bestimmte Manöver, die im Kampf als Stance/Aktion zur Auswahl stehen.

---

## Manöver-Katalog

### WUCHTSCHLAG (Power Strike)
- **Effekt:** Freiwillig eigene Trefferchance senken, dafür mehr Schaden.
- **Umsetzung:** Spieler wählt Ansage (z.B. +2 Schaden, -10 auf Trefferwurf). Risk/Reward.
- **Waffen:** Alle Nahkampfwaffen.
- **Ausschluss:** Bow, Sling (Fernkampf).

### FINTE (Feint)
- **Effekt:** Täuschungsangriff. Senkt die Verteidigung des Gegners für den echten Schlag.
- **Umsetzung:** Wits-basiert statt Strength. Gegner-Difficulty wird reduziert, aber bei Miss härterer Counter.
- **Waffen:** Alle Nahkampfwaffen.
- **Besonders gut mit:** Dagger, Shortsword, Hunting Knife (schnelle Waffen).

### STURMANGRIFF (Charge Attack)
- **Effekt:** Angriff aus dem Lauf. Mehr Schaden, aber keine Verteidigung in der Runde.
- **Umsetzung:** Wie Forward-Stance aber extremer: +3 Bonus, kein Counter-Block möglich.
- **Waffen:** Spear, Battle Axe, Hammer, Longsword, Shortsword, Hand Axe.
- **Ausschluss:** Dagger, Bow, Sling (zu leicht / Fernkampf).
- **Voraussetzung:** Runde 1 oder nach Stance-Wechsel.

### BETÄUBUNGSSCHLAG (Stunning Blow)
- **Effekt:** Schlag mit stumpfer Seite / Knauf. Weniger Schaden, aber hohe Stun-Chance.
- **Umsetzung:** Schadenswurf halbiert, aber Stun bei Solid+ garantiert.
- **Waffen:** Hammer, Club, Battle Axe (Rückseite), Spear (Schaft).
- **Besonders gut mit:** Hammer, Club (ohnehin Crush-Waffen).

### GEZIELTER STICH (Targeted Thrust)
- **Effekt:** Präzisionsstich auf verwundbare Stelle. Ignoriert Rüstung, aber schwerer zu treffen.
- **Umsetzung:** -15 auf Trefferwurf, aber Rüstungssoak wird ignoriert. Cripple-Chance hoch.
- **Waffen:** Dagger, Shortsword, Spear, Longsword.
- **Ausschluss:** Hammer, Club, Battle Axe (keine Stichwaffen).

### ENTWAFFNEN (Disarm)
- **Effekt:** Gegner verliert Waffe. Bereits im System als fx vorhanden.
- **Umsetzung:** Schwerer Angriff (-20), aber bei Treffer → Disarm statt Schaden.
- **Waffen:** Longsword, Shortsword, Hand Axe, Spear.
- **Ausschluss:** Hammer, Club (zu stumpf), Dagger (zu kurz), Bow/Sling.

### NIEDERWERFEN (Knockdown / Trip)
- **Effekt:** Gegner zu Boden werfen. Am Boden = Stunned + nächster Angriff mit Bonus.
- **Umsetzung:** Strength-Check. Bei Erfolg: Gegner verliert nächste Runde, Spieler bekommt freien Angriff.
- **Waffen:** Spear (Schaft), Battle Axe (Haken), Hammer, Club, Shield (Schildstoß).
- **Ausschluss:** Dagger, Bow, Sling.

### SCHILDSTOSS (Shield Bash)
- **Effekt:** Angriff mit dem Schild. Niedriger Schaden, aber Stun-Chance und Gegner zurückdrängen.
- **Umsetzung:** Nur mit Schild. Grit-basiert. 1-3 Schaden + 50% Stun.
- **Waffen:** Alle (solange Schild getragen wird).
- **Voraussetzung:** Player hat Shield.

### BEFREIUNGSSCHLAG (Sweeping Strike)
- **Effekt:** Rundumschlag gegen mehrere Gegner. Teilt Schaden auf.
- **Umsetzung:** Bei Multi-Enemy: trifft aktuellen Gegner UND verursacht 1-2 Schaden an nächstem Gegner in der Reihe.
- **Waffen:** Battle Axe, Longsword, Spear.
- **Ausschluss:** Dagger, Hunting Knife, Shortsword (zu kurz), Hammer/Club (zu schwer für Schwung), Bow/Sling.

### KLINGENSTURM (Blade Storm)
- **Effekt:** Zwei schnelle Angriffe statt einem. Jeder schwächer, aber Chance auf Doppeltreffer.
- **Umsetzung:** Zwei Angriffswürfe mit je -15. Beide können treffen.
- **Waffen:** Shortsword, Dagger, Hunting Knife, Hand Axe.
- **Ausschluss:** Schwere Waffen (Battle Axe, Hammer, Longsword), Fernkampf.

### GEGENHALTEN (Counter-Strike)
- **Effekt:** Defensiv-Angriff: Gegner angreifen lassen und im Moment seines Angriffs zuschlagen.
- **Umsetzung:** Eigener Angriff kommt als Reaktion auf Gegner. Wenn Gegner missed/fumbled → freier Treffer. Wenn Gegner trifft → beide nehmen Schaden.
- **Waffen:** Spear, Longsword, Shortsword, Hand Axe.
- **Ausschluss:** Schwere Waffen (zu langsam für Konter), Fernkampf.

### GEZIELTE FERNATTACKE (Aimed Shot)
- **Effekt:** Längeres Zielen für präziseren Schuss. Verbraucht eine Runde Vorbereitung.
- **Umsetzung:** Runde 1 = Zielen (kein Angriff, kein Counter). Runde 2 = Schuss mit +20 Bonus.
- **Waffen:** Bow, Sling.
- **Nur in Rearward-Stance.**

---

## Waffen → Manöver Matrix

| Waffe | Wucht | Finte | Sturm | Betäub | Gezielt | Entwaffn | Nieder | Schild | Befrei | Klingen | Gegen | Gezielt-Fern |
|-------|-------|-------|-------|--------|---------|----------|--------|--------|--------|---------|-------|-------------|
| Dagger | ✓ | ★ | – | – | ★ | – | – | ○ | – | ★ | – | – |
| Hunting Knife | ✓ | ★ | – | – | ✓ | – | – | ○ | – | ★ | – | – |
| Shortsword | ✓ | ★ | ✓ | – | ✓ | ✓ | – | ○ | – | ★ | ✓ | – |
| Longsword | ✓ | ✓ | ✓ | – | ✓ | ★ | – | ○ | ★ | – | ✓ | – |
| Spear | ✓ | ✓ | ★ | ✓ | ✓ | ✓ | ★ | ○ | ★ | – | ★ | – |
| Javelin | ✓ | ✓ | ✓ | ✓ | ✓ | – | – | ○ | – | – | – | – |
| Hand Axe | ✓ | ✓ | ✓ | – | – | ✓ | – | ○ | – | ✓ | ✓ | – |
| Battle Axe | ★ | ✓ | ★ | ✓ | – | – | ★ | ○ | ★ | – | – | – |
| Hammer | ★ | – | ✓ | ★ | – | – | ✓ | ○ | – | – | – | – |
| Club | ✓ | – | – | ★ | – | – | ✓ | ○ | – | – | – | – |
| Bow | – | – | – | – | – | – | – | – | – | – | – | ★ |
| Sling | – | – | – | – | – | – | – | – | – | – | – | ✓ |

**Legende:**
- ★ = besonders gut geeignet (Bonus auf Manöver)
- ✓ = möglich
- ○ = nur mit Schild
- – = nicht möglich

---

## Design-Notizen

### Was NICHT übernommen wird aus DSA:
- **Windmühle** — zu komplex, P&P-spezifisch (Abwehraktion in Angriff umwandeln)
- **Binden** — Fechtmanöver, zu taktisch für Text-RPG
- **Meisterparade** — P&P-Mechanik, nicht umsetzbar
- **Formation** — Warband-System deckt das ab
- **Tod von Links** — Parierwaffen-System nicht vorhanden
- **Waffe zerbrechen** — zu situativ, Equipment-Verlust frustrierend
- **Festnageln** — Speer-spezifisch und zu nischig für Core-System
- **Halbschwert** — Historisch korrekt aber zu nischig

### Offen für spätere Überlegung:
- **Schildspalter** — Könnte shield_break-Manöver werden (schon als fx vorhanden)
- **Ausfall** — Könnte als aggressive Stance-Variante für Fechtwaffen dienen
- **Defensiver Kampfstil** — Ist de facto bereits die Defensive-Stance

### Prinzip für Umsetzung:
- Jede Waffe hat 2-4 Manöver zur Auswahl (neben den Standard-Stances)
- Manöver ersetzen den normalen Angriff, nicht zusätzlich
- Schwere Waffen (Battle Axe, Hammer) haben wenige aber mächtige Manöver
- Schnelle Waffen (Dagger, Shortsword) haben viele aber schwächere Manöver
- Fernkampfwaffen haben nur Aimed Shot als Spezialmanöver
