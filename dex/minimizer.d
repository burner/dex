module dex.minimizer;

import dex.state;

import hurt.conv.conv;
import hurt.container.dlst;
import hurt.container.vector;
import hurt.container.list;
import hurt.container.set;
import hurt.container.map;
import hurt.container.multimap;

import std.stdio;

private Vector!(Vector!(State)) makeInitPartitions(
		DLinkedList!(State) oldStates, Map!(State,long) states) {
	Vector!(Vector!(State)) ret = new Vector!(Vector!(State))();
	ret.append(new Vector!(State)());
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
			ret[2].append(it);
		}
	}
	return ret;
}

private Vector!(State) finalizeGroups(Vector!(Vector!(State)) old,
		Set!(char) inputSet, Map!(State,long) states) {
	Vector!(State) ret = new Vector!(State)();
	// make the states gone fill them later
	foreach(idx,it; old)
		ret.append(new State(conv!(ulong,int)(idx)));

	assert(ret.getSize() == old.getSize());

	for(size_t i; i < old.getSize(); i++) {
		foreach(c; inputSet) {
			ret[i].addTransition(c, 
				ret[states.find(old[0][0].getSingleTransition(c)).getData()]);
		}
	}

	for(size_t i; i < old.getSize(); i++) {
		foreach(it; old[i]) {
			foreach(jt; it.getAcceptingStates()) {
				ret[i].setAcceptingState(jt);
			}
		}
	}

	return ret;
}

public Vector!(State) minimize(T)(DLinkedList!(State) oldStates, 
		Set!(T) inputSet) {
	Map!(State,long) states = new Map!(State,long)();
	Vector!(Vector!(State)) groups = makeInitPartitions(oldStates, states);
	size_t oldSize = groups.getSize();
	assert(oldSize == 3, "there should be 3 partitions by now");
	size_t grCnt = groups.getSize();
	outer: do {
		oldSize = groups.getSize();
		for(size_t i = 0; i < grCnt; i++) {
			Vector!(State) transGroup = groups[i];
			if(transGroup.getSize() <= 1)
				continue;

			bool added = false;	
			Vector!(State) newGroup = new Vector!(State)();
			State first = transGroup[0];
			size_t groupSize = transGroup.getSize();
			for(size_t j = 1; j < groupSize; j++) {
				State next = transGroup[1];
				foreach(c; inputSet) {
					State gotoFirst = first.getSingleTransition(c);
					State gotoNext = next.getSingleTransition(c);
					if(states.find(gotoFirst) != states.find(gotoNext)) {
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
						break;
					}
				}
			}
		}
	} while(oldSize != groups.getSize());
	return finalizeGroups(groups, inputSet,states);	
}
