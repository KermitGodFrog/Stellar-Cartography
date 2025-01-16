extends Resource
class_name achievement
#dialogue query info is sent to achievementManager, where the criteria of different achievements is matched. achievements are only changed if ALL criteria are met, unlike dialogue rules. maybe just use the dialogueManager get_rule_matches function - some unholy pass between both scripts
#examples for different achievement criteria:
#game_finish_100k: concept: playerWin, score: >=100000
#player score would have to be added to rules!



@export var name : String = ""
@export_multiline var description = ""
@export var dialogue_criteria: Dictionary
