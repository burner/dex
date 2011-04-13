module dex.parseerror;

class ParseError : Exception {
	this(string str) {
		super(str);
	}
}
