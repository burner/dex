module dex.multimap;

class MultiMap(T,S) {
	private class Value(S) {
		uint idx;
		S[] multi;

		this(S value) {
			this.multi = new S[16];
			this.multi[this.idx++] = value;
		}

		public void insert(S value) {
			if(this.idx == multi.length) {
				this.multi.length *= 2u;
			}
			this.multi[this.idx++] = value;
		}

		public S[] remove() {
			return this.multi[0..this.idx].dup;
		}

		public S[] remove(uint rIdx) {
			if(rIdx >= this.idx) {
				assert(0, "not allowed to remove out of index");
			}
			uint upIdx = rIdx + 1u;
			uint lowIdx = rIdx;
			while(lowIdx < this.idx - 1u) {
				this.multi[lowIdx] = this.multi[upIdx];
				upIdx++;
				lowIdx++;
			}
			if(this.idx == 1u) {
				return null;
			} else {
				this.idx--;
				return this.multi[0..this.idx];
			}
		}

		public uint getSize() {
			return this.idx;
		}

		public S[] values() {
			return this.multi[0..this.idx];
		}
	}

	Value!(S)[T] multi;

	MultiMap!(T,S) insert(T key, S value) {
		if(key in this.multi) {
			Value!(S) tmp = this.multi[key];
			tmp.insert(value);
		} else {
			this.multi[key] = new Value!(S)(value);
		}
		return this;
	}

	S[] remove(T key, uint idx) {
		if(key in this.multi) {	
			S[] tmp = this.multi[key].remove(idx);	
			if(tmp is null) {
				return null;
			} else {
				return tmp;
			}
		} else {
			return null;
		}
	}

	S[] remove(T key) {
		if(key in this.multi) {	
			S[] tmp = this.multi[key].remove();	
			this.multi.remove(key);
			return tmp;
		} else {
			return null;
		}
	}

	S[] find(T key) {
		if(key in this.multi) {	
			S[] tmp = this.multi[key].remove();	
			return tmp;
		} else {
			return null;
		}
	}
}

unittest {
	MultiMap!(char,int) mm1 = new MultiMap!(char,int)();
	mm1.insert('t', 12);
	mm1.insert('t', 22);
	mm1.insert('t', 32);
	mm1.insert('t', 42);
	assert(mm1.find('t') == [12,22,32,42]);
	mm1.remove('t', 0u);
	assert(mm1.find('t') == [22,32,42]);
	assert(mm1.find('r') is null);
	mm1.insert('r', 92);
	assert(mm1.find('r') !is null);
	mm1.insert('r', 32);
	mm1.insert('r', 82);
	assert(mm1.find('r') == [92,32,82]);
	mm1.remove('r', 1u);
	assert(mm1.find('r') == [92,82]);
	mm1.remove('t');
	assert(mm1.find('t') is null);
}
