## 0.8.0
* Add documentation

### Breaking changes!
* Remove Rectangle, Vector, Vector3 and Vector4 modules, which I should have done before the first release. If anyone desires them back in, I'll leave them around for a while so make the case. Otherwise I'd like to minimize the code that needs to be supported in the future.
* Rename Vector2.in_bounds to Vector2.in_bounds?
* Move Vector.invert/1 into Vector2.invert/1

## 0.7.1
* No code changes.
* When I built the Hex package, I had included the \*.o files, which worked on the Mac, but fails on other systems. This should eclude object files from the hex package.

## 0.7.0
* First public release