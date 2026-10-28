# M32 C4 — conservation, mineurs et suspension Analytics

Préparation du 27 octobre 2026, PR #171 ; suivi #172–#175, parent #159.
Aucune fusion/publication n'est déduite de ces vérifications locales.

## Implémentation

- Web Analytics bloqué au niveau de la configuration Dart et du bridge JavaScript,
  même avec ENABLE_ANALYTICS=true et une ancienne acceptation de moins de 180 jours.
- Choix antérieurs retirés, cookies GA accessibles nettoyés sans toucher au cookie
  fonctionnel témoin ; aucun opt-in proposé. Lien de confidentialité public conservé.
- Notice courte enfant/parent dans les parcours d'authentification existants.
- Politique/conditions/assets synchronisés, durées approuvées et procédure de
  revue mensuelle, support/droits parentaux et proposition de parcours mineurs.
- Outil opérateur review-retention.cjs en lecture seule, un UID explicite, requêtes
  bornées, aucune identité dans le rapport et aucun mode de suppression.

## Vérification

- Suite widgets complète et 124 tests unitaires réussis ; régression ciblée de
  la notice après simplification du texte réussie. Analyse Flutter sans problème.
- Six tests Node : deux pour le bridge (pas d'import/grant, cookies fonctionnels
  préservés, Firebase absent) ; quatre pour la revue (mois calendaires, activité
  récente prioritaire, dates inconnues/futures, refus d'exécution, lectures bornées).
  Ces quatre tests utilisent des services factices, pas des comptes de production.
- Revue du dépôt : aucun constat. Contrôle de whitespace et égalité sémantique
  Markdown/assets réussis.
- Build Web release avec configuration Firebase publique existante et
  ENABLE_ANALYTICS=true réussi ; ce contrôle démontre que le drapeau général
  ne suffit pas à réactiver la mesure.
- [Rapport Chromium](browser-report.json) et captures : ordinateur 1280×900,
  mobile 390×844, tablette 768×1024. Ancienne acceptation et cookie GA synthétiques,
  actualisation, lien de politique, refus de chargement direct du bridge,
  absence de SDK/requête Analytics et d'erreur JavaScript.
- Aucun bouton invité/connexion utilisé, aucun compte créé, aucune écriture
  Firestore observée, aucune suppression de joueur. Ce n'est pas un nouveau
  test complet des parcours Auth/quiz ni une vérification du domaine déployé.
- Aucun résultat Safari/Firefox nouveau revendiqué. La dérogation Safari du
  propriétaire reste distincte de cette validation Chromium.

## Reproduction

Installer les dépendances et Chromium dans playwright/. Compiler un build Web
avec la configuration publique de l'app (ou le build émulateur), en passant
--dart-define=ENABLE_ANALYTICS=true. Servir build/web sur 127.0.0.1:7362 puis :

```sh
node test/web/analytics_pause_test.cjs
node functions/tests/retention-review.test.cjs
node docs/reviews/m32-c4/reproduce.cjs
```

WEB_QA_URL et QA_BROWSER_EXECUTABLE peuvent préciser URL locale et navigateur.
QA_PLAYWRIGHT_MODULE permet de réutiliser une installation Playwright locale.
Dans un environnement proxy, conserver la validation TLS et son certificat CA ;
PLAYWRIGHT_DISABLE_FORCED_CHROMIUM_PROXIED_LOOPBACK=1 permet le serveur local.
Ne pas utiliser de session navigateur de joueur pour cette reproduction.
Les scénarios Playwright équivalents sont dans playwright/tests/analytics-consent.spec.ts.

## Limites et suite

#172 reste ouvert jusqu'à fusion/publication et recontrôle public. #173 reste
ouvert pour le premier inventaire, le suivi privé et une purge partielle compatible
avec l'idempotence/hors ligne ; aucune suppression n'a été autorisée ici. #174
reste ouvert : mode local, accord parental vérifié et profils mineurs privés ne
sont pas implémentés par une simple notice. #175 suit contrats, transferts,
mentions éditeur/hébergeur et rétentions prestataires encore non vérifiés.
C4 et M32 restent ouverts. Plan Spark conservé, aucune Function déployée.
