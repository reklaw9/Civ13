#define NO_WINNER "Neither side has captured the other side's base."

var/global/obj/map_metadata/map = null
//Max levels showing players how far to advance, appears on the Character tab
var/civmax_research = list(130,130,130)

/obj/map_metadata
	name = ""
	icon = 'icons/mob/screen/1713Style.dmi'
	icon_state = "x2"
	anchored = TRUE
	simulated = FALSE
	invisibility = 101
	var/ID = null // MUST be text, or aspects will break
	var/title = null
	var/lobby_icon_state = "1"
	var/list/caribbean_blocking_area_types = list()
	var/list/allow_bullets_through_blocks = list()
	var/last_crossing_block_status[3]
	var/admin_ended_all_grace_periods = FALSE
	var/event_faction = null
	var/min_autobalance_players = 0
	var/respawn_delay = 3000
	var/list/valid_weather_types = list(WEATHER_RAIN, WEATHER_SNOW, WEATHER_SANDSTORM, WEATHER_BLIZZARD, WEATHER_NONE, WEATHER_STORM)
	var/squad_spawn_locations = TRUE
	var/availablefactions_run = FALSE
	var/list/availablefactions = list("Red Goose Tribesman")

//faction stuff
	var/faction1 = BRITISH
	var/faction2 = PIRATES
	var/no_subfaction_chance = TRUE
	var/subfaction_is_main_faction = FALSE
	var/list/faction_organization = list()
	var/list/initial_faction_organization = list()
	var/list/faction_distribution_coeffs = list(INFINITY) // list(INFINITY) = no hard locks on factions
	var/list/available_subfactions = list()
	var/list/roundend_condition_sides = list(
		list(PIRATES) = /area/caribbean/pirates,
		list(BRITISH) = /area/caribbean/british)
	var/list/ambience = list('sound/ambience/ship1.ogg')
	var/list/songs = list(
		"Fish in the Sea:1" = 'sound/music/shanties/fish_in_the_sea.ogg',
		"Spanish Ladies:1" = 'sound/music/shanties/spanish_ladies.ogg',
		"Irish Rovers:1" = 'sound/music/shanties/irish_rovers.ogg')
	var/mission_start_message = "Round will start soon!"

	var/required_players = 1
	var/time_both_sides_locked = -1
	var/time_to_end_round_after_both_sides_locked = 6000
	var/admins_triggered_roundend = FALSE
	var/admins_triggered_noroundend = FALSE

	// win conditions 3.0 - Kachnov
	var/datum/win_condition/win_condition = null
	var/current_win_condition = NO_WINNER
	var/last_win_condition = null // this is a hash
	var/current_winner = null
	var/current_loser = null
	var/next_win = -1
	var/win_condition_spam_check = FALSE

	// lighting
	var/list/times_of_day = list("Early Morning", "Morning", "Midday", "Afternoon", "Evening", "Night")
	var/list/zlevels_without_lighting = list()
	var/list/areas_without_lighting = list()

	// fluff
	var/meme = FALSE
	var/battle_name = null

	//age (313 B.C., 1013, 1713, etc)
	var/age = "1713"
	var/ordinal_age = 3

	//weather
	var/blizzard = FALSE
	var/heat_wave = FALSE
	var/sandstorm = FALSE
	var/triggered_heatwave = FALSE
	var/triggered_blizzard = FALSE
	var/triggered_sandstorm = FALSE
	//civ stuff
	var/civilizations = FALSE
	var/nomads = FALSE
	var/list/custom_faction_nr = list()
	var/list/custom_civs = list()
	//1st value: industrial (crafting, philosophy) 2nd value: military (gunpowder, fencing, archery), 3rd value: health (anatomy, medical)
	var/civa_research = list(0,0,0,null)
	var/civb_research = list(0,0,0,null)
	var/civc_research = list(0,0,0,null)
	var/civd_research = list(0,0,0,null)
	var/cive_research = list(0,0,0,null)
	var/civf_research = list(0,0,0,null)

	var/chad_mode = FALSE //Virgins BTFO
	var/gamemode = "Team Deathmatch"
	var/research_active = FALSE //if research can be done
	var/default_research = 0 //the starting research level

	//autoresearch
	var/autoresearch = FALSE //if autoresearch is active
	var/autoresearch_mult = 0.4 // the amount research goes up per minute. Can be edited by admins.
	var/resourceresearch = FALSE
	var/age1_lim = 75
	var/age1_done = 0
	var/age1_top = 35
	var/age2_lim = 150
	var/age2_done = 0
	var/age2_timer = 40000
	var/age2_top = 65
	var/age3_lim = 240
	var/age3_done = 0
	var/age3_timer = 42000
	var/age3_top = 85
	var/age4_lim = 315
	var/age4_done = 0
	var/age4_timer = 44000
	var/age4_top = 120
	var/age5_lim = 360
	var/age5_done = 0
	var/age5_timer = 46000
	var/age5_top = 140

/obj/map_metadata/New()
	..()
	map = src
	icon = null
	icon_state = null

	initial_faction_organization = faction_organization.Copy()

	// get a subfaction, just one, for this round
	var/subfaction = null
	for (var/faction in available_subfactions)
		if (prob(available_subfactions[faction]))
			subfaction = faction
			break

	if (!no_subfaction_chance && available_subfactions.len)
		subfaction = pick(available_subfactions)

	qdel_list(available_subfactions)
	available_subfactions = list()

	if (subfaction)
		available_subfactions += subfaction

	// makes win condition helper datum
	win_condition = new
	set_ordinal_age()

/obj/map_metadata/proc/set_ordinal_age()
	if (age == "5000 B.C.")
		ordinal_age = 0
	else if (age == "313 B.C.")
		ordinal_age = 1
	else if (age == "1013")
		ordinal_age = 2
	else if (age == "1713")
		ordinal_age = 3
	else if (age == "1873")
		ordinal_age = 4
	else if (age == "1903")
		ordinal_age = 5
	return


/obj/map_metadata/proc/autoresearch_proc()
	if (autoresearch == TRUE && default_research < 130)
		spawn(600) //1 minute = 0.4 points (by default)
			default_research += autoresearch_mult
			if (map.ID == MAP_CIVILIZATIONS)
				civa_research = list(default_research,default_research,default_research,null)
				civb_research = list(default_research,default_research,default_research,null)
				civc_research = list(default_research,default_research,default_research,null)
				civd_research = list(default_research,default_research,default_research,null)
				cive_research = list(default_research,default_research,default_research,null)
				civf_research = list(default_research,default_research,default_research,null)
			else
				for(var/i = 1, i <= map.custom_civs.len, i++)
					var/key = map.custom_civs[i]
					map.custom_civs[key][1] = default_research
					map.custom_civs[key][2] = default_research
					map.custom_civs[key][3] = default_research
			autoresearch_proc()
// called from the map process
/obj/map_metadata/proc/tick()

	if (last_crossing_block_status[faction1] == FALSE)
		if (faction1_can_cross_blocks())
			world << cross_message(faction1)

	else if (last_crossing_block_status[faction1] == TRUE)
		if (!faction1_can_cross_blocks())
			world << reverse_cross_message(faction1)


	if (last_crossing_block_status[faction2] == FALSE)
		if (faction2_can_cross_blocks())
			world << cross_message(faction2)

	else if (last_crossing_block_status[faction2] == TRUE)
		if (!faction2_can_cross_blocks())
			world << reverse_cross_message(faction2)

	if (last_crossing_block_status[event_faction] == FALSE)
		if (specialfaction_can_cross_blocks())
			world << cross_message(event_faction)
	else if (last_crossing_block_status[event_faction] == TRUE)
		if (!specialfaction_can_cross_blocks())
			world << reverse_cross_message(event_faction)

	last_crossing_block_status[faction2] = faction2_can_cross_blocks()
	last_crossing_block_status[faction1] = faction1_can_cross_blocks()


	if (event_faction)
		last_crossing_block_status[event_faction] = specialfaction_can_cross_blocks()

	update_win_condition()
	check_events()
	if (nomads)
		if (age1_done == FALSE)
			var/count = 0
			for(var/i = 1, i <= custom_faction_nr.len, i++)
				count = custom_civs[custom_faction_nr[i]][1]+custom_civs[custom_faction_nr[i]][2]+custom_civs[custom_faction_nr[i]][3]
				if (count > age1_lim && world.time > 36000)
					world << "<big>The world has advanced into the Bronze Age!</big>"
					age = "313 B.C."
					set_ordinal_age()
					age1_done = TRUE
					age2_timer = (world.time + age2_timer)
					default_research = 25
					break

		else if (age2_done == FALSE)
			var/count = 0
			for(var/i = 1, i <= custom_faction_nr.len, i++)
				count = custom_civs[custom_faction_nr[i]][1]+custom_civs[custom_faction_nr[i]][2]+custom_civs[custom_faction_nr[i]][3]
				if (count > age2_lim && world.time >= age2_timer)
					world << "<big>The world has advanced into the Medieval Age!</big>"
					age = "1013"
					set_ordinal_age()
					age2_done = TRUE
					age3_timer = (world.time + age3_timer)
					default_research = 50
					break

		else if (age3_done == FALSE)
			var/count = 0
			for(var/i = 1, i <= custom_faction_nr.len, i++)
				count = custom_civs[custom_faction_nr[i]][1]+custom_civs[custom_faction_nr[i]][2]+custom_civs[custom_faction_nr[i]][3]
				if (count > age3_lim && world.time >= age3_timer)
					world << "<big>The world has advanced into the Imperial Age!</big>"
					age = "1713"
					set_ordinal_age()
					age3_done = TRUE
					default_research = 80
					break

		else if (age4_done == FALSE)
			var/count = 0
			for(var/i = 1, i <= custom_faction_nr.len, i++)
				count = custom_civs[custom_faction_nr[i]][1]+custom_civs[custom_faction_nr[i]][2]+custom_civs[custom_faction_nr[i]][3]
				if (count > age4_lim && world.time >= age4_timer)
					world << "<big>The world has advanced into the Industrial Age!</big>"
					age = "1873"
					set_ordinal_age()
					age4_done = TRUE
					default_research = 105
					break
		else if (age5_done == FALSE)
			var/count = 0
			for(var/i = 1, i <= custom_faction_nr.len, i++)
				count = custom_civs[custom_faction_nr[i]][1]+custom_civs[custom_faction_nr[i]][2]+custom_civs[custom_faction_nr[i]][3]
				if (count > age5_lim && world.time >= age5_timer)
					world << "<big>The world has advanced into the Early Modern Age!</big>"
					age = "1903"
					set_ordinal_age()
					age5_done = TRUE
					default_research = 120
					break
/obj/map_metadata/proc/check_events()
	return TRUE

/obj/map_metadata/proc/check_caribbean_block(var/mob/living/carbon/human/H, var/turf/T)
	if (!istype(H) || !istype(T))
		return FALSE
	var/area/A = get_area(T)
	if (caribbean_blocking_area_types.Find(A.type))
		if (!H.original_job)
			return FALSE
		else
			switch (H.original_job.base_type_flag())
				if (BRITISH, PORTUGUESE, FRENCH, SPANISH, DUTCH, ROMAN, JAPANESE, RUSSIAN)
					return !faction1_can_cross_blocks()
				if (PIRATES, INDIANS, CIVILIAN, GREEK, ARAB)
					return !faction2_can_cross_blocks()
	return FALSE

/obj/map_metadata/proc/faction1_can_cross_blocks()
	return TRUE

/obj/map_metadata/proc/faction2_can_cross_blocks()
	return TRUE

/obj/map_metadata/proc/specialfaction_can_cross_blocks()
	return TRUE

/obj/map_metadata/proc/game_really_started()
	return (faction1_can_cross_blocks() && faction2_can_cross_blocks())

/obj/map_metadata/proc/job_enabled_specialcheck(var/datum/job/J)
	if (age == "1013" && !civilizations)
		if (J.is_medieval == TRUE)
			. = TRUE
		else
			. = FALSE
	else
		if (J.is_medieval == FALSE)
			. = TRUE
		else
			. = FALSE
	if (civilizations)
		if (J.is_civilizations == TRUE)
			. = TRUE
		else
			. = FALSE
	else if (!civilizations)
		if (J.is_civilizations == FALSE)
			. = TRUE
		else
			. = FALSE
	if (J.is_nomad == TRUE)
		. = FALSE
/obj/map_metadata/proc/cross_message(faction)
	return "<font size = 4>The [faction_const2name(faction)] may now cross the invisible wall!</font>"

/obj/map_metadata/proc/reverse_cross_message(faction)
	return "<span class = 'userdanger'>The [faction_const2name(faction)] may no longer cross the invisible wall!</span>"


// old game mode stuff
/obj/map_metadata/proc/can_start()

	var/playercount = 0
	var/only_client_is_host = FALSE
	for (var/mob/new_player/player in new_player_mob_list)
		if (player.client)
			if (!player.client.is_minimized())
				++playercount
			if (player && player.key == world.host) // client.is_minimized() takes a while, so the player may not still exist
				only_client_is_host = TRUE

	if (playercount >= required_players || only_client_is_host)
		world << mission_start_message
		return TRUE

	return FALSE

/obj/map_metadata/proc/update_win_condition()
	if (!win_condition_specialcheck())
		return FALSE
	if (world.time >= next_win && next_win != -1)
		if (win_condition_spam_check)
			return FALSE
		ticker.finished = TRUE
		var/message = ""
		if (!map.civilizations)
			message = "The [battle_name ? battle_name : "battle"] has ended in a stalemate!"
		else
			message = "The round has ended!"
		if (current_winner && current_loser)
			message = "The battle is over! The [current_winner] was victorious over the [current_loser][battle_name ? " in the [battle_name]" : ""]!"
		world << "<font size = 4><span class = 'notice'>[message]</span></font>"
		win_condition_spam_check = TRUE
		return FALSE
	// German major
	else if (roundend_condition_sides.len > 1)
		if (win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[2]]), roundend_condition_sides[1], roundend_condition_sides[2], 1.33, TRUE))
			if (!win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[1]]), roundend_condition_sides[2], roundend_condition_sides[1], 1.33))
				if (last_win_condition != win_condition.hash)
					current_win_condition = "The [roundend_condition_def2army(roundend_condition_sides[1][1])] has captured the [roundend_condition_def2name(roundend_condition_sides[2][1])] base! They will win in {time} minute{s}."
					next_win = world.time + short_win_time(roundend_condition_sides[2][1])
					announce_current_win_condition()
					current_winner = roundend_condition_def2army(roundend_condition_sides[1][1])
					current_loser = roundend_condition_def2army(roundend_condition_sides[2][1])
		// German minor
		else if (win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[2]]), roundend_condition_sides[1], roundend_condition_sides[2], 1.01, TRUE))
			if (!win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[1]]), roundend_condition_sides[2], roundend_condition_sides[1], 1.01))
				if (last_win_condition != win_condition.hash)
					current_win_condition = "The [roundend_condition_def2army(roundend_condition_sides[1][1])] has captured the [roundend_condition_def2name(roundend_condition_sides[2][1])] base! They will win in {time} minute{s}."
					next_win = world.time + long_win_time(roundend_condition_sides[2][1])
					announce_current_win_condition()
					current_winner = roundend_condition_def2army(roundend_condition_sides[1][1])
					current_loser = roundend_condition_def2army(roundend_condition_sides[2][1])
		// Soviet major
		else if (win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[1]]), roundend_condition_sides[2], roundend_condition_sides[1], 1.33, TRUE))
			if (!win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[2]]), roundend_condition_sides[1], roundend_condition_sides[2], 1.33))
				if (last_win_condition != win_condition.hash)
					current_win_condition = "The [roundend_condition_def2army(roundend_condition_sides[2][1])] has captured the [roundend_condition_def2name(roundend_condition_sides[1][1])] base! They will win in {time} minute{s}."
					next_win = world.time + short_win_time(roundend_condition_sides[1][1])
					announce_current_win_condition()
					current_winner = roundend_condition_def2army(roundend_condition_sides[2][1])
					current_loser = roundend_condition_def2army(roundend_condition_sides[1][1])
		// Soviet minor
		else if (win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[1]]), roundend_condition_sides[2], roundend_condition_sides[1], 1.01, TRUE))
			if (!win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[2]]), roundend_condition_sides[1], roundend_condition_sides[2], 1.01))
				if (last_win_condition != win_condition.hash)
					current_win_condition = "The [roundend_condition_def2army(roundend_condition_sides[2][1])] has captured the [roundend_condition_def2name(roundend_condition_sides[1][1])] base! They will win in {time} minute{s}."
					next_win = world.time + long_win_time(roundend_condition_sides[1][1])
					announce_current_win_condition()
					current_winner = roundend_condition_def2army(roundend_condition_sides[2][1])
					current_loser = roundend_condition_def2army(roundend_condition_sides[1][1])

	else
		if (current_win_condition != NO_WINNER && current_winner && current_loser)
			world << "<font size = 3>The [current_winner] has lost control of the [army2name(current_loser)] base!</font>"
			current_winner = null
			current_loser = null
		next_win = -1
		current_win_condition = NO_WINNER
		win_condition.hash = 0
	last_win_condition = win_condition.hash
	return TRUE

/obj/map_metadata/proc/has_occupied_base(side)

	// hack
	if (current_win_condition == NO_WINNER)
		return FALSE

	var/list/soldiers = list(
		CIVILIAN = 0,
		BRITISH = 0,
		PORTUGUESE = 0,
		SPANISH = 0,
		FRENCH = 0,
		INDIANS = 0,
		PIRATES = 0,
		DUTCH = 0,
		ROMAN = 0,
		GREEK = 0,
		ARAB = 0,
		JAPANESE = 0,
		RUSSIAN = 0,)

	if (!(side in soldiers))
		soldiers[side] = 0

	var/s1 = 0
	var/s2 = 0

	for (var/mob/living/carbon/human/H in human_mob_list)

		var/datum/job/job = H.original_job

		if (!job)
			continue

		if (H.stat != DEAD && H.stat != UNCONSCIOUS && !H.restrained() && ((H.weakened+H.stunned) == 0) && H.client)
			if (job.base_type_flag() in soldiers)
				var/H_area = get_area(H)
				if (job.base_type_flag() in roundend_condition_sides[1])
					if (istype(H_area, roundend_condition_sides[roundend_condition_sides[2]]))
						++s1
				else if (job.base_type_flag() in roundend_condition_sides[2])
					if (istype(H_area, roundend_condition_sides[roundend_condition_sides[1]]))
						++s2
			else
				var/M = "WARNING: could not find '[job.base_type_flag()]' in local list soldiers in proc '/obj/map/proc/has_occupied_base()'. Please contact a coder."
				log_admin(M)
				message_admins(M)
				log_debug(M)

	if (side in roundend_condition_sides[1])
		return s2 > s1
	else if (side in roundend_condition_sides[2])
		return s1 > s2

	return FALSE

/obj/map_metadata/proc/next_win_time()
	return round((next_win - world.time)/600)

/obj/map_metadata/proc/current_stat_message()
	var/next_win_time = max(0, next_win_time())
	. = current_win_condition
	. = replacetext(., "{time}", next_win_time)
	if (next_win_time == 1)
		. = replacetext(., "{s}", "")
	else
		. = replacetext(., "{s}", "s")
	return .

/obj/map_metadata/proc/announce_current_win_condition()
	world << "<font size = 3>[current_stat_message()]</font>"

/obj/map_metadata/proc/short_win_time(faction)
	if (!(alive_n_of_side(faction1)) || !(alive_n_of_side(faction2)))
		return 600
	else
		if (clients.len >= 20)
			return 3000 // 5 minutes
		else
			return 1200 // 2 minutes

/obj/map_metadata/proc/long_win_time(faction)
	if (!(alive_n_of_side(faction1)) || !(alive_n_of_side(faction2)))
		return 600
	else
		if (clients.len >= 20)
			return 4200 // 7 minutes
		else
			return 2400 // 4 minutes

/obj/map_metadata/proc/win_condition_specialcheck()
	return TRUE

/obj/map_metadata/proc/roundend_condition_def2name(define)
	switch (define)
		if (BRITISH)
			return "British"
		if (PIRATES)
			return "Pirate"
		if (CIVILIAN)
			return "Colonist"
		if (INDIANS)
			return "Native"
		if (FRENCH)
			return "French"
		if (PORTUGUESE)
			return "Portuguese"
		if (SPANISH)
			return "Spanish"
		if (DUTCH)
			return "Dutch"
		if (ROMAN)
			return "Roman"
		if (GREEK)
			return "Greek"
		if (ARAB)
			return "Arab"
		if (JAPANESE)
			return "Japanese"
		if (RUSSIAN)
			return "Russian"
/obj/map_metadata/proc/roundend_condition_def2army(define)
	switch (define)
		if (BRITISH)
			return "British Empire"
		if (PIRATES)
			return "Pirate crew"
		if (CIVILIAN)
			return "Colonists"
		if (INDIANS)
			return "Native Tribe"
		if (FRENCH)
			return "French Empire"
		if (PORTUGUESE)
			return "Portuguese Empire"
		if (SPANISH)
			return "Spanish Empire"
		if (DUTCH)
			return "Dutch Republic"
		if (ROMAN)
			return "Roman Republic"
		if (GREEK)
			return "Greek States"
		if (ARAB)
			return "Arabic Caliphate"
		if (JAPANESE)
			return "Japanese Empire"
		if (RUSSIAN)
			return "Russian Empire"
/obj/map_metadata/proc/army2name(army)
	switch (army)
		if ("British Empire")
			return "British"
		if ("Pirate crew")
			return "Pirate"
		if ("Colonists")
			return "Colonist"
		if ("Native Tribe")
			return "Native"
		if ("French Empire")
			return "French"
		if ("Portuguese Empire")
			return "Portuguese"
		if ("Spanish Empire")
			return "Spanish"
		if ("Dutch Republic")
			return "Dutch"
		if ("Roman Republic")
			return "Roman"
		if ("Greek States")
			return "Greek"
		if ("Arabic Caliphate")
			return "Arab"
		if ("Japanese Empire")
			return "Japanese"
		if ("Russian Empire")
			return "Russian"
/obj/map_metadata/proc/special_relocate(var/mob/M)
	return FALSE

#undef NO_WINNER