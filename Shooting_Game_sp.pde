import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

World world;

void setup() {
  size(800, 600);
  frameRate(60);
  world = new World();
  world.init();
}

void draw() {
  world.draw();
}

void keyPressed() {
  world.keyPressed(key);
}

void keyReleased() {
  world.keyReleased(key);
}

void mousePressed() {
  world.mousePressed(); 
}

PApplet getPApplet() { // Worldクラスで音再生に使用（Minimのインスタンスの引数）
  return this;
}

void stop(){
  world.stopMusic();
}
