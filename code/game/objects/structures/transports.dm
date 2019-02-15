/obj/structure/vehicle
	name = "vehicle"
	icon = 'icons/obj/vehicleparts.dmi'
	desc = "A vehicle."
	icon_state = "motorcycle"
	var/list/ontop = list()
	var/mob/living/carbon/human/driver = null
	var/lastmove = 0
	var/vehicle_m_delay = 20
	anchored = FALSE
	not_movable = FALSE
	not_disassemblable = FALSE
	flammable = FALSE
	can_buckle = TRUE
	buckle_lying = FALSE
	var/wheeled = FALSE
	var/obj/item/vehicleparts/wheel/dwheel = null
	var/moving = FALSE
	var/obj/structure/engine/internal/engine = null
	var/obj/structure/vehicleparts/axis/axis = null
	var/obj/item/weapon/reagent_containers/glass/barrel/fueltank/fueltank = null
/obj/structure/vehicle/proc/processmove(var/m_dir = null)
	if (!m_dir)
		return
	else
		if (do_vehicle_check() && lastmove+vehicle_m_delay <= world.time)
			do_move(m_dir)
			lastmove = world.time

/obj/structure/vehicle/proc/do_vehicle_check(var/m_dir = null) //check if the vehicle can move.
	return TRUE

/obj/structure/vehicle/proc/update_overlay() //for the vehicles that have overlays (i.e. motorcycles)
	return

/obj/structure/vehicle/proc/check_engine()
	return

/obj/structure/vehicle/proc/do_move(var/m_dir = null)
	for (var/mob/living/ML in ontop)
		ML.forceMove(get_step(src, m_dir))
	for (var/obj/O in ontop)
		O.forceMove(get_step(src, m_dir))
	forceMove(get_step(src, m_dir))
	update_icon()
	return

/obj/structure/vehicle/update_icon()
	if (driver)
		dir = driver.dir
		buckle_dir = dir
	..()
/obj/structure/vehicle/proc/running_sound()
	if (engine)
		if (engine.on)
			playsound(loc, 'sound/machines/diesel_loop.ogg', 65, FALSE)
			spawn(27)
				running_sound()
				return
////////MOVEMENT LOOP/////////
/obj/structure/vehicle/proc/startmovementloop()
	moving = TRUE
	movementloop()

/obj/structure/vehicle/proc/movementloop()
	if (moving == TRUE && driver)
		if (do_vehicle_check())
			do_move(driver.dir)
		spawn(vehicle_m_delay+1)
			movementloop()
			return
	else
		return

/obj/structure/vehicle/proc/stopmovementloop()
	moving = FALSE
	return

/obj/structure/vehicle/MouseDrop_T(mob/living/carbon/human/M, mob/living/carbon/human/user)
	if (M.anchored == FALSE && M.driver == FALSE && !(M in ontop))
		visible_message("<div class='notice'>[M] starts getting on \the [src]...</div>","<div class='notice'>You start going on \the [src]...</div>")
		if (do_after(M, 40, src))
			visible_message("<div class='notice'>[M] sucessfully climbs into \the [src].</div>","<div class='notice'>You sucessfully climb into \the [src].</div>")
			M.forceMove(get_turf(src))
			if (!driver)
				if (wheeled)
					if (M.put_in_active_hand(dwheel) == FALSE)
						M << "Your hands are full!"
						return

				M.driver = TRUE
				M.driver_vehicle = src
				driver = M
				buckle_mob(driver)
				ontop += M
			update_overlay()
			update_icon()
			return

/obj/structure/vehicle/attack_hand(mob/living/carbon/human/user as mob)
	if ((user in ontop))
		visible_message("<div class='notice'>[user] start leaving \the [src]...</div>","<div class='notice'>You start going on \the [src]...</div>")
		if (do_after(user, 30, src))
			visible_message("<div class='notice'>[user] sucessfully leaves \the [src].</div>","<div class='notice'>You leave \the [src].</div>")
			ontop -= user
			if (user == driver)
				user.driver = FALSE
				unbuckle_mob()
				user.driver_vehicle = null
				driver = null
				if (wheeled)
					if (user.l_hand == dwheel)
						user.l_hand = null
					else if (user.r_hand == dwheel)
						user.r_hand = null
					user.update_icons()
			update_overlay()
			update_icon()
			return

/obj/structure/vehicle/attackby(obj/item/weapon/W as obj, mob/living/carbon/human/user as mob)
	if (istype(W, /obj/item/vehicleparts/wheel))
		if ((user in ontop))
			if (user == driver && engine)
				if (engine.on)
					engine.on = FALSE
					engine.power_off_connections()
					engine.currentspeed = 0
					engine.currentpower = 0
					user << "You turn off the engine."
					playsound(loc, 'sound/machines/diesel_ending.ogg', 65, FALSE, 2)
					return

			visible_message("<div class='notice'>[user] start leaving \the [src]...</div>","<div class='notice'>You start going on \the [src]...</div>")
			if (do_after(user, 30, src))
				visible_message("<div class='notice'>[user] sucessfully leaves \the [src].</div>","<div class='notice'>You leave \the [src].</div>")
				ontop -= user
				if (user == driver)
					user.driver = FALSE
					unbuckle_mob()
					user.driver_vehicle = null
					driver = null
					if (wheeled)
						if (user.l_hand == dwheel)
							user.l_hand = null
						else if (user.r_hand == dwheel)
							user.r_hand = null
				update_overlay()
				update_icon()
				return
	else
		..()
///////////////////////////////////////////////////////
/obj/structure/vehicle/raft
	name = "raft"
	desc = "A simple wood raft. Can be used to cross water."
	icon = 'icons/obj/vehicleparts.dmi'
	icon_state = "raft"
	anchored = FALSE
	density = FALSE
	opacity = FALSE
	flammable = TRUE
	not_movable = TRUE
	not_disassemblable = FALSE

/obj/structure/vehicle/raft/do_vehicle_check(var/m_dir = null)
	if (istype(get_turf(get_step(src,m_dir)), /turf/floor/beach/water))
		if (driver in src.loc)
			return TRUE
		else
			driver.driver = FALSE
			driver.driver_vehicle = null
			driver << "You leave the [src]."
			unbuckle_mob()
			update_overlay()
			update_icon()
			ontop -= driver
			driver = null
	else
		return FALSE

///////////////////////////////////////////////////////
/obj/structure/vehicle/motorcycle
	name = "motorcycle"
	desc = "A motorcycle."
	icon = 'icons/obj/vehicleparts.dmi'
	icon_state = "motorcycle"
	anchored = FALSE
	density = TRUE
	opacity = FALSE
	flammable = FALSE
	not_movable = TRUE
	not_disassemblable = TRUE
	vehicle_m_delay = 3
	var/image/cover_overlay = null
	axis = new/obj/structure/vehicleparts/axis/bike
	wheeled = TRUE
	dwheel = new/obj/item/vehicleparts/wheel/handle
/obj/structure/vehicle/motorcycle/m125
	name = "125cc motorcycle"
	desc = "A 125cc, 4-stroke gasoline motorcycle."

/obj/structure/vehicle/motorcycle/m125/New()
	..()
	engine = new/obj/structure/engine/internal/gasoline
	spawn(1)
		engine.enginesize = 125
		engine.weight = 20*(engine.enginesize/1000)
		engine.name = "125cc gasoline engine"
		engine.maxpower *= (engine.enginesize/1000)
		engine.fuelefficiency *= (engine.enginesize/1000)
		spawn(1)
			engine.fueltank = fueltank
			engine.connections += axis

	fueltank = new/obj/item/weapon/reagent_containers/glass/barrel/fueltank/bike

/obj/structure/vehicle/motorcycle/New()
	..()
	//TODO: assign axis, fueltank, engine and connect them
	cover_overlay = image(icon, "[icon_state]_overlay")//"bike_cover")
	cover_overlay.layer = MOB_LAYER + 2.1

/obj/structure/vehicle/motorcycle/update_overlay()
	if (driver)
		add_overlay(cover_overlay)
		return
	else
		overlays -= cover_overlay
		return

/obj/structure/vehicle/motorcycle/do_vehicle_check(var/m_dir = null)
	if (check_engine())
		for(var/obj/O in get_turf(get_step(src,m_dir)))
			if (O.density == TRUE)
				moving = FALSE
				stopmovementloop()
				return FALSE
		if (!istype(get_turf(get_step(src,m_dir)), /turf/floor/beach/water/deep) && get_turf(get_step(src,m_dir)).density == FALSE)
			if (driver in src.loc)
				return TRUE
			else
				driver.driver = FALSE
				driver.driver_vehicle = null
				driver << "You leave the [src]."
				unbuckle_mob()
				update_overlay()
				update_icon()
				ontop -= driver
				driver = null
		else
			moving = FALSE
			stopmovementloop()
			return FALSE
	else
		moving = FALSE
		stopmovementloop()
		return FALSE

/obj/structure/vehicle/motorcycle/check_engine()
//TODO: add fuel consumption

	if (!engine || !fueltank)
		return FALSE
	else
		if (fueltank.reagents.total_volume <= 0)
			fueltank.reagents.total_volume = 0
			return FALSE
		else
			if (engine.on)
				return TRUE
			else
				return FALSE
		return FALSE

	return TRUE

/obj/structure/vehicle/motorcycle/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if (istype(W, /obj/item/weapon/reagent_containers/glass))
		var/obj/item/weapon/reagent_containers/glass/GC = W
		if (fueltank.reagents.total_volume < fueltank.reagents.maximum_volume)
			if (GC.reagents.has_reagent("gasoline"))
				if (GC.reagents.get_reagent_amount("gasoline")<= fueltank.reagents.maximum_volume-fueltank.reagents.total_volume)
					fueltank.reagents.add_reagent("gasoline",GC.reagents.get_reagent_amount("gasoline"))
					GC.reagents.del_reagent("gasoline")
					user << "You empty \the [W] into the fueltank."
					return
				else
					var/amttransf = fueltank.reagents.maximum_volume-fueltank.reagents.total_volume
					fueltank.reagents.add_reagent("gasoline",amttransf)
					GC.reagents.remove_reagent("gasoline",amttransf)
					user << "You fill the fueltank completly with \the [W]."
					return
			else
				user << "\The [W] has no gasoline in it."
				return
		else
			user << "The fueltank is full already."
			return
	else
		..()