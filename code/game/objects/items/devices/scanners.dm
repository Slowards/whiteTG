
/*
CONTAINS:
T-RAY
DETECTIVE SCANNER
HEALTH ANALYZER
GAS ANALYZER
MASS SPECTROMETER

*/
/obj/item/device/t_scanner
	name = "\improper T-ray scanner"
	desc = "A terahertz-ray emitter and scanner used to detect underfloor objects such as cables and pipes."
	icon_state = "t-ray0"
	var/on = FALSE
	slot_flags = SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	materials = list(MAT_METAL=150)

/obj/item/device/t_scanner/attack_self(mob/user)

	on = !on
	icon_state = copytext(icon_state, 1, length(icon_state))+"[on]"

	if(on)
		START_PROCESSING(SSobj, src)

/obj/item/device/t_scanner/proc/flick_sonar(obj/pipe)
	if(ismob(loc))
		var/mob/M = loc
		var/image/I = new(loc = get_turf(pipe))
		var/mutable_appearance/MA = new(pipe)
		MA.alpha = 128
		MA.dir = pipe.dir
		I.appearance = MA
		I.dir = pipe.dir
		// Workaround for a weird bug with icon direction on T-Ray scan not matching the actual disposal pipe dir.
		if(M.client)
			flick_overlay(I, list(M.client), 8)

/obj/item/device/t_scanner/process()
	if(!on)
		STOP_PROCESSING(SSobj, src)
		return null
	scan()

/obj/item/device/t_scanner/proc/scan()

	for(var/turf/T in range(2, src.loc) )
		for(var/obj/O in T.contents)

			if(O.level != 1)
				continue

			if(O.invisibility == INVISIBILITY_MAXIMUM)
				flick_sonar(O)

/obj/item/device/healthanalyzer
	name = "health analyzer"
	icon_state = "health"
	item_state = "healthanalyzer"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	desc = "A hand-held body scanner able to distinguish vital signs of the subject."
	flags_1 = CONDUCT_1 | NOBLUDGEON_1
	slot_flags = SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	materials = list(MAT_METAL=200)
	var/mode = 1
	var/scanmode = 0
	var/advanced = FALSE

/obj/item/device/healthanalyzer/attack_self(mob/user)
	if(!scanmode)
		to_chat(user, "<span class='notice'>You switch the health analyzer to scan chemical contents.</span>")
		scanmode = 1
	else
		to_chat(user, "<span class='notice'>You switch the health analyzer to check physical health.</span>")
		scanmode = 0

/obj/item/device/healthanalyzer/attack(mob/living/M, mob/living/carbon/human/user)

	// Clumsiness/brain damage check
	if ((user.disabilities & CLUMSY || user.getBrainLoss() >= 60) && prob(50))
		to_chat(user, "<span class='notice'>You stupidly try to analyze the floor's vitals!</span>")
		user.visible_message("<span class='warning'>[user] has analyzed the floor's vitals!</span>")
		to_chat(user, "<span class='info'>Analyzing results for The floor:\n\tOverall status: <b>Healthy</b>")
		to_chat(user, "<span class='info'>Key: <font color='blue'>Suffocation</font>/<font color='green'>Toxin</font>/<font color='#FF8000'>Burn</font>/<font color='red'>Brute</font></span>")
		to_chat(user, "<span class='info'>\tDamage specifics: <font color='blue'>0</font>-<font color='green'>0</font>-<font color='#FF8000'>0</font>-<font color='red'>0</font></span>")
		to_chat(user, "<span class='info'>Body temperature: ???</span>")
		return

	user.visible_message("<span class='notice'>[user] has analyzed [M]'s vitals.</span>")

	if(scanmode == 0)
		healthscan(user, M, mode, advanced)
	else if(scanmode == 1)
		chemscan(user, M)

	add_fingerprint(user)


// Used by the PDA medical scanner too
/proc/healthscan(mob/user, mob/living/M, mode = 1, advanced = FALSE)
	if(isliving(user) && (user.incapacitated() || user.eye_blind))
		return
	//Damage specifics
	var/oxy_loss = M.getOxyLoss()
	var/tox_loss = M.getToxLoss()
	var/fire_loss = M.getFireLoss()
	var/brute_loss = M.getBruteLoss()
	var/mob_status = (M.stat == DEAD ? "<span class='alert'><b>Deceased</b></span>" : "<b>[round(M.health/M.maxHealth,0.01)*100] % healthy</b>")

	if(M.status_flags & FAKEDEATH && !advanced)
		mob_status = "<span class='alert'><b>Deceased</b></span>"
		oxy_loss = max(rand(1, 40), oxy_loss, (300 - (tox_loss + fire_loss + brute_loss))) // Random oxygen loss

	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.undergoing_cardiac_arrest() && H.stat != DEAD)
			to_chat(user, "<span class='danger'>Subject suffering from heart attack: apply defibrillator immediately!</span>")
		if(H.undergoing_liver_failure() && H.stat != DEAD)
			to_chat(user, "<span class='danger'>Subject suffering from liver failure: apply corazone and begin a liver transplant immediately!</span>")

	to_chat(user, "<span class='info'>Analyzing results for [M]:\n\tOverall status: [mob_status]</span>")

	// Damage descriptions
	if(brute_loss > 10)
		to_chat(user, "\t<span class='alert'>[brute_loss > 50 ? "Severe" : "Minor"] tissue damage detected.</span>")
	if(fire_loss > 10)
		to_chat(user, "\t<span class='alert'>[fire_loss > 50 ? "Severe" : "Minor"] burn damage detected.</span>")
	if(oxy_loss > 10)
		to_chat(user, "\t<span class='info'><span class='alert'>[oxy_loss > 50 ? "Severe" : "Minor"] oxygen deprivation detected.</span>")
	if(tox_loss > 10)
		to_chat(user, "\t<span class='alert'>[tox_loss > 50 ? "Severe" : "Minor"] amount of toxin damage detected.</span>")
	if(M.getStaminaLoss())
		to_chat(user, "\t<span class='alert'>Subject appears to be suffering from fatigue.</span>")
		if(advanced)
			to_chat(user, "\t<span class='info'>Fatigue Level: [M.getStaminaLoss()]%.</span>")
	if (M.getCloneLoss())
		to_chat(user, "\t<span class='alert'>Subject appears to have [M.getCloneLoss() > 30 ? "severe" : "minor"] cellular damage.</span>")
		if(advanced)
			to_chat(user, "\t<span class='info'>Cellular Damage Level: [M.getCloneLoss()].</span>")
	if (M.getBrainLoss() >= 100 || !M.getorgan(/obj/item/organ/brain))
		to_chat(user, "\t<span class='alert'>Subject brain function is non-existent.</span>")
	else if (M.getBrainLoss() >= 60)
		to_chat(user, "\t<span class='alert'>Severe brain damage detected. Subject likely to have mental retardation.</span>")
	else if (M.getBrainLoss() >= 10)
		to_chat(user, "\t<span class='alert'>Brain damage detected. Subject may have had a concussion.</span>")
	if(advanced)
		to_chat(user, "\t<span class='info'>Brain Activity Level: [100 - M.getBrainLoss()]%.</span>")
	if (M.radiation)
		to_chat(user, "\t<span class='alert'>Subject is irradiated.</span>")
		if(advanced)
			to_chat(user, "\t<span class='info'>Radiation Level: [M.radiation]%.</span>")

	if(advanced && M.hallucinating())
		to_chat(user, "\t<span class='info'>Subject is hallucinating.</span>")

	//Eyes and ears
	if(advanced)
		if(iscarbon(M))
			var/mob/living/carbon/C = M
			var/obj/item/organ/ears/ears = C.getorganslot(ORGAN_SLOT_EARS)
			to_chat(user, "\t<span class='info'><b>==EAR STATUS==</b></span>")
			if(istype(ears))
				var/healthy = TRUE
				if(C.disabilities & DEAF)
					healthy = FALSE
					to_chat(user, "\t<span class='alert'>Subject is genetically deaf.</span>")
				else
					if(ears.ear_damage)
						to_chat(user, "\t<span class='alert'>Subject has [ears.ear_damage > UNHEALING_EAR_DAMAGE? "permanent ": "temporary "]hearing damage.</span>")
						healthy = FALSE
					if(ears.deaf)
						to_chat(user, "\t<span class='alert'>Subject is [ears.ear_damage > UNHEALING_EAR_DAMAGE ? "permanently ": "temporarily "] deaf.</span>")
						healthy = FALSE
				if(healthy)
					to_chat(user, "\t<span class='info'>Healthy.</span>")
			else
				to_chat(user, "\t<span class='alert'>Subject does not have ears.</span>")
			var/obj/item/organ/eyes/eyes = C.getorganslot(ORGAN_SLOT_EYES)
			to_chat(user, "\t<span class='info'><b>==EYE STATUS==</b></span>")
			if(istype(eyes))
				var/healthy = TRUE
				if(C.disabilities & BLIND)
					to_chat(user, "\t<span class='alert'>Subject is blind.</span>")
					healthy = FALSE
				if(C.disabilities & NEARSIGHT)
					to_chat(user, "\t<span class='alert'>Subject is nearsighted.</span>")
					healthy = FALSE
				if(eyes.eye_damage > 30)
					to_chat(user, "\t<span class='alert'>Subject has severe eye damage.</span>")
					healthy = FALSE
				else if(eyes.eye_damage > 20)
					to_chat(user, "\t<span class='alert'>Subject has significant eye damage.</span>")
					healthy = FALSE
				else if(eyes.eye_damage)
					to_chat(user, "\t<span class='alert'>Subject has minor eye damage.</span>")
					healthy = FALSE
				if(healthy)
					to_chat(user, "\t<span class='info'>Healthy.</span>")
			else
				to_chat(user, "\t<span class='alert'>Subject does not have eyes.</span>")


	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/ldamage = H.return_liver_damage()
		if(ldamage > 10)
			to_chat(user, "\t<span class='alert'>[ldamage > 45 ? "severe" : "minor"] liver damage detected.</span>")

	// Body part damage report
	if(iscarbon(M) && mode == 1)
		var/mob/living/carbon/C = M
		var/list/damaged = C.get_damaged_bodyparts(1,1)
		if(length(damaged)>0 || oxy_loss>0 || tox_loss>0 || fire_loss>0)
			to_chat(user, "<span class='info'>\tDamage: <span class='info'><font color='red'>Brute</font></span>-<font color='#FF8000'>Burn</font>-<font color='green'>Toxin</font>-<font color='blue'>Suffocation</font>\n\t\tSpecifics: <font color='red'>[brute_loss]</font>-<font color='#FF8000'>[fire_loss]</font>-<font color='green'>[tox_loss]</font>-<font color='blue'>[oxy_loss]</font></span>")
			for(var/obj/item/bodypart/org in damaged)
				to_chat(user, "\t\t<span class='info'>[capitalize(org.name)]: [(org.brute_dam > 0) ? "<font color='red'>[org.brute_dam]</font></span>" : "<font color='red'>0</font>"]-[(org.burn_dam > 0) ? "<font color='#FF8000'>[org.burn_dam]</font>" : "<font color='#FF8000'>0</font>"]")

	// Species and body temperature
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		to_chat(user, "<span class='info'>Species: [H.dna.species.name]</span>")
	to_chat(user, "<span class='info'>Body temperature: [round(M.bodytemperature-T0C,0.1)] &deg;C ([round(M.bodytemperature*1.8-459.67,0.1)] &deg;F)</span>")

	// Time of death
	if(M.tod && (M.stat == DEAD || ((M.status_flags & FAKEDEATH) && !advanced)))
		to_chat(user, "<span class='info'>Time of Death:</span> [M.tod]")
		var/tdelta = round(world.time - M.timeofdeath)
		if(tdelta < (DEFIB_TIME_LIMIT * 10))
			to_chat(user, "<span class='danger'>Subject died [DisplayTimeText(tdelta)] ago, defibrillation may be possible!</span>")

	for(var/thing in M.viruses)
		var/datum/disease/D = thing
		if(!(D.visibility_flags & HIDDEN_SCANNER))
			to_chat(user, "<span class='alert'><b>Warning: [D.form] detected</b>\nName: [D.name].\nType: [D.spread_text].\nStage: [D.stage]/[D.max_stages].\nPossible Cure: [D.cure_text]</span>")

	// Blood Level
	if(M.has_dna())
		var/mob/living/carbon/C = M
		var/blood_id = C.get_blood_id()
		if(blood_id)
			if(ishuman(C))
				var/mob/living/carbon/human/H = C
				if(H.bleed_rate)
					to_chat(user, "<span class='danger'>Subject is bleeding!</span>")
			var/blood_percent =  round((C.blood_volume / BLOOD_VOLUME_NORMAL)*100)
			var/blood_type = C.dna.blood_type
			if(blood_id != "blood")//special blood substance
				var/datum/reagent/R = GLOB.chemical_reagents_list[blood_id]
				if(R)
					blood_type = R.name
				else
					blood_type = blood_id
			if(C.blood_volume <= BLOOD_VOLUME_SAFE && C.blood_volume > BLOOD_VOLUME_OKAY)
				to_chat(user, "<span class='danger'>LOW blood level [blood_percent] %, [C.blood_volume] cl,</span> <span class='info'>type: [blood_type]</span>")
			else if(C.blood_volume <= BLOOD_VOLUME_OKAY)
				to_chat(user, "<span class='danger'>CRITICAL blood level [blood_percent] %, [C.blood_volume] cl,</span> <span class='info'>type: [blood_type]</span>")
			else
				to_chat(user, "<span class='info'>Blood level [blood_percent] %, [C.blood_volume] cl, type: [blood_type]</span>")

		var/cyberimp_detect
		for(var/obj/item/organ/cyberimp/CI in C.internal_organs)
			if(CI.status == ORGAN_ROBOTIC && !CI.syndicate_implant)
				cyberimp_detect += "[C.name] is modified with a [CI.name].<br>"
		if(cyberimp_detect)
			to_chat(user, "<span class='notice'>Detected cybernetic modifications:</span>")
			to_chat(user, "<span class='notice'>[cyberimp_detect]</span>")

/proc/chemscan(mob/living/user, mob/living/M)
	if(istype(M))
		if(M.reagents)
			if(M.reagents.reagent_list.len)
				to_chat(user, "<span class='notice'>Subject contains the following reagents:</span>")
				for(var/datum/reagent/R in M.reagents.reagent_list)
					to_chat(user, "<span class='notice'>[R.volume] units of [R.name][R.overdosed == 1 ? "</span> - <span class='boldannounce'>OVERDOSING</span>" : ".</span>"]")
			else
				to_chat(user, "<span class='notice'>Subject contains no reagents.</span>")
			if(M.reagents.addiction_list.len)
				to_chat(user, "<span class='boldannounce'>Subject is addicted to the following reagents:</span>")
				for(var/datum/reagent/R in M.reagents.addiction_list)
					to_chat(user, "<span class='danger'>[R.name]</span>")
			else
				to_chat(user, "<span class='notice'>Subject is not addicted to any reagents.</span>")

/obj/item/device/healthanalyzer/verb/toggle_mode()
	set name = "Switch Verbosity"
	set category = "Object"

	if(usr.stat || !usr.canmove || usr.restrained())
		return

	mode = !mode
	switch (mode)
		if(1)
			to_chat(usr, "The scanner now shows specific limb damage.")
		if(0)
			to_chat(usr, "The scanner no longer shows limb damage.")

/obj/item/device/healthanalyzer/advanced
	name = "advanced health analyzer"
	icon_state = "health_adv"
	desc = "A hand-held body scanner able to distinguish vital signs of the subject with high accuracy."
	advanced = TRUE

/obj/item/device/analyzer
	desc = "A hand-held environmental scanner which reports current gas levels."
	name = "analyzer"
	icon_state = "atmos"
	item_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	flags_1 = CONDUCT_1 | NOBLUDGEON_1
	slot_flags = SLOT_BELT
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	materials = list(MAT_METAL=30, MAT_GLASS=20)

/obj/item/device/analyzer/attack_self(mob/user)

	add_fingerprint(user)

	if (user.stat || user.eye_blind)
		return

	var/turf/location = user.loc
	if(!istype(location))
		return

	var/datum/gas_mixture/environment = location.return_air()

	var/pressure = environment.return_pressure()
	var/volume = environment.return_volume()
	var/total_moles = environment.total_moles()

	to_chat(user, "<span class='info'><B>Results:</B></span>")
	to_chat(user, "<span class='notice'>Local volume: [round(volume,0.01)] liters</span>")
	if(abs(pressure - ONE_ATMOSPHERE) < 10)
		to_chat(user, "<span class='info'>Pressure: [round(pressure,0.1)] kPa</span>")
	else
		to_chat(user, "<span class='alert'>Pressure: [round(pressure,0.1)] kPa</span>")
	if(total_moles)
		var/list/env_gases = environment.gases

		environment.assert_gases(arglist(GLOB.hardcoded_gases))
		var/o2_concentration = env_gases[/datum/gas/oxygen][MOLES]/total_moles
		var/n2_concentration = env_gases[/datum/gas/nitrogen][MOLES]/total_moles
		var/co2_concentration = env_gases[/datum/gas/carbon_dioxide][MOLES]/total_moles
		var/plasma_concentration = env_gases[/datum/gas/plasma][MOLES]/total_moles
		environment.garbage_collect()

		if(abs(n2_concentration - N2STANDARD) < 20)
			to_chat(user, "<span class='info'>Nitrogen: [round(n2_concentration*100, 0.01)] %</span>")
		else
			to_chat(user, "<span class='alert'>Nitrogen: [round(n2_concentration*100, 0.01)] %</span>")

		if(abs(o2_concentration - O2STANDARD) < 2)
			to_chat(user, "<span class='info'>Oxygen: [round(o2_concentration*100, 0.01)] %</span>")
		else
			to_chat(user, "<span class='alert'>Oxygen: [round(o2_concentration*100, 0.01)] %</span>")

		if(co2_concentration > 0.01)
			to_chat(user, "<span class='alert'>CO2: [round(co2_concentration*100, 0.01)] %</span>")
		else
			to_chat(user, "<span class='info'>CO2: [round(co2_concentration*100, 0.01)] %</span>")

		if(plasma_concentration > 0.005)
			to_chat(user, "<span class='alert'>Plasma: [round(plasma_concentration*100, 0.01)] %</span>")
		else
			to_chat(user, "<span class='info'>Plasma: [round(plasma_concentration*100, 0.01)] %</span>")


		for(var/id in env_gases)
			if(id in GLOB.hardcoded_gases)
				continue
			var/gas_concentration = env_gases[id][MOLES]/total_moles
			to_chat(user, "<span class='alert'>[env_gases[id][GAS_META][META_GAS_NAME]]: [round(gas_concentration*100, 0.01)] %</span>")
		to_chat(user, "<span class='info'>Temperature: [round(environment.temperature-T0C)] &deg;C</span>")


/obj/item/device/mass_spectrometer
	desc = "A hand-held mass spectrometer which identifies trace chemicals in a blood sample."
	name = "mass-spectrometer"
	icon_state = "spectrometer"
	item_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	flags_1 = CONDUCT_1
	slot_flags = SLOT_BELT
	container_type = OPENCONTAINER_1
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	materials = list(MAT_METAL=150, MAT_GLASS=100)
	var/details = 0

/obj/item/device/mass_spectrometer/New()
	..()
	create_reagents(5)

/obj/item/device/mass_spectrometer/on_reagent_change(changetype)
	if(reagents.total_volume)
		icon_state = initial(icon_state) + "_s"
	else
		icon_state = initial(icon_state)

/obj/item/device/mass_spectrometer/attack_self(mob/user)
	if (user.stat || user.eye_blind)
		return
	if (!user.IsAdvancedToolUser())
		to_chat(user, "<span class='warning'>You don't have the dexterity to do this!</span>")
		return
	if(reagents.total_volume)
		var/list/blood_traces = list()
		for(var/datum/reagent/R in reagents.reagent_list)
			if(R.id != "blood")
				reagents.clear_reagents()
				to_chat(user, "<span class='warning'>The sample was contaminated! Please insert another sample.</span>")
				return
			else
				blood_traces = params2list(R.data["trace_chem"])
				break
		var/dat = "<i><b>Trace Chemicals Found:</b>"
		if(!blood_traces.len)
			dat += "<br>None"
		else
			for(var/R in blood_traces)
				dat += "<br>[GLOB.chemical_reagents_list[R]]"
				if(details)
					dat += " ([blood_traces[R]] units)"
		dat += "</i>"
		to_chat(user, dat)
		reagents.clear_reagents()


/obj/item/device/mass_spectrometer/adv
	name = "advanced mass-spectrometer"
	icon_state = "adv_spectrometer"
	details = 1

/obj/item/device/slime_scanner
	name = "slime scanner"
	desc = "A device that analyzes a slime's internal composition and measures its stats."
	icon_state = "adv_spectrometer"
	item_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	flags_1 = CONDUCT_1
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	materials = list(MAT_METAL=30, MAT_GLASS=20)

/obj/item/device/slime_scanner/attack(mob/living/M, mob/living/user)
	if(user.stat || user.eye_blind)
		return
	if (!isslime(M))
		to_chat(user, "<span class='warning'>This device can only scan slimes!</span>")
		return
	var/mob/living/simple_animal/slime/T = M
	to_chat(user, "Slime scan results:")
	to_chat(user, "[T.colour] [T.is_adult ? "adult" : "baby"] slime")
	to_chat(user, "Nutrition: [T.nutrition]/[T.get_max_nutrition()]")
	if (T.nutrition < T.get_starve_nutrition())
		to_chat(user, "<span class='warning'>Warning: slime is starving!</span>")
	else if (T.nutrition < T.get_hunger_nutrition())
		to_chat(user, "<span class='warning'>Warning: slime is hungry</span>")
	to_chat(user, "Electric change strength: [T.powerlevel]")
	to_chat(user, "Health: [round(T.health/T.maxHealth,0.01)*100]")
	if (T.slime_mutation[4] == T.colour)
		to_chat(user, "This slime does not evolve any further.")
	else
		if (T.slime_mutation[3] == T.slime_mutation[4])
			if (T.slime_mutation[2] == T.slime_mutation[1])
				to_chat(user, "Possible mutation: [T.slime_mutation[3]]")
				to_chat(user, "Genetic destability: [T.mutation_chance/2] % chance of mutation on splitting")
			else
				to_chat(user, "Possible mutations: [T.slime_mutation[1]], [T.slime_mutation[2]], [T.slime_mutation[3]] (x2)")
				to_chat(user, "Genetic destability: [T.mutation_chance] % chance of mutation on splitting")
		else
			to_chat(user, "Possible mutations: [T.slime_mutation[1]], [T.slime_mutation[2]], [T.slime_mutation[3]], [T.slime_mutation[4]]")
			to_chat(user, "Genetic destability: [T.mutation_chance] % chance of mutation on splitting")
	if (T.cores > 1)
		to_chat(user, "Anomalious slime core amount detected")
	to_chat(user, "Growth progress: [T.amount_grown]/[SLIME_EVOLUTION_THRESHOLD]")
