module dex.input;

import hurt.container.vector;
import hurt.io.stream;
import hurt.io.file;
import hurt.io.stdio;

class RegexCode {
	private string regex;
	private string code;
}

class Input {
	private string filename;
	private string userCode;
	private File ins;
	private Vector!(RegexCode) regexCode;

	private static bool isWellFormedFilename(in string filename) {
		if(filename.length <= 4)
			return false;

		if(filename[$-4..$] != ".dex")
			return false;

		return true;
	}

	this(string filename) {
		this.filename = filename;
		this.regexCode = new Vector!(RegexCode)(16);
		if(!isWellFormedFilename(filename))
			throw new Exception("Filename not well formed");
	
		if(!exists(this.filename))
			throw new Exception("File does not Exist");

		this.ins = new File(filename);
	}

	~this() {
		if(this.ins.isOpen())
			this.ins.close();
		else
			println("file should have been opened");

		assert(!this.ins.isOpen(), "file should not be open");
	}
}
