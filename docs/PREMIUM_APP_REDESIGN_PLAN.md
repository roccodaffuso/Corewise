# Corewise Premium App Redesign Plan

Last updated: 2026-07-09

## Summary

Corewise deve evolvere da MVP diagnostico funzionante a utility macOS premium: piu chiara, piu calma, piu trasparente nel senso nativo del termine, e piu affidabile a colpo d'occhio.

Questo documento non propone nuove feature diagnostiche. Definisce come ridisegnare la superficie dell'app usando solo segnali reali gia presenti, componenti macOS familiari, materiali di sistema, griglie stabili e una gerarchia piu adulta.

Obiettivo visivo: una utility Apple-native seria, non una dashboard SaaS, non una cleaner app, non un clone di Monitoraggio Attivita. Corewise deve sembrare "Activity Monitor explained better": numeri reali, contesto leggibile, azioni manuali sicure.

## Research Inputs

### Apple Design Resources

Apple mette a disposizione risorse ufficiali per progettare app con template, icon production templates, color guides e UI kit macOS. Per Corewise questo significa: usare la struttura Apple come baseline, non inventare chrome proprietario dove il sistema ha gia convenzioni solide.

Applicazioni per Corewise:

- usare SF Pro come famiglia primaria;
- usare SF Mono o monospaced digits per colonne numeriche e valori diagnostici;
- usare SF Symbols come vocabolario iconografico principale;
- allineare sidebar, toolbar, Settings e popover a convenzioni macOS prima di aggiungere personalita.

### Human Interface Guidelines

Le sezioni HIG da tenere come riferimento operativo sono Materials, Sidebars, Popovers e Charts. Anche quando la documentazione web e renderizzata via JavaScript, la direzione progettuale e chiara: materiali, navigazione laterale, popover e grafici devono essere leggibili, contestuali e coerenti con il sistema.

Applicazioni per Corewise:

- i materiali servono a creare profondita e separazione, non decorazione;
- la sidebar deve sembrare una source list premium, non un menu web;
- il menu bar popover deve restare una superficie compatta, non una mini-dashboard rumorosa;
- i grafici devono spiegare un solo punto alla volta e non sostituire tabelle quando i dati sono process rows.

### Liquid Glass Direction

Apple ha spostato la direzione visuale dei sistemi recenti verso superfici piu traslucide, vive e integrate. La lezione utile per Corewise non e "rendere tutto di vetro": e lasciare che materiali e trasparenze rafforzino la gerarchia.

Applicazioni per Corewise:

- standard SwiftUI/AppKit structure prima di custom glass;
- sidebar, toolbar, sheets e Settings devono sfruttare comportamenti nativi;
- superfici custom glass solo dove servono davvero: hero, summary strip, menu bar popover, pannelli di contesto;
- nessun layer scuro opaco che uccide il materiale di sistema;
- niente glass decorativo su ogni card.

### Competitive Utility Signals

Le utility Mac premium vincono quando riducono ansia e aumentano controllo. Le cleaner app piu note spesso sono molto levigate, ma il loro rischio e sembrare aggressive: linguaggio di fix, promesse di pulizia, file "offenders", urgenza visiva. Corewise deve prendere solo la cura visuale, non il posizionamento.

Applicazioni per Corewise:

- evitare parole come "offenders" quando non c'e una diagnosi certa;
- preferire "selected scan", "review", "inspect", "open in Finder";
- mostrare la fonte del dato in modo calmo;
- dare priorita a Performance, Storage Scan e Report come workflow, non a completezza apparente della sidebar.

## Current Design Problems

- La UI e piu utile di prima, ma alcune pagine sembrano ancora assemblate per blocchi invece che progettate come sistema.
- Le prime tile non sempre si allineano tra pagine: cambiando sezione si percepisce un "gradino".
- I pannelli hanno spesso peso visivo simile; manca una gerarchia forte tra hero, summary, tabella e note.
- La trasparenza e presente, ma non ancora abbastanza intenzionale: lo sfondo deve sembrare un materiale macOS, non un grigio appoggiato sopra la finestra.
- La sidebar e migliorata, ma deve diventare piu source-list premium: selezione sottile, meno saturazione, piu profondita.
- Le pagine dense, soprattutto Performance, devono usare una grammatica da utility: summary sopra, tabella primaria, spiegazioni laterali o sotto.
- Data Access e provenance sono importanti, ma non devono dominare il primo viewport.
- Il menu bar popover funziona, ma deve diventare piu "instrument panel": compatto, raffinato, con barre misurate e non pesanti.

## Redesign Principles

### 1. Trust Before Spectacle

Ogni elemento premium deve aumentare fiducia. Se un effetto rende meno leggibile un numero, va eliminato.

### 2. System First, Custom Second

Corewise deve sembrare costruita con macOS, non sopra macOS. Usare `NavigationSplitView`, toolbar, Settings scene, popover e controlli nativi come base.

### 3. Material As Hierarchy

Materiali e trasparenze devono indicare profondita:

- window background: materiale piu morbido e continuo;
- sidebar: materiale separato, source-list;
- hero: superficie piu evidente ma non pesante;
- metric tiles: leggermente piu quiete;
- tabelle: quasi piatte, molto leggibili;
- source notes: basse, leggere, secondarie.

### 4. Fewer Boxes, Better Rails

Ridurre l'effetto "griglia di card". Ogni pagina deve avere un layout riconoscibile:

- hero coerente;
- summary strip coerente;
- content grid coerente;
- tabelle con colonne stabili;
- note e azioni sempre nella stessa posizione relativa.

### 5. Operational Data First

Il primo viewport deve rispondere a una domanda reale:

- Overview: "cosa sta succedendo ora?";
- Performance: "chi sta consumando CPU/RAM/swap?";
- Storage: "quanto spazio ho e cosa ho scelto di esplorare?";
- Report: "cosa posso copiare per capire o condividere?";
- Battery/Thermal/Startup/App Issues: "cosa e leggibile in modo sicuro?".

### 6. Soft Natural Color, Sparse Semantics

La palette deve sembrare naturale, non neon:

- moss green: live/good/available;
- graphite/stone: superfici e testo;
- muted blue/teal: info/planned;
- amber: attention/swap pressure;
- red: critical o used storage, con moderazione.

Non usare colori casuali per chart o pannelli. Non colorare ogni tile.

## Visual System Proposal

### Window Background

Direzione:

- base con materiale macOS reale;
- leggero wash semitrasparente adattivo;
- nessun grande gradiente decorativo;
- nessuna orb/bokeh/shape astratta.

Light mode:

- materiale chiaro, sfondo lattiginoso molto controllato;
- pannelli con hairline fredda e testo alto contrasto;
- accenti leggermente desaturati.

Dark mode:

- sfondo scuro ma non nero pieno;
- superfici graphite con materiale visibile;
- contrasto testo piu alto dell'attuale dove i secondari risultano spenti.

### Sidebar

Direzione:

- source list premium, non menu blu;
- selezione con fill traslucido sottile;
- piccolo indicatore/accent leading o simbolo attivo;
- icone a peso coerente;
- niente badge rumorosi nella navigazione;
- Settings resta sotto come footer link discreto, non sezione diagnostica.

Acceptance:

- la selezione non deve sembrare cheap o web;
- in dark mode non deve dominare l'interfaccia;
- in light mode deve restare leggibile senza diventare grigia.

### Hero

Ogni pagina deve avere una hero coerente, ma non marketing.

Struttura:

- icona o mini visuale a sinistra;
- titolo pagina;
- valore primario a destra quando esiste;
- sottotitolo con fonte/limite chiaro;
- badge di stato singoli e non ripetuti.

Regole:

- Overview hero: `Live Signals`, non score;
- Performance hero: pressione live CPU/memoria/swap;
- Storage hero: volume + spazio libero;
- Report hero: snapshot locale;
- pagine con pochi dati devono dichiarare limite, non riempire con metriche deboli.

### Summary Strip

Una striscia di metriche compatte subito sotto hero.

Regole:

- altezza stabile tra pagine;
- 2-4 colonne a seconda della larghezza;
- numeri con monospaced digits;
- label breve;
- sublabel tecnico solo se utile;
- niente card alte con molto copy.

Esempio Overview:

- CPU total;
- Memory used;
- Swap used/trend;
- Top CPU;
- Top Memory;
- Storage free;
- Battery;
- Thermal.

### Panels

Definire quattro varianti, non inventarne una per pagina:

- `HeroPanel`: maggiore profondita, massimo uno per pagina.
- `MetricTile`: piccolo, numerico, densita alta.
- `OperationalPanel`: contiene tabella/lista primaria.
- `InsightPanel`: spiegazione o safe action, visivamente secondaria.

Regole:

- radius moderato;
- hairline sottile;
- ombra quasi nulla;
- materiale/tint leggero;
- no card dentro card;
- no per-row badges quando la fonte e comune.

### Tables

Performance, Startup e App Issues devono sembrare utility professionali.

Regole:

- colonne numeriche right-aligned;
- tabular digits;
- row height costante;
- alternanza leggera o separator line, non entrambe pesanti;
- path lunghi compressi in secondary text o detail disclosure;
- badge fonte a livello tabella;
- colonne opzionali nascoste in narrow window.

### Charts And Bars

Corewise deve usare chart e progress bar come lettura secondaria, non come effetto dashboard.

Regole:

- chart con un messaggio solo;
- storage used rosso/muted red, available verde;
- swap amber se alto o crescente;
- CPU blue/teal;
- memory moss/green se normale, amber se pressione;
- axis/scale sempre chiari;
- niente numeri tipo "185 / 190" senza unita e spiegazione.

## Page-by-Page Redesign

### Overview

Ruolo: command center di segnali live.

Da tenere:

- `Live Signals`;
- CPU, memory, swap, top CPU, top memory;
- storage free;
- battery/thermal;
- score planned come riga secondaria.

Da cambiare:

- Data Access sotto il primo viewport o collapsible;
- summary strip piu compatta e allineata;
- top process panels piu eleganti e meno "dashboard card";
- coverage utile, ma non protagonista se distrae.

Acceptance:

- entro 3 secondi l'utente capisce che Corewise sta leggendo dati reali;
- non vede uno score mancante come messaggio principale;
- non vede spiegazioni di provenance prima dei segnali.

### Performance

Ruolo: pagina principale del prodotto.

Struttura proposta:

- hero compatta con CPU total, memory used, swap used;
- segmented control `CPU / Memory`;
- top pressure panel con barre leggibili;
- table top 24 processi;
- `What this means` come insight, non al posto della tabella;
- `Swap Insight` solo in Memory mode, sotto summary e prima della tabella se c'e spazio.

Da cambiare:

- ridurre confusione verticale;
- togliere `Live` da ogni riga;
- rendere la tabella piu simile a strumento nativo;
- mostrare path lunghi solo quando servono.

Acceptance:

- Codex/Chrome/WindowServer/etc. devono essere rintracciabili velocemente;
- i valori primari devono allinearsi;
- CPU e Memory devono sembrare due modalita della stessa pagina, non due layout diversi.

### Storage

Ruolo: discovery manuale, non cleaner.

Struttura proposta:

- hero con startup volume e free space;
- donut/bar semplice used vs available;
- selected folder explorer;
- largest items from selected scan;
- safe actions: choose folder, reveal in Finder.

Da cambiare:

- "Largest offenders" diventa "Largest items from selected scan";
- empty state piu elegante e meno largo;
- used rosso/muted red, available verde;
- scan controls come toolbar locale, non bottoni sparsi.

Acceptance:

- senza scan manuale la pagina non sembra rotta;
- dopo scan, e chiaro che i risultati sono della cartella scelta, non dell'intero Mac.

### Battery

Ruolo: segnali reali e limiti onesti.

Struttura proposta:

- hero con charge/power source;
- metriche reali in alto;
- unavailable/planned in gruppo secondario;
- copy chiaro su cycle/max capacity se non affidabili.

Acceptance:

- nessun valore sospetto come `2.2% maximum capacity`;
- se una chiave non e affidabile, non appare come numero.

### Startup

Ruolo: inventario read-only.

Struttura proposta:

- hero con count plist letti;
- filtri tipo `All / Agents / Daemons`;
- tabella con label, kind, executable, run at load, keep alive, signed state, recent;
- safe actions in fondo.

Acceptance:

- non sembra una lista di warning;
- ogni riga comunica "review", non "remove".

### Thermal

Ruolo: safe signal, non sensor page.

Struttura proposta:

- hero con `Nominal / Fair / Serious / Critical`;
- nota chiara: niente temperature private;
- contributors solo se basati su CPU sostenuta live.

Acceptance:

- pagina piccola ma credibile;
- nessuna promessa di temperatura o watt.

### App Issues

Ruolo: crash patterns solo dopo scelta utente.

Struttura proposta:

- empty state forte con `Choose Reports`;
- dopo scan: repeated crashes, last crash date, bundle/version, counts 7/30;
- nota privacy sempre visibile ma secondaria.

Acceptance:

- senza report scelti non sembra una feature falsa;
- dopo scelta manuale, i pattern sono leggibili senza stack trace.

### Report

Ruolo: output EtreCheck-like local-first.

Struttura proposta:

- hero con snapshot timestamp;
- segmented `Summary / Markdown`;
- notable findings;
- sections con fonte/confidence;
- copy buttons primari ma sobri.

Acceptance:

- sembra un documento diagnostico, non una schermata secondaria;
- non include raw crash body, stack trace o contenuti file.

### Settings

Ruolo: preferenze locali, non diagnostica.

Struttura proposta:

- finestra Settings nativa;
- TabView/Form;
- copy breve;
- nessun card dashboard-style;
- nessun setting che abilita scansioni automatiche o remediation.

Acceptance:

- sembra una finestra macOS Settings;
- non compete con la sidebar principale.

### Menu Bar Popover

Ruolo: at-a-glance monitor.

Struttura proposta:

- superficie compatta, scura/chiara adattiva;
- tre metric tiles con barre premium;
- due top process rows con mini progress;
- `Open Corewise` come unica azione forte;
- niente refresh button se gia rimosso.

Acceptance:

- sembra un piccolo instrument panel;
- le barre aiutano senza trasformarlo in mini dashboard;
- leggibile a 320-380 px di larghezza.

## Motion And Interaction

Motion ammessa:

- hover/focus lievi sui pannelli interattivi;
- transizioni 150-220 ms;
- cambio segmented control con animazione minima;
- progress bar che aggiorna senza salto;
- menu bar popover che appare stabile, senza coreografia.

Motion vietata:

- page-load choreography;
- bounce/elastic;
- shimmer decorativo persistente;
- animazioni che ritardano la lettura dei dati;
- motion non disattivabile con Reduce Motion.

## Implementation Phases

### Phase 0: Visual Audit

Deliverable:

- screenshot dark/light di tutte le pagine;
- annotazione dei problemi di allineamento;
- lista componenti duplicati;
- decisione su quali panel variants tenere.

Verification:

- nessun codice prodotto prima di avere screenshot di confronto;
- documentare 5-10 problemi visuali concreti, non sensazioni generiche.

### Phase 1: Design Tokens And App Shell

Deliverable:

- layout constants unici;
- surface/material tokens;
- typography scale;
- semantic color tokens;
- sidebar selection premium;
- window background coerente.

Verification:

- switching tra pagine non crea "gradino" nel primo viewport;
- dark/light leggibili;
- nessun full-row blue selection nella sidebar.

### Phase 2: Overview And Menu Bar

Deliverable:

- Overview primo viewport orientato a live signals reali;
- menu bar popover piu premium con barre proporzionali;
- Data Access spostato o compattato.

Verification:

- utente capisce subito CPU/memory/swap/top process;
- `Score Planned` resta secondario;
- menu bar non sembra un menu testuale.

### Phase 3: Performance Flagship

Deliverable:

- summary strip;
- top pressure panel;
- tabella processi compatta;
- Swap Insight integrato con gerarchia corretta;
- insight panel leggibile.

Verification:

- confronto manuale con Monitoraggio Attivita per plausibilita;
- Codex e processi pesanti rintracciabili;
- nessun badge `Live` ripetuto per ogni riga.

### Phase 4: Storage And Report

Deliverable:

- Storage explorer piu chiaro;
- "Largest items from selected scan";
- Report come documento diagnostico premium;
- copy/export local-first.

Verification:

- nessuna cartella personale letta automaticamente;
- empty state Storage utile;
- Report copiabile senza contenuti sensibili.

### Phase 5: Remaining Pages

Deliverable:

- Battery, Startup, Thermal, App Issues allineate alla nuova griglia;
- tabelle dove servono;
- unavailable/planned visivamente quieti.

Verification:

- nessuna pagina sembra meno rifinita delle altre;
- tutte le sezioni hanno hero, summary/primary content, note fonte.

### Phase 6: Polish Gate

Deliverable:

- screenshot set finale;
- narrow window QA;
- light/dark QA;
- reduced motion check;
- contrast check;
- copy audit.

Verification:

- build/test passano;
- nessun valore finto;
- nessun claim di fix o pulizia automatica;
- font, spacing, surface e icon style coerenti.

## Acceptance Criteria

Corewise raggiunge il livello premium quando:

- la sidebar sembra nativa e sobria;
- il primo viewport di ogni pagina parte dalla stessa griglia;
- i numeri diagnostici hanno gerarchia forte e sono leggibili;
- le trasparenze migliorano profondita senza ridurre contrasto;
- Performance sembra la pagina centrale del prodotto;
- Storage comunica esplorazione manuale, non pulizia;
- Report sembra un output utile e condivisibile;
- Settings sembra una finestra macOS, non una dashboard;
- il menu bar popover sembra intenzionale e rifinito;
- nessuna pagina usa colore o vetro solo per "fare premium".

## Non-Goals

- Nessun health score numerico in questa fase.
- Nessuna nuova fonte diagnostica.
- Nessuna scansione automatica di cartelle personali.
- Nessuna azione di delete/move/kill.
- Nessun claim di parita perfetta con Monitoraggio Attivita.
- Nessuna API privata, sensoristica non supportata, sudo o backend.
- Nessun redesign marketing-style.

## Documentation Follow-Up

Quando il redesign viene implementato, aggiornare:

- `docs/DESIGN_SYSTEM.md`: tokens finali, component variants, regole sidebar e materiali.
- `docs/PROJECT_STATUS.md`: stato del redesign e rischi residui.
- `docs/ROADMAP.md`: fasi completate e prossimi polish gate.
- `docs/DECISIONS.md`: decisioni su materiali, sidebar, Performance flagship e score secondario.
- `README.md`: breve nota se il redesign cambia i workflow visibili.

## Source Links

- Apple Design Resources: https://developer.apple.com/design/resources/
- Apple Human Interface Guidelines, Materials: https://developer.apple.com/design/human-interface-guidelines/materials
- Apple Human Interface Guidelines, Sidebars: https://developer.apple.com/design/human-interface-guidelines/sidebars
- Apple Human Interface Guidelines, Popovers: https://developer.apple.com/design/human-interface-guidelines/popovers
- Apple Human Interface Guidelines, Charts: https://developer.apple.com/design/human-interface-guidelines/charts
- Apple Liquid Glass overview: https://developer.apple.com/documentation/technologyoverviews/liquid-glass
- TechRadar CleanMyMac X review, used only as competitive utility reference: https://www.techradar.com/reviews/cleanmymac-x-for-mac-review
