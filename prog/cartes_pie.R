# --------------------- #
# Cartes avec Camembert #
# --------------------- #

library(tidyverse)
library(ggimage)
library(sf)
library(ggpubr)

# Fond de cartes ----------------------------------------------------------
# Import
shp_reg <- st_read("methodologie/referentiels/shp/FR_REG_DOM.shp")

# Centroid
shp_reg_centr <- shp_reg %>%
  st_centroid() %>%
  st_coordinates() %>%
  as_tibble()

# Data --------------------------------------------------------------------
base_maritime_mer <-
  readxl::read_xlsx("output/base_maritime_reg.xlsx") %>%
  filter(annee == 2019 & code_reg != "05") %>%
  select(code_reg,
         famille_mer,
         nb_defm_tot,
         nb_dpae,
         nb_eff,
         nb_formation)

# Camemberts --------------------------------------------------------------
windowsFonts("Bliss Bold" = windowsFont(family = "Bliss Bold"))

plot_pie <- function(df, indicateur, filtre) {
  df <- df %>% 
    filter(!famille_mer %in% filtre)
  
  nb_tot <- df %>% 
    summarise(somme = format(round(
      sum({{indicateur}}) / 100, 0) * 100, big.mark = " ")) %>%
    pull(somme)
  
  df %>%
    mutate(prop = round({{indicateur}} / sum({{indicateur}}) * 100, 0)) %>% 
    filter(prop != 0) %>%
    arrange(desc(famille_mer)) %>%
    ggplot(aes(x = 4.2, y = prop, fill = famille_mer)) +
    geom_bar(stat = "identity",
             position = "fill",
             show.legend = FALSE,
             color = "white") +
    coord_polar(theta = "y", start = 0) +
    theme_void() +
    theme_transparent() +
    xlim(2, 5) +
    annotate(geom = "text", x = 2, y = 0, label = nb_tot, family = "Bliss Bold") +
    scale_fill_manual(values = c("Activités et Loisirs Littoraux" = "#F7A600",
                                 "Construction et Maintenance Navale" = "#33B6B7",
                                 "Défense et Administrations Maritimes" = "#E3E3E3",
                                 "Hôtellerie-Restauration" = "#430F50",
                                 "Pêches et Cultures Marines" = "#636362",
                                 "Personnel embarqué" = "#FBDFD6",
                                 "R&D et Ingénierie Maritime" = "#E8413A",
                                 "Services Portuaires et Nautiques" = "#00606D",
                                 "Transformation des Produits de la Mer" = "#736497",
                                 "Travaux en Mer" = "#BCBDE0"))
}

# Mise au format des donnees ----------------------------------------------
df_pie_mer <- base_maritime_mer %>%
  group_by(code_reg) %>%
  nest() %>%
  mutate(pie_dpae = map(
    .x = data,
    indicateur = nb_dpae,
    filtre = c("Activités et Loisirs Littoraux", "Hôtellerie-Restauration"),
    .f = plot_pie
  ),
  pie_eff = map(
    .x = data,
    indicateur = nb_eff,
    filtre = c("Activités et Loisirs Littoraux", "Hôtellerie-Restauration"),
    .f = plot_pie
  ),
  pie_defm = map(
    .x = data,
    indicateur = nb_defm_tot,
    filtre = c("0"),
    .f = plot_pie
  ),
  pie_formation = map(
    .x = data,
    indicateur = nb_formation,
    filtre = c("0"),
    .f = plot_pie
  ),
  total = 245000) %>%
  bind_cols(shp_reg_centr)


# Cartes ------------------------------------------------------------------
ggplot() +
  geom_sf(data = shp_reg, fill = "#E3E3E3") +
  theme_void() +
  geom_subview(data = df_pie_mer,
               aes(
                 x = X,
                 y = Y,
                 subview = pie_formation,
                 width = total,
                 height = total
               ))

ggsave("output/pie_formation.png", dpi = 350, units = "mm", height = 220, width = 160)

