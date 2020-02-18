/* ------------------------------ */
/* Emploi maritime - DE STMT */
/* ------------------------------ */

* creation d'une base à partir des corrections STMT;
proc sql;
	create table demande_stmt_corr_init_a as 
		select
			b.rome_corr as rome,
			case 
				when a.rome ne b.rome_corr then "" 
				else aplrome
			end as aplrome,
			a.regres,
			a.dptres,
			a.comres,
			a.typdem,
			a.moista,
			a.catsta,
			a.sex,
			a.agemoi,
			a.trcancsta,
			b.qlf_corr as qlf

		from dem_rest.demande_stmt as a left join sasuser.serie_doe as b 
			on (a.moista = b.moista 
				and a.idtunqdmr = b.idtunqdmr 
				and a.typdem = b.typdem 
				and a.catsta = b.catsta)
		where a.moista between "201805" and "201912"
			and a.catsta in ("A", "B", "C") 
			and a.typdem in ("1", "4");
quit;

* sans correction ; 
proc sql;
	create table demande_stmt_corr_init_b as 
		select
			a.rome,
			a.aplrome,
			a.regres,
			a.dptres,
			a.comres,
			a.typdem,
			a.moista,
			a.catsta,
			a.sex,
			a.agemoi,
			a.trcancsta,
			a.qlf

		from dem_rest.demande_stmt as a 
		where a.moista between "201801" and "201804"
			and a.catsta in ("A", "B", "C") 
			and a.typdem in ("1", "4");
quit;

* fusion;
data demande_stmt_corr_init;
	set demande_stmt_corr_init_a
		demande_stmt_corr_init_b;
run;

proc delete data = demande_stmt_corr_init_a; run;
proc delete data = demande_stmt_corr_init_b; run;

* intégration des filtres maritimes sur les ROME et appellations ;
* regroupement en cantons ;
proc sql;
	create table demande_stmt_corr_maritime as
		select substr(a.moista, 1, 4) as annee,

			   a.regres as code_reg label = "", 
			   a.dptres as code_dep  label = "",
			   c.code_cv,
			   d.littoral,

			   a.catsta,
			   a.rome,
			   a.aplrome,
			   b.famille_mer,
			   case 
					when a.sex = "1" then "H"
					when a.sex = "2" then "F"
			   end as sexe,
			   case
					when a.agemoi <= 24 then "Moins de 24 ans"
					when a.agemoi > 24 and agemoi <= 49 then "25-49 ans"
					when a.agemoi > 49 then "50 ans et plus"
			   end as tr_age,
			   case
					when a.trcancsta in ("10", "11", "12") then "Moins d'un an"
					when a.trcancsta in ("20") then "1-2 ans"
					when a.trcancsta in ("30", "40") then "2 ans et plus"
			   end as tr_anc

			from demande_stmt_corr_init as a 
				left join userlib.perimetre_maritime_rome as b 
					on a.aplrome = b.apl_rome
				left join userlib.passage_com_cv as c 
					on a.comres = c.code_com
				left join userlib.perimetre_maritime_cantons as d
					on c.code_cv = d.code_cv

			where b.famille_mer ne "" 
				and (d.littoral = "1" 
					or (d.littoral = "0" 
						and b.famille_mer not in ("Activités et Loisirs Littoraux",
												"Hôtellerie-Restauration")
						)
					);
quit;

* filtre sur les variables et regroupement ;
* on est sur la DEFM moyenne par année;
proc sql;
	create table defm_maritime as
		select annee,
			   code_reg, 
			   code_dep,
			   code_cv,
			   littoral,
			   famille_mer,

			   count(*)/12 as nb_defm_tot,

			   sum(case
						when catsta = "A" then 1/12
						else 0
			  	    end) as nb_defm_cat_a,
			   sum(case
						when sexe = "F" then 1/12
						else 0
			  	    end) as nb_defm_femme,
			   sum(case
						when tr_age = "Moins de 24 ans" then 1/12
						else 0
			  	    end) as nb_defm_jeunes,
			   sum(case
						when tr_age = "50 ans et plus" then 1/12
						else 0
			  	    end) as nb_defm_seniors,
				sum(case
						when tr_anc  in ("1-2 ans", "2 ans et plus") then 1/12
						else 0
			  	    end) as nb_defm_anc_1an_plus

		from demande_stmt_corr_maritime

		group by annee, 
				code_reg, 
			    code_dep,
			    code_cv,
			    littoral, 
				famille_mer;
quit;
