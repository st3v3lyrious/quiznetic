# Demandes de droits — support Quiznetic

Responsable : Steve Alomassor. Canal : quizneticapp@gmail.com.
Ce document est une procédure, pas un envoi d'email ni une intégration Gmail.
Conserver les demandes dans un suivi privé, jamais dans GitHub/Notion publics.

## Fiche minimale par demande

- Référence interne aléatoire, réception et échéance d'un mois calendaire.
- Droit demandé et périmètre ; coordonnées strictement nécessaires pour répondre.
- Vérification du titulaire/représentant : méthode et résultat, sans recopier
  inutilement les pièces. Ne pas demander systématiquement une pièce d'identité.
- Dates, actions, systèmes contrôlés et exceptions éventuelles.
- Réponse, clôture, prochaine échéance et justification de conservation résiduelle.

Le délai court dès réception. Si une prolongation est nécessaire pour complexité
ou nombre de demandes, informer et expliquer dans le premier mois ; jusqu'à deux
mois supplémentaires selon les règles applicables. Ne pas repartir de zéro à la
fin de la vérification. Demander un complément proportionné en cas de doute réel.

## Accusé de réception — modèle à adapter

« Nous avons reçu votre demande concernant vos données Quiznetic. Nous vous
répondrons dans un délai d'un mois à compter de sa réception. Pour identifier le
compte, indiquez si possible son adresse et son mode de connexion, sans mot de
passe ni jeton de session. Nous vous expliquerons tout complément proportionné
nécessaire à la vérification. Le contact est quizneticapp@gmail.com. »

## Demande parentale

Vérifier le compte concerné et la qualité du représentant de façon proportionnée.
Prendre en compte les droits, la maturité et l'intérêt de l'enfant ; ne pas
communiquer automatiquement l'ensemble de ses données sur simple courriel.
Ne pas prétendre que l'app vérifie déjà le consentement parental à l'inscription.
Suivre MINORS_PROPOSAL.md et le ticket #174 pour l'évolution du parcours.

## Suppression vérifiée

Utiliser ACCOUNT_DELETION.md pour le seul UID vérifié : simulation, confirmation,
verrou, suppression active, contrôle d'absence et retrait du marqueur après au
moins 65 minutes. La consigne de ne supprimer aucun joueur reste applicable à
cette session : la rédaction de la procédure n'est pas une autorisation de purge.
Les demandes réelles futures doivent être traitées selon leur mandat vérifié.

Traiter séparément les copies locales, les événements GA4 antérieurs et les
journaux/sauvegardes des prestataires. Aucune réponse ne doit promettre un effacement
immédiat de toutes les copies à partir du seul résultat Firebase Auth.

## Réponse après exécution — modèle à adapter aux faits

« Les données actives suivantes ont été supprimées et leur absence vérifiée :
[énumérer uniquement les systèmes effectivement contrôlés]. Votre ancien compte
ne peut plus les synchroniser. [État réel du marqueur technique et de son retrait.]
Les copies locales sur vos appareils nécessitent l'effacement des données du site.
[État exact des démarches distinctes prestataires/Analytics, échéances et limites.]
Vous pouvez nous contacter à quizneticapp@gmail.com et saisir la CNIL si nécessaire. »

Ne jamais envoyer ce modèle sans remplacer les indications par les résultats
réels. Définir une échéance justifiée pour la seule preuve minimale de traitement ;
les courriels de support ordinaire suivent les 12 mois après clôture.
