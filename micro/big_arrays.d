// Written by Babele Dunnit <babele.dunnit@gmail.com>
// Found at http://www.digitalmars.com/webnews/newsgroups.php?art_group=digitalmars.D&article_id=54084
// Sightly modified by Leandro Lucarella <llucax@gmail.com>
// (some readability improvements and output removed)

const IT = 100; // original: 300
const N1 = 200; // original: 20_000
const N2 = 400; // original: 40_000

class Individual
{
	Individual[20] children;
}

class Population
{

	void grow()
	{
		foreach(inout individual; individuals)
		{
			individual = new Individual;
		}
	}

	Individual[N1] individuals;
}

version = loseMemory;

int main(char[][] args)
{

	Population testPop1 = new Population;
	Population testPop2 = new Population;

	Individual[N2] indi;

	for(int i = 0; i < IT; i++)
	{
		testPop1.grow();
		testPop2.grow();

		version (loseMemory){
			indi[] = testPop1.individuals ~ testPop2.individuals;
		}

		version (everythingOk){
			indi[0..N1] = testPop1.individuals;
			indi[N1..N2] = testPop2.individuals;
		}
	}

	return 0;
}

