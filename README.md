PlaneMe
=======

PlaneMe is a [Planarity](http://planarity.net) clone by [Vassilis Kazazakis](mailto:bkazaz@gmail.com).

The purpose of the game is to reposition the nodes so that
no two links intersect. 

Available actions:
* *left-click* moves a node.
* *right-click* toggles selection of node.
* `c` Checks on wether the graph is planar and if so, moves to the next level.
* `n` Moves to the next level (no score/bonus is gained).
* `g` Groups selected nodes (see below).
* `q` Quits the game... :-(

In order for nodes to be grouped, the following criteria must hold

  1. They should be connected.
  2. Their links should not intersect.
  3. They should be simple nodes (not already grouped ones).

Be careful, grouping nodes reduces your bonus!

Ruby
----

The game is written in **Ruby** using [Gosu](https://github.com/jlnr/gosu) 
& [Tween](https://rubygems.org/gems/tween) gems.
