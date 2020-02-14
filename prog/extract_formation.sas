/* ---------------------------- */
/* Emploi maritime - entrées en formation */
/* ---------------------------- */

libname PRDSTHIS meta library="PRDSTHIS" metarepository="Foundation" ;
libname NTZ_ECD meta library="NTZ_ECD" metarepository="Foundation" ;

* Selection et filtre formacode;
proc sql;
	create table formation_maritime_init as
		select distinct
				a.DC_REFERENCEMENT_ID,
				a.kc_individu_national,

				a.dc_formacode_id as formacode label = "",
				b.famille_mer,

				case
					when a.dc_typeformation = "AFC" then "AFC"
					when a.dc_typeformation = "AFPR" then "AFPR"
					when a.dc_typeformation = "AIF" then "AIF"
					when a.dc_typeformation in ("OPCA", "AGEFIPH","AUTRES" "Bénéficiaire","Conseil Régional","ETAT / Ministères / Collectivités territoriales") then "Autres"
					when a.dc_typeformation in ("POEI_COF", "POEI_MONO") then "POEI"
					when a.dc_typeformation = "POEC_OPCA" then "OPEC"
					else "Autres"
				end as type_formation,
				
				substr(d.dc_insee_lieuformation, 1, 2) as code_dep,
				d.dc_insee_lieuformation as code_com label = ""
		

		from PRDSTHIS.DRP_ENTREEFORMATIONEFFECTIVE_V as a 
			left join userlib.perimetre_maritime_formacode as b
				on a.dc_formacode_id = b.formacode
			left join NTZ_ECD.DRP_RATTACH_V as c
				on a.dc_referencement_id = c.dc_referencement
			left join NTZ_ECD.DRP_SESSION_V as d
				on c.dn_session_id = d.kn_session
		where b.famille_mer ne "" 
			and a.kc_anneemois between 201810 and 201909
			and a.DC_REFERENCEMENT_ID ne "";
quit;

* regroupement;
proc sql;
	create table formation_maritime as
		select famille_mer,
				type_formation,
				code_dep,
				code_com,
				count(kc_individu_national) as nb_formation
		from formation_maritime_init
		group by famille_mer,
				type_formation,
				code_dep,
				code_com;
quit;