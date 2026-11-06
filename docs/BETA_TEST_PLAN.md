# Première bêta Web — adultes invités

Décision du propriétaire : 6 novembre 2026. Suivi M28 (#62), lancement M32 (#159).
URL : https://quiznetic.eirenya.com ; .fr redirige vers .com.

## Périmètre et conditions d'ouverture

Commencer avec 3 à 5 adultes invités personnellement par le propriétaire.
L'URL est déjà publique : ce choix de recrutement n'est ni une liste d'accès
technique ni une vérification d'âge. Ne pas annoncer une ouverture aux mineurs
avant #174 (mode local, parcours parental vérifié, profils privés).
Aucune invitation, aucun email ni achat n'est effectué par ce document.

Avant les invitations : identifier le commit effectivement publié, contrôler le
parcours ci-dessous sur le domaine public et traiter les points éditeur/contrats
encore ouverts dans #175. Analytics Web reste suspendu, publicités et achats
inactifs. La vérification GA4 attend une éventuelle réactivation ; les données
historiques GA4 ne sont pas réputées effacées. Safari natif reste non testé,
avec dérogation de lancement du propriétaire.

L'invité utilise déjà Firebase Auth ; il ne s'agit pas d'un mode purement local.
Le classement est public pour les comptes permanents : choisir un pseudonyme,
pas un nom complet ou une adresse email. Les contrôles Spark bornent les données
mais ne prouvent pas qu'un score provient d'une partie honnête. App Check est
non imposé et la création automatisée de comptes reste possible (M20).

## Session de test — environ 20 minutes

1. Ouvrir le site en navigation normale ; noter navigateur/version et appareil.
   Vérifier affichage, liens légaux et Analytics Off sans donner de consentement.
2. Choisir invité, terminer Drapeaux puis consulter résultat et profil. Actualiser
   le résultat : aucune nouvelle tentative ne doit être créée.
3. Ouvrir Capitales, changer difficulté, jouer ; vérifier score personnel et
   retour à l'accueil. Tester précédent/suivant du navigateur et actualisation.
4. Facultatif : convertir l'invité en compte Email avec une adresse contrôlée,
   puis actualiser/reconnecter. Scores et progression doivent rester présents.
   Vérifier le classement avec le pseudonyme choisi et les filtres Capital/Expert.
   Le propriétaire peut tester Google avec son propre compte ; ne pas transmettre
   de mot de passe ou code OAuth dans un compte rendu.
5. Dans Settings → Report a problem, afficher l'adresse support et copier le
   modèle. Rien n'est envoyé automatiquement. Vérifier aussi l'affichage mobile.
6. Se déconnecter. Pour demander une suppression, écrire au support ; ce parcours
   reste manuel et suit docs/SUPPORT_PRIVACY_REQUESTS.md.

Un refus du presse-papiers doit laisser l'adresse et une solution manuelle
visibles. Ne pas demander aux testeurs de vider tout leur stockage navigateur.

## Retours privés et triage

Canal : quizneticapp@gmail.com, modèle copiable depuis les paramètres. L'envoi
reste un choix du testeur dans son application mail. Ne jamais joindre jetons,
clé, UID, mot de passe ou captures contenant des données personnelles.
Le modèle ne collecte automatiquement ni compte, ni email, ni appareil.
Le propriétaire confirme qu'aucun échange support n'existe avant cette bêta.

| Champ | Contenu attendu |
| --- | --- |
| Contexte | Version de l'app, navigateur/appareil facultatif, écran |
| Reproduction | Actions, attendu, observé, fréquence |
| Preuve | Capture expurgée si utile ; aucun secret ou identifiant |
| Triage | P0 sécurité/perte de données ; P1 parcours bloqué ; P2 gêne/amélioration |
| Suivi | Issue GitHub expurgée, responsable, état et validation du correctif |

Examiner les retours après chaque session, puis faire une revue de roadmap
hebdomadaire pendant la cohorte. Regrouper les doublons et confirmer les
corrections avec un scénario de reproduction. Ne pas copier les mails bruts dans
GitHub/Notion publics. Conservation : 12 mois après clôture, avec revue minimale
des demandes de droits selon docs/SUPPORT_PRIVACY_REQUESTS.md.

## Décision de poursuite et retour arrière

Élargir seulement après des sessions adultes réelles, sans P0/P1 non traité et
avec reproduction des parcours principaux. M28 reste ouvert tant que les retours
et la première revue de priorités n'existent pas. Les tests automatisés ne
constituent pas des retours utilisateurs.

En cas de fuite ou de perte de données : suspendre les invitations, conserver
une preuve minimale expurgée et traiter l'incident. Pour une régression Web,
revenir à une version vérifiée construite avec la clé Firebase de remplacement.
Ne pas promouvoir aveuglément un ancien déploiement : il peut intégrer la clé
révoquée. Ne pas réactiver Analytics, élargir les API autorisées ou changer Spark
pour contourner un échec.
