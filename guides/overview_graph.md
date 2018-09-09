# Graph Overview

Give an overview of a graph here

Coming soon

## Positions, rotation, scale and more

A major mental model difference between Scenic and everything web is how things
are positioned on the screen. In this case, Scenic is built like a game.

Scenic is aimed at fixed-screen devices and apps that control their own layout.
On the web, there is no guarantee what size screen or window the client will
use, so it relies on dynamic layout that is computed on the client.

Scenic does not have an auto-layout engine. Instead, everything rendered on the
screen is positioned with transform matrices, just like a game.

**Don’t worry!** You will not need to look at any matrices unless you want to
get fancy.

To move something on the screen, just add one of the transform options. Like
this