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

  VertiePoint line_start_pos, line_end_pos;


  SimulationSystem(this.canvas) {
    line_start_pos = null;
    rng = new Random();
    var canvas = this.canvas;
    canvas.onMouseDown.listen(onMouseDown);
    canvas.onMouseUp.listen(onMouseUp);
    canvas.onContextMenu.listen(onContextMenu); // No need for a context menu
    canvas.onMouseMove.listen(onMouseMove);
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

    // Start the animation loop.
    requestRedraw();
  }

  void onMouseDown(MouseEvent e) {
    var pos = new VertiePoint(e.offset.x, e.offset.y);
    if(e.button == 0) {
      var circle = new VertieCircleShape(pos, 20);
      world.add_circle_shape(circle);
    } else if(e.button == 2) {
      line_start_pos = pos;
    }
    e.preventDefault(); // Avoids triggering a canvas selection
  }

  void onMouseUp(MouseEvent e) {
    if(e.button == 2 && line_start_pos != null) {
      var pos = new VertiePoint(e.offset.x, e.offset.y);
      if(line_start_pos.distanceTo(pos) > 5) {
        var line = new VertieLine(line_start_pos, pos);
        world.lines.add(line);
      }
    }
    line_start_pos = null;
    line_end_pos = null;
  }

  void onMouseMove(MouseEvent e) {
    var pos = new VertiePoint(e.offset.x, e.offset.y);
    if(line_start_pos != null) {
      line_end_pos = pos;
    }
  }

  void onContextMenu(MouseEvent e) {e.preventDefault(); }

  void draw(num _) {
    num time = new DateTime.now().millisecondsSinceEpoch;

    if (renderTime != null) {
      showFps((1000 / (time - renderTime)).round());
    }

    renderTime = time;

    var context = canvas.context2d;

    drawBackground(context);
    drawCircles(context);
    drawPlacingLine(context);
    drawStaticLines(context);

    world.step();
    requestRedraw();
  }

  void drawBackground(CanvasRenderingContext2D context) {
    context.clearRect(0, 0, width, height);
  }

  void drawPlacingLine(CanvasRenderingContext2D context) {
    if(line_start_pos != null && line_end_pos != null) {
      var color = "#00FF00";
      context.lineWidth = 0.5;
      context.fillStyle = color;
      context.strokeStyle = color;
      context.beginPath();
      context.moveTo(line_start_pos.x, line_start_pos.y);
      context.lineTo(line_end_pos.x, line_end_pos.y);
      context.closePath();
      context.stroke();
    }
  }

  void drawStaticLines(CanvasRenderingContext2D context) {
    for(final line in world.lines) {
      var color = "#00AA00";
      context.lineWidth = 0.5;
      context.fillStyle = color;
      context.strokeStyle = color;
      context.beginPath();
      context.moveTo(line.A.x, line.A.y);
      context.lineTo(line.B.x, line.B.y);
      context.closePath();
      context.stroke();
    }
  }

  void drawCircles(CanvasRenderingContext2D context) {
    for(final shape in world.circle_shapes) {
      // Draw the figure.
      var color = "#0000FF";
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

