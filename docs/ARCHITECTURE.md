# Architettura BilancioMe

## Panoramica

BilancioMe è un'app di gestione finanziaria personale che utilizza un **database locale SQLite** con funzionalità di backup e ripristino su cloud storage a scelta dell'utente.

## Architettura dei Dati

### Database Locale (SQLite)
- **Posizione**: `bilanciome.db` nella directory dell'app
- **Vantaggi**: 
  - Funziona completamente offline
  - Performance elevate
  - Controllo completo sui dati
  - Nessuna dipendenza da servizi esterni

### Tabelle del Database

#### 1. `categories`
```sql
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  icon TEXT NOT NULL
)
```

#### 2. `transactions`
```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  description TEXT NOT NULL,
  descriptionLowercase TEXT NOT NULL,
  categoryId TEXT NOT NULL,
  paymentType TEXT NOT NULL,
  isRecurring INTEGER NOT NULL DEFAULT 0,
  recurringRuleName TEXT,
  FOREIGN KEY (categoryId) REFERENCES categories (id)
)
```

#### 3. `snapshots`
```sql
CREATE TABLE snapshots (
  id TEXT PRIMARY KEY,
  entityId TEXT NOT NULL,
  entityType TEXT NOT NULL,
  entityName TEXT NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  note TEXT
)
```

#### 4. `recurring_rules`
```sql
CREATE TABLE recurring_rules (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  amount REAL NOT NULL,
  categoryId TEXT NOT NULL,
  rrule TEXT NOT NULL,
  FOREIGN KEY (categoryId) REFERENCES categories (id)
)
```

## Backup e Sincronizzazione

### Formati di Backup

#### 1. JSON (Completo)
- Contiene tutti i dati dell'app
- Formato leggibile e modificabile
- Ideale per backup completi

#### 2. CSV (Transazioni)
- Solo le transazioni
- Compatibile con Excel e altri programmi
- Ideale per analisi esterne

### Opzioni di Backup

#### Backup Locale
- Salva file nella directory dell'app
- Accessibile tramite file manager
- Condivisibile manualmente

#### Cloud Storage (Manuale)
- L'utente sceglie dove salvare
- Google Drive, OneDrive, Dropbox, ecc.
- Controllo completo sulla privacy

## Vantaggi di questa Architettura

### Per l'Utente
- ✅ **Privacy**: I dati rimangono sul dispositivo
- ✅ **Controllo**: Scelta del servizio di backup
- ✅ **Offline**: Funziona senza internet
- ✅ **Portabilità**: File di backup trasferibili
- ✅ **Indipendenza**: Nessuna dipendenza da servizi specifici

### Per lo Sviluppatore
- ✅ **Semplicità**: Nessuna configurazione server
- ✅ **Affidabilità**: Meno punti di fallimento
- ✅ **Performance**: Database locale veloce
- ✅ **Manutenibilità**: Codice più semplice

## Flusso di Utilizzo

1. **Uso Quotidiano**: App funziona offline con database locale
2. **Backup Periodico**: Utente esporta dati in JSON/CSV
3. **Sincronizzazione**: File salvato su cloud storage preferito
4. **Ripristino**: Import da file di backup quando necessario

## Sicurezza

- I dati sono crittografati nel database locale
- I file di backup possono essere protetti da password
- Nessun dato viene inviato a server esterni
- L'utente controlla completamente i propri dati

## Migrazione da Firebase

Se in futuro si vuole tornare a Firebase:

1. I dati JSON possono essere facilmente importati
2. La struttura del database è compatibile
3. I modelli di dati rimangono gli stessi
4. Solo i repository cambiano implementazione

## Considerazioni Future

### Possibili Miglioramenti
- Backup automatico periodico
- Sincronizzazione automatica con cloud
- Crittografia dei file di backup
- Versioning dei backup
- Compressione dei file di backup

### Alternative Considerate
- **Firebase**: Troppo complesso per un'app personale
- **Supabase**: Buona alternativa open source
- **Appwrite**: Self-hosted ma richiede server
- **SQLite + Cloud**: Soluzione scelta (migliore per privacy e controllo) 