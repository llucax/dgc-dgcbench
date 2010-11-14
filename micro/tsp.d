/**
A D implementation of the "tsp" Olden benchmark, the traveling
salesman problem.

R. Karp, "Probabilistic analysis of partitioning algorithms for the
traveling-salesman problem in the plane."  Mathematics of Operations Research
2(3):209-224, August 1977.

Converted to D and optimized by leonardo maffi, V.1.0, Oct 29 2009.

Removed output unless an option is passed by Leandro Lucarella, 2010-08-04.
Downloaded from http://www.fantascienza.net/leonardo/js/
                http://www.fantascienza.net/leonardo/js/dolden_tsp.zip
*/

version (Tango) {
    import tango.stdc.stdio: printf, fprintf, stderr;
    import tango.stdc.time: CLOCKS_PER_SEC, clock;
    import tango.math.Math: sqrt, log;

    import Integer = tango.text.convert.Integer;
    alias Integer.parse toInt;
} else {
    import std.c.stdio: printf, fprintf, stderr;
    import std.c.time: CLOCKS_PER_SEC, clock;
    import std.math: sqrt, log;

    version (D_Version2) {
        import std.conv: to;
        alias to!(int, char[]) toInt;
    } else {
        import std.conv: toInt;
    }
}


double myclock() {
    return clock() / cast(double)CLOCKS_PER_SEC;
}


/**
Basic uniform random generator: Minimal Standard in Park and
Miller (1988): "Random Number Generators: Good Ones Are Hard to
Find", Comm. of the ACM, 31, 1192-1201.
Parameters: m = 2^31-1, a=48271.

Very simple portable random number generator adapted
from Pascal code by Jesper Lund:
http://www.gnu-pascal.de/crystal/gpc/en/mail1390.html
*/
final class Random {
    const int m = int.max;
    const int a = 48271;
    const int q = m / a;
    const int r = m % a;

    public int seed;

    this(int the_seed) {
        this.seed = the_seed;
    }

    public double nextDouble() {
        int k = seed / q;
        seed = a * (seed - k * q) - r * k;
        if (seed < 1)
        seed += m;
        return cast(double)seed / m;
    }

    public int nextInt(int max) {
        int n = max + 1;
        int k = cast(int)(n * this.nextDouble());
        return (k == n) ? k - 1 : k;
    }
}



/**
* A class that represents a node in a binary tree.  Each node represents
* a city in the TSP benchmark.
**/
final class Tree {
    /**
    * The number of nodes (cities) in this subtree
    **/
    private int sz;

    /**
    * The coordinates that this node represents
    **/
    private double x, y;

    /**
    * Left and right child of tree
    **/
    private Tree left, right;

    /**
    * The next pointer in a linked list of nodes in the subtree.  The list
    * contains the order of the cities to visit.
    **/
    private Tree next;

    /**
    * The previous pointer in a linked list of nodes in the subtree. The list
    * contains the order of the cities to visit.
    **/
    private Tree prev;

    static Random rnd;

    // used by the random number generator
    private const double M_E2  = 7.3890560989306502274;
    private const double M_E3  = 20.08553692318766774179;
    private const double M_E6  = 403.42879349273512264299;
    private const double M_E12 = 162754.79141900392083592475;

    public static void initRnd(int seed) {
        rnd = new Random(seed);
    }

    /**
    * Construct a Tree node (a city) with the specified size
    * @param size the number of nodes in the (sub)tree
    * @param x the x coordinate of the city
    * @param y the y coordinate of the city
    * @param left the left subtree
    * @param right the right subtree
    **/
    this(int size, double x, double y, Tree l, Tree r) {
        sz = size;
        this.x = x;
        this.y = y;
        left = l;
        right = r;
        next = null;
        prev = null;
    }

    /**
    * Find Euclidean distance between this node and the specified node.
    * @param b the specified node
    * @return the Euclidean distance between two tree nodes.
    **/
    double distance(Tree b) {
        return sqrt((x - b.x) * (x - b.x) + (y - b.y) * (y - b.y));
    }

    /**
    * Create a list of tree nodes.  Requires root to be the tail of the list.
    * Only fills in next field, not prev.
    * @return the linked list of nodes
    **/
    Tree makeList() {
        Tree myleft, myright, tleft, tright;
        Tree retval = this;

        // head of left list
        if (left !is null)
            myleft = left.makeList();
        else
            myleft = null;

        // head of right list
        if (right !is null)
            myright = right.makeList();
        else
            myright = null;

        if (myright !is null) {
            retval = myright;
            right.next = this;
        }

        if (myleft !is null) {
            retval = myleft;
            if (myright !is null)
                left.next = myright;
            else
                left.next = this;
        }
        next = null;

        return retval;
    }

    /**
    * Reverse the linked list.  Assumes that there is a dummy "prev"
    * node at the beginning.
    **/
    void reverse() {
        Tree prev = this.prev;
        prev.next = null;
        this.prev = null;
        Tree back = this;
        Tree tmp = this;

        // reverse the list for the other nodes
        Tree next;
        for (Tree t = this.next; t !is null; back = t, t = next) {
            next = t.next;
            t.next = back;
            back.prev = t;
        }

        // reverse the list for this node
        tmp.next = prev;
        prev.prev = tmp;
    }

    /**
    * Use closest-point heuristic from Cormen, Leiserson, and Rivest.
    * @return a
    **/
    Tree conquer() {
        // create the list of nodes
        Tree t = makeList();

        // Create initial cycle
        Tree cycle = t;
        t = t.next;
        cycle.next = cycle;
        cycle.prev = cycle;

        // Loop over remaining points
        Tree donext;
        for ( ; t !is null; t = donext) {
            donext = t.next; /* value won't be around later */
            Tree min = cycle;
            double mindist = t.distance(cycle);
            for (Tree tmp = cycle.next; tmp != cycle; tmp = tmp.next) {
                double test = tmp.distance(t);
                if (test < mindist) {
                    mindist = test;
                    min = tmp;
                }
            }

            Tree next = min.next;
            Tree prev = min.prev;

            double mintonext = min.distance(next);
            double mintoprev = min.distance(prev);
            double ttonext = t.distance(next);
            double ttoprev = t.distance(prev);

            if ((ttoprev - mintoprev) < (ttonext - mintonext)) {
                // insert between min and prev
                prev.next = t;
                t.next = min;
                t.prev = prev;
                min.prev = t;
            } else {
                next.prev = t;
                t.next = next;
                min.next = t;
                t.prev = min;
            }
        }

        return cycle;
    }

    /**
    * Merge two cycles as per Karp.
    * @param a a subtree with one cycle
    * @param b a subtree with the other cycle
    **/
    Tree merge(Tree a, Tree b) {
        // Compute location for first cycle
        Tree min = a;
        double mindist = distance(a);
        Tree tmp = a;
        for (a = a.next; a != tmp; a = a.next) {
            double test = distance(a);
            if (test < mindist) {
                mindist = test;
                min = a;
            }
        }

        Tree next = min.next;
        Tree prev = min.prev;
        double mintonext = min.distance(next);
        double mintoprev = min.distance(prev);
        double ttonext   = distance(next);
        double ttoprev   = distance(prev);

        Tree p1, n1;
        double tton1, ttop1;
        if ((ttoprev - mintoprev) < (ttonext - mintonext)) {
            // would insert between min and prev
            p1 = prev;
            n1 = min;
            tton1 = mindist;
            ttop1 = ttoprev;
        } else {
            // would insert between min and next
            p1 = min;
            n1 = next;
            ttop1 = mindist;
            tton1 = ttonext;
        }

        // Compute location for second cycle
        min = b;
        mindist = distance(b);
        tmp = b;
        for (b = b.next; b != tmp; b = b.next) {
            double test = distance(b);
            if (test < mindist) {
                mindist = test;
                min = b;
            }
        }

        next = min.next;
        prev = min.prev;
        mintonext = min.distance(next);
        mintoprev = min.distance(prev);
        ttonext = this.distance(next);
        ttoprev = this.distance(prev);

        Tree p2, n2;
        double tton2, ttop2;
        if ((ttoprev - mintoprev) < (ttonext - mintonext)) {
            // would insert between min and prev
            p2 = prev;
            n2 = min;
            tton2 = mindist;
            ttop2 = ttoprev;
        } else {
            // would insert between min andn ext
            p2 = min;
            n2 = next;
            ttop2 = mindist;
            tton2 = ttonext;
        }

        // Now we have 4 choices to complete:
        // 1:t,p1 t,p2 n1,n2
        // 2:t,p1 t,n2 n1,p2
        // 3:t,n1 t,p2 p1,n2
        // 4:t,n1 t,n2 p1,p2
        double n1ton2 = n1.distance(n2);
        double n1top2 = n1.distance(p2);
        double p1ton2 = p1.distance(n2);
        double p1top2 = p1.distance(p2);

        mindist = ttop1 + ttop2 + n1ton2;
        int choice = 1;

        double test = ttop1 + tton2 + n1top2;
        if (test < mindist) {
            choice = 2;
            mindist = test;
        }

        test = tton1 + ttop2 + p1ton2;
        if (test < mindist) {
            choice = 3;
            mindist = test;
        }

        test = tton1 + tton2 + p1top2;
        if (test < mindist)
            choice = 4;

        switch (choice) {
            case 1:
                // 1:p1,this this,p2 n2,n1 -- reverse 2!
                n2.reverse();
                p1.next = this;
                this.prev = p1;
                this.next = p2;
                p2.prev = this;
                n2.next = n1;
                n1.prev = n2;
                break;

            case 2:
                // 2:p1,this this,n2 p2,n1 -- OK
                p1.next = this;
                this.prev = p1;
                this.next = n2;
                n2.prev = this;
                p2.next = n1;
                n1.prev = p2;
                break;

            case 3:
                // 3:p2,this this,n1 p1,n2 -- OK
                p2.next = this;
                this.prev = p2;
                this.next = n1;
                n1.prev = this;
                p1.next = n2;
                n2.prev = p1;
                break;

            default: // case 4:
                // 4:n1,this this,n2 p2,p1 -- reverse 1!
                n1.reverse();
                n1.next = this;
                this.prev = n1;
                this.next = n2;
                n2.prev = this;
                p2.next = p1;
                p1.prev = p2;
                break;
        }

        return this;
    } // end merge

    /**
    * Compute TSP for the tree t. Use conquer for problems <= sz
    * @param sz the cutoff point for using conquer vs. merge
    **/
    Tree tsp(int sz) {
        if (this.sz <= sz)
            return conquer();
        Tree leftval  = left.tsp(sz);
        Tree rightval = right.tsp(sz);
        return merge(leftval, rightval);
    }

    /**
    * Print the list of cities to visit from the current node.  The
    * list is the result of computing the TSP problem.
    * The list for the root node (city) should contain every other node
    * (city).
    **/
    void printVisitOrder() {
        printf("x = %.15f y = %.15f\n", x, y);
        for (Tree tmp = next; tmp != this; tmp = tmp.next)
            printf("x = %.15f y = %.15f\n", tmp.x, tmp.y);
    }

    /**
    * Computes the total length of the current tour.
    **/
    double tourLength() {
        double total = 0.0;
        Tree precedent = next;
        Tree current = next.next;
        if (current == this)
            return total;

        do {
            total += current.distance(precedent);
            precedent = current;
            current = current.next;
        } while (precedent != this);

        total += current.distance(this);
        return total;
    }


    // static methods ===============================================

    /**
    * Return an estimate of median of n values distributed in [min, max)
    * @param min the minimum value
    * @param max the maximum value
    * @param n
    * @return an estimate of median of n values distributed in [min, max)
    **/
    private static double median(double min, double max, int n) {
        // get random value in [0.0, 1.0)
        double t = rnd.nextDouble();

        double retval;
        if (t > 0.5)
            retval = log(1.0 - (2.0 * (M_E12 - 1) * (t - 0.5) / M_E12)) / 12.0;
        else
            retval = -log(1.0 - (2.0 * (M_E12 - 1) * t / M_E12)) / 12.0;

        // We now have something distributed on (-1.0, 1.0)
        retval = (retval + 1.0) * (max - min) / 2.0;
        return retval + min;
    }

    /**
    * Get double uniformly distributed over [min,max)
    * @return double uniformily distributed over [min,max)
    **/
    private static double uniform(double min, double max) {
        // get random value between [0.0, 1.0)
        double retval = rnd.nextDouble();
        retval = retval * (max - min);
        return retval + min;
    }

    /**
    * Builds a 2D tree of n nodes in specified range with dir as primary
    * axis (false for x, true for y)
    *
    * @param n the size of the subtree to create
    * @param dir the primary axis
    * @param min_x the minimum x coordinate
    * @param max_x the maximum x coordinate
    * @param min_y the minimum y coordinate
    * @param max_y the maximum y coordinate
    * @return a reference to the root of the subtree
    **/
    public static Tree buildTree(int n, bool dir, double min_x,
                                 double max_x, double min_y, double max_y) {
        if (n == 0)
            return null;

        Tree left, right;
        double x, y;
        if (dir) {
            dir = !dir;
            double med = median(min_x, max_x, n);
            left = buildTree(n/2, dir, min_x, med, min_y, max_y);
            right = buildTree(n/2, dir, med, max_x, min_y, max_y);
            x = med;
            y = uniform(min_y, max_y);
        } else {
            dir = !dir;
            double med = median(min_y,max_y,n);
            left = buildTree(n/2, dir, min_x, max_x, min_y, med);
            right = buildTree(n/2, dir, min_x, max_x, med, max_y);
            y = med;
            x = uniform(min_x, max_x);
        }

        return new Tree(n, x, y, left, right);
    }
}


public class TSP {
    /**
    * Number of cities in the problem.
    **/
    private static int cities;

    /**
    * Set to true if the result should be printed
    **/
    private static bool printResult = false;

    /**
    * Set to true to print informative messages
    **/
    private static bool printMsgs = false;

    /**
    * The main routine which creates a tree and traverses it.
    * @param args the arguments to the program
    **/
    public static void main(char[] args[]) {
        if (!parseCmdLine(args))
            return;

        if (printMsgs)
            printf("Building tree of size: %d\n", nextPow2(cities+1) - 1);

        Tree.initRnd(1);

        auto t0 = myclock();
        Tree t = Tree.buildTree(cities, false, 0.0, 1.0, 0.0, 1.0);

        auto t1 = myclock();
        t.tsp(150);
        auto t2 = myclock();

        if (printMsgs)
            printf("Total tour length: %.15f\n", t.tourLength());
        auto t3 = myclock();

        if (printResult)
            // if the user specifies, print the final result
            t.printVisitOrder();

        if (printMsgs) {
            printf("Tsp build time: %.2f\n", t1 - t0);
            printf("Tsp computing time: %.2f\n", t2 - t1);
            printf("Tsp total time: %.2f\n", t3 - t0);
        }
    }

    private static /*unsigned*/ int nextPow2(/*unsigned*/ int x) {
        if (x < 0)
            throw new Exception("x must be >= 0");
        x = x - 1;
        x = x | (x >>  1);
        x = x | (x >>  2);
        x = x | (x >>  4);
        x = x | (x >>  8);
        x = x | (x >> 16);
       return x + 1;
    }

    /**
    * Parse the command line options.
    * @param args the command line options.
    **/
    private static final bool parseCmdLine(char[] args[]) {
        int i = 1;

        while (i < args.length && args[i][0] == '-') {
            char[] arg = args[i++];

            if (arg == "-c") {
                if (i < args.length)
                    cities = toInt(args[i++]);
                else
                    throw new Exception("-c requires the size of tree");
                if (cities < 1)
                    throw new Exception("Number of cities must be > 0");
            } else if (arg == "-p") {
                printResult = true;
            } else if (arg == "-m") {
                printMsgs = true;
            } else if (arg == "-h") {
                return usage();
            }
        }

        if (cities == 0)
            return usage();

        return true;
    }

    /**
    * The usage routine which describes the program options.
    **/
    private static final bool usage() {
        fprintf(stderr, "usage: tsp_d -c <num> [-p] [-m] [-h]\n");
        fprintf(stderr, "  -c number of cities (rounds up to the next power of 2 minus 1)\n");
        fprintf(stderr, "  -p (print the final result)\n");
        fprintf(stderr, "  -m (print informative messages)\n");
        fprintf(stderr, "  -h (print this message)\n");
        return false;
    }
}


void main(char[][] args) {
    TSP.main(args);
}
