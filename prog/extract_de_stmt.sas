/* ------------------------------ */
/* Emploi maritime - DE STMT */
/* ------------------------------ */

* creation d'une base à partir des corrections STMT;

* -- TO DO -- ;

* intégration des filtres maritimes sur les ROME et appellations ;
* regroupement en bassins ;

* filtre sur les variables et regroupement ;
* on est sur la DEFM moyenne par année;
* on sort une table par an, qu'on assemblera ensuite;
%macro defm_maritime(annee= );

	%let date_deb = cats(&annee., "01");
	%let date_fin = cats(&annee., "12");

	proc sql;
		create table defm_mean_&annee. as
			select substr(moista, 1, 4) as annee,
				   regres, 
				   comres,
				   catsta,
				   rome,
				   aplrome,
				   sex,
				   case
						when agemoi <= 24 then "Moins de 24 ans"
						when agemoi > 24 and agemoi <= 49 then "25-49 ans"
						when agemoi > 49 then "50 ans et plus"
				   end as tr_age,
				   case
						when trcancsta in ("10", "11", "12") then "Moins d'un an"
						when trcancsta in ("20") then "1-2 ans"
						when trcancsta in ("30", "40") then "2 ans et plus"
				   end as tr_anc,
				   count(*)/12 as nb_defm

			from dem_rest.demande_stmt

			where catsta in ("A", "B", "C") 
				and typdem in ("1", "4")
				and moista between &date_deb. and &date_fin.

			group by calculated annee, 
					regres, 
					comres, 
					catsta, 
					rome, 
					aplrome,
				    sex,
				    calculated tr_age,
				    calculated tr_anc;
	quit;
%mend;

* execution de la macro;
%defm_maritime(annee = 2018); 