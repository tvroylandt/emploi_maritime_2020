# ------------------------------------------ #
# Mise en forme statistiques emploi maritime #
# ------------------------------------------ #

library(tidyverse)
library(haven)
library(readxl)
library(writexl)

# Référentiels ------------------------------------------------------------
ref_rome <- read_xlsx("methodologie/referentiels/ref_rome.xlsx")

ref_competence <-
  read_sas("methodologie/referentiels/ref_competence.sas7bdat") %>%
  rename(code_comp = KC_SPECIFICITES,
         lib_comp = DC_LBLSPECIFICITES)

ref_reg <- read_xlsx("methodologie/referentiels/ref_reg.xlsx")

# Offres competences ------------------------------------------------------
df_off_comp <-
  read_sas("data/comp_offre_maritime_2019.sas7bdat") %>%
  left_join(ref_competence, by = c("comp" = "code_comp"))

# Top
df_off_comp_top3 <- df_off_comp %>%
  group_by(famille_mer, lib_comp) %>%
  summarise(nb_off = sum(nb_off)) %>%
  top_n(3, wt = nb_off) %>%
  mutate(id = row_number()) %>%
  ungroup() %>%
  select(-nb_off) %>%
  pivot_wider(names_from = id, values_from = lib_comp)

# Offres ------------------------------------------------------------------
# STMT
df_off_stmt <- read_sas("data/off_stmt_maritime.sas7bdat")

# ADO
df_off_ado <- read_sas("data/off_ado_maritime.sas7bdat")

# Fusion
df_off <- df_off_stmt %>%
  full_join(
    df_off_ado,
    by = c(
      "annee",
      "code_reg",
      "code_dep",
      "code_cv",
      "littoral",
      "rome",
      "famille_mer",
      "contratdurable"
    )
  ) %>%
  replace_na(list(nb_off_stmt = 0,
                  nb_off_ado = 0)) %>%
  mutate(nb_off_tot = nb_off_stmt + nb_off_ado) %>%
  left_join(ref_rome, by = c("rome" = "code_rome")) %>%
  left_join(ref_reg, by = c("code_reg"))

# Mise au format
df_off_full <- df_off %>%
  select(-nb_off_stmt, -nb_off_ado) %>%
  pivot_wider(
    names_from = contratdurable,
    values_from = nb_off_tot,
    values_fill = list(nb_off_tot = 0)
  ) %>%
  group_by(annee,
           code_reg,
           lib_reg,
           code_dep,
           famille_mer) %>%
  summarise(nb_off_tot = sum(`0` + `1`),
            nb_off_durable = sum(`1`)) %>%
  ungroup()

# Nombre d'offres
nb_off_evol <- df_off %>%
  group_by(annee) %>%
  summarise(nb_off_tot = sum(nb_off_tot))

# Offres par famille
nb_off_famille <- df_off %>%
  filter(annee == 2019) %>%
  group_by(famille_mer) %>%
  summarise(nb_off_tot = sum(nb_off_tot)) %>%
  mutate(part_off_tot = round(nb_off_tot / sum(nb_off_tot) * 100, 0))

# Top tous métiers
nb_off_top10_global <- df_off %>%
  filter(annee == 2019) %>%
  group_by(rome, lib_rome) %>%
  summarise(nb_off_tot = sum(nb_off_tot)) %>%
  ungroup() %>%
  top_n(10, wt = nb_off_tot) %>%
  arrange(desc(nb_off_tot))

# Top métiers hors tourisme
nb_off_top10_htourisme <- df_off %>%
  filter(
    annee == 2019 &
      !famille_mer %in% c("Activités et Loisirs Littoraux", "Hôtellerie-Restauration")
  ) %>%
  group_by(rome, lib_rome) %>%
  summarise(nb_off_tot = sum(nb_off_tot)) %>%
  ungroup() %>%
  top_n(10, wt = nb_off_tot) %>%
  arrange(desc(nb_off_tot))

# DEFM --------------------------------------------------------------------
df_defm <- read_sas("data/defm_maritime.sas7bdat") %>%
  mutate(annee = as.numeric(annee)) %>%
  left_join(ref_reg, by = c("code_reg")) %>%
  group_by(annee, code_reg, lib_reg, code_dep, famille_mer) %>%
  summarise_at(vars(starts_with("nb")), sum) %>%
  ungroup()

# Evol
nb_defm_evol <- df_defm %>%
  group_by(annee) %>%
  summarise(nb_defm_tot = sum(nb_defm_tot))

# DEFM par région
nb_defm_reg <- df_defm %>%
  filter(annee == 2019) %>%
  group_by(code_reg, lib_reg) %>%
  summarise(nb_defm_tot = sum(nb_defm_tot))

# Part par famille et région
nb_defm_famille_reg <- df_defm %>%
  filter(annee == 2019) %>%
  group_by(code_reg, lib_reg, famille_mer) %>%
  summarise(nb_defm_tot = sum(nb_defm_tot)) %>%
  group_by(code_reg, lib_reg) %>%
  mutate(part_defm_tot = round(nb_defm_tot / sum(nb_defm_tot) * 100, 0)) %>%
  ungroup()

# DEFM par famille
nb_defm_famille <- df_defm %>%
  filter(annee == 2019) %>%
  group_by(famille_mer) %>%
  summarise(nb_defm_tot = sum(nb_defm_tot))

# Profil
nb_defm_profil <- df_defm %>%
  filter(annee == 2019) %>%
  summarise(
    nb_defm_tot = sum(nb_defm_tot),
    nb_defm_cat_a = sum(nb_defm_cat_a),
    nb_defm_anc_1an_plus = sum(nb_defm_anc_1an_plus),
    nb_defm_femme = sum(nb_defm_femme),
    nb_defm_jeunes = sum(nb_defm_jeunes),
    nb_defm_seniors = sum(nb_defm_seniors)
  ) %>%
  mutate(
    part_cat_a = nb_defm_cat_a / nb_defm_tot * 100,
    part_anc_1an_plus = nb_defm_anc_1an_plus / nb_defm_tot * 100,
    part_femme = nb_defm_femme / nb_defm_tot * 100,
    part_jeunes = nb_defm_jeunes / nb_defm_tot * 100,
    part_seniors = nb_defm_seniors / nb_defm_tot * 100
  ) %>%
  select(starts_with("part")) %>%
  mutate_all(round, 0)

# DPAE --------------------------------------------------------------------
df_dpae <- read_sas("data/dpae_maritime.sas7bdat") %>%
  select(-contrat, -mois) %>%
  left_join(ref_reg, by = "code_reg") %>%
  group_by(annee,
           famille_mer,
           code_reg,
           lib_reg,
           code_dep,
           code_cv,
           littoral,
           ind_durable) %>%
  summarise(nb_dpae = sum(nb_dpae)) %>%
  ungroup() %>%
  pivot_wider(
    names_from = ind_durable,
    values_from = nb_dpae,
    values_fill = list(nb_dpae = 0)
  ) %>%
  mutate(nb_dpae = `0` + `1`,
         annee = as.numeric(annee)) %>%
  select(-`0`) %>%
  rename(nb_dpae_durable = `1`)

# DPAE full
df_dpae_full <- df_dpae %>%
  group_by(annee,
           famille_mer,
           code_reg,
           lib_reg,
           code_dep) %>%
  summarise(nb_dpae = sum(nb_dpae),
            nb_dpae_durable = sum(nb_dpae_durable)) %>%
  ungroup()

# Evol DPAE
nb_dpae_evol <- df_dpae %>%
  group_by(annee) %>%
  summarise(nb_dpae = sum(nb_dpae))

# DPAE par famille
nb_dpae_famille <- df_dpae %>%
  group_by(famille_mer) %>%
  summarise(nb_dpae = sum(nb_dpae))

# DPAE par famille et région
nb_dpae_famille_reg <- df_dpae %>%
  filter(
    annee == 2019 &
      !famille_mer %in% c("Activités et Loisirs Littoraux", "Hôtellerie-Restauration")
  ) %>%
  group_by(code_reg, lib_reg, famille_mer) %>%
  summarise(nb_dpae = sum(nb_dpae)) %>%
  ungroup()

# DPAE par famille et région - littoral
nb_dpae_famille_reg_littoral <- df_dpae %>%
  filter(annee == 2019 & littoral == "1") %>%
  group_by(code_reg, lib_reg, famille_mer) %>%
  summarise(nb_dpae = sum(nb_dpae)) %>%
  group_by(code_reg) %>%
  mutate(part_dpae = round(nb_dpae / sum(nb_dpae) * 100, 0)) %>%
  filter(part_dpae > 10) %>%
  ungroup()

# DPAE par région
nb_dpae_reg <- df_dpae %>%
  filter(annee == 2019) %>%
  group_by(code_reg, lib_reg) %>%
  summarise(nb_dpae = sum(nb_dpae))

# Emploi ------------------------------------------------------------------
df_emploi <- read_rds("data/df_acoss_maritime.rds") %>%
  left_join(ref_reg, by = "code_reg") %>%
  mutate(annee = as.numeric(annee)) %>%
  group_by(annee, code_reg, lib_reg, code_dep, famille_mer) %>%
  summarise(nb_etab = sum(nb_etab),
            nb_eff = sum(nb_eff)) %>%
  ungroup()

# Evol
nb_emploi_evol <- df_emploi %>%
  mutate(gde_famille_mer = if_else(
    famille_mer %in% c("Activités et Loisirs Littoraux", "Hôtellerie-Restauration"),
    "Tourisme",
    "Hors tourisme"
  )) %>%
  group_by(annee, gde_famille_mer) %>%
  summarise(nb_etab = sum(nb_etab),
            nb_eff = sum(nb_eff))

# Evol par region
nb_emploi_evol_reg_htourisme <- df_emploi %>%
  filter(!famille_mer %in% c("Activités et Loisirs Littoraux", "Hôtellerie-Restauration")) %>%
  group_by(annee, code_reg, lib_reg) %>%
  summarise(nb_eff = sum(nb_eff)) %>%
  pivot_wider(names_from = annee_ref_emploi,  values_from = nb_eff) %>%
  ungroup() %>%
  mutate(evol = round((`2018` / `2017` - 1) * 100, 1),
         part_eff = round(`2018` / sum(`2018`) * 100, 1))

# Par famille et region
nb_emploi_famille_reg_htourisme <- df_emploi %>%
  filter(
    annee == 2018 &
      !famille_mer %in% c("Activités et Loisirs Littoraux", "Hôtellerie-Restauration")
  ) %>%
  group_by(code_reg, lib_reg, famille_mer) %>%
  summarise(nb_eff = sum(nb_eff)) %>%
  group_by(code_reg, lib_reg) %>%
  mutate(part_eff = round(nb_eff / sum(nb_eff) * 100, 0)) %>%
  ungroup()

# Formation ---------------------------------------------------------------
df_formation <- read_sas("data/formation_maritime.sas7bdat") %>%
  left_join(ref_reg, by = "code_reg")

# full
df_formation_full <- df_formation %>%
  mutate(annee = 2019) %>%
  group_by(annee,
           annee_ref_formation,
           code_reg,
           lib_reg,
           code_dep,
           famille_mer) %>%
  summarise(nb_formation = sum(nb_formation)) %>%
  ungroup()

# type formation + montants
nb_formation_type <- df_formation %>%
  group_by(type_formation) %>%
  summarise(nb_formation = sum(nb_formation),
            montants = sum(montants, na.rm = TRUE))

# par region et famille
nb_formation_reg_famille <- df_formation %>%
  group_by(code_reg, lib_reg, famille_mer) %>%
  summarise(nb_formation = sum(nb_formation)) %>%
  group_by(code_reg, lib_reg) %>%
  mutate(part_formation = round(nb_formation / sum(nb_formation) * 100 , 0)) %>%
  ungroup()

# Base totale -------------------------------------------------------------
# Jointure
df_base_maritime_dep_famille <- df_off_full %>%
  full_join(df_defm,
            by = c("annee",
                   "code_reg",
                   "lib_reg",
                   "code_dep",
                   "famille_mer")) %>%
  full_join(df_dpae_full,
            by = c("annee",
                   "code_reg",
                   "lib_reg",
                   "code_dep",
                   "famille_mer")) %>%
  full_join(df_emploi,
            by = c("annee",
                   "code_reg",
                   "lib_reg",
                   "code_dep",
                   "famille_mer")) %>%
  full_join(df_formation_full,
            by = c("annee",
                   "code_reg",
                   "lib_reg",
                   "code_dep",
                   "famille_mer")) %>%
  mutate_at(vars(starts_with("nb")), function(x) {
    if_else(is.na(x), 0, x)
  }) %>%
  filter(annee >= 2018)

# Par région et famille maritime
df_base_maritime_reg_famille <- df_base_maritime_dep_famille %>%
  group_by(annee, code_reg, famille_mer) %>%
  summarise_at(vars(starts_with("nb")), sum) %>%
  ungroup()

# Export ------------------------------------------------------------------
write_xlsx(list("Competence_top3" = df_off_comp_top3),
           "output/resultats_maritime_2019.xlsx")

write_xlsx(df_base_maritime_dep_famille,
           "output/base_maritime_dep.xlsx")

write_xlsx(df_base_maritime_reg_famille,
           "output/base_maritime_reg.xlsx")
