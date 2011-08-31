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

	ret.state = new int[states.getSize()-1];
	ret.inputChar = new Map!(dchar,int)();

	// use this mapping to find the dchar the given column index points to
	// than use this information to make the dchar point to the new index
	// after the column was changed
	Map!(int,dchar) map = new Map!(int,dchar)();

	// fill the datastructures
	ISRIterator!(dchar) isIt = inputSet.begin();
	for(int i = 0; i < inputSet.getSize(); isIt++, i++) {
		ret.inputChar.insert(*isIt, i);
		map.insert(i, *isIt);
	}
	assert(mapTest(map, ret.inputChar));

	return ret;
}

bool mapTest(Map!(int,dchar) m1, Map!(dchar,int) m2) {
	ISRIterator!(MapItem!(int,dchar)) mIt = m1.begin();

	for(; mIt.isValid(); mIt++) {
		dchar dc = (*mIt).getData();
		int one = m2.find(dc).getData();
		if(one != (*mIt).getKey()) {
			return false;	
		}
	}
	return true;
}
