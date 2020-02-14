/* ------------------------ */
/* Emploi maritime - DPAE */
/* ------------------------ */

libname ntz_ecd meta library = "NTZ_ECD" metarepository = "Foundation" ;

* Selection et recodage des DPAE ;
* + filtre NAF -> à charger en amont ;
* + jointure commune-canton --> Table à charger ;
proc sql; 
	create table dpae_maritime_init as 
		select distinct 

			a.KC_SIRET,
			a.DC_NAF_ID as naf label = "",
			b.famille_mer,
			b.type_metier,

			a.DC_COMMUNE_ID as code_com label = "",
			substr(a.dc_commune_id, 1, 2) as code_dep,

			a.DC_INDIVIDU_NATIONAL,
			a.DC_TYPECONTRAT_ID,

			year(datepart(a.KD_DATEEMBAUCHE)) as annee, 
			month(datepart(a.KD_DATEEMBAUCHE)) as mois,

			(datepart(a.DD_DATEFINCDD) - datepart(a.KD_DATEEMBAUCHE) + 1) as duree,
			case
				when a.DC_TYPECONTRAT_ID = "2" = "CDI" 
					or (a.DC_TYPECONTRAT_ID = "1" and calculated duree >= 182) then "1" 
				else "0"
			end as ind_durable,
			case
				when a.DC_TYPECONTRAT_ID = "2" = "CDI" then "CDI"
				when a.DC_TYPECONTRAT_ID = "1" and calculated duree >= 182 then "CDD_6m_plus"
				when a.DC_TYPECONTRAT_ID = "1" and calculated duree < 182  and calculated duree > 31 then "CDD_1_5m"
				when a.DC_TYPECONTRAT_ID = "1" and calculated duree <= 31 then "CDD_moins_1m"
				when a.DC_TYPECONTRAT_ID = "3" or a.DC_NAF_ID = "7820Z" then "ETT"
				else "ND"
			end as contrat

		from NTZ_ECD.XDP_DPAE_V as a 
			left join userlib.perimetre_maritime_naf as b 
				on a.dc_naf_id = b.naf732
			/*left join userlib.passage_com_cv as c
				on a.dc_commune_id = c.code_com */
		where calculated annee between 2018 and 2019 
			and b.famille_mer ne ""
			and calculated contrat not in ("ND", "ETT");
quit; 

* regroupement ;
proc sql;
	create table dpae_maritime as
		select famille_mer,
				type_metier,
				code_dep,
				code_com,
				annee,
				mois,
				ind_durable,
				contrat,
				count(dc_individu_national) as nb_dpae
		from dpae_maritime_init
		group by famille_mer,
				type_metier,
				code_dep,
				code_com,
				annee,
				mois,
				ind_durable,
				contrat;
quit;