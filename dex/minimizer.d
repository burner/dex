module dex.minimizer;

import dex.state;

import hurt.algo.sorting;
import hurt.container.dlst;
import hurt.container.isr;
import hurt.container.list;
import hurt.container.map;
import hurt.container.multimap;
import hurt.container.set;
import hurt.container.vector;
import hurt.conv.conv;
import hurt.io.stdio;

private Vector!(Vector!(State)) makeInitPartitions(
		DLinkedList!(State) oldStates, Map!(State,long) states) {
	Vector!(Vector!(State)) ret = new Vector!(Vector!(State))();
	ret.append(new Vector!(State)());
	ret.append(new Vector!(State)());
	foreach(it; oldStates) {
		if(it.getStateId() == -1) {
			states.insert(it, 0);
			ret[0].append(it);
		} else if(it.isAccepting()) {
			states.insert(it, 1);
			ret[1].append(it);
		} else {
			states.insert(it, 2);
			if(ret.getSize() == 2) {
				ret.append(new Vector!(State)());
			}
			ret[2].append(it);
		}
	}
	
	// test if the created mapping is ok
	foreach(idx,it;ret) {
		assert(it.getSize() > 0, conv!(size_t,string)(idx));
		foreach(jt;it)
			assert(states.find(jt).getData() == idx);
	}
	return ret;
}

private Vector!(State) finalizeGroups(Vector!(Vector!(State)) old,
		Set!(dchar) inputSet, Map!(State,long) states) {
	Vector!(State) ret = new Vector!(State)();
	//writeln(__LINE__," ",old.getSize());
	// make the states gone fill them later
	int idCnt = 1;
	outer: foreach(idx,it; old) {
		foreach(jt; it) {
			if(jt.getStateId() == 1) {
				ret.append(new State(0));
				continue outer;
			} else if(jt.getStateId() == -1) {
				ret.append(new State(-1));
				continue outer;
			}
		}
		ret.append(new State(idCnt++));
	}

	assert(ret.getSize() == old.getSize(), conv!(size_t,string)(ret.getSize()) 
		~ " " ~ conv!(size_t,string)(old.getSize()));

	for(size_t i; i < old.getSize(); i++) {
		if(ret[i].getStateId() == -1)
			continue;
		// create the output transition for every input
		foreach(c; inputSet) {
			ret[i].addTransition(c, 
				ret[states.find(old[i][0].getSingleTransition(c)).getData()]);
		}

		foreach(it; old[i]) {
			foreach(jt; it.getAcceptingStates()) {
				ret[i].setAcceptingState(jt);
			}
		}
	}

	//printStates(states);
	return ret;
}

private void printStates(Map!(State,long) states) {
	print("states {");
	for(auto it = states.begin(); it.isValid(); it++)
		print((*it).getKey(),":",(*it).getData());
	println("}");
}

public Vector!(State) minimize(T)(DLinkedList!(State) oldStates, 
		Set!(T) inputSet) {
	Map!(State,long) states = new Map!(State,long)();
	Vector!(Vector!(State)) groups = makeInitPartitions(oldStates, states);
	//printStates(states);
	size_t oldSize = 0;
	assert(groups.getSize() > 1, "there should at least 2 partitions by now");
	assert(inputSet.getSize() > 0);
	size_t grCnt = groups.getSize();
	int rounds = 0;
	while(oldSize != grCnt) {
		oldSize = groups.getSize();
		for(size_t i = 0; i < grCnt; i++) {
			Vector!(State) transGroup = groups[i];
			size_t groupSize = transGroup.getSize();
			if(groupSize == 1)
				continue;
			assert(groupSize > 0, "A valid group can't have size 0");

			bool added = false;	
			Vector!(State) newGroup = new Vector!(State)();
			State first = transGroup[0];
			for(size_t j = 1; j < groupSize; j++) {
				State next = transGroup[j];
				int cntInner = 0;
				foreach(c; inputSet) {
					State gotoFirst = first.getSingleTransition(c);
					State gotoNext = next.getSingleTransition(c);
					if(states.find(gotoFirst).getData() != 
							states.find(gotoNext).getData() ||
							(first.isAccepting() && next.isAccepting() &&
							first.getAcceptingStates() !=
							next.getAcceptingStates())) {
						/*writeln(__LINE__," ",c, " ",gotoFirst.getStateId(),
							" ", gotoNext.getStateId()," ", 
							states.find(gotoFirst).getData(), " ",
							states.find(gotoNext).getData());*/
						transGroup.remove(j);
						j--;
						groupSize--;
						newGroup.append(next);

						if(!added) {
							added = true;
							grCnt++;
							groups.append(newGroup);
						}
						states.insert(next, groups.getSize()-1);
						//printStates(states);

						assert(groups.contains(newGroup));
						assert(groups.contains(transGroup));
						assert(transGroup.contains(first));
						assert(!transGroup.contains(next));
						assert(!newGroup.contains(first));
						assert(newGroup.contains(next));
						assert(transGroup.getSize() == groupSize);
						assert(states.find(first).getData() == i,
							conv!(long,string)(states.find(next).getData()) ~
							" " ~ conv!(size_t,string)(i));
						assert(states.find(next).getData() != i);
						assert(states.find(next).getData() == 
							groups.getSize()-1,
							conv!(long,string)(states.find(next).getData()) ~
							" " ~ conv!(size_t,string)(groups.getSize()-1));
						break;
					} 					
					cntInner++;
				}
			}
		}
		rounds++;
	}
	return finalizeGroups(groups, inputSet,states);	
}

struct MinTable {
	Vector!(Vector!(int)) table;
	int[] state;
	Map!(dchar,int) inputChar;
}

class Row {
	int idx;
	Vector!(int) row;

	this(int idx, size_t size) {
		this.idx = idx;
		this.row = new Vector!(int)(size);
	}

	override hash_t toHash() const {
		return this.idx;
	}

	override int opCmp(Object o) const {
		Row f = cast(Row)o;
		if(this.idx > f.idx)
			return 1;
		else if(this.idx < f.idx)
			return -1;
		else
			return 0;
	}

	override bool opEquals(Object o) {
		Row r = cast(Row)o;
		if(r.row.getSize() != this.row.getSize())
			return false;

		foreach(size_t idx, int it; r.row) {
			if(it != this.row[idx]) {
				return false;
			}
		}

		return true;
	}
}

MinTable minTable(Vector!(State) states, Set!(dchar) inputSet) {
	// create the return type and it's members
	MinTable ret;
	sortVector!(State)(states, function(in State a, in State b) { 
		return a.getStateId() < b.getStateId(); });

	// fill the vectors with the uncompressed transition table
	// the compression is done on this vectors
	assert(states.getSize() != 0);
	ret.table = new Vector!(Vector!(int))(states.getSize()-1);
	for(int i = 1; i < states.getSize(); i++) {
		ret.table.pushBack(new Vector!(int)(inputSet.getSize()));
		
		State s = states[i];
		ISRIterator!(dchar) isIt = inputSet.begin();
		for(; isIt.isValid(); isIt++) {
			ret.table[i-1].pushBack(s.getSingleTransition(*isIt).getStateId());
		}
	}
	assert(ret.table.getSize() != 0);

	println(__LINE__);
	MultiMap!(Row,dchar) rt = new MultiMap!(Row,dchar)(ISRType.HashTable);
	ISRIterator!(dchar) cit = inputSet.begin();
	println(__LINE__);
	for(int i = 0; cit.isValid(); cit++, i++) {
		Row row = (rt.insert(new Row(i, states.getSize()), *cit)).getKey();
		println(__LINE__,i);
		foreach(idx, sit; states) {
			if(idx > 0)
				row.row.pushBack(sit.getSingleTransition(*cit).getStateId());
		}
	}

	println(__LINE__);
	hurt.container.multimap.Iterator!(Row, dchar) mit = rt.begin();
	for(; mit.isValid(); mit++) {
		printf("%2d %c [",mit.getKey().idx, *mit);
		foreach(it; mit.getKey().row) {
			printf("%3d,", it);
		}
		println("]");
	}
	reduceRow(rt);
	println(__LINE__, rt.getSize());
	mit = rt.begin();
	for(; mit.isValid(); mit++) {
		printf("%2d %c [",mit.getKey().idx, *mit);
		foreach(it; mit.getKey().row) {
			printf("%3d,", it);
		}
		println("]");
	}

	printEqual(ret.table);
	printTable(ret.table);

	return ret;
}

void reduceRow(MultiMap!(Row, dchar) r) {
	hurt.container.multimap.Iterator!(Row, dchar) it = r.begin();
	outer: while(it.isValid()) {
		hurt.container.multimap.Iterator!(Row, dchar) jt = r.begin();
		while(jt.isValid() && jt.getKey().idx == it.getKey().idx) {
			println(__LINE__, it.getKey().idx, jt.getKey().idx);
			jt++;
		}
		println(__LINE__, it.getKey().idx, jt.getKey().idx);
		for(; jt.isValid(); jt++) {
			println(__LINE__, it.getKey().idx, jt.getKey().idx);
			if(it.getKey().row == jt.getKey().row && it.getKey().idx != jt.getKey().idx) {
				printfln("%4d %2d %2d", __LINE__, it.getKey().idx, jt.getKey().idx);
				dchar toAdd = *jt;
				r.remove(jt);
				r.insert(it.getKey(), toAdd);
				it = r.begin();
				continue outer;
			}
		}
		it++;
	}
}

void columnReduce(Vector!(Vector!(int)) t, Map!(dchar,int) c, 
		MultiMap!(int,dchar) h) {
	assert(t.getSize() > 0);

	for(int i = 0; i < t[0].getSize()-1; i++) {
		for(int j = i+1; j < t[0].getSize(); j++) {
			println(i,j, t[0].getSize());
			if(columnEqual(t, i, j)) {
				println(__LINE__);
				foreach(it; t) {
					it.remove(j);
				}
				println(__LINE__);
				hurt.container.multimap.Iterator!(int,dchar) it = h.range(j);
				for(; it.isValid(); it++) {
					c.insert(*it, i);
					h.insert(i, *it); 
				}
				h.removeRange(j);
				assert(cmapTest(h, c));
				println(__LINE__);
				reduceByOne(h,c,j);
				println(__LINE__);
				assert(cmapTest(h, c));
				j--;
			}
		}
	}
}

void reduceByOne(MultiMap!(int,dchar) mm, Map!(dchar,int) m, int j) {
	assert(mm.getSize() == m.getSize(), 
		conv!(size_t,string)(mm.getSize()) ~ " " ~ 
		conv!(size_t,string)(m.getSize()));

	hurt.container.multimap.Iterator!(int,dchar) it = mm.lower(++j);
	for(; it.isValid(); it++) {
		if(it.getKey() == j) {
			mm.insert(j-1, *it);
			m.insert(*it, j-1);
		} else {
			mm.removeRange(j);
			m.remove(j);
			j++;
			mm.insert(j-1, *it);
			m.insert(*it, j-1);
			if(mm.getSize() != m.getSize())
				printColumnMapping(mm,m);	
			assert(mm.getSize() == m.getSize(), 
				conv!(size_t,string)(mm.getSize()) ~ " " ~ 
				conv!(size_t,string)(m.getSize()));
		}
	}
	mm.removeRange(j);
	m.remove(j);
}

bool columnEqual(Vector!(Vector!(int)) t, int i1, int i2) {
	// check if the given indices i1 and i2 are valid, for all rows
	assert(t.getSize() > 0);
	foreach(Vector!(int) it; t) {
		assert(it.getSize() > i1);
		assert(it.getSize() > i2);
	}

	foreach(Vector!(int) it; t) {
		if(it[i1] != it[i2])
			return false;
	}
	return true;
}

bool rowEqual(Vector!(Vector!(int)) t, int i1, int i2) {
	// check if the given indices i1 and i2 are valid, for all rows
	assert(t.getSize() > i1);
	assert(t.getSize() > i2);
	assert(t[i1].getSize() == t[i2].getSize());

	for(size_t i = 0; i < t[i1].getSize(); i++) {
		if(t[i1][i] != t[i2][i]) {
			return false;
		}
	}

	return true;
}

bool cmapTest(MultiMap!(int,dchar) m1, Map!(dchar,int) m2) {
	hurt.container.multimap.Iterator!(int,dchar) mIt = m1.begin();

	for(; mIt.isValid(); mIt++) {
		dchar dc = *mIt;
		int one = m2.find(dc).getData();
		if(one != mIt.getKey()) {
			return false;	
		}
	}
	return true;
}

bool rmapTest(in int[] states, MultiMap!(int,int) map) {
	hurt.container.multimap.Iterator!(int,int) it = map.begin();
	for(; it.isValid(); it++) {
		if(states[*it] != it.getKey()) {
			return false;
		}
	}
	return true;
}

void printTable(Vector!(Vector!(int)) table) {
	printf("    ");
	for(int i = 0; i < table[0].getSize(); i++) {
		printf("%3d", i);
	}
	println();
	foreach(idx, it ; table) {
		printf("%3d ", idx);
		foreach(jt; it) {
			printf("%3d", jt);
		}
		println();
	}
}

void printEqual(Vector!(Vector!(int)) table) {
	println("equal column");
	for(int i = 0; i < table[0].getSize(); i++) {
		bool p = false;
		for(int j = i+1; j < table[0].getSize(); j++) {
			if(columnEqual(table, i, j)) {
				if(!p)
					printf("%2d: ",i);
				p = true;
				printf("%3d",j);
			}
		}
		if(p)
			println();
	}

	println("equal rows");
	for(int i = 0; i < table.getSize(); i++) {
		bool p = false;
		for(int j = i+1; j < table.getSize(); j++) {
			if(rowEqual(table, i, j)) {
				if(!p)
					printf("%2d: ",i);
				p = true;
				printf("%3d",j);

			}
		}
		if(p)
			println();
	}
	println();
}

void printColumnMapping(MultiMap!(int,dchar) mm, Map!(dchar,int) m) {
	hurt.container.multimap.Iterator!(int,dchar) it = mm.begin();
	print("mmp ");
	for(; it.isValid(); it++) {
		printf("%d:%c ", it.getKey(), *it);
	}
	println();

	ISRIterator!(MapItem!(dchar,int)) jt = m.begin();
	print("map ");
	for(; jt.isValid(); jt++) {
		printf("%d:%c ", **jt, (*jt).getKey());
	}
	println();
}
