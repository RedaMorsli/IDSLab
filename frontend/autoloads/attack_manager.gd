extends Node


signal attack_terminated()
signal attack_progress(progress)

var attack_running: bool = false


func simulate_web_attack(attack: WebAttackConfig):
	if attack_running:
		return
	attack_running = true
	var args = {
		"target_address": attack.target_app.address, 
		"target_port": attack.target_app.port,
		'timeout': attack.timeout
	}
	for param in attack.params:
		args[param.attr] = param.value[0]
	Server.send_command(attack.server_command, args,
	"Launching " + attack.attack_name + " on \'" + attack.target_app.address + "\'", 
	func (args):
		attack_running = false
		attack_terminated.emit()
	,
	func (args):
		attack_progress.emit(args)
	)


func dos_slowloris(target_address: String, target_port: int, timeout: int):
	if attack_running:
		return
	attack_running = true
	Server.send_command("dos_slowloris",
	{"target_address": target_address, "target_port": target_port, "timeout": timeout},
	"Launching DoS Slowloris on \'" + target_address + "\'", 
	func (args):
		attack_running = false
		attack_terminated.emit()
	,
	func (args):
		attack_progress.emit(args)
	)
