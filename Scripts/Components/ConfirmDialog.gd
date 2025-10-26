extends ConfirmationDialog

# ConfirmDialog.gd - Reusable confirmation dialog component
# Provides a simple way to ask for user confirmation before actions

@onready var message_label = $MessageLabel

# Signal emitted when user confirms the action
signal action_confirmed()

func _ready():
	# Connect to built-in signals
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)

func show_confirmation(title_text: String, message_text: String, confirm_text: String = "Confirm", cancel_text: String = "Cancel"):
	"""
	Show the confirmation dialog with custom text.
	
	Args:
		title_text: Dialog window title
		message_text: Message to display to user
		confirm_text: Text for confirm button (default: "Confirm")
		cancel_text: Text for cancel button (default: "Cancel")
	"""
	title = title_text
	message_label.text = message_text
	ok_button_text = confirm_text
	cancel_button_text = cancel_text
	popup_centered()

func _on_confirmed():
	"""User clicked confirm button."""
	emit_signal("action_confirmed")

func _on_canceled():
	"""User clicked cancel button - dialog auto-closes."""
	pass
