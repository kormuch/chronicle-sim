# Brainstorm: Combat System — Chronicle Sim

Arbeitsnotiz. Sammlung, keine fertigen Regeln.

---

## 1. Aktueller Stand (GameManager.gd)

### Kampfformel
```
effective = roll + (stat + weapon_bonus + stance_bonus + rally_bonus) * 5 - difficulty * 2
```
- `roll`: 1–100 (randi() % 100 + 1)
- `stat`: strength/wits/grit je nach Stance (Wert 1–5)
- `weapon_bonus`: 0, +1 (legend ≥ 1), +2 (legend ≥ 3)
- `stance_bonus`: 0–3, je nach Szenario
- `difficulty`: 4–10, je nach Szenario

### Hit Tiers
| effective | Tier | Spieler-dmg | Selbst-dmg |
|---|---|---|---|
| ≤ 5 | fumble | 0 | 2–3 |
| ≤ 25 | miss | 0 | 1–2 |
| ≤ 50 | glancing | 1–2 | 0 |
| ≤ 75 | solid | 3–5 | 0 |
| ≤ 90 | critical | 6–7 | 0 |
| > 90 | devastating | 8–9 | 0 |

### Gegner-Gegenangriff
```
counter_roll = randi() % 100 + 1
counter_effective = counter_roll + enemy_attack * 10 - (stat + stance_bonus) * 3
```
Gleiche Tier-Schwellen, aber mit `enemy_*` Damage-Table.

### Group Status (Moral)
4 Stufen: strong → holding → wavering → breaking
- Beeinflusst durch Spieler-Ergebnis pro Runde
- Wavering/breaking: "Rally"-Option erscheint
- Breaking + forward stance: "exposed flank!"-Warnung

### Aktuelle Waffen
| Waffe | Typ | Fumble | Rolle |
|---|---|---|---|
| Dagger | puncture | 2 | Letzte Reserve, schnell, präzise. Sonderrolle: Sneak Attacks, Wachen eliminieren, leise Optionen in Adventures |
| Hunting Knife | slash | 2 | Schnell, vielseitig, Alltagswaffe |
| Shortsword | slash | 3 | Bronze, Standardwaffe |
| Longsword | slash | 4 | Eisen — extrem selten, Häuptlingswaffe, Prestigeobjekt |
| Spear | puncture | 5 | Standardwaffe jedes Kriegers |
| Javelin | puncture | 6 | Wurf + Nahkampf, Rearward-fähig |
| Axe | slash | 8 | Brutal, riskant, Alltagswerkzeug |
| Hammer | crush | 7 | Schädelbrecher |
| Club | crush | 8 | Primitiv, hoher Fumble |
| Bow | puncture | 5 | Fernkampf, Rearward |
| Sling | crush | 4 | Fernkampf, unterschätzt, Rearward-fähig |

### Rüstung (Setting: späte Bronzezeit, Eisen extrem selten)
| Stufe | Bezeichnung | Soak | Verfügbarkeit |
|---|---|---|---|
| none | Ungeschützt | 0 | Standard |
| leather | Gehärtetes Leder | 1 | Verbreitet |
| bronze | Bronzeschuppen/-platten | 2 | Selten, Statussymbol |

### Stats
| Stat | Rolle | Stance |
|---|---|---|
| Strength | Kampfkraft | Forward (+1), Open (+0) |
| Wits | Taktik | Rearward (+2, nur Bogen/Speer/Javelin/Sling) |
| Grit | Zähigkeit, Endurance (grit*3+5) | Defensive (mit Schild +2, ohne +0) |
| Heart | Warband-Moral (passiv) | Kein Stance — verlangsamt Moralverfall, stärkt Rally |

### Dread / Nobility
Reputations-Achse, kein gut/böse:
- **Dread**: Feinde ergeben sich schneller ODER kämpfen bis zum Tod (bei hohem Dread keine Gnade erwartet). Feinde laufen ggf. weg.
- **Nobility**: Keine direkte Kampfauswirkung. Wirkt bei Diplomatie, Allianzen, Adventure-Entscheidungen.
- Geändert durch Mercy-Choice bei Surrender (Spare → +Nobility, Execute → +Dread)

### Forward Initiative ✅
- Forward-Stance: Spielerangriff wird IMMER zuerst aufgelöst
- Wenn Gegner am Spielerangriff stirbt → kein Counter-Angriff
- Kein Lighter-First-Reorder in Forward-Stance

### Kill-Flag-System ✅
- Texteinträge mit `kill: true` → Gegner stirbt sofort, unabhängig von verbleibenden HP
- Alle devastating-Einträge + ausgewählte criticals (Kehle, Auge, Schädel, Wirbelsäule)
- Verhindert narrative Inkonsistenz (Kopf ab → aber Gegner lebt weiter)

### Grit-Save bei >50% HP-Verlust ✅
- Gegner verliert >50% Max-HP in einem Schlag → Rettungswurf oder Stunned
- Rettungschance: devastating 20%, critical 30%, sonst 50%

### Legend-System ✅
- Waffe wird durch Kills aufgeladen: Legend +1 nach 1., 3., 6., 10., 15., 21. Kill
- Boss-Kill gibt immer Legend +1
- Legend beeinflusst weapon_bonus: +1 ab Legend 1, +2 ab Legend 3
- Eigene Flavor-Texte für First Blood, Folge-Kills, Boss-Kills

### Consecutive Kills → Morale Impact ✅
- `consecutiveKills` wird gezählt, Reset bei >3 Counter-Schaden
- 2 consecutive: Enemy-Morale eine Stufe runter + "Die feindliche Linie zögert"
- 3+ consecutive: Morale auf `breaking` + "Angst breitet sich aus"

### Rout-Mechanik ✅
- Wenn `breaking` + >50% der Feinde tot + kein Boss → Feinde fliehen
- Kampf endet sofort mit Sieg

### 2-Handed Weapons ✅
- Battle Axe, Hammer: `twoHanded: true`
- UI deaktiviert Shield-Checkbox bei 2H/Ranged-Waffen
- Balance-Test überspringt Defensive(shield) für 2H-Waffen

### Warband-System
- Warband kämpft parallel im Hintergrund (Attrition pro Runde)
- Befehl einmal vor Kampfbeginn: Charge (aggressiv) / Hold the Line (balanced) / Shield Wall (defensiv)
- Surrender-Logik: Wenn feindliche Gruppe auf 1-2 reduziert und kein Boss → Ergeben-Option
- Ally-Wipe = Niederlage, Enemy-Wipe = Gegner allein (reduzierte Effektivität)

### Stun-Recovery
- Defensive Stance heilt Stun ("Recover — find your footing")
- Wenn stunned: nur Recover-Option verfügbar, kein Angriff, aber defensiver Bonus gegen Counter

### Kampfszenen-Schema (Adventure JSON)
```json
"combat": {
    "enemy":          "Name",
    "enemy_hp":       7–16,
    "enemy_table":    "enemy_ashkin",
    "enemy_attack":   2–4,
    "difficulty":     4–10,
    "max_rounds":     3–4,
    "win_scene":      "scene_id",
    "lose_scene":     "scene_id",
    "stalemate_scene":"scene_id",
    "round_1_text":   "optional Sondertext Runde 1",
    "stances": [
        {
            "label":       "Beschreibung",
            "stat":        "strength|wits|grit",
            "stance_type": "forward|open|defensive|rearward",
            "bonus":       0–3,
            "conditions":  ["optional"]
        }
    ]
}
```

---

## 2. MERP-Referenz: Standardwaffen (CST-1)

### Waffenkategorien und Schadenstypen

**1H Hiebwaffen** (Slash) — mit Schild kombinierbar
| Waffe | Fumble-Range | Primär-Crit | Gewicht | Besonderheit |
|---|---|---|---|---|
| Breitschwert | 1–3 | Slash | 4 lb | Standard |
| Dolch | 1 | Puncture(C) | 1 lb | −15 OB, max C-Crit |
| Handaxt | 1–4 | Slash | 5 lb | +5 OB vs. Kette/Platte |
| Krummsäbel | 1–4 | Slash | 4 lb | −5 OB Kette, +5 OB sonst |
| Kurzschwert | 1–2 | Slash | 3 lb | Bonus Kette/Platte, Malus sonst |

**1H Wuchtwaffen** (Crush) — mit Schild kombinierbar
| Waffe | Fumble-Range | Primär-Crit | Gewicht | Besonderheit |
|---|---|---|---|---|
| Keule | 1–4 | Crush(D) | 5 lb | −10 OB, max D-Crit |
| Streitkolben | 1–2 | Crush | 5 lb | Standard |
| Morgenstern | 1–8 | Crush | 5 lb | +10 OB, B-Crit bei Fumble, großer Fumble-Range |
| Netz | 1–6 | Grapple | 3 lb | — |
| Kriegshammer | 1–4 | Crush | 5 lb | +5 OB |
| Peitsche | 1–6 | Grapple(C) | 3 lb | −10 OB |

**1H Stangenwaffen** — Schild ODER +10 OB (Wahl)
| Waffe | Fumble-Range | Primär-Crit | Besonderheit |
|---|---|---|---|
| Wurfspeer | 1–4 | Puncture | Wurfwaffe (30'), −10 OB, aus 2. Reihe |
| Speer | 1–5 | Puncture | −5 OB, aus 2. Reihe |

**2H Waffen** — kein Schild möglich
| Waffe | Fumble-Range | Primär-Crit | Besonderheit |
|---|---|---|---|
| Streitaxt | 1–5 | Slash + Crush | +5 Kette/Platte, −5 sonst |
| Flegel | 1–8 | Crush + Puncture | +10 OB, C-Crit bei Fumble, riesiger Fumble-Range |
| Kampfstab | 1–3 | Crush | −10 OB |
| Zweihänder | 1–5 | Slash + Crush | Standard |

**Fernwaffen** — nicht im Nahkampf nutzbar
| Waffe | Fumble-Range | Reichweite | Besonderheit |
|---|---|---|---|
| Kompositbogen | 1–4 | 75' | Laden(1) oder Nachladen(0) −25 OB |
| Armbrust | 1–5 | 90' | Laden(2), +20 OB bis 50' |
| Langbogen | 1–5 | 100' | Laden(1) oder Nachladen(0) −35 OB |
| Kurzbogen | 1–4 | 60' | Laden(1), mit Schild nutzbar |
| Schleuder | 1–6 | 50' | Crush(D), Laden(1) |

### MERP-Kernprinzip: Fumble-Risk vs. Damage-Output
- Schwere/mächtige Waffen haben **höheren Fumble-Range** (Flegel 1–8 vs. Dolch 1)
- Kompensiert durch höheren OB-Bonus oder stärkere Criticals
- **Tradeoff**: Macht vs. Kontrolle

---

## 3. MERP-Referenz: Critical Hit Tables — Vollständige Beschreibungen

Quelle: MERP Appendix A-10, Tabellen CT-1 bis CT-5, FT-1/FT-2. Alle Texte 1:1 aus dem PDF.
Schweregrade laufen von leicht (−49 bis −05) bis tödlich (120). Für Chronicle Sim relevant sind die Einträge ab Schwere 66, weil dort der atmosphärische Text beginnt.

### CT-1 — CRUSH (Keulen, Hämmer, Fäuste, Stampfen)

| Roll | Beschreibung |
|---|---|
| −49 – 05 | Weak grip. No extra damage. +0 hits. |
| 06 – 20 | Minor fracture of ribs. +5 hits. −5 to activity. |
| 21 – 35 | Blow to side. +4 hits. −40 to activity for 1 round. |
| 36 – 50 | Blow to forearm. +5 hits. If no arm armor, stunned 1 round. |
| 51 – 65 | Blow to shield shoulder breaks shield. If no shield: shoulder broken, arm useless. |
| 66 – 79 | Bone breaks in leg. +12 hits. −40 to activity. Stunned 2 rounds. |
| **80** | **Strike to forehead. +30 hits. One eye destroyed. If no helm: a 1 month coma results.** |
| 81 – 86 | Blow to weapon arm. +8 hits. Stunned 2 rounds. If no arm armor: tendon damaged, arm broken and useless. |
| 87 – 89 | Shatter knee. +9 hits. −60 to activity. Knocked down and stunned for 3 rounds. |
| **90** | **Blow to back of neck paralyzes from the shoulders down. +25 hits. Foe quite stunned.** |
| 91 – 96 | Unconscious for 4 hours due to blow to side of head. If no helm: skull crushed. +20 hits. |
| 97 – 99 | Blast to chest sends rib cage through lungs. Drops and dies in 6 rounds. Vicious. |
| **100** | **Blow to jaw. Drives into bone into brain. Dies instantly.** |
| 101 – 106 | Breaks hip. +15 hits. −75 to activity. Knocked down and stunned 3 rounds. |
| 107 – 109 | Strike crushes throat. Cannot breath and stunned for 12 rounds. Poor fool then expires. |
| **110** | **Crushes hip. +35 hits. Stunned for 2 rounds. Active the following 4 rounds, but then dies of nerve failure.** |
| 111 – 116 | Shatter elbow in weapon arm. Arm useless. Stunned 5 rounds. |
| 117 – 119 | Blow to side crushes chest cavity. Drops and dies in 3 rounds. |
| **120** | **Blast to chest area. Destroys heart. Dies immediately. +25 hits. Fine work.** |

**Flavor-Muster**: Betäubung, Knochenbrüche, innere Zertrümmerung. Selten Blutung — Opfer werden bewusstlos geschlagen, Organe kollabieren. Schilde werden zerbrochen. Tödlich durch Schädelbruch, Rippenbruch in Lunge, Herzversagen.

---

### CT-2 — SLASH (Schwerter, Äxte, Klauen)

| Roll | Beschreibung |
|---|---|
| −49 – 05 | Weak strike yields no extra damage. +0 hits. |
| 06 – 20 | Minor calf wound. 1 hit per round. Glancing blow to side. +3 hits. |
| 21 – 35 | Blow to upper leg. +5 hits. If no leg armor: +3 hits & 2 hits/rnd. |
| 36 – 50 | Minor chest wound. +3 hits. 1 hit per round. −5 to activity. |
| 51 – 65 | Minor forearm wound. +4 hits. 2 hits per round. Stunned 1 round. |
| 66 – 79 | Medium thigh wound. +6 hits. 1 hit per round. −10 to activity. Stunned 2 rounds. |
| **80** | **Neck strike severs carotid artery. Neck broken. Dies in 1 round of intense agony.** |
| 81 – 86 | Slash weapon arm. +10 hits. 1 hit per round. If no arm armor: muscle and tendon damage, arm broken and useless. |
| 87 – 89 | Destroys one eye. +10 hits. Stunned for 30 rounds. |
| **90** | **Disemboweled, dies instantly. 25% chance your weapon is stuck in opponent for 2 rounds.** |
| 91 – 96 | Knocked out for 6 hours with a strike to side of head. +15 hits. If no helm: dies instantly. |
| 97 – 99 | Sever lower leg. 20 hits per round. Drops and lapses into unconsciousness. |
| **100** | **Slash side. Down, unconscious and dies in 3 rounds due to massive internal organ damage.** |
| 101 – 106 | Major abdominal wound. +10 hits. 8 hits per round. −10 to activity. Stunned for 4 rounds. |
| 107 – 109 | Sever weapon arm. 15 hits per round. Down and unconscious immediately. |
| **110** | **Impaled in heart. Dies instantly. 25% chance your weapon is stuck in foe 3 rounds.** |
| 111 – 116 | Sever hand. 12 hits per round. Knocked down and stunned for 6 rounds. |
| 117 – 119 | Sever spine. Collapses immediately. Paralyzed from the neck down permanently. +20 hits. |
| **120** | **Strike to head destroys brain. Life is hard for the unfortunate fool. Expires in a heap, immediately.** |

**Flavor-Muster**: Blutung über Runden (1–20 hits/rnd), Gliedmaßen abgetrennt, Sehnen durchtrennt. Tödlich durch Enthauptung, Ausweidung, Herzstich. Waffe bleibt im Gegner stecken (25%). Schwerste Verletzungen = sofort bewusstlos + Verbluten.

---

### CT-3 — PUNCTURE (Speere, Pfeile, Dolche, Bisse)

| Roll | Beschreibung |
|---|---|
| −49 – 05 | Glancing blow. No extra damage. |
| 06 – 20 | Glancing blow to side. +3 hits. |
| 21 – 35 | Thigh strike. +3 hits. If no leg armor: 3 hits per round. |
| 36 – 50 | Minor forearm wound. +2 hits. If no arm armor: stunned 1 round. |
| 51 – 65 | Strike along side of chest. 1 hit per round. Stunned 1 round. |
| 66 – 79 | Strike to lower leg. Tendons torn. +3 hits. −25 to activity. |
| **80** | **Strike to neck. Nerves and blood vessels severed. Dies of a massive heart failure.** |
| 81 – 86 | Strike to weapon arm. +10 hits. If no arm armor: bone broken, stunned 3 rounds. |
| 87 – 89 | Strike through lower leg. Sever muscle. −50 to activity. Stunned 3 rounds. |
| **90** | **Strike through both lungs. Drops and passes out. Dies in 6 rounds.** |
| 91 – 96 | Strike to side of head. Knocked out for 6 hours. +10 hits. If no helm: dies instantly. |
| 97 – 99 | Strike through neck breaks backbone and severs spine. Paralyzed from the neck down, permanently. |
| **100** | **Strike through eye. Dies instantly. A real eye full.** |
| 101 – 106 | Major abdominal wound. +10 hits. 6 hits per round. −20 to activity. Stunned 4 rounds. |
| 107 – 109 | Nailed in lower back. Down and unconscious. Dies from internal bleeding and shock in 6 rounds. |
| **110** | **Shot through heart. Reels 10 feet to a spot suitable for dying. Weapon stuck in spinning victim for at least 3 rounds.** |
| 111 – 116 | Strike through leg. Artery severed. Down and unconscious. 12 hits per round. |
| 117 – 119 | Strike through kidneys. +9 hits. Knocked down and dies after 6 rounds of very intense agony. Sad. |
| **120** | **Shot through both ears. Hearing impaired, dies immediately. Awesome shot.** |

**Flavor-Muster**: Durchdringung spezifischer Körperstellen. Sehnen gerissen, Organe durchbohrt. Blutung langsamer als Slash, aber tödlicher bei Organtreffern. Tödlich durch Hals/Auge/Herz/Niere. Trockener Humor bei extremen Ergebnissen ("A real eye full", "Awesome shot").

---

### CT-4 — UNBALANCING (Rammen, Tritte, Schildstoß, Wucht ohne Waffe)

| Roll | Beschreibung |
|---|---|
| −49 – 05 | Fairly weak. +0 hits. Zip. |
| 06 – 20 | Arm strike. +2 hits. −5 to activity for 2 rounds. |
| 21 – 35 | Leg strike. +4 hits. If no leg armor: stunned 1 round. |
| 36 – 50 | Chest strike. Knocked back 3 feet. +5 hits. −10 to activity for 2 rnds. |
| 51 – 65 | Blow to shield arm. +5 hits. Shield torn away. If no shield: +8 hits and stunned 2 rounds. |
| 66 – 79 | Elbow strike. Forearm numbed. +8 hits. Drop weapon. −10 to activity for 10 rounds. |
| **80** | **Brutal hip strike. Knocked down. Tendon torn and joint shattered. Leg useless. −80 to activity.** |
| 81 – 86 | Shot to side. Knocked 5 feet sideways. Drop anything carried in hands. Stunned 3 rounds. |
| 87 – 89 | Side strike. Stumble ungracefully to an embarrassing prone position. Stunned 6 rounds. |
| **90** | **Back strike. Knocked flying 10' onto face. Severe nerve damage. Paralyzed from waist down.** |
| 91 – 96 | Hard head strike. Knocked back 10' and stunned 6 rounds. If no helm: unconscious for 24 hours. |
| 97 – 99 | Totally awesome strike. Knocked to knees. If using 1 hand weapon: it is thrown backwards 10 feet. Stunned 15 rounds. |
| **100** | **Upper chest strike. Knocked 10' sideways. Fall down, break both arms. A 2 month coma results.** |
| 101 – 106 | Breaks leg. +12 hits. −50 to activity. Stunned 4 rounds. |
| 107 – 109 | Strike to head. Knocked 10' back. +9 hits. Stunned 6 rounds. If no helm: a 4 week coma results. |
| **110** | **Savage blow to head. Knocked down. Dies in 12 rounds due to severed vein.** |
| 111 – 116 | Great side shot. Knocked down and sideways 5'. Lower leg broken. Stunned 7 rounds. −40 to activity. |
| 117 – 119 | Blow to shield shoulder. Stunned 9 rounds. −20 to activity. If no shield: unconscious and upper arm shattered. |
| **120** | **Frightening strike to temple. Knocked back 20 feet. Dies instantly. Not nice.** |

**Flavor-Muster**: Zurückschleudern (3–20 Fuß!), Waffe/Schild fliegt weg, Position verloren. Selten sofort tödlich — Opfer wird kampfunfähig gemacht. Komischer Unterton ("Zip", "ungracefully", "Not nice", "Totally awesome strike"). Betäubung in Runden statt Blutung.

---

### CT-5 — GRAPPLING (Ringen, Würgen, Festhalten)

| Roll | Beschreibung |
|---|---|
| −49 – 05 | An opportunity lost. |
| 06 – 20 | Passing strike. +2 hits. |
| 21 – 35 | Attack fended off. +3 hits. If arm armor: stunned 1 round. |
| 36 – 50 | Leg attack. Spun about, but breaks loose. If leg armor, stunned 1 round. |
| 51 – 65 | Shield arm entangled. If shield: −50 to activity until it is dropped. If no shield: −50 to activity. |
| 66 – 79 | Weapon arm grasped. Disarmed and wrist sprained. Stunned 2 rounds. −25 to activity. |
| **80** | **Both legs entangled. Down and knocked out. +9 hits.** |
| 81 – 86 | Weapon arm grasped. Ligaments torn and muscle pulled. +3 hits per round. −40 to activity. Stunned 3 rounds. |
| 87 – 89 | Completely entangled and immobilized. Knocked down, but still conscious. No activity. |
| **90** | **Vicious hold around neck. Knocked out. Sprained neck: −60 to activity.** |
| 91 – 96 | Head grappled. Stunned 9 rounds. If no helm: coma (1–10 days) results due to a fractured skull. |
| 97 – 99 | Both arms entangled and pinned to chest. Arms may not be moved until entanglement removed. −75 to activity. |
| **100** | **Neck grappled. If neck armor: −60 to activity due to neck sprain and stunned 3 rounds. If not: dies from broken neck.** |
| 101 – 106 | Chest grasped. Ribs broken. Stunned 5 rounds. −10 to activity. |
| 107 – 109 | Legs entangled and completely immobilized. Fall and break weapon arm. Disarmed and knocked out. +20 hits. |
| **110** | **Neck grappled. If neck armor: disarmed and stunned 5 rounds. If not: dies in 6 rounds.** |
| 111 – 116 | Foot entangled. Stumble, fall, break weapon on impact, and stunned 2 rounds. If no chest armor: take a 'D' crush crit. |
| 117 – 119 | Both legs wrapped up. Tumbles to ground and knocked out. −80 to activity due to a broken ankle. +20 hits. |
| **120** | **Windpipe crushed. Dies instantly due to massive shock and savage asphyxiation.** |

**Flavor-Muster**: Immobilisierung, Entwaffnung, Würgen. Kein Blut — Kontrolle über Gegner. Tödlich nur durch Genickbruch oder Erdrosseln. Entangled = Kampf vorbei ohne Tod. Rüstung schützt paradoxerweise vor Grappling (Helm schützt vor Schädelbruch, Nackenrüstung vor Genickbruch).

---

### FT-1 — HAND ARMS FUMBLE TABLE (Nahkampf-Patzer)

| Roll | Beschreibung |
|---|---|
| −49 – 05 | Lose your grip. No further activity this round. |
| 06 – 20 | You slip. If your weapon is 1-handed and non-magic, it breaks. |
| 21 – 35 | Bad follow-through. You lose your opportunity, give yourself 2 hits. |
| 36 – 50 | Drop your weapon. It will take 1 round to draw a new one or 2 rounds to recover old one. |
| 51 – 65 | You lose your wind and realize that you should try to relax. −40 to activity for 2 rounds. |
| 66 – 79 | The classless display leaves you stunned for 2 rounds. With luck, you might still survive. |
| **80** | **Incredibly inept move. Roll a 'B' crush crit on yourself. If opponent is using a slashing weapon, your weapon is broken.** |
| 81 – 86 | Bite and swallow tongue in the excitement. Stunned 2 rounds. |
| 87 – 89 | Lose your grip on your weapon and reality. Stunned 3 rounds. |
| **90** | **Poor execution. You attempt to maim yourself as your weapon breaks. You take a 'C' slash crit.** |
| 91 – 96 | Unbelievable mishandling of your weapon. A friendly combatant near you takes a 'B' crush crit. |
| 97 – 99 | Stumble over an unseen, imaginary, deceased turtle. You are very confused. Stunned 3 rounds. |
| **100** | **Worst move seen in ages. −60 to activity from a pulled groin. Foe is stunned 2 rounds laughing.** |
| 101 – 106 | You fall in an attempt to commit suicide. Stunned 3 rounds. If using a pole-arm, its shaft is shattered. |
| **110** | **You stumble, driving your weapon into the ground. Stunned 5 rounds. If mounted: you pole vault 30', take a 'C' crush crit upon landing.** |
| 117 – 119 | You do not coordinate your movement with your mount's. −90 to activity for next 3 rounds trying to stay mounted. |
| **120** | **You fall off your mount. Roll a 'D' crush crit on yourself.** |

**Flavor-Muster**: Schwarzer Humor durchgehend. Waffe bricht, fällt hin, verletzt sich selbst, verletzt Verbündete. Gegner lacht. Imaginary deceased turtle. Pole vault 30 feet. "Worst move seen in ages." Eigene Verbündete nehmen Criticals. Fumbles sind peinlich, nicht nur schmerzhaft.

---

### FT-2 — MISSILE WEAPONS FUMBLE TABLE (Fernkampf-Patzer)

| Roll | Beschreibung |
|---|---|
| −49 – 05 | Lose your grip. No further activity this round. |
| 06 – 20 | One's ten thumbs just cannot handle loading. Lose this round. |
| 21 – 35 | Fumble ammunition. Lose this round. −50 to activity next round. |
| 36 – 50 | Break ammunition and lose your cool. You find yourself at −30 activity for 3 rounds of action. |
| 51 – 65 | Drop ammunition. Stunned this round and next trying to decide whether to retrieve it. |
| 66 – 79 | You really mishandle your weapon. Stunned 2 rounds. |
| **80** | **Poor judgment. +5 hits. If not using a crossbow, you let arrow fly, lose an ear and take 2 hits per round.** |
| 81 – 86 | Bowstring breaks. 2 rnds to draw a weapon or 6 rnds to restring bow. |
| 87 – 89 | Fumble ammunition when loading. You scatter all of your ammunition over a 10' radius area. |
| **90** | **Weapon shatters. You are stunned for 4 rounds of action. Good luck, pal.** |
| 91 – 96 | You let your arrow fly too soon. You strike 20' short of target. You are at −30 activity for 3 rnds. |
| 97 – 99 | You seem to think that your bow is a baton. Trying to grab it, it slips. You knock it 5' in front of you. |
| **100** | **Ammunition slips as you fire. The missile goes through your hand; its useless. +8 hits. 2 hits per round.** |

**Flavor-Muster**: Munition geht verloren, Bogen bricht, Sehne reißt. Schießt sich selbst (Ohr ab, Hand durchbohrt). Weniger tödlich als Nahkampf-Fumbles, aber kampfunfähig machend.

---

### Zusammenfassung: Was macht MERP-Criticals atmosphärisch stark?

1. **Körperspezifisch**: Nie "du triffst ihn" — immer Knie, Schlüsselbein, Halsschlagader, Auge
2. **Konsequenzen statt Zahlen**: "Arm useless", "paralyzed from waist down", "dies in 6 rounds" — nicht "+20 HP"
3. **Zeitliche Dimension**: Opfer stirbt nicht sofort, sondern "in 6 rounds of intense agony" oder "collapses, then dies of nerve failure after 4 rounds"
4. **Schwarzer Humor bei Extremen**: "A real eye full", "Fine work", "Not nice", "deceased imaginary turtle", "Foe stunned 2 rounds laughing"
5. **Rüstung als narratives Element**: "If no helm: skull crushed", "If no shield: shoulder broken" — Rüstung erzählt die Geschichte mit
6. **Waffe bleibt stecken**: 25% Chance dass die Waffe im Gegner steckt — brillantes Detail
7. **Collateral**: Fumbles treffen Verbündete ("A friendly combatant takes a 'B' crush crit")
8. **Eskalation spürbar**: Von "stunned 1 round" über "knocked 10 feet" bis "dies instantly" — jeder Schweregrad fühlt sich anders an

---

## 4. Was fehlt / Probleme im aktuellen System

### ~~Keine Waffen-Differenzierung im Kampf~~ ✅ GELÖST
### ~~Kein Rüstungssystem~~ ✅ GELÖST
### ~~Fumble-Range nicht waffenabhängig~~ ✅ GELÖST
### ~~Critical-Typen nicht mechanisch relevant~~ ✅ GELÖST
### ~~Defensive-Stance dominiert~~ ✅ GELÖST (Forward Initiative)
### ~~Kill-Texte inkonsistent mit HP~~ ✅ GELÖST (kill-Flag)
### ~~Legend-System nicht sichtbar~~ ✅ GELÖST (Kill-Threshold-System)
### ~~Keine Rout-Mechanik~~ ✅ GELÖST (breaking + >50% tot → Flucht)
### ~~2H-Waffen + Schild kombinierbar~~ ✅ GELÖST (twoHanded-Flag)

### Keine Reichweiten-Mechanik
- Bogen, Speer, Javelin, Sling haben keinen Vorteil in Runde 1
- **Offen**: round_1_bonus als Feld?

---

## 5. Ideen / Stellschrauben

### A. Waffen-Differenzierung (einfachste Variante)
Jede Waffe bekommt eigene Schadenswerte statt einheitlich 2/4/6/8:

| Waffe | glancing | solid | critical | devastating | Fumble-self | Besonderheit |
|---|---|---|---|---|---|---|
| Speer | 1–2 | 3–4 | 5–6 | 7 | 2 | Runde 1: +10 effective (Reichweite) |
| Keule | 1–2 | 3–5 | 6–7 | 8 | 3 | Fumble-Range höher (≤ 8 statt ≤ 5) |
| Kurzschwert | 2 | 3–4 | 6 | 7 | 2 | Niedrigster Fumble-self |
| Axt | 2 | 4–5 | 7 | 9 | 3 | Höchster Schaden, höchstes Risiko |
| Bogen | 2 | 3–4 | 6–7 | 8 | 2 | Nur rearward, Runde 1 auto-attack |

**Problem**: Axt wäre immer beste Wahl. Braucht Ausgleich (Fumble oder Schildverlust).

### B. Fumble-Range pro Waffe
Statt fester Schwelle (≤ 5) → waffenabhängig:

| Waffe | Fumble wenn effective ≤ |
|---|---|
| Kurzschwert | 3 |
| Speer | 5 |
| Keule | 8 |
| Axt | 8 |
| Bogen | 5 |

Schwere Waffen fumble öfter, treffen aber härter. MERP-Kernprinzip.

### C. Critical-Typ pro Waffe
Jede Waffe hat einen Critical-Typ, der die Texte in damage_tables.json steuert:

| Waffe | Critical-Typ | Mechanischer Effekt |
|---|---|---|
| Keule | Crush | Gegner betäubt (nächste Runde kein Counter) |
| Schwert | Slash | Blutung (+1 dmg pro Folgerunde) |
| Speer | Puncture | Durchdringung (ignoriert Rüstung bei critical+) |
| Axt | Slash/Crush | Kein Sondereffekt, dafür höchster Rohschaden |

### D. Rüstung ✅ GELÖST — 3 Stufen (Bronzezeit-Setting)
| Stufe | Beispiel | Soak |
|---|---|---|
| None | Ashkin, Wölfe | 0 |
| Leather | Banditen, Jäger | 1 |
| Bronze | Wachen, Häuptlinge | 2 |

Spieler + Gegner haben Rüstung, Schild, Helm als Equipment.

### E. Gegner-Damage-Tables erweitern
Aktuell nur `enemy_ashkin`. Brauchen:

| Gegner-Typ | Angriffs-Typ | Flavor |
|---|---|---|
| enemy_ashkin | Tooth & Claw / Crush | Knochen, Zähne, Steinkeulen |
| enemy_bandit | Slash | Rostige Schwerter, Dolche |
| enemy_wolf | Tooth & Claw | Bisse, Reißen, Rudeltaktik |
| enemy_boar | Ram / Puncture | Hauer, Überrennen |
| enemy_undead | Grapple / Crush | Greifen, Würgen, kein Schmerzempfinden |

### F. Stance-Standardisierung
Aktuell: Jede Kampfszene definiert eigene Stances ad hoc. Könnte standardisiert werden:

| Stance | Stat | Typischer Bonus | Risiko | Verfügbarkeit |
|---|---|---|---|---|
| Forward | strength | +1 bis +3 | Höherer Gegner-Counter | Immer |
| Open | strength/wits | 0 bis +1 | Standard | Immer |
| Defensive | grit | 0 bis +1 | Niedrigerer Gegner-Counter | Nur mit Schild |
| Rearward | wits | +1 bis +2 | Kein direkter Counter | Nur mit Bogen/Speer |

**Problem**: Forward hat aktuell keinen mechanischen Nachteil. MERP: Forward = höhere OB, aber auch höhere Verwundbarkeit.

### G. Runde-1-Bonus (Überraschung / Aufstellung)
MERP: Überraschung gibt +20. In Chronicle Sim:
- `round_1_text` existiert schon als Feld
- Könnte `round_1_bonus` als Feld dazukommen
- Wert: +10 (leichter Vorteil) bis +30 (Schlaf-Überfall)
- Ersetzt die aktuellen ad-hoc difficulty/HP-Anpassungen

---

## 6. Offene Fragen

- ~~Soll Rüstung ein Spieler-Stat werden oder nur Gegner-Eigenschaft?~~ ✅ Beides
- ~~Wie weit soll Waffen-Differenzierung gehen?~~ ✅ 12 Waffen, eigene Stats
- ~~Sollen Critical-Effekte echte Runden-Mechanik sein?~~ ✅ fx-System implementiert
- ~~Ist das Group-Status-System gut genug?~~ ✅ Warband-Attrition + Heart-Stat + Consecutive Kills + Rout
- ~~Forward Stance nutzlos?~~ ✅ Forward Initiative
- ~~Legend nie sichtbar?~~ ✅ Kill-Threshold-System
- ~~Kill-Texte widersprechen HP?~~ ✅ kill-Flag
- Verschiedene Gegner-Damage-Tables? (aktuell: generisch)
- Runde-1-Bonus für Fernwaffen / Überraschungsangriffe?
- Dagger-Sneak-Mechanik: Wie in Adventure-JSON abbilden?
- Longsword als narratives Objekt: Quest, Erbe, Eroberung?
- Dread/Nobility-Schwellwerte: Ab welchem Wert neue Optionen?
- Kampfformel vereinfachen? (asymmetrische Multiplikatoren 5/10/3/2 → hinten angestellt)
- Waffen-Manöver einbauen? (gesammelt in weapon-maneuvers.md, noch nicht implementiert)
