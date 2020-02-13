/* ------------------------------ */
/* Emploi maritime - Offres STMT */
/* ------------------------------ */

* intégration des filtres maritimes sur les ROME et appellations --> charger perimetre_maritime_rome dans la userlib avant ;
* regroupement en cantons --> charger le passage commune-canton avant ;
proc sql;
	create table off_stmt_maritime_init as
		select a.regeta,
				a.dpteta,
				a.cometa,
				a.rome,
				a.aplrome,
				b.famille_mer,
				b.type_metier,
				a.contratdurable,
				a.nbroff

		from off_rest.offre_stmt as a left join userlib.perimetre_maritime_rome as b
				on a.aplrome = b.apl_rome
		where b.famille_mer ne "";
quit;

* regroupement ;
proc sql;
	create table off_stmt_maritime as
		select a.regeta,
				a.dpteta,
				a.cometa,
				a.rome,
				a.famille_mer,
				a.type_metier,
				a.contratdurable,
				sum(a.nbroff) as nb_off_stmt

		from off_stmt_maritime_init as a
		group by  a.regeta,
				a.dpteta,
				a.cometa,
				a.rome,
				a.famille_mer,
				a.type_metier,
				a.contratdurable;
quit;

proc delete data = off_stmt_maritime_init; run;