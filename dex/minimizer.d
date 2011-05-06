module dex.minimizer;

import dex.state;

import hurt.conv.conv;
import hurt.container.vector;
import hurt.container.dlst;
import hurt.container.set;

import std.stdio;

public void makeFirstPartition(DLinkedList!(State) oldStates, DLinkedList!(Set!(State)) partitions) {
	auto aState = partitions.pushBack(new Set!(State)());
	auto oState = partitions.pushBack(new Set!(State)());
	foreach(it; oldStates) {
		if(it.isAccepting()) {
			(*aState).insert(it);
		} else {
			(*oState).insert(it);
		}
	}
	assert( (*aState).getSize() + (*oState).getSize() == oldStates.getSize(), 
		"not all states placed in a partition");
}

public DLinkedList!(State) minimize(T)(DLinkedList!(State) oldStates, Set!(T) inputSet) {
	DLinkedList!(Set!(State)) partitions = new DLinkedList!(Set!(State))();	
	makeFirstPartition(oldStates, partitions);
	assert(partitions.getSize() == 2, "should have size of 2");
	size_t oldSize = partitions.getSize();
	// as long as there are new partitions
	while(oldSize != partitions.getSize()) {
		// check every input character
		foreach(charIt; inputSet.values()) {
			// against every partition
			foreach(parIt; partitions) {
				// and in every partition against every state
				foreach(stateIt; parIt.values()) {
					State next = stateIt.getTransition(charIt)[0];
					if(next is null || !parIt.contains(next)) {
						Set!(State) tmp = new Set!(State)();
						tmp.insert(stateIt);
						parIt.remove(stateIt);
						break;
					}

				}
			}
		}

	}
	
	return null;
}

