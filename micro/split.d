// Written by bearophile <bearophileHUGS@lycos.com>
// Fount at http://www.digitalmars.com/webnews/newsgroups.php?art_group=digitalmars.D&article_id=67673
// Sightly modified by Leandro Lucarella <llucax@gmail.com>
// (removed timings)

import tango.io.device.File: File;
import tango.text.Util: delimit;
import tango.util.Convert: to;

int main(char[][] args) {
	if (args.length < 2)
		return 1;
	auto txt = cast(byte[]) File.get(args[1]);
	auto n = (args.length > 2) ? to!(uint)(args[2]) : 1;
	if (n < 1)
		n = 1;
	while (--n)
		txt ~= txt;
	auto words = delimit!(byte)(txt, cast(byte[]) " \t\n\r");
	return !words.length;
}

