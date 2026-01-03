# 🌐 lysz210 Ecosystem - Backbone

Questo progetto è il "cuore" della mia infrastruttura su AWS. Contiene le configurazioni di base che permettono a tutti i miei siti e applicazioni (i Microfrontend) di funzionare sotto l'identità unica **lysz210.me**.

## 🎯 Obiettivi

* **Identità Unica:** Gestione del dominio principale **`lysz210.me`** e dei certificati di sicurezza (SSL) per tutti i sottodomini.
* **Controllo Spese:** Un budget centralizzato di **5€** che mi avvisa via email se i crawler dei motori di ricerca o il traffico anomalo superano le aspettative.
* **Condivisione:** Fornisce le impostazioni base necessarie ai nuovi progetti per agganciarsi al dominio principale in totale autonomia.

## 🏗️ Cosa gestisce

1. **DNS:** La "mappa" che indirizza i visitatori verso i vari sottodomini (es. `cv.lysz210.me`).
2. **Certificati:** La crittografia (HTTPS) valida per `lysz210.me` e tutti i suoi sottodomini.
3. **Parametri:** Una lista di impostazioni condivise (sotto il namespace `/lysz210/`) utilizzate dai microfrontend per riconoscere l'ambiente.
4. **Budget:** Un sistema di allerta intelligente che monitora sia la spesa attuale che quella prevista a fine mese.

## 🚀 Deployment Automatico

L'infrastruttura si aggiorna da sola per minimizzare la manutenzione:

* **Push su GitHub:** Ogni volta che effettuo un `git push` sul ramo principale, **Terraform Cloud** intercetta la modifica e applica gli aggiornamenti