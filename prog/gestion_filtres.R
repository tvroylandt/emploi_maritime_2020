# ---------------------- #
# Liste des filtres #
# ---------------------- #

library(tidyverse)
library(haven)
library(readxl)
library(writexl)
library(sf)

# Filtres NAF -------------------------------------------------------------
# Import des périmètres
perimetre_naf <-
  read_xlsx(
    "methodologie/filtres_init/Aquitaine_Liste codes NAF Appellations ROME et cantons retenus.xlsx",
    sheet = "NAF",
    col_types = c(
      "text",
      "skip",
      "skip",
      "text",
      "text",
      "skip",
      "skip",
      "skip",
      "skip"
    ),
    col_names = c("naf732", "famille_mer", "type_metier"),
    skip = 1
  ) %>%
  filter(!is.na(naf732)) %>%
  select(naf732, famille_mer, type_metier) %>%
  mutate(type_metier = fct_recode(type_metier,
                                  "Coeur" = "1",
                                  "Transverse" = "2"))

# Export
write_xlsx(perimetre_naf,
           "methodologie/filtres/perimetre_maritime_naf.xlsx")

# Filtres ROME ------------------------------------------------------------
# Import des périmètres
perimetre_rome <-
  read_xlsx(
    "methodologie/filtres_init/Aquitaine_Liste codes NAF Appellations ROME et cantons retenus.xlsx",
    sheet = "ROME",
    col_types = c(
      "text",
      "text",
      "skip",
      "skip",
      "text",
      "skip",
      "text",
      "skip",
      "skip",
      "skip"
    ),
    col_names = c("apl_rome", "rome", "famille_mer", "type_metier"),
    skip = 1
  ) %>%
  select(rome, apl_rome, famille_mer, type_metier) %>%
  mutate(type_metier = fct_recode(type_metier,
                                  "Coeur" = "1",
                                  "Transverse" = "2"))

# Pour chaque ROME, on veut une famille prioritaire
# Pour les attributions quand on n'a pas l'appellation
perimetre_rome_prior <- perimetre_rome %>%
  group_by(rome, famille_mer) %>%
  count() %>%
  group_by(rome) %>%
  top_n(1, wt = n) %>%
  ungroup() %>%
  select(-n)

# Export
write_xlsx(perimetre_rome,
           "methodologie/filtres/perimetre_maritime_rome.xlsx")
write_xlsx(perimetre_rome_prior,
           "methodologie/filtres/perimetre_maritime_rome_prior.xlsx")


# Filtres formacode -------------------------------------------------------
perimetre_formacode <-
  read_xlsx(
    "methodologie/filtres_init/Liste FORMACODES Filière maritime.xlsx",
    col_types = c("text", "skip", "skip", "skip", "text"),
    col_names = c("formacode", "famille_mer"),
    skip = 1
  )

write_xlsx(perimetre_formacode,
           "methodologie/filtres/perimetre_maritime_formacode.xlsx")

# Filtres géographiques ---------------------------------------------------
# Import des shapefiles
shp_commune <-
  st_read("methodologie/referentiels/FR_COMMUNE_DOM_IDF_2019.shp") %>%
  filter(zoom_idf == "0")

# Table de passage commune -> canton
passage_commune_cv <-
  read_xls("methodologie/referentiels/table-appartenance-geo-communes-19.xls",
           skip = 5) %>%
  select(CODGEO, CV, REG, DEP) %>%
  rename_all(tolower)

# Shapefiles CV
shp_canton <- shp_commune %>%
  left_join(passage_commune_cv %>% select(codgeo, cv),
            by = c("code_com" = "codgeo")) %>%
  group_by(cv, code_dep, code_reg) %>%
  summarise()

# périmètre cv
perimetre_cv <-
  read_xlsx("methodologie/filtres/perimetre_maritime_cantons.xlsx")


# fusion
shp_canton_littoral <- shp_canton %>%
  left_join(perimetre_cv, by = c("cv"))
