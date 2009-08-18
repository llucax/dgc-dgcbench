// Written by Kevin Bealer <kevinbealer@gmail.com>
// Found at http://www.digitalmars.com/webnews/newsgroups.php?art_group=digitalmars.D.announce&article_id=6978
// Sightly modified by Leandro Lucarella <llucax@gmail.com>
// (changed not to print anything and lower the total iterations; ported to
// Tango)

import tango.core.Memory;
import tango.math.random.Random;

int main(char[][] args)
{
     int[][] stuff;

     int NUM = 2_000_000;

     stuff.length = 20;

     GC.disable();

     auto rand = new Random();

     for(int i = 0; i < 200; i++) {
         int[] arr = new int[NUM];

         for(int j = 0; j < arr.length; j++) {
             rand(arr[j]);
         }

         int zig = i;
         if (zig > stuff.length)
             zig = rand.uniform!(int) % stuff.length;

         stuff[zig] = arr;

         if (i == 20) {
             GC.enable();
         }
     }

     return 0;
}

