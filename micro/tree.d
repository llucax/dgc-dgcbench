// Written by Piotr Modzelewski <http://petermodzelewski.blogspot.com/>
// Found at http://www.dsource.org/projects/tango/wiki/GCBenchmark

class TreeNode {
	int item;
	TreeNode left, right;

	this(int item, TreeNode left=null, TreeNode right=null) {
		this.item = item;
		this.left = left;
		this.right = right;
	}

	int check() {
		return left is null ? item : item + left.check - right.check;
	}
}

TreeNode makeTree(int item, int depth) {
	if (depth > 0)
		return new TreeNode(item, makeTree(2*item-1, depth-1),
				makeTree(2*item, depth-1));
	else
		return new TreeNode(item);
}

void main(char[][] args) {
	const minDepth = 4;
	int n = 6; // 13;
	int maxDepth = (minDepth + 2) > n ? minDepth + 2 : n;

	int check = makeTree(0, maxDepth + 1).check;

	auto longLivedTree = makeTree(0, maxDepth);

	for (int depth = minDepth; depth <= maxDepth; depth += 2) {
		int iterations = 1 << (maxDepth - depth + minDepth);
		check = 0;

		for (int i = 1; i <= iterations; i++)
			check += (makeTree(i, depth)).check
					+ (makeTree(-i, depth)).check;
	}

}

