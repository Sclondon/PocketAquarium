extends Node
## The player's tickets: the arcade's own currency, which is all the shop takes.
##
## In the arcade the hosting page owns the balance. The game talks to it with window messages:
##   game -> page   { type: 'AQUARIUM_READY' }                    once, when it has loaded
##   page -> game   { type: 'TICKETS', balance: 1234 }            then, and whenever it changes
##   game -> page   { type: 'SPEND_TICKETS', amount: 40, item: 'fish:goldfish' }
## The game takes the price off its own copy at once; the page should answer a spend with a
## fresh TICKETS message, which always wins.
##
## Until a page has answered, the game runs on a practice wallet kept in the save, so it can be
## played on its own. `?tickets=500` in the address (or `--tickets=500`) sets the practice wallet.

signal changed

const PRACTICE := 300

var balance := 0
## Whether the arcade page has told us the balance (false: the practice wallet).
var hosted := false

var _callback: JavaScriptObject


func _ready() -> void:
	balance = int(Save.data.get("wallet", PRACTICE))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tickets="):
			balance = int(arg.get_slice("=", 1))
	if not OS.has_feature("web"):
		return
	var asked := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('tickets') || ''", true))
	if asked.is_valid_int():
		balance = int(asked)
	_callback = JavaScriptBridge.create_callback(_on_message)
	JavaScriptBridge.get_interface("window").pocketAquariumTickets = _callback
	# only the page that holds the cabinet may set the balance
	JavaScriptBridge.eval("""window.addEventListener('message', function (e) {
		if (e.source !== window.parent || !e.data || e.data.type !== 'TICKETS') return;
		window.pocketAquariumTickets(JSON.stringify(e.data));
	});""", true)
	post({"type": "AQUARIUM_READY"})


func _on_message(args: Array) -> void:
	if args.is_empty():
		return
	var parsed: Variant = JSON.parse_string(str(args[0]))
	if parsed is Dictionary and parsed.has("balance"):
		balance = maxi(int(parsed.balance), 0)
		hosted = true
		changed.emit()


## Pays for something. False (and nothing is taken) when there are not enough tickets.
func spend(amount: int, item: String) -> bool:
	if amount > balance:
		return false
	balance -= amount
	if hosted:
		post({"type": "SPEND_TICKETS", "amount": amount, "item": item})
	else:
		Save.data["wallet"] = balance
		Save.write()
	changed.emit()
	return true


## Sends a message to the page the cabinet is in (nothing happens outside a browser).
func post(message: Dictionary) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.parent.postMessage(%s, '*')" % JSON.stringify(message), true)
