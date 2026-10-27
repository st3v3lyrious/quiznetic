# Parcours mineurs — proposition d'implémentation

Public éducatif tout âge confirmé par le propriétaire le 27 octobre 2026.
Suivi #174, parent #159. Ce document ne prétend pas qu'un contrôle parental existe.

## Protection immédiate dans cette PR — #172

Analytics Web suspendu, y compris avec ancien consentement et ENABLE_ANALYTICS=true.
Pas de bouton d'acceptation ; lien de confidentialité maintenu. Choix anciens
invalidés et cookies GA accessibles retirés sans effacer session ou scores.
Prend effet après publication seulement. Les données GA4 antérieures restent
à traiter séparément. Les requêtes nécessaires Auth/Firestore/Vercel persistent.

## Parcours recommandé

1. Découverte réellement locale : pas de compte Firebase, pas de Firestore ni
   classement ; progression sur l'appareil. Le mode invité actuel crée un UID :
   il n'est pas ce mode local et n'est pas anonyme au sens juridique.
2. À la création de compte/synchronisation : tranche d'âge minimale, sans date
   de naissance complète. Pour la France : moins de 15 ans, 15–17 ans, adulte.
   Vérifier les autres marchés avant de généraliser ce seuil.
3. Moins de 15 ans : parcours avec parent, explication intelligible pour l'enfant
   et le parent, vérification proportionnée de la qualité du représentant,
   trace minimale et retrait/suppression. Une case déclarative ne prouve pas
   un accord vérifié ; pas de pièce d'identité demandée par défaut. Le moyen
   concret de vérification et la capacité contractuelle doivent être examinés.
4. 15–17 ans : information adaptée et autorisation parentale prévue aux conditions.
   Le seuil de 15 ans concerne certains traitements fondés sur le consentement ;
   il ne règle pas à lui seul la capacité contractuelle de tous les mineurs.
5. Profil mineur privé par défaut, classement désactivé par défaut, pseudonyme
   non identifiant ; aucune publication automatique du nom/photo Google.
   Ne pas réécrire les noms historiques. Le classement actuel est visible aux
   utilisateurs authentifiés, invités inclus : ce comportement doit évoluer.
6. Notice courte : « Tes résultats servent à garder ta progression. Ne mets pas
   ton vrai nom dans ton pseudo. Pour demander de l'aide ou supprimer tes données
   avec ton parent : quizneticapp@gmail.com. » Notice complète accessible.
7. Maintenir Analytics suspendu. Toute réintroduction nécessite une revue séparée,
   un nouvel accord et, pour les traitements concernés en France avant 15 ans,
   l'accord conjoint enfant/parent. Aucun réemploi des anciens choix.

## Demandes parentales et validation

Accuser réception et suivre le délai d'un mois dès réception. Vérifier de façon
proportionnée le représentant et le compte, en prenant en compte les droits et
l'intérêt de l'enfant. Un courriel parental seul ne donne pas accès à toutes les
données. Appliquer C3 au seul compte vérifié, expliquer les limites locales/
prestataires et ne rien publier sur l'enfant dans les tickets.

Tester enfant/parent/adolescent, abandon/refus, absence de GA avec ancien accord,
non-publication du nom du fournisseur, impossibilité d'accéder au compte d'un autre
enfant et droits parentaux. Mode local, accord parental et profils privés restent
à développer/tester : l'app ne doit pas les présenter comme déjà disponibles.
Ne pas annoncer une ouverture spécialement destinée aux enfants comme validée
sur la seule base de la suspension Analytics.

Sources :
- [CNIL — consentement parental](https://www.cnil.fr/fr/recommandation-4-rechercher-le-consentement-dun-parent-pour-les-mineurs-de-moins-de-15-ans)
- [CNIL — capacité d'agir des mineurs](https://www.cnil.fr/fr/recommandation-1-encadrer-la-capacite-dagir-des-mineurs-en-ligne)
