class Set(T) {
	class bNode(T) {
	    // By value storage of the data
	    T key;
	 
	    // Combine the two branches into an array to optimize the logic
	    bNode link[2];
	 
	    // Null the branches so we don't have to do it in the implementation
	    this() {
	        // Left branch
	        link[0] = null;
	 
	        // Right branch
	        link[1] = null;
	    }
	}
}
 
class BST(T) {
    // Number of nodes in the tree
    int count;
 
    // Pointer to the root of the tree
    bNode!(T) root;
	void clear(bNode!(T) ptr) {
	    if(ptr !is null) {
	        clear(ptr.link[0]);
	        clear(ptr.link[1]);
	    }
	}
	 
	bool search(const T item, bNode!(T) curr, bNode!(T) prev, ref bool lr) const {
	    while (curr !is null) {
	        if(item == curr.key)
		    return true;
	        lr = (item > curr.key);
	        prev = curr;
	        curr = curr.link[lr];
	    }
	    return false;
	}
	 
	T inOrder(bNode!(T) ptr) const {
	    bool lr = 1;
	    T temp;
	    bNode!(T) prev = ptr;
	 
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
	 
	int subNodes(bNode!(T) ptr) const {
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
	 
	int height(bNode!(T) ptr) const {
	    if(ptr is null)
	        return 0;
	 
	    int lt = height(ptr.link[0]), rt = height(ptr.link[1]);
	 
	    if(lt < rt)
	        return rt + 1;
	    return lt + 1;
	}
	 
	bNode!(T) minmax(bNode!(T) ptr, ref bool lr) const {
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
	 
	bool insert(const T item) {
	    if(root is null) {
	        root = new bNode!(T);
	        root.key = item;
	        count++;
	        return true;
	    }
	    bool lr;
	    bNode!(T) curr = root, prev;
	 
	    if(search(item, curr, prev, lr))
	        return false;
	    prev.link[lr] = new bNode!(T);
	    prev.link[lr].key = item;
	    count++;
	    return true;
	}
	 
	bool remove(const T item) {
	    bool lr = 1;
	    bNode!(T) curr = root, prev;
	 
	    if(!search(item, curr, prev, lr))
	        return false;
	    int s = subNodes(curr);
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
	 
	bool search(const T item, ref T ptr) const {
	    bool found;
	    bNode!(T) curr = root, prev;
	 
	    found = search(item, curr, prev, found);
	    ptr = curr.key;
	    return found;
	}
	 
	T min() const {
	    return minmax(root, 0).key;
	}
	 
	T max() const {
	    return minmax(root, 1).key;
	}
	 
	int size() const {
	    return count;
	}
	 
	int height() const {
	    return height(root);
	}
}
