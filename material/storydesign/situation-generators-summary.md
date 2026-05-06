# Situation Generators — Zusammenfassung & Storytelling-Hinweise
> Basierend auf: *Creating Fun Game Situations* von Levi Kornelsen
> Anwendungskontext: Chronicle Sim — Event-Writing für Founding Era & Growth Era

---

## Überblick

Kornelsen beschreibt sechs modulare Methoden, um aus wenigen Entscheidungen vollständige, spielbare Situationen zu erzeugen. Jede Methode folgt dem gleichen Grundprinzip: **Erst Struktur, dann Detail** — zuerst die Beziehungen und Spannungen klären, dann die Einzelheiten ausschmücken.

Kernthese: Eine gute Spielsituation entsteht nicht durch eine interessante Welt, sondern durch **Charaktere, die voneinander wollen, was sie nicht bekommen können**.

---

## Methode 1 — Long Knives (Fehden & Intrigen)

**Kernidee:** Mehrere Gruppen stehen in Spannung zueinander. Die Spieler werden hineingezogen, weil beide Seiten sie brauchen.

### Schritte:
1. **Gruppen-Liste** — 4–8 Gruppen benennen, die im Raum aktiv sind (Familien, Gilden, Fraktionen, Clans)
2. **Fraktionen** — Für jede Gruppe: Ziel, Ressource, Feind, Verbündeter
3. **Streit erzeugen** — Auslöser / Reaktion / Eskalation: Wer hat angefangen? Was wurde erwidert? Was droht jetzt?
4. **Appeal** — Zwei Besucher/Kontakte, die die Spieler aktiv ansprechen und ins Geschehen ziehen

### Strukturelle Hinweise:
- Der Auslöser muss *nicht gerecht* sein — das erzeugt moralische Graubereiche
- Jede Seite braucht etwas, das die Spieler liefern können (Information, Gewalt, Neutralität)
- Eskalation schreibt sich selbst: wenn Seite A reagiert, reagiert Seite B — Kettenreaktion vorprogrammieren

### Anwendung Chronicle Sim:
- **Faction events**: Streit zwischen zwei Siedlungs-Lagern (Händler vs. Handwerker, Einwanderer vs. Alteingesessene)
- **Conditions**: `merchant_guild_hostile`, `faction_strife_active`
- Gut für **Founding Era** (Gründungsstreitigkeiten) und **Growth Era** (wirtschaftliche Rivalitäten)

---

## Methode 2 — Broken Places (Schurke übernimmt die Macht)

**Kernidee:** Eine Struktur mit legitimer Macht wird von innen heraus durch eine Gegenmacht unterwandert. Die Spieler müssen entscheiden, ob und wie sie eingreifen.

### Schritte:
1. **Orts-Geschichte** — Was war dieser Ort früher? Wer lebte hier, was war seine Funktion?
2. **Legitime Ordnung** — Wer hat offiziell die Macht, und was sind ihre Regeln?
3. **Echte Macht** — Wer hat die Kontrolle wirklich? Wie hat der Schurke sie gewonnen?
4. **Einstieg** — Hook (warum kommen Spieler?), Kontakte (wer hilft?), Netzwerk (wer weiß was?), Insider (jemand, der auf beiden Seiten steht)

### Strukturelle Hinweise:
- Der "Schurke" braucht eine nachvollziehbare Logik — kein reines Böse
- Insider sind die dramatisch interessanteste Figur: loyale Person, die zögert
- Die legitime Ordnung ist oft selbst korrupt — das macht die Entscheidung schwieriger

### Anwendung Chronicle Sim:
- **Corruption arc**: Stadtrat wird von Kaufmann infiltriert; Sheriff arbeitet für Holzfäller-Syndikat
- **NPC role**: Insider als recurring character über mehrere Generationen hinweg
- Gut für **späte Growth Era** und **Decline Era** Events

---

## Methode 3 — The Quest (Zeitkritische Reise)

**Kernidee:** Eine Aufgabe muss erfüllt werden, bevor etwas Schlimmes passiert. Jede Verzögerung kostet.

### Schritte:
1. **Grundsituation** — 6 Sätze: Was wird gesucht? Von wem? Warum jetzt? Was passiert bei Scheitern? Wer steht im Weg? Was ist der erste Schritt?
2. **Komplikationen** — Pro Grundelement eine Wendung: Was macht es schwieriger als erwartet?
3. **Timing-Phasen:**
   - **Einführung** — Situation und Dringlichkeit aufbauen
   - **Beschaffung** — Ressourcen/Informationen sammeln (hier passieren erste Komplikationen)
   - **Herausforderungen** — Direkte Hindernisse auf dem Weg
   - **Komplikationen** — Etwas geht schief, Plan ändert sich
   - **Abschluss** — Erfolg, Teilerfolg oder Scheitern mit Konsequenz

### Strukturelle Hinweise:
- Die Uhr läuft immer — das erzeugt Spannung ohne aktive Feinde
- Jede Phase sollte eine neue Information liefern, die die nächste Phase verändert
- Teilerfolg ist oft dramatisch interessanter als vollständiger Erfolg

### Anwendung Chronicle Sim:
- **Multi-generation events**: Quest beginnt in Gen 1, Konsequenz landet in Gen 3
- **Timed events** mit Countdown-Bedingung: `drought_threatens: true`, `epidemic_spreading: true`
- Gut für jede Era — universell anwendbar

---

## Methode 4 — Transgression (Soziale Bewegungen)

**Kernidee:** Eine Gruppe bricht mit der etablierten Ordnung. Drei Seiten entstehen: Transgressoren, Gegner, Neutrale. Die Spieler müssen sich verorten.

### Schritte:
1. **Das Thema** — Was ist der Bruch? Welche Rhetorik benutzen beide Seiten?
2. **Die Geschichte** — Identifikationsfigur / Fürsprecher / Treffpunkt / Ziel der Bewegung
3. **Die Gegenseite** — Anführer / Anhänger / Ressourcen der Opposition
4. **Der Konflikt** — Wie spitzt es sich zu? (3 mögliche Eskalations-Plots)
5. **Drei Spieler-Positionen** — Als Teil der Bewegung / Als Teil der Opposition / Als Außenstehende mit eigenem Interesse

### Strukturelle Hinweise:
- Beide Seiten müssen *Recht haben* in mindestens einem Punkt — sonst kein Drama, nur Propaganda
- Der Treffpunkt (Taverne, Kirche, Markt) ist wichtiger als der Anführer — er gibt der Bewegung Substanz
- Spieler-Position muss *kostspielig* sein: Jede Wahl schließt eine andere aus

### Anwendung Chronicle Sim:
- **Social events**: Aufstand der Leibeigenen, Religionsstreit, Einwanderer-Integration
- **Moral choice events**: Keine richtige Antwort, nur Konsequenzen
- `moral_tension: true` als event-Flag
- Besonders stark für **Founding Era** (wer darf mitentscheiden?) und **Growth Era** (Arbeiterbewegung, Ungleichheit)

---

## Methode 5 — Predator Souls (Monster-Jagd)

**Kernidee:** Eine Bedrohung existiert, die nicht einfach besiegt werden kann. Die Spieler müssen sie verstehen, bevor sie sie stoppen können.

### Schritte:
1. **Das Monster** — Identität / Hunger / Jagdmethode / Agenda / Revier / Geschichte
2. **Infektion & Schwarm** — Wie verbreitet es sich? Wer ist bereits betroffen?
3. **Jagdreviere** — 3 Orte mit konkreten Spuren und Zeugen
4. **Hook** — Warum werden Spieler aktiv? (Pflicht / Rache / Belohnung / Bedrohung)

### Strukturelle Hinweise:
- Das Monster braucht eine Logik, keine bloße Bösartigkeit
- Zeugen und Spuren sind wichtiger als direkte Konfrontation
- "Infektion" (Menschen, die für das Monster arbeiten) erzeugt Paranoia

### Anwendung Chronicle Sim:
- **Crisis events**: Banditen-Hauptmann, Seuche als "Predator", parasitärer Händler
- Weniger wörtlich als andere Methoden — metaphorisch auf wirtschaftliche/soziale Bedrohungen übertragbar
- Gut für **Decline Era** oder **Crisis Moments**

---

## Methode 6 — Nine Rooms (Dungeon-Design)

**Kernidee:** Ein physischer oder konzeptueller Raum wird durch Funktionen statt durch Beschreibungen strukturiert.

### Raum-Funktionen:
| Typ | Funktion |
|-----|----------|
| Eingänge & Ausgänge | Kontrollpunkte, erste Eindrücke |
| Schatzkammern | Was wird hier bewacht? |
| Geheimnisse | Was ist verborgen, was offenbart es? |
| Schalter | Was verändert die Umgebung? |
| Gauntlets | Durchlauf-Herausforderungen, kein Entkommen |
| Gefahren | Passive Risiken (Fallen, Umgebung) |
| Fallen | Aktive Fallen mit Auslöser |
| Originalmerkmale | Was macht diesen Ort einzigartig? |
| Invertierte Merkmale | Was wurde umgekehrt oder verdorben? |
| Begegnungen | Themen-Ambush / Offener Kampf / Geweckter Brute |

### Strukturelle Hinweise:
- Karte zuletzt zeichnen — erst Funktion, dann Topografie
- Invertierte Merkmale sind der stärkste Hinweis auf Geschichte
- Begegnungen brauchen Variation: nicht alles auf Konfrontation ausrichten

### Anwendung Chronicle Sim:
- Weniger direkt anwendbar (kein klassisches Dungeoncrawling)
- **Nützlich für**: Orte mit Geschichte (alte Mine, verlassene Burg, Kathedrale)
- Raum-Funktionen → **Location-Events** mit mehreren möglichen Outcomes

---

## Übergreifende Storytelling-Prinzipien

### 1. Spannungsstruktur vor Details
Immer zuerst: *Wer will was von wem?* — erst dann Aussehen, Namen, Beschreibungen.

### 2. Dreiecks-Dramatik
Die interessantesten Situationen haben drei Seiten, nicht zwei. Jede Partei zieht in eine andere Richtung.

### 3. Kosten der Entscheidung
Eine Wahl ist nur dann dramatisch, wenn jede Option etwas kostet. Keine richtigen Antworten.

### 4. Insider-Figuren
Eine Person, die auf beiden Seiten steht, ist immer interessanter als ein Bote von einer Seite.

### 5. Eskalationslogik
Jede Aktion hat eine Reaktion. Situationen schreiben sich selbst fort, wenn die Reaktions-Kette klar ist.

### 6. Timing als Werkzeug
Dringlichkeit ersetzt Feinde. Eine Deadline ohne Gegner erzeugt genauso viel Spannung.

---

## Mapping auf Chronicle Sim Event-Schema

| Generator | Event-Typ | Empfohlene Felder |
|-----------|-----------|-------------------|
| Long Knives | Faction conflict | `conflict_type: faction`, `sides: [a, b]`, `player_appeal` |
| Broken Places | Corruption / Power shift | `npc_betrayal`, `insider_npc`, `power_structure_change` |
| The Quest | Time-limited mission | `deadline_gen`, `phases: [intro, acquire, challenge, complication, close]` |
| Transgression | Social movement | `moral_tension: true`, `three_sides`, `rhetorik_a`, `rhetorik_b` |
| Predator Souls | Threat / Crisis | `threat_type`, `spread_mechanic`, `evidence_locations` |
| Nine Rooms | Location event | `location_history`, `room_functions`, `encounter_type` |

---

## Empfehlung für Event-Writing Prioritäten

**Founding Era** (braucht 24 Events):
- 8× Long Knives (Gründungsstreitigkeiten, Ressourcenkonflikte)
- 6× Transgression (Wer hat Mitsprache? Wer gehört dazu?)
- 5× The Quest (erste Expedition, erster Winter, erste Krise)
- 3× Broken Places (erste Korruption, Machtergreifung)
- 2× Predator Souls (erste externe Bedrohung)

**Growth Era** (braucht 20 Events):
- 6× Transgression (Ungleichheit, Arbeit, Migration)
- 5× Long Knives (wirtschaftliche Rivalitäten)
- 4× The Quest (Expansion, Handel, Diplomatie)
- 3× Broken Places (Institutionelle Korruption)
- 2× Predator Souls (wirtschaftlicher Parasitismus)
