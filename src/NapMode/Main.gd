extends Node

# Nap Mode, built on Metro Mod Loader hooks.
# Hooks rewrite the vanilla scripts themselves, so they also reach beds that
# Database.gd preloads at startup (take_over_path can't).

const Nap = preload("res://NapMode/Nap.gd")
const HOLD_TIME = 0.5

var gameData = preload("res://Resources/GameData.tres")
var _lib = null


func _ready():
	if !Engine.has_meta("RTVModLib"):
		push_error("[NapMode] Metro Mod Loader not found")
		return

	var lib = Engine.get_meta("RTVModLib")
	if lib._is_ready:
		_on_lib_ready()
	else:
		lib.frameworks_ready.connect(_on_lib_ready)

func _on_lib_ready():
	_lib = Engine.get_meta("RTVModLib")

	if _lib.hook("bed-interact", _on_bed_interact) == -1:
		push_warning("[NapMode] Bed.Interact is already replaced by another mod, hold-to-nap disabled")

	_lib.hook("bed-updatetooltip-post", _on_bed_tooltip)
	_lib.hook("context-_ready-post", _on_context_ready)
	_lib.hook("context-update-post", _on_context_update)


# ---------------------------------------------------------------- Bed

# Tap interact = vanilla sleep (6-12h), hold interact = nap (1-3h)
func _on_bed_interact():
	var bed = _lib._caller

	if !bed.canSleep:
		return

	var held = 0.0
	while Input.is_action_pressed("interact") && held < HOLD_TIME:
		await get_tree().process_frame
		held += get_process_delta_time()

	if held < HOLD_TIME || gameData.freeze:
		return

	# Set right before returning so no other dispatch can interleave with it
	_lib.skip_super()
	BedNap(bed)

func _on_bed_tooltip():
	var bed = _lib._caller
	if bed.canSleep:
		gameData.tooltip = "Sleep (Random sleep: 6-12h)\n[Hold: Nap 1-3h]"

# Mirrors vanilla Bed.Interact() with a 1-3h nap and scaled effects
func BedNap(bed):

	# Rolled once per bed, like vanilla randomSleep
	if !bed.has_meta("nap_hours"):
		bed.set_meta("nap_hours", Nap.Roll())
	var napTime = bed.get_meta("nap_hours")


	Simulation.simulate = false
	gameData.isSleeping = true
	gameData.freeze = true


	bed.UpdateSimulation(napTime * 100.0)
	bed.PlayTransition()
	bed.PlaySleep()


	await get_tree().create_timer(napTime, false).timeout;
	if gameData.isDead: return


	Nap.ApplyEffects(gameData, napTime)


	var controller = get_tree().current_scene.get_node("/root/Map/Core/Controller")
	controller.global_transform.basis = controller.global_transform.basis.rotated(Vector3.UP, deg_to_rad(180))


	Nap.Message(napTime)


	# A nap uses up the bed, same as a full sleep
	Simulation.simulate = true
	gameData.isSleeping = false
	gameData.freeze = false
	if is_instance_valid(bed): bed.canSleep = false


# ---------------------------------------------------------------- Inventory context menu

# Adds a "Nap" button next to "Sleep" for sleep items
func _on_context_ready():
	var context = _lib._caller

	# Copy without signals so it doesn't also fire _on_sleep_pressed
	var napButton = context.sleepButton.duplicate(DUPLICATE_GROUPS | DUPLICATE_SCRIPTS | DUPLICATE_USE_INSTANTIATION)
	napButton.name = "Nap"
	napButton.text = "Nap"
	context.sleepButton.add_sibling(napButton)
	napButton.pressed.connect(_on_nap_pressed.bind(context))
	context.set_meta("nap_button", napButton)

func _on_context_update(_slotData):
	var context = _lib._caller
	if context.has_meta("nap_button"):
		context.get_meta("nap_button").visible = context.sleepButton.visible

# Mirrors Interface.ContextSleep()
func _on_nap_pressed(context):
	var interface = context.interface

	if !interface.visible:
		return

	if interface.contextItem == null || interface.contextGrid == null:
		print("Null: Context Nap")
		return


	var sleepItem = interface.contextItem.slotData.itemData


	interface.contextGrid.Pick(interface.contextItem)
	interface.contextItem.reparent(interface)
	interface.contextItem.queue_free()


	interface.HideContext()
	interface.PlayClick()
	interface.Reset()


	interface.UIManager.ToggleInterface()


	ItemNap(interface, sleepItem)

# Mirrors Interface.Sleep() with a 1-3h nap and scaled effects
func ItemNap(interface, sleepItem):

	var napTime = Nap.Roll()


	Simulation.simulate = false
	gameData.isSleeping = true
	gameData.freeze = true


	interface.UpdateSimulation(napTime * 100)
	interface.PlayTransition()
	interface.PlaySleep()

	await get_tree().create_timer(napTime, false).timeout;
	if gameData.isDead: return


	Nap.ApplyEffects(gameData, napTime)


	var factor = Nap.Factor(napTime)

	if sleepItem.temperature > 0:
		gameData.temperature += sleepItem.temperature * factor

	elif !gameData.shelter && Simulation.season == 2:
		gameData.temperature -= sleepItem.temperature * factor


	Nap.Message(napTime)


	Simulation.simulate = true
	gameData.isSleeping = false
	gameData.freeze = false
