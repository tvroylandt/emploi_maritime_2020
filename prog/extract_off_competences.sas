/* ---------------------------------------------------- */
/* - Emploi maritime - Compétences techniques offres */
/* ---------------------------------------------------- */

* filtre de la table competence sur les métiers maritimes ;
proc sql;
	create table comp_offre_maritime_2019_init as
		select cats(a.KC_MOISSTATISTIQUE, "_", a.KC_OFFRE, "_", a.KC_NATUREENREGDETAILLEE_ID) as cle_ident,
			  a.DC_ROMEV3_ID as rome, 
			  a.DC_APPELATIONROMEV3_ID as aplrome,
			  a.DN_NBOFFRENATUREDETAILLEE as nbroff, 
			  b.famille_mer,

			  c.code_reg,
			  c.code_dep,
			  c.code_cv,
			  d.littoral,

			  a.DC_SPECIFICITE1 as specif1, 
	          a.DC_SPECIFICITE2 as specif2, 
	          a.DC_SPECIFICITE3 as specif3, 
	          a.DC_SPECIFICITE4 as specif4, 
	          a.DC_SPECIFICITE5 as specif5, 
	          a.DC_SPECIFICITE6 as specif6, 
	          a.DC_SPECIFICITE7 as specif7, 
	          a.DC_SPECIFICITE8 as specif8, 
	          a.DC_SPECIFICITE9 as specif9, 
	          a.DC_SPECIFICITE10 as specif10, 
	          a.DC_SPECIFICITE11 as specif11, 
	          a.DC_SPECIFICITE12 as specif12, 
	          a.DC_SPECIFICITE13 as specif13, 
	          a.DC_SPECIFICITE14 as specif14, 
	          a.DC_SPECIFICITE15 as specif15, 
	          a.DC_SPECIFICITE16 as specif16, 
	          a.DC_SPECIFICITE17 as specif17, 
	          a.DC_SPECIFICITE18 as specif18, 
	          a.DC_SPECIFICITE19 as specif19, 
	          a.DC_SPECIFICITE20 as specif20, 
	          a.DC_SPECIFICITE21 as specif21, 
	          a.DC_SPECIFICITE22 as specif22, 
	          a.DC_SPECIFICITE23 as specif23, 
	          a.DC_SPECIFICITE24 as specif24, 
	          a.DC_SPECIFICITE25 as specif25, 
	          a.DC_SPECIFICITE26 as specif26, 
	          a.DC_SPECIFICITE27 as specif27, 
	          a.DC_SPECIFICITE28 as specif28, 
	          a.DC_SPECIFICITE29 as specif29, 
	          a.DC_SPECIFICITE30 as specif30, 
	          a.DC_SPECIFICITE31 as specif31, 
	          a.DC_SPECIFICITE32 as specif32, 
	          a.DC_SPECIFICITE33 as specif33, 
	          a.DC_SPECIFICITE34 as specif34, 
	          a.DC_SPECIFICITE35 as specif35, 
	          a.DC_SPECIFICITE36 as specif36, 
	          a.DC_SPECIFICITE37 as specif37, 
	          a.DC_SPECIFICITE38 as specif38, 
	          a.DC_SPECIFICITE39 as specif39, 
	          a.DC_SPECIFICITE40 as specif40

		from ntz_secu.doe_comp_offre_2019 as a 
			left join userlib.perimetre_maritime_rome as b
				on a.dc_romev3_id = b.rome and a.DC_APPELATIONROMEV3_ID = b.apl_rome
			left join userlib.passage_com_cv as c 
				on a.DC_COMMUNE_ETABLISSEMENT_ID = c.code_com
			left join userlib.perimetre_maritime_cantons as d
				on c.code_cv = d.code_cv

		where b.famille_mer ne ""
			and (d.littoral = "1" 
				or (d.littoral = "0" 
					and b.famille_mer not in ("Activités et Loisirs Littoraux",
											"Hôtellerie-Restauration",
											"Travaux en Mer")
					)
				);
quit;

* tri ;
proc sql;
	create table comp_offre_maritime_2019_init as
		select *
		from comp_offre_maritime_2019_init
		order by cle_ident,
				rome,
				aplrome,
				famille_mer,
				code_reg,
				code_dep,
				code_cv,
				littoral,
				nbroff ;
quit;

* transposition ;
proc transpose data = comp_offre_maritime_2019_init out = comp_offre_maritime_2019_tr;
	by 
		cle_ident
		rome
		aplrome
		famille_mer
		code_reg
		code_dep
		code_cv
		littoral
		nbroff ;
	var SPECIF1--SPECIF40;
run;

* filtre et regroupement;
proc sql;
	create table comp_offre_maritime_2019 as
		select famille_mer,
				code_reg,
				code_dep,
				code_cv,
				littoral,
				col1 as comp,
				sum(nbroff) as nb_off
		from comp_offre_maritime_2019_tr
		where col1 ne "000000"
		group by famille_mer,
				code_reg,
				code_dep,
				code_cv,
				littoral,
				comp ;
quit;