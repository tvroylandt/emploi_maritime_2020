/* ------------------------------ */
/* Emploi maritime - Offres STMT */
/* ------------------------------ */

* int�gration des filtres maritimes sur les ROME et appellations ;
* regroupement en cantons ;
proc sql;
	create table off_stmt_maritime_init as
		select  a.anneestat as annee  label = "",

				a.regeta as code_reg label = "",
				a.dpteta as code_dep  label = "",
				c.code_cv,
				d.littoral,

				a.rome as rome label = "",
				a.aplrome,
				b.famille_mer,
				a.contratdurable as contratdurable label = "",
				a.nbroff

		from off_rest.offre_stmt as a 
			left join userlib.perimetre_maritime_rome as b
				on a.aplrome = b.apl_rome
			left join userlib.passage_com_cv as c 
				on a.cometa = c.code_com
			left join userlib.perimetre_maritime_cantons as d
				on c.code_cv = d.code_cv
		where b.famille_mer ne "" 
			and (d.littoral = "1" 
				or (d.littoral = "0" 
					and b.famille_mer not in ("Activit�s et Loisirs Littoraux",
											"H�tellerie-Restauration",
											"Travaux en Mer",
											"R&D et Ing�nierie Maritime")
					)
				)
			and a.natregoff = "ENREG" 
			and a.moista between "201801" and "201912";
quit;

* regroupement ;
proc sql;
	create table off_stmt_maritime as
		select annee,
				code_reg,
				code_dep,
				code_cv,
				littoral,
				rome,
				famille_mer,
				contratdurable,
				sum(nbroff) as nb_off_stmt

		from off_stmt_maritime_init 
		group by  annee,
				code_reg,
				code_dep,
				code_cv,
				littoral,
				rome,
				famille_mer,
				contratdurable;
quit;

proc delete data = off_stmt_maritime_init; run;