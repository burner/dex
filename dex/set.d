module dex.set;

import hurt.conv.conv;

import std.stdio;

public class Set(T) {
	private class Elem(T) {
		T value;
		Elem!(T) left;
		Elem!(T) right;
	
		this(T value) {
			this.value = value;
		}

		bool insert(T value, bool function(in T a, in T b) cmp) {
			if(this.value == value) {// opEquals is needed
				return false;
			} 
			if(left !is null && left.value == value)
				return false;
			if(right !is null && right.value == value)
				return false;

			if(left is null) {
				this.left = new Elem!(T)(value);
				return true;
			} else if(left !is null && cmp(value, left.value)) {
				return this.left.insert(value, cmp);
			} else if(right is null) {
				this.right = new Elem!(T)(value);
				return true;
			} else if(right !is null){
				return this.right.insert(value, cmp);
			} else {
				return false;
			}
		}

		bool insert(Elem!(T) value, bool function(in T a, in T b) cmp) {
			if(this.value == value.value) {// opEquals is needed
				return false;
			} 
			if(left !is null && left.value == value.value)
				return false;
			if(right !is null && right.value == value.value)
				return false;

			if(left is null) {
				this.left = value;
				return true;
			} else if(left !is null && cmp(value.value, left.value)) {
				return this.left.insert(value, cmp);
			} else if(right is null) {
				this.right = value;
				return true;
			} else if(right !is null){
				return this.right.insert(value, cmp);
			} else {
				return false;
			}
		}

		void validate() {
			if(this.left !is null) {
				assert(this.left.value < this.value);
				this.left.validate();
			}
			if(this.right !is null) {
				assert(this.right.value > this.value);
				this.right.validate();
			}
		}
	
		bool contains(T value, bool function(in T a, in T b) cmp) {
			if(this.value == value) {
				return true;
			}
			if(this.left !is null && this.left.value == value) {
				return true;
			} else if(this.left !is null && cmp(value, this.left.value)) {
				return this.left.contains(value, cmp);
			} else if(this.right !is null && this.right.value == value) {
				return true;
			} else if(this.right !is null && cmp(value, this.right.value)) {
				return this.right.contains(value, cmp);
			} else {
				return false;
			}
		}
		 
	}

	private Elem!(T) root;
	bool function(T a, T b) cmp;
	uint size;

	this() {
		this.root = null;
		this.size = 0u;
		this.cmp = function(in T a, in T b) { return a < b; };
	}

	this(bool function(in T a, in T b) cmp) {
		this.root = null;
		this.size = 0u;
		this.cmp = cmp;
	}

	public bool insert(T value) {
		// Root is null
		if(this.root is null) {
			this.root = new Elem!(T)(value);
			this.size++;
			return true;
		} else {
			bool tmp = this.root.insert(value, cmp);
			if(tmp)
				this.size++;
	
			return tmp;
		}
	}

	public bool insert(Elem!(T) value) {
		// Root is null
		if(this.root is null) {
			this.root = value;
			this.size++;
			return true;
		} else {
			bool tmp = this.root.insert(value, cmp);
			if(tmp)
				this.size++;
	
			return tmp;
		}
	}

	public void validate() {
		if(this.root !is null) {
			this.root.validate();
		}
	}

	public bool contains(T value) {
		if(this.root is null) {
			throw new Exception("element can't be found");
		}
		return this.root.contains(value, cmp);
	}

	private void reInsert(Elem!(T) elem) {
		if(elem !is null) {
			Elem!(T)[256] stack;	
			uint stackPtr = 0;
			Elem!(T) cur = elem;
			while(stackPtr != 0 || cur !is null) {
				if(cur !is null) {
					stack[stackPtr++] = cur;
					cur = cur.left;	
				} else {
					cur = stack[--stackPtr];
					this.insert(cur);
					cur = cur.right;
				}
			}
		}
	}

	public bool remove(T value) {
		if(root is null) {
			return false;
		}	
		if(root.value == value) {
			Elem!(T) tLeft = root.left;
			Elem!(T) tRight = root.right;
			this.root = null;
			this.size = 0;
			this.reInsert(tLeft.left);
			this.reInsert(tRight.right);
			return true;
		}

		Elem!(T) tmp = this.root;
		while(tmp !is null) {
			// left child is to be removed
			if(tmp.left !is null && tmp.left.value == value
					&& tmp.left.left is null && tmp.left.right is null) {
				tmp.left = null;
				this.size--;
				return true;
			// right child is to be removed
			} else if(tmp.right !is null && tmp.right.value == value
					&& tmp.right.left is null && tmp.right.right is null) {
				tmp.right = null;
				this.size--;
				return true;
			// left has left child
			} else if(tmp.left !is null && tmp.left.value == value
					&& tmp.left.left !is null && tmp.left.right is null) {
				tmp.left = tmp.left.left;
				this.size--;
				return true;	
			// left has right child
			} else if(tmp.left !is null && tmp.left.value == value
					&& tmp.left.left is null && tmp.left.right !is null) {
				tmp.left = tmp.left.right;
				this.size--;
				return true;	
			// rigth has left child
			} else if(tmp.right !is null && tmp.right.value == value
					&& tmp.right.left !is null && tmp.right.right is null) {
				tmp.left = tmp.right.left;
				this.size--;
				return true;	
			// rigth has right child
			} else if(tmp.right !is null && tmp.right.value == value
					&& tmp.right.left is null && tmp.right.right !is null) {
				tmp.left = tmp.right.right;
				this.size--;
				return true;	
			// other
			} else if(tmp.left !is null && tmp.left.value == value
					&& tmp.left.left !is null && tmp.left.right !is null) {
				Elem!(T) tLeft = tmp.left.left;
				Elem!(T) tRight = tmp.left.right;
				tmp.left = null;
				tmp.right = null;
				this.reInsert(tLeft);
				this.reInsert(tRight);
				this.size--;
				return true;
			} else {
				if(cmp(tmp.left.value, value)) {	
					tmp = tmp.left;
					continue;
				} else if(tmp.right !is null) {
					tmp = tmp.right;
					continue;
				}
				return false;
			}
		}
		return false;
	}
}

unittest {
	Set!(int) intTest = new Set!(int)();
	int[] t = [123,13,5345,752,12,3,1,654,22];
	foreach(idx,it;t) {
		assert(intTest.insert(it));
		foreach(jt;t[0..idx]) {
			assert(intTest.contains(jt));
		}
		foreach(jt;t[idx+1..$]) {
			assert(!intTest.contains(jt));
		}
	}
	intTest.validate();
	foreach(idx,it;t) {
		assert(!intTest.insert(it), conv!(int,string)(it));
	}
	intTest.validate();
	foreach(idx,it;t) {
		writeln(it);
		assert(intTest.remove(it), conv!(int,string)(it));
	}
}
