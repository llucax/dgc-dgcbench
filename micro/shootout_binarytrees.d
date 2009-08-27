// Written by Andrey Khropov <andkhropov_nosp@m_mtu-net.ru>
// Found at http://www.digitalmars.com/webnews/newsgroups.php?art_group=digitalmars.D&article_id=43991
// Modified by Leandro Lucarella
// (ported to Tango)

import tango.util.Convert;

alias char[] string;

int main(string[] args)
{
	int N = args.length > 1 ? to!(int)(args[1]) : 1;

	int minDepth = 4;
	int maxDepth = (minDepth + 2) > N ? minDepth + 2 : N;
	int stretchDepth = maxDepth + 1;

	TreeNode stretchTree = TreeNode.BottomUpTree(0, stretchDepth);

	TreeNode longLivedTree = TreeNode.BottomUpTree(0, maxDepth);

	int depth;
	for(depth = minDepth; depth <= maxDepth; depth += 2)
	{
		int check, iterations = 1 << (maxDepth - depth + minDepth);

		for(int i = 1; i <= iterations; i++)
		{
			auto tempTree = TreeNode.BottomUpTree(i, depth);
			check += tempTree.ItemCheck;
			//delete tempTree;

			tempTree = TreeNode.BottomUpTree(-i, depth);
			check += tempTree.ItemCheck;
			//delete tempTree;
		}

	}

	return 0;
}

class TreeNode
{
public:
	this(int item, TreeNode left = null, TreeNode right = null)
	{
		this.item  = item;
		this.left  = left;
		this.right = right;
	}

	static TreeNode BottomUpTree(int item, int depth)
	{
		if(depth > 0)
			return new TreeNode(item
					,BottomUpTree(2 * item - 1, depth - 1)
					,BottomUpTree(2 * item, depth - 1));
		return new TreeNode(item);
	}

	int ItemCheck()
	{
		if(left)
			return item + left.ItemCheck() - right.ItemCheck();
		return item;
	}
private:
	TreeNode            left, right;
	int                 item;
}

