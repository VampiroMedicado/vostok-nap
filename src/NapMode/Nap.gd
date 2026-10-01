extends RefCounted

# Shared nap rules for beds and sleep items: vanilla sleep is a random 6-12h,
# a nap is a random 1-3h with effects scaled by hours / 9 (vanilla's average sleep).
const MIN_HOURS = 1
const MAX_HOURS = 3
const SLEEP_AVERAGE = 9.0


static func Roll():
	return randi_range(MIN_HOURS, MAX_HOURS)

static func Factor(hours):
	return hours / SLEEP_AVERAGE

static func ApplyEffects(gameData, hours):
	var factor = Factor(hours)
	gameData.energy -= 20.0 * factor
	gameData.hydration -= 20.0 * factor
	gameData.mental += 20.0 * factor

static func Message(hours):
	Loader.Message("You napped " + str(hours) + (" hour" if hours == 1 else " hours"), Color.GREEN)
