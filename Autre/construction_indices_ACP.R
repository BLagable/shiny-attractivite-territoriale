# =============================================================================
# Construction des indices d'attractivité territoriale par ACP
# Zones d'emploi françaises (ZE2020)
# Auteur : Benjamin Lagable — Bpifrance / Observatoire de la Création d'Entreprise
# =============================================================================
#
# Méthode : Analyse en Composantes Principales (ACP) par dimension thématique,
# agrégation par moyenne simple pour l'indice global.
#
# Référence méthodologique :
# OECD/JRC (2008). Handbook on Constructing Composite Indicators: Methodology
# and User Guide. OECD Publishing, Paris.
# https://doi.org/10.1787/9789264043466-en
#
# Données source : data_retraited.xlsx
# Variables standardisées (mean=0, std=1), 306 zones d'emploi, 70 variables.
# Aucune valeur manquante.
# =============================================================================

library(readxl)
library(dplyr)
library(ggplot2)
library(openxlsx)
library(tidyr)

# -----------------------------------------------------------------------------
# 1. Chargement des données
# -----------------------------------------------------------------------------

data_retraited <- readxl::read_xlsx("data/data_retraited.xlsx")

cat("Dimensions :", nrow(data_retraited), "zones d'emploi,",
    ncol(data_retraited), "variables\n")
cat("Valeurs manquantes :", sum(is.na(data_retraited)), "\n\n")

# -----------------------------------------------------------------------------
# 2. Définition des dimensions thématiques
# -----------------------------------------------------------------------------
# nombre_creations est exclu de toutes les dimensions.
# Il sert uniquement à documenter les corrélations descriptives a posteriori,
# conformément au principe de séparation entre construction de l'indice
# et validation externe (OCDE/JRC 2008, ch. 7).

dimensions <- list(

  dynamisme_economique_emploi = c(
    "Médiane.du.niveau.de.vie.2021",
    "Indicateur.de.dépendance.économique",
    "Salaire.net.horaire.moyen.2022",
    "Indice.de.concentration.de.l'emploi",
    "Nombre.d'emplois.au.lieu.de.travail",
    "Taux.d'activité.des.15-64.ans",
    "Poids.des.multinationales.étrangères.dans.l'emploi.salarié",
    "Poids.des.multinationales.dans.l'emploi.salarié",
    "Taux.de.pauvreté",
    "indice_emploi_industrie_agriculture_construction",
    "indice_emploi_tertiaire"
  ),

  fiscalite_ressources_publiques = c(
    "Part.des.impôts.dans.le.rev..disp..2021",
    "moyenne_Taxe_Habitation",
    "moyenne_Taxe_Foncier_Bati",
    "moyenne_Taxe_Foncier_Non_Bati",
    "moyenne_Cotisation_Fonciere_Entreprises",
    "Total_Dep_equipement_par_habitant",
    "Evolution_du_montant_d_encours_de_dette_par_hab",
    "Epargne_brute_moyenne_par_hab",
    "aides_par_km2"
  ),

  capital_humain_education = c(
    "Part.des.20-24.ans.sans.diplôme",
    "Taux.de.réussite.au.DNB",
    "Taux.de.croissance.des.effectifs.dans.les.établissements.d'enseignement.supérieur.au.cours.des.10.dernières.années.(2010-2020)",
    "Part.des.25-34.ans.titulaires.d'un.diplôme.de.l'enseignement.supérieur",
    "Effectif.des.établissements.d'enseignement.supérieur.-.2022",
    "Part.des.jeunes.non.insérés.(ni.en.emploi,.ni.scolarisés.-.NEET)"
  ),

  services_equipements_qualite_vie = c(
    "Commerces",
    "Enseignement",
    "Santé",
    "Services aux particuliers",
    "Sports, loisirs et culture",
    "Tourisme",
    "Nbr.equipements.socio-culturels",
    "Nombre.de.licenciés.sportifs.pour.100.habitants",
    "Taux.d'équipements.sportifs.pour.1.000.habitants",
    "indice_capacite_touristique",
    "indice_densite_offre_sante"
  ),

  demographie_structure_sociale = c(
    "Part.des.étrangers.dans.la.population",
    "Densité.de.population",
    "Indice.de.vieillissement",
    "Superficie",
    "QPV.-.Quartiers.prioritaires.de.la.politique.de.la.ville.2024.:.Part.de.la.population.municipale.résidant.en.QPV",
    "Municipales.-.Taux.de.participation.au.1er.tour",
    "Moyenne_part_pop_éloignée"
  ),

  logement_cadre_residentiel = c(
    "Part.des.résidences.principales",
    "Part.des.résidences.secondaires",
    "Part.des.logements.vacants.2021",
    "Taux_logements_sociaux",
    "loyer_moyen_m2"
  ),

  environnement_risques = c(
    "Surface.agricole.utilisée.(SAU)",
    "total_infractions",
    "Emissions.de.gaz.à.effet.de.serre.hors.puits.(PRG),.par.secteur",
    "moyenne_code_qual",
    "Nombre.d'établissements.industriels.à.risque.(classés.Seveso)",
    "Territoires artificialisés",
    "Territoires agricoles",
    "Forêts et milieux semi-naturels",
    "Zones humides",
    "Surfaces en eau",
    "Part.des.Zones.Naturelles.d'Intérêt.Ecologique.Faunistique.et.Floristique.(ZNIEFF).de.type.1.dans.la.superficie.du.territoire",
    "indice_DDRM",
    "indice_catnat"
  ),

  infrastructures_numeriques = c(
    "Moyenne_vitesse_internet",
    "Part.de.la.surface.couverte.en.4G.par.a.minima.un.opérateur.2022",
    "Part.des.locaux.raccordables.FttH.(fibre.optique).2024"
  ),

  mobilite_accessibilite = c(
    "Transports et déplacements",
    "total_stations",
    "Temps.moyen.de.trajet.entre.le.domicile.et.le.travail.selon.le.sexe",
    "Part.des.déplacements.domicile-travail.en.voiture"
  )
)

# Variable dominante attendue par dimension (loading positif attendu).
# Sert à orienter le PC1 de façon ancrée dans le contenu de la dimension,
# conformément à la pratique recommandée par OCDE/JRC 2008, section 6.2.
# Si le loading de cette variable sur PC1 est négatif, le PC1 est multiplié
# par -1 pour que le score soit dans le sens "favorable" de la dimension.

var_dominante <- list(
  dynamisme_economique_emploi      = "Taux.d'activité.des.15-64.ans",
  fiscalite_ressources_publiques   = "Total_Dep_equipement_par_habitant",
  capital_humain_education         = "Part.des.25-34.ans.titulaires.d'un.diplôme.de.l'enseignement.supérieur",
  services_equipements_qualite_vie = "Commerces",
  demographie_structure_sociale    = "Densité.de.population",
  logement_cadre_residentiel       = "Part.des.résidences.principales",
  environnement_risques            = "Forêts et milieux semi-naturels",
  infrastructures_numeriques       = "Moyenne_vitesse_internet",
  mobilite_accessibilite           = "Transports et déplacements"
)

# -----------------------------------------------------------------------------
# 3. Fonction ACP par dimension
# -----------------------------------------------------------------------------

acp_dimension <- function(data, vars, dim_name, var_orient) {

  vars_ok        <- vars[vars %in% colnames(data)]
  vars_absentes  <- vars[!vars %in% colnames(data)]

  if (length(vars_absentes) > 0) {
    cat("  AVERTISSEMENT — variables absentes dans", dim_name, ":",
        paste(vars_absentes, collapse = ", "), "\n")
  }

  X   <- as.matrix(data[, vars_ok])
  acp <- prcomp(X, center = FALSE, scale. = FALSE)

  score_brut  <- acp$x[, 1]
  var_exp_pc1 <- summary(acp)$importance[2, 1]
  loadings    <- setNames(acp$rotation[, 1], vars_ok)

  # Orientation ancrée sur la variable dominante de la dimension
  if (var_orient %in% names(loadings)) {
    if (loadings[var_orient] < 0) {
      score_brut <- -score_brut
      loadings   <- -loadings
    }
  } else {
    cat("  AVERTISSEMENT — variable d'orientation absente pour", dim_name,
        ": orientation par défaut (loading dominant absolu)\n")
    if (loadings[which.max(abs(loadings))] < 0) {
      score_brut <- -score_brut
      loadings   <- -loadings
    }
  }

  # Normalisation min-max 0-100 (OCDE/JRC 2008, eq. 6.1)
  score_norm <- (score_brut - min(score_brut)) /
                (max(score_brut) - min(score_brut)) * 100

  r_creations <- cor(score_norm, data[["nombre_creations"]],
                     use = "complete.obs")

  cat(sprintf("  %-42s | PC1: %4.1f%% | r_creations: %+.3f | n_vars: %d\n",
              dim_name,
              var_exp_pc1 * 100,
              r_creations,
              length(vars_ok)))

  list(
    score       = score_norm,
    var_exp_pc1 = var_exp_pc1,
    loadings    = loadings,
    vars_ok     = vars_ok,
    r_creations = r_creations,
    var_orient  = var_orient
  )
}

# -----------------------------------------------------------------------------
# 4. Calcul des scores dimensionnels
# -----------------------------------------------------------------------------

cat("=== ACP par dimension (OCDE/JRC 2008) ===\n")

resultats <- lapply(names(dimensions), function(dim) {
  acp_dimension(
    data       = data_retraited,
    vars       = dimensions[[dim]],
    dim_name   = dim,
    var_orient = var_dominante[[dim]]
  )
})
names(resultats) <- names(dimensions)

# -----------------------------------------------------------------------------
# 5. Indice global — moyenne simple des 9 scores dimensionnels
# -----------------------------------------------------------------------------
# Choix justifié : en l'absence de raison théorique solide pour pondérer
# différemment les 9 dimensions entre elles, la moyenne simple est la méthode
# par défaut recommandée par OCDE/JRC 2008 (section 7.2).
# Elle est transparente, facilement reproductible, et ses limites sont connues.

scores_matrix <- sapply(names(resultats), function(dim) resultats[[dim]]$score)
colnames(scores_matrix) <- names(resultats)

score_global_brut  <- rowMeans(scores_matrix)
score_global_norm  <- (score_global_brut - min(score_global_brut)) /
                      (max(score_global_brut) - min(score_global_brut)) * 100

r_global <- cor(score_global_norm, data_retraited$nombre_creations,
                use = "complete.obs")

cat(sprintf("\n=== Indice global (moyenne simple des 9 scores) ===\n"))
cat(sprintf("Corrélation descriptive ~ créations : r = %.3f\n\n", r_global))

# -----------------------------------------------------------------------------
# 6. Construction du tableau final
# -----------------------------------------------------------------------------

data_scores <- data.frame(
  ZE2020             = data_retraited$ZE2020,
  LIBZE2020          = data_retraited$LIBZE2020,
  nombre_creations   = data_retraited$nombre_creations
)

for (dim in names(resultats)) {
  data_scores[[paste0("score_", dim)]] <- resultats[[dim]]$score
}

data_scores$score_global <- score_global_norm

# Tableau de synthèse
synthese <- data.frame(
  dimension   = names(resultats),
  n_variables = sapply(names(resultats), function(d) length(resultats[[d]]$vars_ok)),
  var_exp_pc1 = sapply(names(resultats), function(d) round(resultats[[d]]$var_exp_pc1 * 100, 1)),
  r_creations = sapply(names(resultats), function(d) round(resultats[[d]]$r_creations, 3)),
  var_orient  = sapply(names(resultats), function(d) resultats[[d]]$var_orient)
)

cat("=== Synthèse ===\n")
print(synthese[, c("dimension", "n_variables", "var_exp_pc1", "r_creations")],
      row.names = FALSE)

# Export
openxlsx::write.xlsx(data_scores, "data/data_scores_ACP.xlsx", overwrite = TRUE)
cat("\nFichier exporté : data/data_scores_ACP.xlsx\n")

# -----------------------------------------------------------------------------
# 7. Graphiques de diagnostic
# -----------------------------------------------------------------------------

dir.create("figures", showWarnings = FALSE)

labels_dim <- c(
  dynamisme_economique_emploi      = "Dynamisme économique et emploi",
  fiscalite_ressources_publiques   = "Fiscalité et ressources publiques",
  capital_humain_education         = "Capital humain et éducation",
  services_equipements_qualite_vie = "Services, équipements et qualité de vie",
  demographie_structure_sociale    = "Démographie et structure sociale",
  logement_cadre_residentiel       = "Logement et cadre résidentiel",
  environnement_risques            = "Environnement et risques",
  infrastructures_numeriques       = "Infrastructures numériques",
  mobilite_accessibilite           = "Mobilité et accessibilité"
)

# --- 7a. Corrélations des scores avec nombre_creations ---

corr_df <- data.frame(
  dimension   = c(names(resultats), "global"),
  correlation = c(
    sapply(names(resultats), function(d) resultats[[d]]$r_creations),
    r_global
  )
)
corr_df$label <- c(labels_dim[corr_df$dimension[-nrow(corr_df)]],
                   "Indice global (moyenne des 9 scores)")
corr_df$label <- factor(corr_df$label,
                        levels = corr_df$label[order(corr_df$correlation)])
corr_df$couleur <- ifelse(corr_df$dimension == "global", "gray30", "#2166AC")

p_corr <- ggplot(corr_df, aes(x = correlation, y = label, fill = couleur)) +
  geom_col(width = 0.65, show.legend = FALSE) +
  geom_vline(xintercept = 0, color = "gray40", linewidth = 0.5) +
  geom_text(aes(label = sprintf("r = %.3f", correlation),
                hjust = ifelse(correlation >= 0, -0.1, 1.1)),
            size = 3.2, color = "gray20") +
  scale_fill_identity() +
  scale_x_continuous(limits = c(-0.1, 0.85), expand = c(0, 0)) +
  labs(
    title    = "Corrélation de Pearson entre chaque score ACP et le nombre de créations d'entreprises",
    subtitle = "Corrélations descriptives — 306 zones d'emploi (ZE2020). Aucune inférence causale.",
    caption  = "Méthode : OCDE/JRC (2008). Handbook on Constructing Composite Indicators.",
    x        = "Corrélation de Pearson (r)",
    y        = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(size = 11, face = "bold", color = "gray10"),
    plot.subtitle = element_text(size = 9, color = "gray40"),
    plot.caption  = element_text(size = 8, color = "gray50", hjust = 0),
    axis.text.y   = element_text(size = 10)
  )

ggsave("figures/correlations_scores_creations.png", p_corr,
       width = 10, height = 6, dpi = 150)
cat("Figure : figures/correlations_scores_creations.png\n")

# --- 7b. Variance expliquée par le PC1 ---

var_df <- data.frame(
  dimension = names(resultats),
  var_exp   = sapply(names(resultats), function(d) resultats[[d]]$var_exp_pc1 * 100)
)
var_df$label <- labels_dim[var_df$dimension]
var_df$label <- factor(var_df$label,
                       levels = var_df$label[order(var_df$var_exp)])

p_var <- ggplot(var_df, aes(x = var_exp, y = label)) +
  geom_col(fill = "#4a90d9", width = 0.65) +
  geom_vline(xintercept = 50, color = "gray40", linewidth = 0.5,
             linetype = "dashed") +
  geom_text(aes(label = sprintf("%.1f%%", var_exp), hjust = -0.1),
            size = 3.2, color = "gray20") +
  scale_x_continuous(limits = c(0, 75), expand = c(0, 0)) +
  labs(
    title    = "Variance expliquée par le premier composant principal (PC1) par dimension",
    subtitle = "La ligne pointillée indique 50% — seuil indicatif de cohérence interne",
    caption  = "Un PC1 faible indique une dimension hétérogène, moins bien résumée par un axe unique.",
    x        = "Variance expliquée par PC1 (%)",
    y        = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(size = 11, face = "bold", color = "gray10"),
    plot.subtitle = element_text(size = 9, color = "gray40"),
    plot.caption  = element_text(size = 8, color = "gray50", hjust = 0),
    axis.text.y   = element_text(size = 10)
  )

ggsave("figures/variance_expliquee_pc1.png", p_var,
       width = 10, height = 5, dpi = 150)
cat("Figure : figures/variance_expliquee_pc1.png\n")

# --- 7c. Loadings PC1 par dimension ---

for (dim in names(resultats)) {
  load_df <- data.frame(
    variable = names(resultats[[dim]]$loadings),
    loading  = as.numeric(resultats[[dim]]$loadings)
  )
  load_df <- load_df[order(abs(load_df$loading)), ]
  load_df$variable <- factor(load_df$variable, levels = load_df$variable)
  load_df$couleur  <- ifelse(load_df$loading >= 0, "#2166AC", "#B2182B")

  p_load <- ggplot(load_df, aes(x = loading, y = variable, fill = couleur)) +
    geom_col(width = 0.7, show.legend = FALSE) +
    geom_vline(xintercept = 0, color = "gray40", linewidth = 0.4) +
    scale_fill_identity() +
    labs(
      title    = paste("Loadings PC1 —", labels_dim[dim]),
      subtitle = sprintf("Variance expliquée PC1 : %.1f%%  |  Variable d'orientation : %s",
                         resultats[[dim]]$var_exp_pc1 * 100,
                         resultats[[dim]]$var_orient),
      x        = "Loading sur PC1",
      y        = NULL
    ) +
    theme_minimal(base_size = 9) +
    theme(
      plot.title    = element_text(size = 10, face = "bold", color = "gray10"),
      plot.subtitle = element_text(size = 7.5, color = "gray40"),
      axis.text.y   = element_text(size = 7)
    )

  ggsave(paste0("figures/loadings_", dim, ".png"), p_load,
         width = 9, height = 5, dpi = 130)
}
cat("Figures loadings : figures/loadings_*.png\n")

# --- 7d. Distribution de l'indice global ---

p_global <- ggplot(data_scores, aes(x = score_global)) +
  geom_histogram(bins = 30, fill = "#4a90d9", color = "white", alpha = 0.85) +
  geom_vline(xintercept = median(data_scores$score_global),
             color = "red3", linewidth = 1) +
  geom_vline(xintercept = quantile(data_scores$score_global, 0.25),
             color = "orange2", linewidth = 0.8, linetype = "dashed") +
  geom_vline(xintercept = quantile(data_scores$score_global, 0.75),
             color = "orange2", linewidth = 0.8, linetype = "dashed") +
  annotate("text",
           x     = median(data_scores$score_global),
           y     = Inf,
           label = paste0("Médiane : ", round(median(data_scores$score_global), 1)),
           vjust = 2, hjust = -0.15, color = "red3", size = 3.5) +
  labs(
    title    = "Distribution de l'indice global d'attractivité territoriale",
    subtitle = "306 zones d'emploi — scores normalisés 0-100 — moyenne simple des 9 dimensions",
    x        = "Score global (0-100)",
    y        = "Nombre de zones d'emploi"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(size = 11, face = "bold", color = "gray10"),
    plot.subtitle = element_text(size = 9, color = "gray40")
  )

ggsave("figures/distribution_score_global.png", p_global,
       width = 9, height = 5, dpi = 150)
cat("Figure : figures/distribution_score_global.png\n")

# --- 7e. Indice global vs nombre_creations ---

p_scatter <- ggplot(data_scores, aes(x = score_global, y = nombre_creations)) +
  geom_point(alpha = 0.4, color = "#2166AC", size = 1.8) +
  geom_smooth(method = "lm", color = "red3", se = TRUE, linewidth = 0.8) +
  annotate("text",
           x     = 15,
           y     = max(data_scores$nombre_creations) * 0.88,
           label = sprintf("r = %.3f", r_global),
           size  = 4, color = "gray20") +
  labs(
    title    = "Indice global d'attractivité vs. dynamique de création d'entreprises",
    subtitle = "Corrélation descriptive — aucune interprétation causale",
    caption  = "nombre_creations est standardisé (mean=0, std=1).",
    x        = "Score global ACP (0-100)",
    y        = "Nombre de créations d'entreprises (standardisé)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(size = 11, face = "bold", color = "gray10"),
    plot.subtitle = element_text(size = 9, color = "gray40"),
    plot.caption  = element_text(size = 8, color = "gray50", hjust = 0)
  )

ggsave("figures/scatter_global_creations.png", p_scatter,
       width = 8, height = 6, dpi = 150)
cat("Figure : figures/scatter_global_creations.png\n")

cat("\n=== Script terminé avec succès ===\n")
