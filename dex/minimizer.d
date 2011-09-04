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
	Map!(dchar,Column) inputChar;
}

class Column {
	int idx;
	Vector!(int) row;

	this(int idx, size_t size) {
		this.idx = idx;
		this.row = new Vector!(int)(size);
	}

	this(int idx, Vector!(int) row) {
		this.idx = idx;
		this.row = row;
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

alias Column Row;

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

	Map!(dchar,Column) co = new Map!(dchar,Column)();
	ISRIterator!(dchar) cit = inputSet.begin();
	for(int i = 0; cit.isValid(); cit++, i++) {
		Column row = new Column(i, states.getSize());
		co.insert(*cit, row);
		foreach(idx, sit; states) {
			if(idx > 0)
				row.row.pushBack(sit.getSingleTransition(*cit).getStateId());
		}
	}

	/*ISRIterator!(MapItem!(dchar, Column)) mit = co.begin();
	for(; mit.isValid(); mit++) {
		printf("%c [",(*mit).getKey());
		foreach(it; (*mit).getData().row) {
			printf("%3d,", it);
		}
		println("]");
	}

	printEqual(ret.table);*/
	columnReduce(ret.table);
	columnRemap(ret.table, co);
	ret.inputChar = co;

	/*mit = co.begin();
	for(; mit.isValid(); mit++) {
		printf("%c %3d [",(*mit).getKey(), (*mit).getData().idx);
		foreach(it; (*mit).getData().row) {
			printf("%3d,", it);
		}
		println("]");
	}
	printTable(ret.table);*/

	Map!(int,Row) r = new Map!(int,Row)();
	foreach(idx, it; ret.table) {
		r.insert(conv!(size_t,int)(idx), 
			new Row(conv!(size_t,int)(idx), it.clone));	
	}
	
	/*ISRIterator!(MapItem!(int,Row)) rit = r.begin();
	for(; rit.isValid(); rit++) {
		printf("%c %3d [",(*rit).getKey(), (*rit).getData().idx);
		foreach(it; (*rit).getData().row) {
			printf("%3d,", it);
		}
		println("]");
	}*/

	rowReduce(ret.table);
	rowRemap(ret.table, r);

	ret.state = new int[r.getSize()];
	ISRIterator!(MapItem!(int,Row)) it = r.begin();
	for(size_t idx = 0; it.isValid(); idx++, it++) {
		assert((*it).getKey() == idx);
		ret.state[idx] = (*it).getData().idx;
	}

	/*rit = r.begin();
	for(; rit.isValid(); rit++) {
		printf("%3d %3d [",(*rit).getKey(), (*rit).getData().idx);
		foreach(it; (*rit).getData().row) {
			printf("%3d,", it);
		}
		println("]");
	}

	printTable(ret.table);*/

	return ret;
}

bool compareColumn(Vector!(int) r1, Vector!(Vector!(int)) r2, size_t r2idx) {
	assert(r2.getSize > 0);
	assert(r2[0].getSize() > r2idx);
	assert(r1.getSize() == r2.getSize());
	
	foreach(idx, it; r2) {
		if(it[r2idx] != r1[idx]) {
			return false;
		}
	}
	return true;
}

void columnRemap(Vector!(Vector!(int)) t, Map!(dchar,Row) r) {
	ISRIterator!(MapItem!(dchar, Row)) it = r.begin();
	for(; it.isValid(); it++) {
		for(size_t idx = 0; idx < t[0].getSize(); idx++) {
			if(compareColumn((*it).getData().row, t, idx)) {
				(*it).getData().idx = conv!(size_t,int)(idx);
				break;
			}
		}
	}
}

void columnReduce(Vector!(Vector!(int)) t) {
	assert(t.getSize() > 0);

	for(int i = 0; i < t[0].getSize()-1; i++) {
		for(int j = i+1; j < t[0].getSize(); j++) {
			//println(i,j, t[0].getSize());
			if(columnEqual(t, i, j)) {
				//println(__LINE__);
				foreach(it; t) {
					it.remove(j);
				}
				//println(__LINE__);
				j--;
			}
		}
	}
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

bool compareRow(Vector!(int) r1, Vector!(Vector!(int)) r2, size_t r2idx) {
	assert(r2.getSize() > r2idx);
	assert(r1.getSize() == r2[0].getSize());
	
	foreach(idx, it; r2[r2idx]) {
		if(it != r1[idx]) {
			return false;
		}
	}
	return true;
}

void rowRemap(Vector!(Vector!(int)) t, Map!(int,Row) r) {
	ISRIterator!(MapItem!(int, Row)) it = r.begin();
	for(; it.isValid(); it++) {
		for(size_t idx = 0; idx < t[0].getSize(); idx++) {
			if(compareRow((*it).getData().row, t, idx)) {
				(*it).getData().idx = conv!(size_t,int)(idx);
				break;
			}
		}
	}
}

void rowReduce(Vector!(Vector!(int)) t) {
	assert(t.getSize() > 0);
	for(int i = 0; i < t.getSize()-1; i++) {
		for(int j = i+1; j < t.getSize(); j++) {
			if(t[i] == t[j]) {
				t.remove(j);
				j--;
			}
		}
	}
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
