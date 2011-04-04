module dex.set;

import hurt.conv.conv;

import std.stdio;

public class Set(T) {
	T[T] array;
	
	bool insert(T value) {
		if(value in this.array) {
			return false;
		} else {
			this.array[value] = value;
			return true;
		}
	}

	bool remove(T value) {
		if(value in this.array) {
			this.array.remove(value);
			return true;
		} else {
			return false;
		}
	}

	bool contains(T value) {
		if(value in this.array) {
			return true;
		} else {
			return false;
		}
	}

	T[] values() {
		return this.array.values();
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
	foreach(idx,it;t) {
		assert(!intTest.insert(it), conv!(int,string)(it));
		assert(intTest.contains(it), conv!(int,string)(it));
	}
	foreach(idx,it;t) {
		assert(intTest.remove(it), conv!(int,string)(it));
		assert(!intTest.contains(it), conv!(int,string)(it));
		foreach(jt;t[0..idx]) {
			assert(!intTest.contains(jt));
		}
		foreach(jt;t[idx+1..$]) {
			assert(intTest.contains(jt));
		}
	}
}
