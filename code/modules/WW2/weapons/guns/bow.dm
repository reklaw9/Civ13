/obj/item/weapon/gun/projectile/bow
	name = "bow"
	desc = "A simple and crude bow. Outdated but faster than muskets."
	icon_state = "bow"
	item_state = "bow"
	w_class = 4
	throw_range = 5
	throw_speed = 5
	force = 6
	throwforce = 6
	max_shells = 1 //duh
	slot_flags = SLOT_BACK
	caliber = "arrow"
	recoil = 0 //no shaking
	fire_sound = 'sound/weapons/arrow_fly.ogg'
	handle_casings = HOLD_CASINGS
	load_method = SINGLE_CASING
	ammo_type = /obj/item/ammo_casing/arrow
//	magazine_type = /obj/item/ammo_magazine/musketball
	load_shell_sound = 'sound/weapons/pull_bow.ogg'
	bulletinsert_sound = 'sound/weapons/pull_bow.ogg'
	//+2 accuracy over the LWAP because only one shot
	accuracy = TRUE
//	scoped_accuracy = 2
	gun_type = GUN_TYPE_BOW
	attachment_slots = null
	accuracy_increase_mod = 3.00
	accuracy_decrease_mod = 7.00
	KD_chance = KD_CHANCE_HIGH
	stat = "rifle"
	move_delay = 5
	fire_delay = 5
	muzzle_flash = FALSE
	value = 18

	accuracy_list = list(

		// small body parts: head, hand, feet
		"small" = list(
			SHORT_RANGE_STILL = 90,
			SHORT_RANGE_MOVING = 55,

			MEDIUM_RANGE_STILL = 80,
			MEDIUM_RANGE_MOVING = 40,

			LONG_RANGE_STILL = 63,
			LONG_RANGE_MOVING = 32,

			VERY_LONG_RANGE_STILL = 50,
			VERY_LONG_RANGE_MOVING = 25),

		// medium body parts: limbs
		"medium" = list(
			SHORT_RANGE_STILL = 95,
			SHORT_RANGE_MOVING = 50,

			MEDIUM_RANGE_STILL = 79,
			MEDIUM_RANGE_MOVING = 39,

			LONG_RANGE_STILL = 68,
			LONG_RANGE_MOVING = 34,

			VERY_LONG_RANGE_STILL = 58,
			VERY_LONG_RANGE_MOVING = 29),

		// large body parts: chest, groin
		"large" = list(
			SHORT_RANGE_STILL = 99,
			SHORT_RANGE_MOVING = 54,

			MEDIUM_RANGE_STILL = 83,
			MEDIUM_RANGE_MOVING = 42,

			LONG_RANGE_STILL = 73,
			LONG_RANGE_MOVING = 37,

			VERY_LONG_RANGE_STILL = 63,
			VERY_LONG_RANGE_MOVING = 32),
	)

	load_delay = 30
	aim_miss_chance_divider = 3.00

/obj/item/weapon/gun/projectile/bow/New()
	..()
	loaded = list()
	chambered = null

/obj/item/weapon/gun/projectile/bow/handle_post_fire()
	..()
	loaded -= chambered
	chambered = null

/obj/item/weapon/gun/projectile/bow/load_ammo(var/obj/item/A, mob/user)
	if (world.time < user.next_load)
		return

	if (load_delay && !do_after(user, load_delay, src, can_move = TRUE))
		return

	user.next_load = world.time + 1
	if (istype(A, /obj/item/ammo_casing))
		var/obj/item/ammo_casing/C = A
		if (caliber != C.caliber)
			return //incompatible
		if (loaded.len >= max_shells)
			user << "<span class='warning'>the [src] already has an arrow ready!</span>"
			return

		user.remove_from_mob(C)
		C.loc = src
		loaded.Insert(1, C) //add to the head of the list
		user.visible_message("[user] inserts \an [C] into the [src].", "<span class='notice'>You insert \an [C] into the [src].</span>")
		icon_state = "bow_loaded"
		if (bulletinsert_sound) playsound(loc, bulletinsert_sound, 75, TRUE)

/obj/item/weapon/gun/projectile/bow/unload_ammo(mob/user, var/allow_dump=1)
	if (ammo_magazine)
		user.put_in_hands(ammo_magazine)

		if (unload_sound) playsound(loc, unload_sound, 75, TRUE)
		ammo_magazine.update_icon()
		ammo_magazine = null
	else if (loaded.len)
		if (load_method & SINGLE_CASING)
			var/obj/item/ammo_casing/C = loaded[loaded.len]
			loaded.len--
			user.put_in_hands(C)
			user.visible_message("[user] removes \an [C] from the [src].", "<span class='notice'>You remove \an [C] from the [src].</span>")
			icon_state = "bow"
			if (bulletinsert_sound) playsound(loc, bulletinsert_sound, 75, TRUE)
	else
		user << "<span class='warning'>[src] is empty.</span>"
	update_icon()

/obj/item/weapon/gun/projectile/bow/update_icon()

	if (chambered)
		icon_state = "bow_loaded"
		return
	else
		icon_state = "bow"
		return

/obj/item/weapon/gun/projectile/bow/handle_click_empty(mob/user)
	if (user)
		user.visible_message("", "<span class='danger'>You don't have an arrow here!</span>")
	else
		visible_message("")
	return