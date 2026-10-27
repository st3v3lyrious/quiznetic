# C4 — Quiznetic, projet personnel exploité depuis la France

Recherche et revue technique du 27 octobre 2026. Document de travail : il
sépare les faits vérifiés, les choix proposés et les points encore ouverts.
Il ne certifie pas une conformité générale ni une validation par la CNIL.

## Responsable et cadre applicable

Le propriétaire a confirmé être **Steve Alomassor**, personne physique résidant
en France, responsable du projet. Quiznetic est le nom du produit, pas une
société. Le contact retenu pour la protection des données et les demandes est
**quizneticapp@gmail.com**. Aucune immatriculation ou adresse n'a été inventée.

Un responsable peut être une personne physique : il détermine les objectifs et
les moyens des traitements. L'absence de société, de revenu ou de marque déposée
ne dispense pas d'expliquer les traitements d'un service ouvert au public.
La revue retient le RGPD et la loi française Informatique et Libertés ; elle ne
prétend pas couvrir toutes les obligations de tous les marchés internationaux.

Les mentions d'éditeur/hébergeur restent à compléter séparément. La LCEN prévoit
une possibilité d'anonymat public pour l'éditeur non professionnel sous conditions,
notamment la communication des éléments d'identité à l'hébergeur. Ce n'est pas
une dispense générale d'information RGPD, ni la preuve que le compte d'hébergement
actuel remplit ces conditions. Ne pas publier une adresse personnelle déduite
d'une autre source ni inventer un SIRET.

Sources : [information des personnes, CNIL][information],
[LCEN, chapitre communication au public en ligne][lcen].

## Inventaire établi à partir du code et des contrôles Firebase

| Traitement et déclencheur | Données et emplacement observés | Utilité et visibilité |
| --- | --- | --- |
| Ouverture du site | Requêtes de pages/ressources vers Vercel et bibliothèques Google ; informations techniques de connexion | Distribution et sécurité ; refuser Analytics n'empêche pas ces requêtes nécessaires |
| Entrée invitée ou connexion | Firebase Auth UID, statut invité ou fournisseur ; email/nom selon la connexion ; identifiants de session côté navigateur | Authentification. « Invité » est pseudonyme, pas une anonymisation irréversible |
| Création/actualisation du profil | `users/{uid}` : `isAnonymous`, `createdAt`, `lastSeen`, nom si disponible, email si fourni | Profil privé sous les règles propriétaire |
| Fin d'un quiz | `users/{uid}/attempts/{id}` : identifiant, catégorie, difficulté, nombre de bonnes réponses/questions, statut/source, date ; scores privés séparés | Historique, synchronisation, meilleur score et prévention des doublons |
| Classement d'un compte permanent | `leaderboard/{scope}/entries/{uid}` : nom public, score, catégorie/difficulté, statut, date | Visible aux utilisateurs authentifiés, y compris invités ; pas d'email ni de mot de passe dans ces champs. Des noms historiques peuvent néanmoins contenir du texte choisi ou issu d'anciens replis |
| Stockage local | SharedPreferences : tentatives/projections en attente, meilleurs scores, préférences et session Auth | Fonctionnement local ; l'effacement serveur ne nettoie pas tous les appareils à distance |
| Acceptation Analytics | SDK GA4, identifiants navigateur/cookies, vues et événements de quiz/soumission | Mesure facultative ; signaux publicitaires désactivés. Aucun `setUserId` applicatif n'a été trouvé dans le code relu |
| Contact support | Adresse de réponse, texte de la demande, échanges nécessaires | Réponse et exercice des droits ; aucune automatisation de boîte mail n'est configurée par cette PR |

Preuves techniques : `lib/services/user_checker.dart`, `score_service.dart`,
`score_repository.dart`, `analytics_consent.dart`, `analytics_service.dart`,
`web/analytics_consent.js`, `firestore.rules` et `docs/ACCOUNT_DELETION.md`.
L'inventaire porte sur le Web ; il ne présente pas Crashlytics mobile comme un
collecteur Web actif. Le choix Analytics est valable **180 jours** dans le
navigateur : ce n'est pas une durée de conservation des comptes ou de GA4.

## Bases légales proposées pour ce service

- Fourniture du service demandé : article 6(1)(b), limité aux données réellement
  nécessaires à l'authentification, aux scores/synchronisation et au classement
  prévu pour les comptes. L'information sur la publication du pseudonyme doit
  être visible ; cette base ne justifie pas une réutilisation générale des données.
- Sécurité et lutte contre les abus : article 6(1)(f). Intérêt poursuivi : protéger
  les comptes, le service et l'intégrité des scores. Documenter nécessité,
  proportionnalité et équilibre avec les droits, particulièrement pour les mineurs.
- Analytics facultatif : consentement distinct, article 6(1)(a) et article 82 de
  la loi Informatique et Libertés. Le refus reste aussi simple que l'acceptation.
- Traitement des demandes de droits : obligations RGPD, article 6(1)(c) ; support
  nécessaire à la fourniture du service : article 6(1)(b).

Cette affectation est une analyse proposée à valider par le responsable avant
publication. Aucun intérêt légitime n'est invoqué pour contourner le refus des
traceurs Analytics. Il faut réexaminer ces choix si le produit ou le public change.

Sources : [contrat, CNIL][contrat], [intérêt légitime, CNIL][interet],
[cookies, CNIL][cookies].

## Circuit concret des demandes de suppression

1. Le joueur écrit au support, par exemple avec l'objet « Quiznetic — suppression
   du compte et des données ». Envoyer depuis l'adresse du compte aide, sans être
   une condition absolue. Pour un invité, contacter le support tant que la session
   reste disponible aide à établir le lien avec le compte.
2. Enregistrer la date de réception et l'échéance d'un mois dans un suivi **privé**.
   Répondre sans délai indu. Toute prolongation nécessaire, au maximum deux mois
   supplémentaires, est motivée et annoncée avant la fin du premier mois.
3. Vérifier l'appartenance du compte de façon proportionnée. Une session
   authentifiée ou une vérification du canal de contact peut aider. Email déclaré,
   nom public ou UID seuls ne suffisent pas pour déclencher une destruction.
   Ne demander une pièce supplémentaire qu'en cas de doute raisonnable ; pas de
   collecte systématique de pièce d'identité et jamais de mot de passe/token.
4. Exécuter le dry-run puis la procédure opérateur C3 sur le projet et l'UID
   vérifiés. Elle bloque les anciens jetons, désactive/révoque Auth, supprime les
   données privées récursives et toutes les entrées de classement de cet UID,
   puis supprime Auth et vérifie l'absence des données.
5. Conserver le verrou minimal au moins 65 minutes, puis exécuter son nettoyage
   et vérifier son absence. C'est une étape opérateur, pas un TTL ou une Function
   facturée. Ne pas annoncer que toute donnée est déjà effacée si ce suivi reste
   à faire.
6. Traiter séparément les données GA4 identifiables, logs et copies fournisseurs
   avec leurs mécanismes applicables. L'email d'un compte ne permet pas forcément
   d'identifier les enregistrements GA4 pseudonymes. Ne pas acquérir de nouveaux
   identifiants superflus uniquement pour les rapprocher.
7. Confirmer les suppressions **vérifiées**, les éventuelles opérations encore
   en cours, leur calendrier connu et les exceptions légales précises. Expliquer
   comment effacer le stockage du site sur les autres appareils. Limiter le
   dossier de preuve et son accès ; ne pas créer de sauvegarde complète du joueur.

Il ne faut pas promettre « toutes les copies partout sont immédiatement effacées ».
La documentation Google indique notamment un délai pouvant atteindre 180 jours
pour le retrait de certaines données Auth des systèmes actifs et de sauvegarde.
Ce délai fournisseur ne remplace pas l'échéance de réponse RGPD d'un mois et ne
permet pas de retarder l'action sur les données actives supprimables.

Sources : [effacement, CNIL][effacement], [vérification proportionnée, CNIL][identite],
[Firebase : traitement et rétention][firebase].

## Conservation : proposition de travail, pas une purge activée

Le code n'implémente pas de purge automatique des comptes inactifs. Les formulations
actuelles sur une conservation pour des besoins génériques ne suffisent pas à
définir une politique opérationnelle. Article 13 : une durée ou des critères
compréhensibles sont à communiquer ; l'inactivité ne justifie pas une conservation
indéfinie sans revue.

Pour simplifier la bêta, proposition à approuver et mettre en pratique : revue
mensuelle des comptes ; envisager l'effacement après **12 mois d'inactivité**,
en évaluant la dernière interaction réellement disponible (pas uniquement un vieux
champ de connexion), avec information préalable adaptée. Limiter les échanges de
support ordinaires, par exemple à **12 mois après clôture**, et conserver séparément
seulement la preuve minimale justifiée des demandes de droits/litiges. Ces nombres
sont des **choix proposés**, pas des délais imposés par la CNIL ou déjà appliqués.

Ne pas insérer ces échéances comme une promesse publique ni supprimer des données
de joueurs avant validation du choix et du mode opératoire. Les règles de GA4,
cookies, logs, sauvegardes et éventuelles preuves légales doivent être distinguées.
Source : [durées de conservation, CNIL][retention].

## Hébergement, transferts et points encore non vérifiés

- Firestore `(default)` vérifié en `eur3` : Europe (répliques Belgique/Pays-Bas,
  témoin Finlande). Ce fait ne prouve pas une localisation européenne de tout le
  service. Google documente Firebase Authentication aux États-Unis.
- Google distingue ses services Firebase/GCP et Analytics, avec des conditions
  différentes. Vérifier les conditions effectivement acceptées, la couverture des
  entités et les garanties de transfert ; ne pas déduire la conformité de la seule
  présence d'un logo ou d'un hébergement Firestore européen.
- Le DPA Vercel consulté indique un champ Pro/Enterprise. Le connecteur n'expose
  pas ici le plan ni les engagements acceptés. La notice Vercel décrit aussi son
  propre rôle de responsable pour certaines informations de trafic. Le frontend
  est statique et les comptes/scores vont directement à Firebase : cela ne permet
  ni d'affirmer un DPA couvrant tout, ni de conclure qu'un abonnement payant est
  automatiquement requis. Vérifier les rôles/flux et conditions applicables.
- Rétention réelle GA4, logs Vercel, sauvegardes et preuve des garanties de transfert
  restent ouverts. Aucun plan Firebase/Vercel n'a été modifié et aucun achat engagé.

Sources : [lieux Firestore][locations], [Firebase][firebase],
[notice Vercel][vercel-notice], [champ du DPA Vercel][vercel-dpa].

## Mineurs et organisation minimale

En France, le seuil de **15 ans** concerne le consentement à certains traitements
d'un service en ligne ; ce n'est pas un âge universel pour jouer. En dessous,
un consentement conjoint enfant/représentant est requis lorsque ce fondement
s'applique. Aucun parcours de consentement parental vérifié n'est implémenté.
Pour une première bêta, limiter réellement le public invité aux adultes est une
option à décider, pas une restriction déjà active. Ne pas présenter une phrase
dans les conditions comme la preuve d'un contrôle d'âge effectué.

Conserver un petit registre des traitements récurrents et des prestataires,
protéger les accès opérateur/support, limiter les habilitations et tenir un suivi
privé des demandes. Documenter les incidents : si une violation présente un risque,
la notification CNIL est à examiner dans les 72 heures après en avoir pris
connaissance ; un risque élevé peut imposer d'informer les personnes.

Sources : [consentement des mineurs][mineurs], [registre][registre],
[violations][violations].

## État C4 après cette préparation

- Confirmé : identité, résidence France, projet personnel, contact support,
  collecte effective, procédure C3 et absence de monétisation Web.
- Préparé, non publié : politique et conditions synchronisées avec les assets,
  droits, circuit support, bases légales proposées et limites d'effacement.
- Encore à valider : durées/processus de conservation, public mineur/adulte,
  mentions d'éditeur/hébergeur et exigences de contact applicables, conditions/
  garanties des prestataires et réglages GA4. **C4 reste ouvert** ; le propriétaire
  doit valider le texte final avant sa publication.

[information]: https://www.cnil.fr/fr/conformite-rgpd-information-des-personnes-et-transparence
[lcen]: https://www.legifrance.gouv.fr/codes/id/LEGISCTA000006117684/
[contrat]: https://www.cnil.fr/fr/les-bases-legales/contrat
[interet]: https://www.cnil.fr/fr/les-bases-legales/interet-legitime
[cookies]: https://www.cnil.fr/fr/cookies-et-autres-traceurs/que-dit-la-loi
[effacement]: https://www.cnil.fr/fr/comprendre-mes-droits/le-droit-leffacement-supprimer-vos-donnees-en-ligne
[identite]: https://www.cnil.fr/fr/respecter-les-droits-des-personnes/professionnels-comment-repondre-une-demande-de-droit-dacces
[firebase]: https://firebase.google.com/support/privacy
[retention]: https://www.cnil.fr/fr/passer-laction/les-durees-de-conservation-des-donnees
[locations]: https://firebase.google.com/docs/firestore/locations
[vercel-notice]: https://vercel.com/legal/privacy-notice
[vercel-dpa]: https://vercel.com/legal/dpa
[mineurs]: https://www.cnil.fr/fr/les-bases-legales/consentement
[registre]: https://www.cnil.fr/fr/RGPD-le-registre-des-activites-de-traitement
[violations]: https://www.cnil.fr/fr/violations-de-donnees-personnelles-les-regles-suivre
