# --------------- #
# Emploi salarié Acoss #
# --------------- #

library(tidyverse)
library(readxl)

# Import et concatenation -------------------------------------------------
# fonction de lecture des onglets
read_excel_allsheets <- function(chemin) {
  list_sheets <- excel_sheets(chemin)
  
  map_dfr(list_sheets[-c(1, 2)], read_xls, path = chemin)
}

# lire tous les fichiers et tous les onglets et assembler
df_acoss_init <-
  map_dfr(list.files("data/acoss_emploi", full.names = TRUE),
          read_excel_allsheets)

# Mise en forme -----------------------------------------------------------
df_acoss_propre <- df_acoss_init %>%
  mutate(
    code_com = str_sub(commune, 1, 5),
    naf = paste0(str_sub(ape, 1, 2), str_sub(ape, 4, 6)),
    code_dep = if_else(
      str_sub(code_com, 1, 2) == "97",
      str_sub(code_com, 1, 3),
      str_sub(code_com, 1, 2)
    )
  ) %>%
  pivot_longer(
    cols = c(starts_with("nb_"), starts_with("eff")),
    names_to = c(".value", "annee"),
    names_pattern = "(.*)(.{4}$)"
  ) %>%
  select(annee, code_dep, code_com, naf, nb_etab, eff) %>%
  replace_na(list(nb_etab = 0, eff = 0))

# Familles de la mer ------------------------------------------------------
perimetre_maritime_naf <-
  read_xlsx("methodologie/filtres/perimetre_maritime_naf.xlsx")

df_acoss_maritime_com <- df_acoss_propre %>%
  left_join(perimetre_maritime_naf, by = c("naf" = "naf732")) %>%
  filter(!is.na(famille_mer))

# Cantons littoral --------------------------------------------------------
# Table de passage commune-cv - en historique
# !!! POUR L'INSTANT TABLE INITALE - PROVISOIRE !!!
passage_commune_cv <-
  read_xls("methodologie/referentiels/table-appartenance-geo-communes-19.xls",
           skip = 5) %>%
  select(CODGEO, CV, REG, DEP) %>%
  rename_all(tolower)

# Reste
df_acoss_maritime_com %>%
  anti_join(passage_commune_cv, by = c("code_com" = "codgeo")) %>%
  distinct(code_com)

# Périmètre CV
perimetre_cv <-
  read_xlsx("methodologie/filtres/perimetre_maritime_cantons.xlsx")

# Jointure et filtre
df_acoss_maritime <- df_acoss_maritime_com %>%
  left_join(passage_commune_cv, by = c("code_com" = "codgeo")) %>%
  group_by(code_dep, cv, naf, famille_mer, type_metier) %>%
  summarise(nb_etab = sum(nb_etab),
            eff = sum(eff)) %>%
  ungroup() %>%
  left_join(perimetre_cv, by = c("cv")) %>%
  filter(type_metier == "Coeur" |
           (littoral == "1" & type_metier == "Transverse"))

# Export ------------------------------------------------------------------
write_rds(df_acoss_maritime, "data/df_acoss_maritime.rds")
