module dex.oldset;

import hurt.conv.conv;
import hurt.container.set;

import std.stdio;

void print(T)(OldSet!(T) old, Set!(T) ne) {
	write("old: ");
	foreach(it;old.values()) {
		write(it, " ");
	}
	writeln();	
	write("new: ");
	foreach(it;ne) {
		write(it, " ");
	}
	writeln();	
}

bool same(T)(OldSet!(T) old, Set!(T) ne) {
	if(old.getSize() != ne.getSize()) {
		writeln(__FILE__,__LINE__);
		print(old, ne);
		return false;
	}
	int runsOld = 0;
	foreach(it;old.values()) {
		if(!ne.contains(it)) {
			writeln(__FILE__,__LINE__);
			print(old, ne);
			return false;
		}
		runsOld++;
	}
	outer: foreach(it;old.values()) {
		foreach(jt; ne) {
			if(it == jt) {
				continue outer;
			}
		}
		writeln(__FILE__,__LINE__);
		print(old, ne);
		return false;
	}
	int runsNew = 0;
	foreach(it;ne) {
		if(!ne.contains(it)) {
			writeln(__FILE__,__LINE__);
			print(old, ne);
			return false;
		}
		runsNew++;
	}
	if(runsOld != runsNew) {
		writeln(__FILE__,__LINE__);
		print(old, ne);
		return false;
	}
	return true;
}

public class OldSet(T) {
	T[T] array;

	this(OldSet!(T) toCopy) {
		foreach(it;toCopy.values()) {
			this.insert(it);
		}
	}

	this() {
	
	}

	size_t getSize() const {
		return this.array.length;
	}
	
	bool insert(T value) {
		if(value in this.array) {
			return false;
		} else {
			this.array[value] = value;
			return true;
		}
	}

	T get(T value) {
		if(value in this.array) {
			assert(0);
		} else {
			return this.array[value];
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

	bool contains(T value) const {
		if(value in this.array) {
			return true;
		} else {
			return false;
		}
	}

	T[] values() {
		return this.array.values();
	}

	const(T[]) constValues() const {
		const T[] tmp = this.array.values();
		return tmp;
	}

	OldSet!(T) dup() {
		OldSet!(T) ret = new OldSet!(T)(this);
		return ret;
	}

	override bool opEquals(Object o) const {
		OldSet!(T) f = cast(OldSet!(T))o;
		foreach(it; f.values()) {
			if(!this.contains(it)) {
				return false;
			}	
		}
		return f.values().length == this.array.length;
	}

	bool empty() const {
		return this.array.length == 0;
	}	
}
