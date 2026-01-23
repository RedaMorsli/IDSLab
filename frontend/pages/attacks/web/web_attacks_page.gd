extends Page


@export var web_attacks: Array[WebAttackConfig]
@export var ParamUIScene: PackedScene

@onready var targetOptionButton: OptionButton = %TargetOptionButton
@onready var attackOptionButton: OptionButton = %AttackOptionButton
@onready var timeoutSpinBox: SpinBox = %TimeoutSpinBox
@onready var launchAttackButton: Button = %LaunchAttackButton
@onready var outputLabel: RichTextLabel = %OutputLabel
@onready var parameterContainer: Container = %ParameterContainer


func _ready() -> void:
	_update_web_apps(AppManager.web_apps)
	_update_attacks()
	
	AppManager.web_apps_fetched.connect(_update_web_apps)
	AttackManager.attack_progress.connect(
		func (args):
			outputLabel.add_text(args.data['output'])
			outputLabel.newline()
	)


func _update_web_apps(apps: Array[WebApp]):
	targetOptionButton.clear()
	for app in apps:
		targetOptionButton.add_item(app.app_name)


func _update_attacks():
	attackOptionButton.clear()
	for attack_idx in web_attacks.size():
		var web_attack: WebAttackConfig = web_attacks[attack_idx]
		attackOptionButton.add_icon_item(web_attack.icon, web_attack.attack_name, attack_idx)
		_update_attack_params(web_attack)

func _update_attack_params(attack: WebAttackConfig):
	for child in parameterContainer.get_children():
		child.queue_free()
	for param in attack.params:
		var param_ui: ParameterUI = ParamUIScene.instantiate()
		param_ui.parameter = param
		param_ui.value_changed.connect(
			func (value):
				param.value.clear()
				param.value.append(value)
		)
		parameterContainer.add_child(param_ui)


func _on_back_button_pressed() -> void:
	request_pop_back.emit()


func _on_launch_attack_button_pressed() -> void:
	launchAttackButton.disabled = true
	outputLabel.clear()
	var target_app: WebApp = AppManager.web_apps[targetOptionButton.selected]
	var web_attack = web_attacks[attackOptionButton.selected]
	web_attack.target_app = target_app
	web_attack.timeout = int(timeoutSpinBox.value)
	AttackManager.simulate_web_attack(web_attack)
	await AttackManager.attack_terminated
	launchAttackButton.disabled = false
