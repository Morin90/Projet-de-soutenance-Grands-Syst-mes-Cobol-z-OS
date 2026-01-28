# Projet-de-soutenance-Grands-Systemes-Cobol-z-OS

 Présentation du projet réalisé en binôme

Ce projet est une application batch COBOL sur z/OS réalisée en binôme dans le cadre d’un projet de soutenance Grands Systèmes.
Il couvre l’ensemble d’une chaîne de traitement mainframe, depuis l’intégration des données de ventes jusqu’à la génération de factures formatées, en passant par des traitements DB2 transactionnels, des sous-programmes métiers et des tests unitaires.

L’objectif est de démontrer la maîtrise des concepts fondamentaux du monde mainframe IBM :

COBOL batch

DB2

JCL

fichiers séquentiels et indexés

sous-programmes

gestion transactionnelle

qualité logicielle (tests)

 Objectifs fonctionnels

Intégrer des ventes internationales (Europe / Asie)

Gérer des produits multidevises

Convertir automatiquement les devises

Alimenter une base de données DB2

Mettre à jour les balances clients

Extraire les données consolidées

Générer des factures texte prêtes à l’impression

Valider la logique métier par des tests unitaires

 Architecture globale
Fichiers ventes (EU / AS)
        ↓
TSELLEXT  → DB2 (ORDERS, ITEMS, CUSTOMERS…)
        ↓
EXTRACTD  → Fichier d’extraction
        ↓
GENFACTU  → Factures texte (80 colonnes)


Des sous-programmes et utilitaires sont appelés à différents niveaux pour :

la conversion de devises

le formatage des dates

la validation par tests unitaires

 Description des programmes COBOL
* TSELLEXT

Traitement des ventes internationales

Lecture des fichiers VENTEEU et VENTEAS

Calcul des montants

Insertion DB2 :

ORDERS

ITEMS

Mise à jour des balances clients (CUSTOMERS)

Gestion des commits par commande

Rollback en cas d’erreur SQL

* TNEWPROD

Chargement des nouveaux produits

Lecture d’un fichier CSV (;)

Conversion de devise via sous-programme

Insertion dans la table PRODUCTS

Gestion des doublons et SQLCODE

* SCONVDEV / TCONVSUB

Sous-programmes de conversion de devise

Lecture du fichier des devises

Application du taux

Retour du prix converti

Réutilisables par plusieurs programmes

* EXTRACTD

Extraction DB2

Jointures multi-tables :

ORDERS, ITEMS, PRODUCTS

CUSTOMERS, EMPLOYEES, DEPTS

Alimentation d’un fichier plat séquentiel

Tri logique par numéro de commande

* GENFACTU

Génération des factures

Lecture du fichier d’extraction

Regroupement par commande

Calcul :

sous-total

TVA

commission

total général

Mise en forme texte (80 colonnes)

Appel du sous-programme DATETXT

* DATETXT

Utilitaire de date

Conversion YYYY-MM-DD

Génération d’une date littérale (jour + mois en toutes lettres)

Utilisé dans les factures

 Tests unitaires COBOL

Le projet intègre un mini framework de tests unitaires, ce qui est rare et très apprécié en soutenance.

* ASSEQ

Assertion EXPECTED vs ACTUAL

Comptage :

tests exécutés

succès

échecs

* TCONVDEV

Programme de tests

Scénarios de conversion de devises

Affichage d’un résumé clair des résultats

 Fichiers de données

VENTEEU / VENTEAS : ventes internationales

DEVISE : taux de conversion

NEWPRODS : nouveaux produits

EXTRACT.DATA : données consolidées

FACTURES : sorties texte formatées

 JCL

Le projet contient des JCL distincts pour :

compilation COBOL batch

précompilation DB2

link-edit

bind DB2

exécution

nettoyage des fichiers

Cette séparation respecte les bonnes pratiques mainframe.

 Technologies utilisées

COBOL z/OS

DB2

JCL

SQL embarqué

Fichiers séquentiels et indexés

Sous-programmes

Batch processing

Tests unitaires COBOL

 Contexte pédagogique

Projet réalisé dans le cadre d’une soutenance Grands Systèmes, avec pour objectif de :

mettre en œuvre une application mainframe complète

respecter une architecture professionnelle

démontrer la qualité du code et des traitements

 Auteur

Julien & Z******
Projet de soutenance – Grands Systèmes
COBOL / z-OS / DB2
