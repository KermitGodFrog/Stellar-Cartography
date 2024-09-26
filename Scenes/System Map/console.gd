extends ItemList

var pending_items: Array[Array] = []
const MAX_ITEM_COUNT: int = 7

func async_add_item(text: String, bg_color: Color = Color.WHITE, time: int = 500):
	pending_items.append([text, bg_color, time])
	pass

func _physics_process(delta):
	var _range = range(item_count)
	if item_count > 0:
		_range.append(0)
	for item in _range:
		var metadata = get_item_metadata(item)
		if metadata: 
			set_item_metadata(item, maxi(0, metadata - delta))
			if get_item_metadata(item) == 0: remove_item(item)
	
	
	
	
	if item_count < (MAX_ITEM_COUNT - 1):
		if not pending_items.is_empty():
			var new_item_data = pending_items.front()
			if new_item_data:
				var new_item = add_item(new_item_data[0], null, false)
				set_item_custom_bg_color(new_item, new_item_data[1])
				set_item_metadata(new_item, float(new_item_data[2]))
				set_item_selectable(new_item, false)
				pending_items.remove_at(0)
	
	force_update_list_size()
	pass
