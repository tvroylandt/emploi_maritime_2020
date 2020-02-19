/* ------------------------------ */
/* Emploi maritime - Offres ADO */
/* ------------------------------ */

* pre-traitement code apl rome + Paris ;
proc sql;
	create table off_ado_maritime_000 as
		select annee,
				DC_REGIONLIEUTRAVAIL,
				DC_DEPARTEMENTLIEUTRAVAIL,
				rome,
				cats("0", DC_APPELATIONROME_ID) as aplrome,
				typeoffre,
				moista,
				case
					when DC_DEPARTEMENTLIEUTRAVAIL = "75" then "75056"
					else DC_COMMUNELIEUTRAVAIL
				end as code_com,
				dn_nbposte
		from userlib.dg_dsee_doe_ado;
quit;

* intégration des filtres maritimes sur les ROME et appellations ;
* regroupement en cantons ;
* on ne code que ceux dont on dispose du code commune nativement ;
proc sql;
	create table off_ado_maritime_init as
		select  a.annee,

				a.DC_REGIONLIEUTRAVAIL as code_reg label = "",
				a.DC_DEPARTEMENTLIEUTRAVAIL as code_dep  label = "",
				c.code_cv,
				d.littoral,

				a.rome as rome label = "",
				a.aplrome,
				b.famille_mer,

				case
					when a.typeoffre in ("CDI", "CDD de plus de 6 mois") then 1
					else 0
				end as contratdurable,

				a.dn_nbposte as nbroff

		from off_ado_maritime_000 as a 
			left join userlib.perimetre_maritime_rome as b
				on a.aplrome = b.apl_rome
			left join userlib.passage_com_cv as c 
				on a.code_com = c.code_com
			left join userlib.perimetre_maritime_cantons as d
				on c.code_cv = d.code_cv

		where  b.famille_mer ne "" 
			and (d.littoral = "1" 
				or (d.littoral = "0" 
					and b.famille_mer not in ("Activités et Loisirs Littoraux",
											"Hôtellerie-Restauration",
											"Travaux en Mer",
											"R&D et Ingénierie Maritime")
					)
				)
			and a.moista between "201801" and "201912";
quit;

* regroupement ;
proc sql;
	create table off_ado_maritime as
		select annee,
				code_reg,
				code_dep,
				code_cv,
				littoral,
				rome,
				famille_mer,
				contratdurable,
				sum(nbroff) as nb_off_ado

		from off_ado_maritime_init 
		group by  annee,
				code_reg,
				code_dep,
				code_cv,
				littoral,
				rome,
				famille_mer,
				contratdurable;
quit;
