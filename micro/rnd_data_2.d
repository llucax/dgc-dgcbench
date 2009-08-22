// Written by Kevin Bealer <kevinbealer@gmail.com>
// Found at http://www.digitalmars.com/webnews/newsgroups.php?art_group=digitalmars.D.announce&article_id=6978
// Sightly modified by Leandro Lucarella <llucax@gmail.com>
// (changed not to print anything and lower the total iterations; ported to
// Tango)

import tango.math.random.Random;

const N = 2_000_000;
const L = 20;
const I = 50; // original: 200

int main(char[][] args)
{
     int[][] stuff;

     stuff.length = L;

     auto rand = new Random();

     for(int i = 0; i < I; i++) {
         int[] arr = new int[N];

         for(int j = 0; j < arr.length; j++) {
             rand(arr[j]);
         }

         int zig = i;
         if (zig > stuff.length)
             zig = rand.uniform!(int) % stuff.length;

         stuff[zig] = arr;
     }

     return 0;
}

