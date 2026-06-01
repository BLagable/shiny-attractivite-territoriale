# =============================================================================
# Script de conversion — à lancer UNE SEULE FOIS en local avant déploiement
# Génère ze2020.geojson depuis le shapefile
# Auteur : Benjamin Lagable
# =============================================================================

library(sf)

cat("Lecture du shapefile...\n")
fond <- sf::st_read("data/ze2020_2024.shp", quiet = TRUE) %>%
  dplyr::rename(ZE2020 = ze2020, LIBZE2020 = libze2020) %>%
  sf::st_transform(crs = 4326)

cat("Dimensions :", nrow(fond), "zones d'emploi\n")
cat("Colonnes :", paste(names(fond), collapse = ", "), "\n")

# Export GeoJSON
sf::st_write(fond, "data/ze2020.geojson", driver = "GeoJSON",
             delete_dsn = TRUE, quiet = TRUE)

cat("Fichier exporté : data/ze2020.geojson\n")
cat("Taille :", round(file.size("data/ze2020.geojson") / 1024 / 1024, 1), "Mo\n")
cat("\nConversion terminée. Tu peux maintenant déployer l'app sur shinyapps.io.\n")
