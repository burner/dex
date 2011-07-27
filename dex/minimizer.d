module dex.minimizer;

import dex.state;

import hurt.conv.conv;
import hurt.container.dlst;
import hurt.container.list;
import hurt.container.set;
import hurt.container.map;
import hurt.container.isr;
import hurt.container.multimap;

import std.stdio;

Map!(State,int) initGroups(DLinkedList!(State) os, MultiMap!(int,State) gr) {
	Map!(State,int) ret = new Map!(State,int)(ISRType.HashTable);
	foreach(it; os) {
		if(it.getStateId() == -1) {
			ret.insert(it, 0);
			gr.insert(0,it);
		}
		if(it.isAccepting()) {
			ret.insert(it, 1);
			gr.insert(1,it);
		} else {
			ret.insert(it, 2);
			gr.insert(2,it);
		}
	}
	return ret;
}

DLinkedList!(State) mergeMemberOfGroup(MultiMap!(int,State) mm) {
	DLinkedList!(State) ret = new DLinkedList!(State)();
	foreach(group; mm.keys()) {
			
	}
	return ret;
}

DLinkedList!(State) minimize(DLinkedList!(State) old, Set!(char) ic) {
	MultiMap!(int,State) gr = new MultiMap!(int,State)();
	Map!(State,int) lo = initGroups(old, gr);
	size_t os;

	do {
		os = gr.getCountKeys();
		foreach(grIt; gr.keys()) {
			DLinkedList!(State) ne = new DLinkedList!(State)();
			hurt.container.multimap.Iterator!(int,State) fi = gr.lower(grIt);
			hurt.container.multimap.Iterator!(int,State) it = gr.range(grIt); it++;
			while(it.isValid()) {
				foreach(icIt; ic) {
					int fiNe = *lo.find((*fi).getSingleTransition(icIt));
					int itNe = *lo.find((*it).getSingleTransition(icIt));
					if(fiNe != itNe) {
						State re = *it;	
						gr.remove(it);
						ne.pushBack(re);
						it = gr.range(grIt); it++;
					}
				}
				it++;
			}
			if(!ne.isEmpty()) {
				foreach(neIt; ne) {
					lo.insert(neIt, conv!(size_t,int)(os));
					gr.insert(conv!(size_t,int)(os), neIt);
				}
			}
		}

	} while(os != gr.getCountKeys());
	return null;
}
