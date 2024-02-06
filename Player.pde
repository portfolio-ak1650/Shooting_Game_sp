class Player {
  private PVector position;              //[移動]自機座標
  private int HP;                        //体力  現在値
  private int life;                      //残機
  private int size;                      //自機のサイズ
  private ArrayList<Bullet> bullets;     //自機の弾丸
  private float angle;                   //自機の角度
  
  public boolean is_dead;                //死亡判定
  
  Minim minim;                           //音楽ライブラリ
  AudioPlayer shootSE, hitSE, clushSE;   //効果音
  AudioPlayer bombSE;   // ボムの効果音
  
  //新規作成
  private color cursor_color;             //カーソルの色
  private float cursor_length;            //カーソルの長さ
  private float cursor_width;             //カーソルの太さ
 

  public Player(PVector pos) {           //コンストラクタ
    position = pos;                      //位置
    bullets = new ArrayList<Bullet>();   //弾丸の生成
    size = 30;
    HP = 100;
    
    life = 3;
    cursor_color = color(#9CFF12);
    cursor_length = 20;
    cursor_width = 3.5;
    minim = new Minim(getPApplet());    
    shootSE = minim.loadFile("shoot1.mp3");
    hitSE = minim.loadFile("glass-break4.mp3");
    clushSE = minim.loadFile("flee1.mp3");
    bombSE = minim.loadFile("game_explosion5.wav");
  }

  public void hit(int damage) {           //攻撃を受けた時の処理
    HP -= damage;                         //damage分のHPダウン
    if(HP < 0) {                          //体力0 であるとき
      is_dead = (life-- == 0);            //life減少させ，lifeが1から0になれば死亡
      
      if (is_dead){                       //死亡
        return;
      }else{                              //lifeが残っていた場合
        HP = 100;                          //HPを全回復
        clushSE.rewind();                 
        clushSE.play();
        clushCount = millis();            //HPが0になり，lifeが残っていた時の時刻
        for(int idx = 0; idx < 6; idx++){
          debris[idx] = new PVector(idx + random((float)0, (float)1), random((float)1));
        }
      }
    }
    hitSE.rewind();                       //効果音再生
    hitSE.play();
    hitCount = millis();
  }

//敵の球が自機に当たっているかチェック．自機は円形の当たり判定
  public void hitCheck() {
    for (Enemy enemy : world.getEnemies()) {  //各敵に対して当たり判定
      for (int b_idx = enemy.getBullets().size()-1; b_idx > 0; b_idx--) { //取得したEnemyデータの所持している全弾のインデックスを取得．インデックスが大きいものから回す．
       //衝突判定
        Bullet e_bullet = enemy.getBullets().get(b_idx);                  //敵の弾丸
        float dist = PVector.sub(e_bullet.getPosition(), position).mag(); //自機座標 - 敵の弾丸の座標取得
        if (dist < size/2 && millis() - hitCount > 1000) {  //一定距離以下(自機サイズの半分以下)　かつ 現在時刻 - 前回ヒットした時刻が1秒以上(ヒットしてから1秒は無敵時間)
          int damage = e_bullet.getDamage();                              //敵の弾丸のダメージ数を取得
          hit(damage);                                                    //hit関数で当たった時の処理
          enemy.getBullets().remove(b_idx);                               //当たった球は削除
        }
      }
    }
  }

  // hit処理、場所のアップデートなど
  //毎フレームで呼び出される
  public void update() {
    changePosition();
    hitCheck();
    animation();
    checkWall();
  }

  // 弾丸を発射する関数。
  public void shoot() {
    int difficulty = world.get_difficulty();
    float bulletVel = 0.0;
    if(difficulty == 1){   //難易度によって弾丸の速度変更
      bulletVel = 20.0;                             //弾丸の速度
    } else if(difficulty == 2){
      bulletVel = 17.0;
    } else if(difficulty == 3){
      bulletVel = 15.0;
    }
    for (int i = -1; i <= 1; i++) {                    //3way弾
      float theta = -PI/2 + i*PI/6.0 + this.angle;
      float xDir = cos(theta) * bulletVel;
      float yDir = sin(theta) * bulletVel;
      bullets.add(new Bullet(this.position.copy(), new PVector(xDir, yDir), 10, true));  //弾丸生成
    }
    shootSE.rewind();   
    shootSE.play();
    shootCount = millis(); //発射時の時刻を取得
  }


  // ボムを起こす関数
  // 敵にしかきかない（ボスにはきかない）
  private boolean is_bomb = false;
  public void bomb() {
    // ボムの残り回数を取得
    int bomb_left = world.get_bomb_left();

    if(bomb_left > 0) {
      is_bomb = true;

      bombSE.rewind();   
      bombSE.play();
      world.set_bomb_left(--bomb_left);
      
      for (Enemy enemy : world.getEnemies()) {  // 全ての敵のHPを0にする
        System.out.println("Right mouse\n");
        // 敵のHPを0にする
        enemy.hp = 0;
        enemy.is_dead = true;
      }

    }

  }

  // Playerを描画する関数
  public void draw() {
    push();
    this.angle = calcHeadingAngle(this.position, new PVector(mouseX, mouseY));   //方向計算
    translate(position.x, position.y);                                           //描画の原点へ移動
    if(millis() - clushCount < 2000) drawDebri(millis() - clushCount);
    rotate(this.angle);
    
    noStroke();
    //炎のゆらぎ
    fill(255, 100, 0);
    ellipse(0.0,size / 2, size / 4, size / 4 * (millis() - boostCount) / 20);
    //hit時の点滅
    if ((millis() - hitCount) < 1000) {
      noFill();
      stroke(255, 255, 0);
      ellipse(0, 0, 100, 100);
      if((millis() - hitCount) / 100 % 2 == 0){
        fill(0);
      } else {
        fill(255, 255, 0);
      }
    } else {
      fill(255, 255, 0);
    }
    // 機体の絵
    if(millis() - shootCount <= 100) translate(0, (millis() - shootCount) / 5);   //自機が弾丸を打った時の反動
    drawAircraft(this.size);
    
    pop();
    
    drawBullets();
    drawCursor(this.cursor_length, this.cursor_width);
    //drawProperties();

    drawBomb();
  }
  
  private void drawBullets(){
    for (int b_idx = 0; b_idx < this.bullets.size(); b_idx++) {                   //自機の弾丸の全インデックス分回す．インデックスの小さい方から．
      Bullet b = bullets.get(b_idx);                                              //自機の弾丸の取得
      b.update();                                                                 //自機の弾丸の位置の更新
      if (b.getPosition().x > width || b.getPosition().x < 0
        || b.getPosition().y > height || b.getPosition().y < 0)                   //画面外なら弾丸を消す
        bullets.remove(b_idx);
      else                                                                        //画面内であれば描画
        b.draw();
    }
  }
  
  private void drawProperties() {   //残機表示メソッド，デフォでは呼ばれない
    fill(255,255,0);
    noStroke();
    for(int i = 0; i < life; i++) {
      push();
      int x = 40 + 25 * i;
      int y = 40;
      
      translate(x, y);
      drawAircraft(15);
      pop();
    }
    
    
    fill(100, 200, 150);
    noStroke();
    float barSize = map(HP, 0, 100, 0, width - 200);
    rect(200, 30, barSize, 10);
    
    fill(255);
    textSize(20);
    text(str(this.HP), 160, 42.5);
  }
  
  // s: size, p: position
  private void drawAircraft(int s) {    //自機表示
    triangle(- s / 3, s / 2, 
      - s / 6, - s / 2, 
      - s * 2 / 3, s / 2);
    triangle(s / 3, s / 2, 
      s / 6, - s/ 2, 
      s * 2 / 3, s / 2);
    triangle(0.0, - s, 
      s / 3, 0.0, 
      - s / 3, 0.0);    
    ellipse(0.0, 0.0, s / 2, s);
  }
  
  private void drawCursor(float l, float w){
    strokeWeight(w);
    stroke(cursor_color);
    //line(mouseX-l/2, mouseY, mouseX+l/2, mouseY);
    //line(mouseX, mouseY-l/2, mouseX, mouseY+l/2);
    float radius = sqrt(pow(mouseX - position.x, 2) + pow(mouseY - position.y, 2));
    for (int i = -1; i <= 1; i++) { 
      float theta = -PI/2 + i*PI/6.0 + this.angle;
      float xDir = cos(theta) * radius + position.x;
      float yDir = sin(theta) * radius + position.y;
      line(xDir-l/2, yDir, xDir+l/2, yDir);
      line(xDir, yDir-l/2, xDir, yDir+l/2);
    }
    strokeWeight(1.0);
    //line(mouseX, mouseY, position.x, position.y);
    for (int i = -1; i <= 1; i++) {                   
      float theta_l = -PI/2 + i*PI/6.0 + this.angle;
      float xDir_l = cos(theta_l) * radius + position.x;
      float yDir_l = sin(theta_l) * radius + position.y;
      line(xDir_l, yDir_l, position.x, position.y);
    }
    fill(255, 255, 0, 50);
    arc(position.x, position.y, 2*radius, 2*radius, -PI/2 -PI/6.0 + this.angle, -PI/2 + PI/6.0 + this.angle);
  }
  
  private void drawDebri(int s){
    for(int idx = 0; idx < 6; idx++){
      fill(255, 255, 0);
      ellipse(s/10.0*debris[idx].y*cos(debris[idx].x), s/10.0*debris[idx].y*sin(debris[idx].x),
      10, 10);
      //println("f");
    }
  }



  // ボムの際の爆発（点滅）
  private int bombflicker_num = 2;
  private boolean is_bomblight = false;
  private void drawBomb() {
    if(is_bomb) {
      // 点滅回数内の時
      if(bombflicker_num > 0) {

        color c_tmp;

        // 点滅のうち、白くないとき
        if(!is_bomblight) {
          is_bomblight = true;
          c_tmp = color(255, 255, 255);
        // 点滅のうち、白いとき
        } else {
          is_bomblight = false;
          c_tmp = color(0, 0, 0);
          --bombflicker_num;
        }
        fill(c_tmp);
        rect(0, 0, width, height);

      } else {
        is_bomb = false;
        bombflicker_num = 2;
      }
    }
  }

  private int hitCount, boostCount, shootCount, clushCount;
  private PVector[] debris = new PVector[6];//xにrad, yに変位
  public void animation() {
    boostCount = (millis() - boostCount >= 200) ? millis() : boostCount ;
  }
  
  private void checkWall() {   //画面外判定
    position.x = position.x < 50 ? 50 : position.x;
    position.x = position.x > width - 50 ? width - 50 : position.x;
    
    position.y = position.y < 50 ? 50 : position.y;
    position.y = position.y > height - 50 ? height - 50 : position.y;
  }
  
  private float calcHeadingAngle(PVector p, PVector target) {     //機体の向きを計算．p:プレイヤー座標，target:カーソル座標
    PVector dir = PVector.sub(target, p).normalize();
    float angle = atan2(dir.y, dir.x) + PI/2;
    return angle;
  }

  public void setHP(int HP) { 
    this.HP = HP;
  }
  public int getHP() { 
    return this.HP;
  }

  public void setLife(int life) { 
    this.life = life;
  }
  public int getLife() { 
    return this.life;
  }


  public PVector getPosition() { 
    return this.position;
  }

  public ArrayList<Bullet> getBullets() { 
    return this.bullets;
  }

  private boolean key_a, key_w, key_d, key_s;
  public void keyPressed(int key) {   //キーが押された時の処理
    
    for(Bullet bullet : this.bullets)
      bullet.keyPressed(key);


    if (key == 'a') key_a = true;
    if (key == 'w') key_w = true;
    if (key == 'd') key_d = true;
    if (key == 's') key_s = true;
  }
  
  public void keyReleased(int key){    //キーが離れたときの処理
    //if (key == 'a') println("releasing a");
    if (key == 'a') key_a = false;
    if (key == 'w') key_w = false;
    if (key == 'd') key_d = false;
    if (key == 's') key_s = false;
  }
  
  private void changePosition(){       //自機の移動
    int difficulty = world.get_difficulty();  //難易度によってプレイヤーの速度変更
    if(difficulty == 1){
      if(key_a) position.x -= 7;
      if(key_w) position.y -= 7;
      if(key_d) position.x += 7;
      if(key_s) position.y += 7;
    } else if(difficulty == 2){
      if(key_a) position.x -= 5;
      if(key_w) position.y -= 5;
      if(key_d) position.x += 5;
      if(key_s) position.y += 5;
    } else if(difficulty == 3){
      if(key_a) position.x -= 3;
      if(key_w) position.y -= 3;
      if(key_d) position.x += 3;
      if(key_s) position.y += 3;
    }
  }
  
  public void mousePressed() {
    if(mouseButton == LEFT)
      shoot();
    else if(mouseButton == RIGHT)
      bomb();
  }
}
