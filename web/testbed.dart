/**
 * A solar system visualization.
 */

library testbed;

import 'dart:html';
import 'dart:math';
import 'vertie.dart';

/**
 * The entry point to the application.
 */
void main() {

  var simulation = new SimulationSystem(query("#container"));

  simulation.start();
}

num fpsAverage;

/**
 * Display the animation's FPS in a div.
 */
void showFps(num fps) {
  if (fpsAverage == null) {
    fpsAverage = fps;
  }

  fpsAverage = fps * 0.05 + fpsAverage * 0.95;

  query("#notes").text = "${fpsAverage.round().toInt()} fps";
}

/**
 */
class SimulationSystem {
  
  CanvasElement canvas;
  Random rng;

  num _width;
  num _height;

  VertieWorld world;

  num renderTime;

  SimulationSystem(this.canvas) {
    this.rng = new Random();
  }

  num get width => _width;

  num get height => _height;

  start() {
    // Measure the canvas element.
    window.setImmediate(() {
      _width = (canvas.parent as Element).client.width;
      _height = (canvas.parent as Element).client.height;

      canvas.width = _width;
      canvas.height = _height;
      query("#res").text = "$width $height";
      // Initialize the world and start the simulation.
      _start();
    });

  }

  _start() {
    world = new VertieWorld(width, height);
    world.gravity = new VertieVector(0, 0.5);

    for(var i=0; i<50; i++) {
      var pos = new VertiePoint(rng.nextInt(width), rng.nextInt(height)); 
      var circle = new VertieCircleShape(pos, 20);
      world.add_circle_shape(circle);
    }
    
    // Start the animation loop.
    requestRedraw();
  }

  void draw(num _) {
    num time = new DateTime.now().millisecondsSinceEpoch;

    if (renderTime != null) {
      showFps((1000 / (time - renderTime)).round());
    }

    renderTime = time;

    var context = canvas.context2d;
    
    drawBackground(context);
    drawCircles(context);

    world.step();
    requestRedraw();
  }

  void drawBackground(CanvasRenderingContext2D context) {
    context.clearRect(0, 0, width, height);
  }

  void drawCircles(CanvasRenderingContext2D context) {
    for(VertieCircleShape shape in this.world.circle_shapes) {
      // Draw the figure.
      String color = "#0000FF";
      context.lineWidth = 0.5;
      context.fillStyle = color;
      context.strokeStyle = color;
      context.beginPath();
      context.arc(shape.center.x, shape.center.y, shape.radius, 0, PI * 2, false);
      context.fill();
      context.closePath();
      context.stroke();
    }
    //sun.draw(context, width / 2, height / 2);
  }

  void requestRedraw() {
    window.requestAnimationFrame(draw);
  }
}

