extends Node

#--- Notes ---
# Hello, greetings to whoever is reading this. This is merely a prototype and there's a lot of things to implement to. 
# UNDO is still built-in, not manually coded to see how the game works. So, as arrays.
# Note written by: Sharksnow-123 (Briar)




# --- SETTINGS ---
const MAX_GUESSES := 5
var word_list_day1 = ["APPLE", "ROBOT", "SNAKE"]
var word_list_day2 = ["WATERFALL", "NOTEBOOK", "PYTHON"]
var word_list_day3 = ["ASTRONOMY", "COMPUTER", "VOLCANO"]

# --- STATE ---
var chosen_word := ""
var hidden := []
var guessed_letters := []
var wrong_guesses := 0
var undo_stack := []          # using built-in Array for undo snapshots
var current_day := 1
const MAX_DAYS := 3
var last_round_result : String = ""   # "win" or "lose"

# --- UI ---
@onready var word_label = $WordLabel
@onready var guessed_label = $GuessedLetters
@onready var letters = $Letters
@onready var undo_button = $UndoButton

@onready var lose_panel = $LosePanel
@onready var title_label = $LosePanel/Title
@onready var continue_button = $LosePanel/ContinueButton
@onready var return_button = $LosePanel/ReturnMain
@onready var day_frame = $DayFrame

func _ready():
	randomize()
	connect_buttons()
	start_game()


# ----------------------------------
# START GAME
# ----------------------------------
func start_game():
	wrong_guesses = 0
	guessed_letters.clear()
	undo_stack.clear()
	
	# choose a word based on current day
	chosen_word = _get_word_for_day()
	hidden.clear()
	for c in chosen_word:
		hidden.append("_")

	update_ui()
	_update_day_display()
	lose_panel.visible = false

	print("[Game] Day %d - New word length: %d" % [current_day, chosen_word.length()])
	print("[Game] Guesses allowed:", MAX_GUESSES)


func _get_word_for_day() -> String:
	# pick a random word according to current day
	if current_day == 1:
		return word_list_day1[randi() % word_list_day1.size()]
	elif current_day == 2:
		return word_list_day2[randi() % word_list_day2.size()]
	else:
		return word_list_day3[randi() % word_list_day3.size()]


# ----------------------------------
# CONNECT KEY BUTTONS
# ----------------------------------
func connect_buttons():
	# connect letter buttons safely (capture local reference)
	for btn in letters.get_children():
		if btn is Button:
			var b = btn
			b.pressed.connect(func(): handle_letter(b.text))

	# other buttons
	undo_button.pressed.connect(undo)
	
	continue_button.pressed.connect(_on_continue_pressed)
	return_button.pressed.connect(_on_return_main_pressed)


# ----------------------------------
# UPDATE DISPLAY
# ----------------------------------
func update_ui():
	word_label.text = " ".join(hidden)
	guessed_label.text = "Guessed: " + ", ".join(guessed_letters)


func _update_day_display():
	# day_frame can be Label or a container with a child label; handle both
	if day_frame is Label:
		day_frame.text = "Day: " + str(current_day) + " / " + str(MAX_DAYS)


# ----------------------------------
# GUESS LETTER
# ----------------------------------
func handle_letter(letter):
	letter = letter.to_upper()

	if letter in guessed_letters:
		return

	save_state()

	guessed_letters.append(letter)
	update_ui()

	var correct := false

	for i in range(chosen_word.length()):
		if chosen_word[i] == letter:
			hidden[i] = letter
			correct = true

	update_ui()

	if correct:
		if "_" not in hidden:
			show_end("YOU WIN!")
	else:
		wrong_guesses += 1
		print("[GUESS] Wrong guesses:", wrong_guesses, " / ", MAX_GUESSES)

		if wrong_guesses >= MAX_GUESSES:
			show_end("YOU LOSE!")


# ----------------------------------
# UNDO
# ----------------------------------
func save_state():
	# store snapshots so undo can fully restore
	var snapshot = {
		"hidden": hidden.duplicate(),
		"guessed": guessed_letters.duplicate(),
		"wrong": wrong_guesses
	}
	undo_stack.append(snapshot)
	print("[SAVE] saved state; undo stack size =", undo_stack.size())


func undo():
	if undo_stack.is_empty():
		print("[UNDO] No more undo")
		return

	var state = undo_stack.pop_back()
	hidden = state.hidden
	guessed_letters = state.guessed
	wrong_guesses = state.wrong

	update_ui()
	print("[UNDO] restored state; undo stack size =", undo_stack.size())

	update_ui()
	print("[UNDO] restored state; undo stack size =", undo_stack.size())


# ----------------------------------
# SHOW LOSE/WIN
# ----------------------------------
func show_end(text):
	if text == "YOU LOSE!":
		title_label.text = text + "\nThe word was: " + chosen_word
		last_round_result = "lose"
	else:
		title_label.text = text
		last_round_result = "win"

	lose_panel.visible = true
	print("[GAME END] " + title_label.text, " | result =", last_round_result)



# ----------------------------------
# CONTINUE / NEXT DAY
# ----------------------------------
func _on_continue_pressed():
	if last_round_result == "win":
		# Player won the round
		if current_day < MAX_DAYS:
			# Go to next day
			current_day += 1
			print("[DAY] Player won. Going to day:", current_day)
			start_game()

		else:
			# Player completed the final day → WIN THE ENTIRE GAME
			print("[GAME] Completed all days! Changing scene...")
			await get_tree().create_timer(0.8).timeout
			get_tree().change_scene_to_file("res://Scenes/EndScene1.tscn")

	elif last_round_result == "lose":
		# Reset to day 1
		print("[DAY] Player lost. Resetting to Day 1")
		current_day = 1
		get_tree().change_scene_to_file("res://Scenes/DeathScene.tscn")

	else:
		print("[ERROR] Continue pressed but no round result stored!")

	# Clear result so it doesn't apply twice
	last_round_result = ""




# ----------------------------------
# RETURN TO MAIN 
# ----------------------------------
func _on_return_main_pressed():
	await get_tree().create_timer(0.5).timeout #added delay for aesthetics ahh
	get_tree().change_scene_to_file("res://main.tscn")
