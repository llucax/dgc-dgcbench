// Written by Oskar Linde <oskar.lindeREM@OVEgmail.com>
// Found at http://www.digitalmars.com/webnews/newsgroups.php?art_group=digitalmars.D&article_id=46407
// Sightly modified by Leandro Lucarella <llucax@gmail.com>
// (changed the main loop not to be endless and ported to Tango)

import tango.math.random.Random;

const IT = 5_000; // original: 50_000

void main() {
	// The real memory use, ~55 KiB (original: ~20 MiB)
	uint[] data;
	data.length = 10_000; // original: 5_000_000
	auto rand = new Random();
	foreach (ref x; data)
		rand(x);
	for (int i = 0; i < IT; ++i) {
		// simulate reading a few kb of data (14 KiB +/- 10 KiB)
		uint[] incoming;
		incoming.length = 1000 + rand.uniform!(uint) % 5000;
		foreach (ref x; incoming)
			rand(x);
		// do something with the data...
	}
}

