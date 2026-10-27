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
