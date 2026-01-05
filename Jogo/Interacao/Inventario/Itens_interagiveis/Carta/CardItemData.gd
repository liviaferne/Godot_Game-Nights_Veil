extends ItemData
class_name CardItemData

@export_multiline var CardText : String = "Texto padrão da carta."

func get_card_text() -> String:
	return CardText
