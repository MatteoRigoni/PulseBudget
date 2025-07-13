# PulseBudget

**PulseBudget** è un'app mobile Flutter per la gestione delle finanze personali, con categorizzazione automatica delle spese tramite AI offline.  
Supporta importazione estratti conto (CSV/PDF), analisi, ricorrenze, backup locale/cloud e funziona completamente offline.

---

## Caratteristiche principali

- **Gestione entrate e uscite** con categorie personalizzabili (icone, colori)
- **Analisi e report** per categoria, periodo, trend
- **Movimenti ricorrenti** (es. abbonamenti, stipendi)
- **Importazione estratti conto** (CSV/PDF) con AI Naive Bayes offline per la categorizzazione automatica
- **Ricerca e filtro movimenti** (full-text, periodo, categoria)
- **Backup e ripristino** (JSON/CSV, locale o cloud a scelta utente)
- **Supporto multi-account/patrimoni**
- **Completamente offline**: i dati restano sul dispositivo
- **Tema chiaro/scuro** (Material 3)
- **Test unitari e widget**

---

## Screenshot

*(Aggiungi qui screenshot dell'app se disponibili)*

---

## Installazione e Avvio

### Prerequisiti

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.0.0)
- Android Studio / VSCode / Xcode (per build e test su device/emulatore)
- Dart >=3.0.0

### Clona il repository

```sh
git clone https://github.com/tuo-utente/pulsebudget.git
cd pulsebudget
```

### Installa le dipendenze

```sh
flutter pub get
```

### Avvia in debug su emulatore/dispositivo

```sh
flutter run
```

### Build per Android (APK/AAB)

```sh
flutter build apk --release
# oppure
flutter build appbundle --release
```

### Build per iOS

```sh
flutter build ios --release
```

---

## Struttura del progetto

- `lib/`
  - `ui/` — Schermate e widget principali (Home, Movimenti, Categorie, Ricorrenti, Report, Import)
  - `model/` — Modelli dati (Transaction, Category, RecurringRule, ecc.)
  - `providers/` — Provider Riverpod per stato e logica
  - `repository/` — Repository per accesso dati (SQLite, astratti)
  - `services/` — Servizi (database, backup, parsing PDF, AI, ecc.)
  - `theme/` — Temi Material 3
- `assets/` — Immagini e risorse
- `test/` — Test unitari e widget

---

## Funzionalità avanzate

- **Import PDF/CSV**: parser universale, anteprima modificabile, AI locale per suggerire categoria, training incrementale.
- **Backup/Restore**: esporta/importa dati in JSON/CSV, scegli dove salvare (locale/cloud).
- **Ricorrenze**: regole flessibili, generazione automatica movimenti futuri.
- **Analisi**: grafici, trend, dettaglio per categoria.
- **AI offline**: categorizzazione automatica tramite Naive Bayes + regole keyword, addestrabile dall’utente.

---

## Tecnologie e dipendenze principali

- **Flutter** (Material 3, multiplatform)
- **Riverpod** (state management)
- **Sqflite** (database locale)
- **pdf_text** (estrazione testo PDF)
- **isar** (AI training set)
- **fl_chart** (grafici)
- **file_picker, share_plus, open_file** (import/export)
- **flex_color_picker, flutter_iconpicker** (UI)
- **rxdart** (debounce search)
- **intl** (localizzazione, date, valute)

Vedi `pubspec.yaml` per la lista completa.

---

## Backup e privacy

- I dati restano **sempre sul dispositivo**.
- Puoi esportare/importare i tuoi dati in qualsiasi momento.
- Nessun dato viene inviato a server esterni.
- Backup compatibili con Excel (CSV) e modificabili (JSON).

---

## Contribuire

Pull request e segnalazioni sono benvenute!  
Per contribuire:

1. Forka il repo
2. Crea una branch feature/bugfix
3. Fai una PR descrivendo la modifica

---

## Licenza

MIT

---

## Autore

Matteo Rigoni  
[matteo.rigoni2@gmail.com](mailto:matteo.rigoni2@gmail.com)

---

Se vuoi aggiungere altre sezioni (FAQ, changelog, roadmap) fammi sapere! Vuoi la versione in inglese?
