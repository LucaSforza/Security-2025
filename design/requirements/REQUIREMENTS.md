# Cosa scrivere nella relazione
- Come funzione il tool che stiamo utilizzando? Ovvero: cosa significare fare fuzzing? e Echidna come impone le proprietà richieste dallo sviluppatore?
- Il significato del codice che hai scritto per verificare le proprietà.
- Includi screenshot dell'output del tool prima e dopo che hai trovato l'errore.

- Report non più lungo di 10 pagine.

# Parte 1

- Taxpayer class record informations about individuals
    - If person x is married to person y then person y is married to person x
    - add invariants to the code and use Echidna to detect possible violations
    - Fix complaints by:
        - correcting the code
        - add a precodition for the method
        - add an invariant for another property that can help in the verification
    - Hints
        - introduce one invariant at a time
        - Se il tool produce dei warnings allora:
            - C'è un errore nel codice
            - C'è un errore nelle specifiche
            - Ci potrebbero essere proprietà mancanti ma necessare dal tool per la verifica.