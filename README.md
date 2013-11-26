PlaneMe
===========

PlaneMe is a Planarity clone (see <http://planarity.net>).

The purpose of the game is to reposition the nodes so that
no two links intersect. 

Available actions:

* *left-click* moves a node.
* *right-click* selects a node.
* '`c`' Checks on weather the graph is planar and if so, moves to the next level.
* '`n`' Moves to the next level (no score/bonus is gained).
* '`g`' Groups selected nodes (see below).
* '`q`' Quits the game... :-(

In order for nodes to be grouped, the following criteria must hold

* They should be connected.
* Their links should not intersect.
* They should be simple nodes (not already grouped ones).

Be careful, grouping nodes reduces your bonus!
