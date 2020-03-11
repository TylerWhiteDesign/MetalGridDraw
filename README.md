# MetalGridDraw
A grid-based drawing app and particle system using Metal.

![MetalGridDraw demo animation](https://media.giphy.com/media/U8MI97yk1UjFFIhDEU/giphy.gif)

This project demonstrates how to create a grid-based drawing app using Apple's [Metal](https://developer.apple.com/metal/) framework and use each cell in the grid to form a particle system.

Each cell has its own set of 4 vertices (to build the square) which allows each cell to be shaded and moved independantly. The independance of each cell allows for the particle _explosion_ effect of the canvas and because I'm using instancing, the app's framerate maintains 60fps even with hundreds of thousands of cells moving at once!

**Compute Kernels:**
* I use a compute kernel to do the hit testing which allows the cells to be tested in parallel and while they are animating on the screen.
* Tranlation matrices for each cell are calculated using a seperate compute kernel.
