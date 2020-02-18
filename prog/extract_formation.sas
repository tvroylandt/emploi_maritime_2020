/* ---------------------------- */
/* Emploi maritime - entrées en formation */
/* ---------------------------- */

libname PRDSTHIS meta library="PRDSTHIS" metarepository="Foundation" ;
libname NTZ_ECD meta library="NTZ_ECD" metarepository="Foundation" ;

* Selection et filtre formacode;
proc sql;
	create table formation_maritime_init as
		select 
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
					when a.dc_typeformation = "POEC_OPCA" then "POEC"
					else "Autres"
				end as type_formation,
				
				a.dc_region as code_reg label = "",
				a.dc_departement as code_dep label = ""

		from PRDSTHIS.DRP_ENTREEFORMATIONEFFECTIVE_V as a 
			left join userlib.perimetre_maritime_formacode as b
				on a.dc_formacode_id = b.formacode

		where b.famille_mer ne "" 
			and a.kc_anneemois between 201810 and 201909
			and a.DC_REFERENCEMENT_ID ne "";
quit;

* regroupement au niveau formation;
proc sql;
	create table formation_maritime_form as
		select dc_referencement_id ,
				famille_mer,
				type_formation,
				code_reg,
				code_dep,
				count(kc_individu_national) as nb_formation

		from formation_maritime_init
		group by dc_referencement_id ,
				famille_mer,
				type_formation,
				code_reg,
				code_dep;
quit;

* jointure montants ;
proc sql;
	create table formation_maritime_form_montants as
		select a.*,
			   b.DN_MONTANTPAYEDECISIONBUREAU as montants label = ""
		from formation_maritime_form as a
			left join NTZ_ECD.DRP_REFERENCEMENT_STK_V as b 
				on a.dc_referencement_id = b.KC_REFERENCEMENT;
quit;

* regroupement ;
proc sql;
	create table formation_maritime as
		select famille_mer,
				type_formation,
				code_reg,
				code_dep,
				sum(nb_formation) as nb_formation,
				sum(montants) as montants

		from formation_maritime_form_montants
		group by famille_mer,
				type_formation,
				code_reg,
				code_dep;
quit;
