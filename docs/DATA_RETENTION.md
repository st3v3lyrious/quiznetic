# Conservation — procédure opérateur sur Spark

Décision du propriétaire du 27 octobre 2026 ; suivi #173, parent #159.
Ces durées sont des choix de gestion, pas des durées légales universelles.
Aucune suppression de joueur n'est autorisée par cette préparation.

| Données | Politique retenue |
| --- | --- |
| Compte, progression, meilleurs scores et classement | Pendant l'utilisation, puis suppression après 24 mois d'inactivité avec avertissement préalable lorsque joignable |
| Historique détaillé des parties | 12 mois glissants, avec conservation des synthèses nécessaires |
| Support ordinaire | 12 mois après clôture |
| Preuves des droits/litiges | Minimum séparé, durée justifiée et accès restreint |
| Marqueur C3 | Au moins 65 minutes après achèvement, puis retrait vérifié |
| GA4, journaux et sauvegardes prestataires | Vérifier leurs réglages et mécanismes propres |

## Revue mensuelle

### Outil préparatoire en lecture seule

Depuis functions/, après npm ci --ignore-scripts :

```sh
node scripts/review-retention.cjs --project quiznetic-30734 --uid VERIFIED_UID
```

Cet outil ne possède aucun mode d'exécution/suppression. Il examine un seul
compte explicitement sélectionné, les métadonnées Auth/profil, la dernière
tentative et le dernier score ; il compte au plus 101 anciennes tentatives et
signale le dépassement de 100. Il ne constitue pas un inventaire exhaustif.
Les requêtes ordonnées excluent les documents sans timestamp : vérifier les
données legacy séparément. Les dates incohérentes imposent une revue manuelle.
Même un résultat review_candidate n'autorise pas de suppression. Le rapport
n'imprime ni UID, ni adresse, ni contenu des parties. Ne pas l'ajouter aux tickets.
Les erreurs s'arrêtent sans écrire ; les droits opérateur restent nécessaires.

Responsable : Steve Alomassor. Tenir un registre privé : date de revue, périmètre,
anomalies, échéances et statut. Aucun UID, courriel ou échange de support dans
GitHub/Notion publics. Aucun rappel externe ni ordonnanceur n'est créé ici.

1. Faire un premier inventaire en lecture seule : Auth, users, attempts, scores,
   leaderboard et invités orphelins. Minimiser les données exportées et les lectures
   pour respecter les quotas Spark.
2. Déterminer la dernière activité à partir du signal fiable le plus récent :
   connexion Auth, profil lastSeen, tentatives ou mise à jour de score.
   Un lastSeen ancien/absent ne suffit pas ; des visites sans écriture peuvent ne
   pas être mesurées. En cas de doute, aucune suppression.
3. Pour les comptes joignables, prévenir au moins 30 jours avant suppression,
   avec possibilité de maintien par reprise d'activité. Ce préavis est notre
   choix opérationnel. Aucun message n'est envoyé par cette préparation.
4. Recontrôler l'activité et les demandes de maintien immédiatement avant
   exécution. Préparer une sélection privée exacte et revue. L'instruction de
   ne supprimer aucune donnée de joueur reste applicable : demander une
   autorisation distincte sur un lot concret avant toute exécution.
5. Pour chaque compte autorisé : ACCOUNT_DELETION.md, simulation, confirmation
   projet/UID, vérification et retrait différé du marqueur.
6. Pour les tentatives anciennes : ne pas utiliser C3, qui supprime tout le compte.
   Développer et tester un outil distinct préservant synthèses, meilleurs scores,
   idempotence et files hors ligne. Supprimer un attemptId peut permettre son
   rejeu : ce risque doit être résolu avant toute purge partielle.
7. Examiner les échanges de support clos depuis 12 mois, pièces jointes et
   corbeilles comprises. Isoler seulement les preuves justifiées avec une
   échéance documentée ; ne pas conserver le compte entier pour prouver un droit.
8. Vérifier séparément GA4, journaux et sauvegardes. Ne pas prétendre effacer à
   distance les données locales des navigateurs.

## Prérequis de publication et limites

Le processus et les délais sont définis ; le premier inventaire, l'organisation
du registre privé, le suivi mensuel et l'outil de purge partielle restent à
terminer dans #173. Aucun inventaire de joueurs ni audit de boîte support n'a
été exécuté dans cette préparation.

Ne pas remettre à zéro l'âge des anciens enregistrements au déploiement.
Préparer les avis aux comptes déjà éligibles ; aucune purge rétroactive silencieuse.
Avant publication, vérifier que la notice décrit fidèlement l'état opérationnel.
La rédaction seule ne clôture pas C4. Pas de Functions, TTL payant ou passage Blaze.

Sources :
- [CNIL — durées de conservation](https://www.cnil.fr/fr/passer-laction/les-durees-de-conservation-des-donnees)
- [CNIL — comptes inactifs et contenus numériques](https://www.cnil.fr/fr/achat-de-contenus-numeriques-quelle-duree-de-conservation-des-comptes-inactifs)


## Mise en œuvre préparée — 6 novembre 2026

L'inventaire du 28 octobre reste la dernière observation de production : aucun
seuil de 24 mois/12 mois atteint, trois profils déclarés invités sans Auth à
examiner. Ce résultat historique n'est pas un nouvel inventaire de novembre.
Le registre durable est initialisé en brouillon privé Notion ; aucun UID ni
contenu de support n'est publié dans ce dépôt. Le registre nominatif source
reste dans l'environnement initial actuellement indisponible : ne pas
reconstituer les identités ni conclure que les trois profils sont supprimables.

### Purge partielle par reçu minimal

Le script functions/scripts/prune-attempt-history.cjs remplace, pour un compte
explicite et une sélection exacte, les détails de tentatives de plus de 12 mois
par le seul champ retentionMarkerVersion: 1 au même chemin de document.
Il ne supprime jamais le profil, les meilleurs scores, les synthèses ou le
classement. Il n'installe aucun ordonnanceur, Function ou TTL.

Le chemin conserve le UID et l'attemptId nécessaires à l'anti-rejeu. Un identifiant
peut lui-même encoder une date : le reçu est pseudonyme, pas anonyme. Il reste
jusqu'à la suppression du compte selon la politique de 24 mois d'inactivité et
n'est pas une raison de conserver le compte indéfiniment. C3 le supprime avec
les autres sous-documents du compte. Aucun score, réponse, catégorie, difficulté
ou horodatage de partie n'est conservé comme champ dans ce reçu.

Les clients existants vérifient l'existence du document avant d'écrire :
ScoreService._saveScoreDirect retourne duplicate et la file locale considère
la soumission résolue. Le callable existant utilise aussi l'existence du document.
Les règles actuelles interdisent update/delete et la création d'un reçu par un
client. Un pending ancien ne peut donc ni réintroduire les détails, ni augmenter
le score en rejouant ce même identifiant. Un identifiant différent reste un
risque de score fabriqué, suivi dans M20 ; cette procédure ne constitue pas un
scoring autoritaire ni un effacement des caches locaux.

### Utilisation opérateur

Authentification opérateur par les mécanismes habituels du SDK Admin, avec droits
minimums. Ne jamais copier un jeton ou une clé dans le script ou dans Git.
Le projet, le UID vérifié et le fichier privé sont passés par variables
d'environnement. Créer le dossier des manifestes avec permissions 0700,
en dehors du checkout ; le script crée le manifeste en 0600 sans écrasement.

    RETENTION_PROJECT=quiznetic-30734
    RETENTION_UID=UID_VERIFIE
    RETENTION_MANIFEST=/chemin/prive/selection.json
    export RETENTION_PROJECT RETENTION_UID RETENTION_MANIFEST
    node functions/scripts/prune-attempt-history.cjs --plan

La simulation ne modifie pas les données. Elle imprime uniquement le nombre,
l'empreinte SHA-256 et l'expiration ; le UID et les identifiants restent dans le
manifeste privé. Aucun contenu de partie n'y est copié. Les dates manquantes ne
sont pas sélectionnées et doivent être revues par l'inventaire dédié.
Un lot de plus de 100 documents est refusé sans sélection tronquée.
Les champs legacy inconnus et les sous-collections imposent une revue séparée.

Avant exécution : vérifier le compte et la nécessité de chaque élément,
relire le manifeste exact, obtenir l'autorisation distincte du propriétaire
pour ce lot et consigner son empreinte dans le registre privé. La demande de
préparer #173 ou la génération d'un plan ne sont pas cette autorisation.
Le manifeste expire après 24 heures ; replanifier si nécessaire.

Après cette autorisation seulement :

    node functions/scripts/prune-attempt-history.cjs --execute --confirm EMPREINTE_SHA256_APPROUVEE

Le script vérifie les règles déployées contre le checkout revu, l'existence et
l'état du compte, le profil et le verrou C3. Une transaction recontrôle toutes
les versions avant de remplacer les documents. Si un document a changé ou
disparu, tout le lot échoue ; le script ne recrée pas une tentative manquante.
Une nouvelle exécution du même manifeste encore valide reconnaît les reçus
déjà présents sans réintroduire les détails. La vérification des projections,
du classement, de la file en attente et du registre reste une étape opérateur.
Aucune exécution sur des joueurs n'a été réalisée lors de cette préparation.

### Vérification technique

Tests avec Firestore Emulator, projet demo-quiznetic-retention et identités
synthétiques ; le lookup Auth est simulé dans cette suite. Cas couverts :
conservation des synthèses, anti-rejeu client, refus de modification/suppression
du reçu par le client, reprise idempotente, frontière de 12 mois, dates absentes,
plan expiré/modifié, traversée de chemin, compte marqué C3, absence de vérification
des règles, sélection disparue, champs legacy et lot trop grand.
Le contrat de replay est exercé par le SDK client ; un scénario natif Flutter
hors ligne sur appareil n'a pas été exécuté ici.

### Registre et revue mensuelle

Le registre privé durable conserve les références aléatoires de revue, les
preuves consultées, anomalies, décisions, préavis et prochaines échéances.
Les manifestes nominatifs restent séparés et privés. Ne pas y recopier les
pièces de support ou données de jeu ; n'y conserver que le nécessaire.
Prochaine revue mensuelle inscrite : 28 novembre 2026. Aucun rappel externe
n'est installé. Réévaluer la durée du registre à chaque clôture : par défaut
échéance de revue à 12 mois ; prolongation uniquement pour une finalité
documentée avec nouvelle échéance. Ce délai de revue n'est pas une règle légale.

### Support et état opérationnel réel

Le compte Gmail connecté le 6 novembre est différent de la boîte support.
La recherche strictement ciblée sur les messages à/de l'adresse support n'a
renvoyé aucun message dans ce compte ; cela ne prouve pas que la boîte support
est vide. Le propriétaire demande de connecter quizneticapp@gmail.com.
La revue des messages, dates de clôture, pièces jointes, corbeille et réserves
justifiées demeure ouverte jusqu'à cet accès.

La notice publiée indique encore que le déploiement opérationnel de la
conservation est préparatoire et qu'aucune purge historique n'a été exécutée.
Cette mention reste vraie. Ne pas la remplacer par une promesse de purge
automatique : l'outil doit être revu/intégré, le registre nominatif récupéré
et la boîte support examinée avant clôture de #173.
