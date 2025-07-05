# Firestore Indexes per BilancioMe

## Indici necessari per le query

### 1. Indice per ricerca per descrizione (descriptionLowercase)

**Collezione:** `transactions`

**Campi da indicizzare:**
- `descriptionLowercase` (Ascending)
- `date` (Descending)

**Tipo:** Composite Index

**Query supportata:**
```dart
.where('descriptionLowercase', isGreaterThanOrEqualTo: query)
.where('descriptionLowercase', isLessThan: query + '\uf8ff')
.orderBy('descriptionLowercase')
.orderBy('date', descending: true)
```

### 2. Indice per filtraggio per periodo

**Collezione:** `transactions`

**Campi da indicizzare:**
- `date` (Ascending)
- `date` (Descending)

**Tipo:** Composite Index

**Query supportata:**
```dart
.where('date', isGreaterThanOrEqualTo: startDate)
.where('date', isLessThanOrEqualTo: endDate)
.orderBy('date', descending: true)
```

### 3. Indice per snapshot per periodo

**Collezione:** `snapshots`

**Campi da indicizzare:**
- `date` (Ascending)
- `date` (Descending)

**Tipo:** Composite Index

**Query supportata:**
```dart
.where('date', isGreaterThanOrEqualTo: startDate)
.where('date', isLessThanOrEqualTo: endDate)
.orderBy('date', descending: true)
```

## Come creare gli indici in Firebase Console

1. Vai su [Firebase Console](https://console.firebase.google.com/)
2. Seleziona il tuo progetto
3. Vai su **Firestore Database** nel menu laterale
4. Clicca sulla tab **Indici**
5. Clicca su **Crea indice**
6. Seleziona la collezione e aggiungi i campi come specificato sopra
7. Clicca su **Crea**

## Note importanti

- Gli indici possono richiedere alcuni minuti per essere creati
- Le query che non hanno un indice corrispondente falliranno con un errore
- È consigliabile creare gli indici prima di testare le funzionalità di ricerca
- Gli indici hanno un costo in base al numero di documenti indicizzati

## Verifica degli indici

Dopo aver creato gli indici, puoi verificare che funzionino correttamente eseguendo le query di ricerca nell'app. Se vedi errori relativi agli indici, controlla che siano stati creati correttamente nella Firebase Console. 