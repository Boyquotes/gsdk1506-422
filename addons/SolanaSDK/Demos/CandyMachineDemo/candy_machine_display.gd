extends Node
class_name CandyMachineDisplay

@export var candy_machine_id:String
@export var candy_guard_id:String

@export var nft_display:DisplayableNFT
@export var collection_desc:Label
@export var minted_amount:Label
@export var progress_bar:ProgressBar

@export var guard_settings:CandyGuardAccessList

@export var mint_groups:Array[String]
#first one is default
@export var mint_buttons:Array[ButtonLock]

var cm_data:CandyMachineData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cm_data = await SolanaService.candy_machine_manager.fetch_candy_machine(Pubkey.new_from_string(candy_machine_id))
	print(cm_data)
	if cm_data!=null:
		setup(cm_data)
	
	for button in mint_buttons:
		button.pressed.connect(self.try_mint.bind(button))
		
	SolanaService.transaction_processor.connect("on_transaction_finish",refresh_cm_data)
	pass # Replace with function body.

func setup(cm_data:CandyMachineData) -> void:
	var collection_nft:Nft = await SolanaService.nft_manager.get_nft_from_mint(cm_data.collection_mint,true)
	nft_display.set_data(collection_nft)
	collection_desc.text = collection_nft.offchain_metadata["description"]

	minted_amount.text = "%s/%s Minted" % [cm_data.items_redeemed,cm_data.items_available]
	progress_bar.value = float(cm_data.items_redeemed)/float(cm_data.items_available)

func try_mint(pressed_button:Button) -> void:
	var button_index = mint_buttons.find(pressed_button,0)
	SolanaService.transaction_processor.connect("on_transaction_finish",refresh_cm_data)
	
	if guard_settings!=null:
		SolanaService.candy_machine_manager.mint_nft_with_guards(
			Pubkey.new_from_string(candy_machine_id),
			Pubkey.new_from_string(candy_guard_id),
			cm_data,
			SolanaService.wallet,
			SolanaService.wallet.get_kp(),
			guard_settings,
			mint_groups[button_index]
		)
	
func refresh_cm_data(transaction_id:String) -> void:
	SolanaService.transaction_processor.disconnect("on_transaction_finish",refresh_cm_data)
	if transaction_id=="":
		return
		
	cm_data = await SolanaService.candy_machine_manager.fetch_candy_machine(Pubkey.new_from_string(candy_machine_id))
	if cm_data!=null:
		setup(cm_data)
		
	for button in mint_buttons:
		button.try_unlock()
	
