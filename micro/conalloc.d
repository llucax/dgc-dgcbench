// Written by Leandro Lucarella
//
// The goal of this program is to do very CPU intensive work in threads

import tango.core.Thread: Thread;
import tango.core.sync.Atomic: atomicStore, atomicLoad, atomicAdd;
import tango.io.device.File: File;
import tango.util.digest.Sha512: Sha512;
import tango.util.Convert: to;

auto N = 100;
auto NT = 2;
ubyte[] BYTES;
int running; // Atomic

void main(char[][] args)
{
	auto fname = args[0];
	if (args.length > 3)
		fname = args[3];
	if (args.length > 2)
		NT = to!(int)(args[2]);
	if (args.length > 1)
		N = to!(int)(args[1]);
	N /= NT;
	atomicStore(running, NT);
	BYTES = cast(ubyte[]) File.get(fname);
	auto threads = new Thread[NT];
	foreach(ref thread; threads) {
		thread = new Thread(&doSha);
		thread.start();
	}
	while (atomicLoad(running)) {
		auto a = new void[](BYTES.length / 4);
		a[] = cast(void[]) BYTES[];
		Thread.yield();
	}
	foreach(thread; threads)
		thread.join();
}

void doSha()
{
	for (size_t i = 0; i < N; i++) {
		auto sha = new Sha512;
		sha.update(BYTES);
	}
	atomicAdd(running, -1);
}

