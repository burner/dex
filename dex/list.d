module dex.list;

class List(T) {
	private class Item(T) {
		T value;
		Item!(T) next;
	
		this(T value) {
			this.value = value;
			this.next = null;
		}
	}

	private Item!(T) root;
	private uint size;
	
	public this() {
		this.root = null;
		this.size = 0;
	}

	public List!(T) clear() {
		this.root = null;
		return this;
	}

	bool find(T search) {
		Item!(T) tmp = this.root;
		while(tmp !is null) {
			if(search == tmp.value) {
				return true;
			}
			tmp = tmp.next;
		}
		return false;
	}

	List!(T) remove(T search) {
		if(this.root is null)
			return null;
		if(this.root.value == search) {
			this.root = this.root.next;
			this.size--;
		}
		Item!(T) tmp = this.root;
		while(tmp !is null) {
			if(tmp.next !is null && tmp.next.value == search) {
				tmp.next = tmp.next.next;
				return;
			}
			tmp = tmp.next;
		}
		return this;	
	}

	List!(T) insert(T toIn) {
		if(root is null) {
			this.root = new Item!(T)(toIn);
			this.size++;
			return this;
		}
		toIn.next = this.root;
		this.root = toIn;
		this.size++;
		return this;
	}

	public uint getSize() const {
		return this.size;
	}

	int opApply(int delegate(ref Item!(T)) dg) {
		int result = 0;
		Item!(T) it = root;
		while(it !is null) {
			result = dg(it);
			if(result)
				break;

			it = it.next;
		}
		return result;
	}
}
