extends Resource
class_name userDetailsHelper

@export var played_previously: bool = false

@export var win_condition_runs: int = 0
@export var lose_condition_runs: int = 0
@export var total_runs: int = 0

@export var unlocked_mutations: Array[worldAPI.MUTATION_ID] = []

@export var metadata: Dictionary #any required data in the future should be put here so this class doesnt have to be modified in the future, as doing so could cause all user details to be cleared for the player, which wouldnt be a fun experience for them
