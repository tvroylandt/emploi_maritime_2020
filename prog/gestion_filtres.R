# ---------------------- #
# Liste des filtres #
# ---------------------- #

library(tidyverse)
library(haven)
library(readxl)
library(writexl)
library(sf)
library(COGugaison)

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
  select(naf732, famille_mer) %>%
  distinct(naf732, famille_mer)

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
  select(rome, apl_rome, famille_mer) %>%
  distinct(rome, apl_rome, famille_mer)

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
# Table de passage commune -> canton : A AMELIORER EN INCLUANT L'HISTORIQUE DES COMMUNES
passage_com_cv <-
  read_xls("methodologie/referentiels/init/table-appartenance-geo-communes-19.xls",
           skip = 5) %>%
  select(CODGEO, CV, REG, DEP) %>%
  rename_all(tolower) %>%
  rename(
    code_com = codgeo,
    code_cv = cv,
    code_reg = reg,
    code_dep = dep
  )

# gerer l'historique + PLM
echecs_cog <- read_xlsx("methodologie/referentiels/init/echecs_cog.xlsx") %>% 
  mutate(code_cv = case_when(str_sub(code_com, 1, 2) == "75" ~ "75ZZ",
                             str_sub(code_com, 1, 3) == "132" ~ "1398" ,
                             str_sub(code_com, 1, 4) == "6938" ~ "69ZZ"),
         code_dep = str_sub(code_cv, 1, 2),
         code_reg = fct_recode(code_dep,
                               "11" = "75",
                               "84" = "69",
                               "93" = "13")) %>% 
  select(-eff)

# pour jointer sur les vieilles tables de passage
join_passage <- function(data, deb, fin) {
  nom_df <- paste0("PASSAGE_", deb, "_", fin)
  
  cod_fin <- paste0("cod", fin)
  
  data %>%
    left_join(get(nom_df), by = c("code_com2" = paste0("cod", deb))) %>%
    mutate(code_com2 = if_else(is.na(!!sym(cod_fin)), code_com2, !!sym(cod_fin))) %>%
    select(code_com, code_com2)
}

# on execute
echecs_cog_recode <- echecs_cog %>%
  filter(is.na(code_cv)) %>%
  mutate(code_com2 = code_com) %>%
  join_passage(deb = 1968, fin = 1975) %>%
  join_passage(deb = 1975, fin = 1982) %>%
  join_passage(deb = 1982, fin = 1990) %>%
  join_passage(deb = 1990, fin = 1999) %>%
  join_passage(deb = 1999, fin = 2008) %>%
  join_passage(deb = 2008, fin = 2009) %>%
  join_passage(deb = 2009, fin = 2010) %>%
  join_passage(deb = 2010, fin = 2011) %>%
  join_passage(deb = 2011, fin = 2012) %>%
  join_passage(deb = 2012, fin = 2013) %>%
  join_passage(deb = 2013, fin = 2014) %>%
  join_passage(deb = 2014, fin = 2015) %>%
  join_passage(deb = 2015, fin = 2016) %>%
  join_passage(deb = 2016, fin = 2017) %>%
  join_passage(deb = 2017, fin = 2018) %>%
  join_passage(deb = 2018, fin = 2019) %>%
  left_join(passage_com_cv, by = c("code_com2" = "code_com")) %>%
  filter(!is.na(code_cv)) %>%
  select(-code_com2) %>%
  bind_rows(echecs_cog %>% 
              filter(!is.na(code_cv)))

# et on rejointe
passage_com_cv <- passage_com_cv %>% 
  bind_rows(echecs_cog_recode)

# sauvegarde
write_xlsx(passage_com_cv,
           "methodologie/referentiels/passage_com_cv.xlsx")

# Import des shapefiles
shp_commune <-
  st_read("methodologie/referentiels/shp/FR_COMMUNE_DOM_IDF_2019.shp") %>%
  filter(zoom_idf == "0")

# Shapefiles CV
shp_canton <- shp_commune %>%
  left_join(passage_com_cv %>% select(code_com, code_cv),
            by = c("code_com")) %>%
  group_by(code_cv, code_dep, code_reg) %>%
  summarise()

# périmètre cv
perimetre_cv <-
  read_xlsx("methodologie/filtres/perimetre_maritime_cantons.xlsx")

# fusion
shp_canton_littoral <- shp_canton %>%
  left_join(perimetre_cv, by = c("code_cv"))

# export
st_write(
  shp_canton_littoral,
  "methodologie/referentiels/shp/FR_CANTON_LITTORAL.shp",
  delete_dsn = TRUE
)
