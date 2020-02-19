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
  mutate(code_com = str_sub(commune, 1, 5),
         naf = paste0(str_sub(ape, 1, 2), str_sub(ape, 4, 6))) %>%
  pivot_longer(
    cols = c(starts_with("nb_"), starts_with("eff")),
    names_to = c(".value", "annee"),
    names_pattern = "(.*)(.{4}$)"
  ) %>%
  select(annee, code_com, naf, nb_etab, eff) %>%
  replace_na(list(nb_etab = 0, eff = 0)) %>%
  rename(nb_eff = eff)

# Familles de la mer ------------------------------------------------------
perimetre_maritime_naf <-
  read_xlsx("methodologie/filtres/perimetre_maritime_naf.xlsx")

df_acoss_maritime_com <- df_acoss_propre %>%
  left_join(perimetre_maritime_naf, by = c("naf" = "naf732")) %>%
  filter(!is.na(famille_mer))

# Cantons littoral --------------------------------------------------------
# Table de passage commune-cv - en historique
passage_com_cv <-
  read_xlsx("methodologie/referentiels/passage_com_cv.xlsx")

# Périmètre CV
perimetre_cv <-
  read_xlsx("methodologie/filtres/perimetre_maritime_cantons.xlsx")

# Jointure et filtre
df_acoss_maritime <- df_acoss_maritime_com %>%
  left_join(
    passage_com_cv %>% select(code_com, code_cv, code_reg, code_dep),
    by = c("code_com")
  ) %>%
  group_by(annee, code_reg, code_dep, code_cv, naf, famille_mer) %>%
  summarise(nb_etab = sum(nb_etab),
            nb_eff = sum(nb_eff)) %>%
  ungroup() %>%
  left_join(perimetre_cv %>% select(code_cv, littoral), by = c("code_cv")) %>%
  filter((littoral == "1" |
            (
              littoral == "0" &
                !famille_mer %in% c(
                  "Activités et Loisirs Littoraux",
                  "Hôtellerie-Restauration",
                  "Travaux en Mer",
                  "R&D et Ingénierie Maritime"
                )
            )) &
           annee %in% c("2017", "2018"))

# Export ------------------------------------------------------------------
write_rds(df_acoss_maritime, "data/df_acoss_maritime.rds")
