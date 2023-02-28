extends Node

const ActionType = [
	"Movement", 
	"Attack", 
	"Special", 
	"Super", 
	"Defense", 
	"Hurt", 
]

const BusyInterrupt = [
	"Normal", 
	"Hurt", 
	"None", 
]

const AirType = [
	"Grounded", 
	"Aerial", 
	"Both"
]

const HitboxType = [
	"Normal", 
	"Flip", 
	"ThrowHit", 
	"OffensiveBurst", 
	"Burst", 
]

const HitHeight = [
	"High",
	"Mid",
	"Low"
]

func _init(modLoader = ModLoader):
	pass

func _ready():
	print("CSV export ready")
	var dir = Directory.new()
	if not dir.dir_exists("user://states"):
		dir.make_dir("user://states")
	var states = {}
	for fighter_name in Global.name_paths:
		states[fighter_name] = []
		var fighter = load(Global.name_paths[fighter_name]).instance()
		var action_cancels = {}
		for state in fighter.get_node("StateMachine").get_children():
			if state is CharacterState:
				for category in get_categories(state.interrupt_from_string):
					if not action_cancels.has(category):
						action_cancels[category] = []
					if not (state in action_cancels[category]):
						# print("Category check: %s" % category)
						# print(action_cancels[category])
						action_cancels[category].append(state)
		# print(action_cancels)
		# print("---")
		for category in action_cancels:
			for state in action_cancels[category]:
				if state.show_in_menu and not state in states[fighter_name]:
					states[fighter_name].append(state)

	for fighter in states:
		var action_export = "Internal Name,Action Title,Type,IASA At,Anim Length,Ending Stance,Endless,Air Type,Uses Air Movement,Land Cancel,Interrupt Frames,Throw Techable,Interruptible On Opponent Turn,Dynamic IASA,Backdash IASA,Next State On Hold,Combo Only,Neutral Only,Busy Interrupt Type,Burst Cancellable,Burstable,Self Hit Cancellable,Self Interruptable,Reversible,Instant Cancellable,Force Feint,Can Feint,Interruptable From,Interruptable Into,Hit Cancel Into,Interrupt Exceptions,Hit Cancel Exceptions,Allowed Stances,Realease Opponent On Startup,Release Opponent On Exit,Initiative Effect,Initiative Startup Reduction,Pushback,Beats Backdash,Can Be Counterhit\n"
		
		var hitbox_export = "Internal Name,Action Title,Hitbox Number,Damage,Damage In Combo,Minimum Damage,Start Tick,Active Ticks,Always On,Hitbox Type,Hitstun Ticks,Combo Hitstun Ticks,Hitlag Ticks,Victim Hitlag,Damage Proration,Cancellable,Increment Combo,Hits OTG,Hits Vs Grounded,Hits Vs Aerial,Can Counter Hit,DI Modifier,SDI Modifier,Parry Meter Gain,Ignore Armor,Followup State,Force Grounded,Can Clash,Hits Vs Dizzy,Hit Height,Knockback,Knockback Angle,Launch Reversible,Pushback X,Grounded Hit State,Aerial Hit State,Knockdown,Knockdown Extends Hitstun,Hard Knockdown,Disable Collision,Ground Bounce,Wall Slam,Looping,Loop Active Ticks,Loop Inactive Ticks\n"
		for state in states[fighter]:
			action_export += "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n"\
			% [state.name,state.title,ActionType[state.type],state.iasa_at,state.anim_length,state.change_stance_to,state.endless,AirType[state.air_type],state.uses_air_movement,state.land_cancel,
			get_interrupt_frames(state),state.throw_techable,state.interruptible_on_opponent_turn,state.dynamic_iasa,state.backdash_iasa,state.next_state_on_hold,
			state.combo_only,state.neutral_only,BusyInterrupt[state.busy_interrupt_type],state.burst_cancellable,state.burstable,state.self_hit_cancellable,state.self_interruptable,
			state.reversible,state.instant_cancellable,state.force_feintable,state.can_feint_if_possible,get_interruptable_from(state),get_interruptable_into(state),
			get_hit_cancel_into(state),get_interrupt_exceptions(state),get_hit_cancel_exceptions(state),get_allowed_stances(state),state.release_opponent_on_startup,
			state.release_opponent_on_exit,state.initiative_effect,state.initiative_startup_reduction,state.apply_pushback,state.beats_backdash,state.can_be_counterhit]
			var inc = 0
			for hitbox in get_hitboxes_from_state(state):
				inc += 1
				hitbox_export += "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n"\
				% [state.name,state.title,inc,hitbox.damage,hitbox.damage_in_combo,hitbox.minimum_damage,hitbox.start_tick,hitbox.active_ticks,hitbox.always_on,HitboxType[hitbox.hitbox_type],
				hitbox.hitstun_ticks,hitbox.combo_hitstun_ticks,hitbox.hitlag_ticks,hitbox.victim_hitlag,hitbox.damage_proration,hitbox.cancellable,hitbox.increment_combo,
				hitbox.hits_otg,hitbox.hits_vs_grounded,hitbox.hits_vs_aerial,hitbox.can_counter_hit,hitbox.di_modifier,hitbox.sdi_modifier,hitbox.parry_meter_gain,hitbox.ignore_armor,
				hitbox.followup_state,hitbox.force_grounded,hitbox.can_clash,hitbox.hits_vs_dizzy,hitbox.hit_height,hitbox.knockback,str(get_knockback_angle(hitbox))+"°",
				hitbox.launch_reversible,hitbox.pushback_x,hitbox.grounded_hit_state,hitbox.aerial_hit_state,hitbox.knockdown,hitbox.knockdown_extends_hitstun,hitbox.hard_knockdown,
				hitbox.disable_collision,hitbox.ground_bounce,hitbox.wall_slam,hitbox.looping,hitbox.loop_active_ticks,hitbox.loop_inactive_ticks]

		var file = File.new()
		file.open("user://states/%s.csv" % fighter, File.WRITE)
		file.store_string(action_export)
		file.close()
		file.open("user://states/%s-hitboxes.csv" % fighter, File.WRITE)
		file.store_string(hitbox_export)
		file.close()

func get_categories(string:String):
	if not string:
		return []
	var lines = []
	for s in string.split("\n"):
		var line = s.strip_edges()
		if line:
			lines.append(line)
	return lines

func get_interrupt_frames(state):
	var frames = []
	for frame in state.interrupt_frames:
		frames.append(frame)
	return " - ".join(frames)

func get_interruptable_from(state):
	var states = []
	for s in get_categories(state.interrupt_from_string):
		states.append(s)
	return " - ".join(states)

func get_interruptable_into(state):
	var states = []
	for s in get_categories(state.interrupt_into_string):
		states.append(s)
	return " - ".join(states)

func get_hit_cancel_into(state):
	var states = []
	for s in get_categories(state.hit_cancel_into_string):
		states.append(s)
	return " - ".join(states)

func get_interrupt_exceptions(state):
	var states = []
	for s in get_categories(state.interrupt_exceptions_string):
		states.append(s)
	return " - ".join(states)

func get_hit_cancel_exceptions(state):
	var states = []
	for s in get_categories(state.hit_cancel_exceptions_string):
		states.append(s)
	return " - ".join(states)

func get_allowed_stances(state):
	var stances = []
	for stance in get_categories(state.allowed_stances_string):
		stances.append(stance)
	return " - ".join(stances)

func get_hitboxes_from_state(state):
	var hitboxes = []
	for child in state.get_children():
		if child is Hitbox:
			hitboxes.append(child)
	hitboxes.sort_custom(self, "compare_hitboxes")
	return hitboxes

func compare_hitboxes(a, b):
	return a.start_tick < b.start_tick

func get_knockback_angle(hitbox):
	return rad2deg(atan2(-hitbox.knockback_y, hitbox.knockback_x))