# Attractivité entrepreneuriale des zones d'emploi françaises

Application Shiny cartographiant l'attractivité entrepreneuriale des 306 zones d'emploi françaises (ZE2020) selon une méthode d'indice composite multidimensionnel.

**Auteur :** Benjamin Lagable  
**Méthode :** ACP par dimension + moyenne simple (OCDE/JRC 2008)  
**Données :** INSEE, DGFIP, ADEME, ANCT — période 2021-2024

---

## Présentation

L'outil synthétise plus de 60 indicateurs statistiques en 9 dimensions thématiques et un indice global, permettant de comparer les territoires selon leur capacité structurelle à accueillir et faire naître des entreprises.

Les 9 dimensions :

| Dimension | Variables | Variance PC1 |
|---|:---:|:---:|
| Dynamisme économique et emploi | 9 | 33.6% |
| Fiscalité et ressources publiques | 9 | 21.0% |
| Capital humain et éducation | 6 | 50.9% |
| Services, équipements et qualité de vie | 11 | 40.0% |
| Démographie et structure sociale | 7 | 33.0% |
| Logement et cadre résidentiel | 5 | 42.3% |
| Environnement et risques | 13 | 25.2% |
| Infrastructures numériques | 3 | 57.1% |
| Mobilité et accessibilité | 4 | 42.6% |

Corrélation indice global / nombre de créations : **r = 0.475** (Pearson), **rho = 0.427** (Spearman).  
Robustesse aux choix de pondération : **rho = 0.971** entre pondération égale et pondération par variance PC1 (OCDE/JRC 2008, ch. 8).

---

## Fonctionnalités

- **Carte interactive** — visualisation par quartile de n'importe quel score dimensionnel ou global, avec tooltip au survol
- **Distribution et corrélations** — histogramme de distribution avec position de la zone sélectionnée, graphique des corrélations avec les créations d'entreprises
- **Profil territorial** — radar sur les 9 dimensions avec comparaison à la médiane nationale, tableau des rangs
- **Comparaison de zones** — radar superposé de deux zones au choix
- **Classement** — top 20 / flop 20 par dimension ou indice global
- **Téléchargement des données** — export Excel des scores par zone

---

## Structure du projet

```
shiny-attractivite-territoriale/
├── app.R                            # Application Shiny
├── construction_indices_ACP.R       # Script de construction des indices
├── README_shiny.md                  # Ce fichier
└── data/
    ├── data_retraited.xlsx          # Données sources standardisées (306 ZE, ~70 vars)
    ├── data_scores_ACP.xlsx         # Scores ACP par dimension et indice global
    └── ze2020_2024.shp + annexes    # Fond de carte zones d'emploi ZE2020
```

---

## Lancer l'application en local

```r
# Packages requis
install.packages(c("shiny", "shinyjs", "sf", "leaflet", "dplyr",
                   "readxl", "openxlsx", "ggplot2"))

# Depuis le répertoire du projet
shiny::runApp()
```

---

## Méthode

### Construction des indices

1. **Standardisation** (mean = 0, sd = 1) de toutes les variables — OCDE/JRC 2008, section 5
2. **ACP par dimension** : extraction du PC1, orienté par une variable d'ancrage a priori — OCDE/JRC 2008, section 6.2
3. **Normalisation min-max 0-100** — OCDE/JRC 2008, équation 6.1
4. **Indice global** : moyenne simple des 9 scores dimensionnels — OCDE/JRC 2008, section 7.2

### Référence

OCDE/JRC (2008). *Handbook on Constructing Composite Indicators: Methodology and User Guide*. OECD Publishing, Paris. https://doi.org/10.1787/9789264043466-en

### Limites principales

- **Fiscalité** (r = -0.567) et **Logement** (r = -0.458) présentent une corrélation négative avec les créations. Ces dimensions captent des profils territoriaux distincts (intensité de l'intervention publique / tissu résidentiel stable), pas une attractivité au sens entrepreneurial. Les variables d'orientation n'ont pas été modifiées a posteriori — OCDE/JRC 2008, ch. 6.
- Fiscalité (PC1 = 21%) et Environnement (PC1 = 25%) : faible cohérence interne, le score ne résume qu'une partie de la variance de ces dimensions.
- La corrélation indice global / créations est calculée sur le nombre brut de créations (standardisé), sensible à la taille des zones.

---

## Données sources

| Source | Variables |
|---|---|
| INSEE | Démographie, emploi, logement, revenus, équipements |
| DGFIP | Fiscalité locale (taxes, CFE, épargne brute) |
| ADEME | Émissions GES, qualité de l'air |
| ANCT | QPV, équipements territoriaux, population éloignée |
| IGN | Fond de carte ZE2020 |
