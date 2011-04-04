class Set(T) {
	private class BNode(T) {
	    // By value storage of the data
	    T key;
	 
	    // Combine the two branches into an array to optimize the logic
	    BNode link[2];
	 
	    // Null the branches so we don't have to do it in the implementation
	    this() {
	        // Left branch
	        link[0] = null;
	 
	        // Right branch
	        link[1] = null;
	    }
	}
 
    // Number of nodes in the tree
    int count;
 
    // Pointer to the root of the tree
    BNode!(T) root;

	void clear(BNode!(T) ptr) {
	    if(ptr !is null) {
	        clear(ptr.link[0]);
	        clear(ptr.link[1]);
	    }
	}
	 
	bool search(T item, BNode!(T) curr, BNode!(T) prev, ref bool lr) {
	    while (curr !is null) {
	        if(item == curr.key)
		    return true;
	        lr = (item > curr.key);
	        prev = curr;
	        curr = curr.link[lr];
	    }
	    return false;
	}
	 
	T inOrder(BNode!(T) ptr) {
	    bool lr = 1;
	    T temp;
	    BNode!(T) prev = ptr;
	 
	    ptr = ptr.link[1];
	    while (ptr.link[0] !is null) {
	        prev = ptr;
	        ptr = ptr.link[lr = 0];
	    }
	    prev.link[lr] = ptr.link[1];
	    temp = ptr.key;
	    //delete ptr;
	    return temp;
	}
	 
	int suBNodes(BNode!(T) ptr) {
	    if(ptr.link[1] !is null) {
	        if(ptr.link[0] !is null)
	            return 3;
	        else
	            return 2;
	    }
	    else if(ptr.link[0] !is null)
	        return 1;
	    else
	        return 0;
	}
	 
	int height(BNode!(T) ptr) {
	    if(ptr is null)
	        return 0;
	 
	    int lt = height(ptr.link[0]), rt = height(ptr.link[1]);
	 
	    if(lt < rt)
	        return rt + 1;
	    return lt + 1;
	}
	 
	BNode!(T) minmax(BNode!(T) ptr, ref int lr) {
	    while (ptr.link[lr] !is null)
	        ptr = ptr.link[lr];
	    return ptr;
	}
	 
	this() {
	    root = null;
	    count = 0;
	}
	 
	~this() {
	    clear(root);
	}
	 
	void clear() {
	    clear(root);
	    root = null;
	    count = 0;
	}
	 
	bool isEmpty() const {
	    return (root is null);
	}
	 
	bool insert(T item) {
	    if(root is null) {
	        root = new BNode!(T);
	        root.key = item;
	        count++;
	        return true;
	    }
	    bool lr;
	    BNode!(T) curr = root, prev;
	 
	    if(search(item, curr, prev, lr))
	        return false;
	    prev.link[lr] = new BNode!(T);
	    prev.link[lr].key = item;
	    count++;
	    return true;
	}
	 
	bool remove(T item) {
	    bool lr = 1;
	    BNode!(T) curr = root, prev;
	 
	    if(!search(item, curr, prev, lr))
	        return false;
	    int s = suBNodes(curr);
	    switch(s) {
	    	case 0:
	    	case 1:
	    	case 2:
	    	    if(curr == root)
	    	        root = curr.link[(s > 1)];
	    	    else
	    	        prev.link[lr] = curr.link[(s > 1)];
	    	    //delete curr;
	    	    break;
	    	case 3:
	    	    curr.key = inOrder(curr);
	    }
	    count--;
	    return true;
	}
	 
	bool search(T item, out T ptr) {
	    bool found;
	    BNode!(T) curr = this.root, prev;
	 
	    found = search(item, curr, prev, found);
	    ptr = curr.key;
	    return found;
	}
	 
	T min() {
		int tmp = 0;
	    return this.minmax(this.root, tmp).key;
	}
	 
	T max() {
		int tmp = 1;
	    return this.minmax(this.root, tmp).key;
	}
	 
	int size() const {
	    return count;
	}
	 
	int height() {
	    return height(root);
	}
}

unittest {
	Set!(int) intTest = new Set!(int)();
	int[] t = [123,13,5345,752,12,3,1,654,22];
	foreach(idx,it;t) {
		assert(intTest.insert(it));
		foreach(jt;t[0..idx]) {
			assert(intTest.search(jt, null));
		}
		foreach(jt;t[idx+1..$]) {
			assert(!intTest.search(jt, null));
		}
	}
	intTest.validate();
	foreach(idx,it;t) {
		assert(!intTest.insert(it), conv!(int,string)(it));
	}
	intTest.validate();
}
