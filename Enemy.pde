class Enemy {
  PVector position;
  private ArrayList<Bullet> bullets;

  int size;
  int hp;
  float heartbeat_phase,heartbeat_freq;

  private boolean isShooted;//射撃したか保持する変数．
  protected int shootingTiming_ms;//射撃タイミングの設定
  
  private int moveselect;//Enemyの動きを選択する
  private int moveflag;//動きを変えるタイミング
  private PVector velocity;//動きパターン1の速度
  private PVector velocity2 = new PVector(0,0);//動きパターン2の速度
  private long lastHitTime_ms;  //最後にBulletに当たった時刻(ms)
  

  public boolean is_dead;

  final int INVINCIBLE_TERM_MS = 1000;  // 無敵期間(ms)

  public Enemy(PVector pos) {
     position = pos;
     bullets = new ArrayList<Bullet>();

     isShooted = false;
  
     // 弾を撃つ間隔を設定

    // 現在のゲームの難易度を取得
     int difficulty = world.get_difficulty();
     switch(difficulty) {
      case 1:
        shootingTiming_ms = 500;
        hp = 2;
        size = 70;
        break;
      case 2:
        shootingTiming_ms = 600;
        hp = 4;
        size = 90;
        break;
      case 3:
        shootingTiming_ms = 700;
        hp = 6;
        size = 120;
        break;
      default:
        break;
     }

      System.out.println("Enemy timing = "+shootingTiming_ms);
     
     moveselect = int(random(2));
     moveflag = int(random(2,4));
     velocity = new PVector(random(0,3), random(3,5));
     
     for(Player player : world.getPlayers()){
       velocity2 = PVector.sub(player.getPosition(),position).div(100);
     }

     //size = 100;
     heartbeat_phase = random(2.0*PI);
     heartbeat_freq = 200.0;
     //hp = 3;
     lastHitTime_ms = 0L;
  }
  
  public Enemy(PVector pos, int size, int hp, long lastHitTime_ms){
    this(pos);
    this.size = size;
    this.hp = hp;
    this.lastHitTime_ms = lastHitTime_ms;
  }

  public void shoot() {
    threeWayShooter_addtiming(shootingTiming_ms);
  }


  public void move(){
    if(moveselect == 0){//動きパターン1　まっすぐ～ギザギザ
      if(millis()/1000 % moveflag == 0){
        position.add(velocity);
      }else{
        position.add(-velocity.x ,velocity.y);
      }
    }else{//動きパターン2　Playerに向けて動く
      position.add(velocity2);
    }
  }
  
  public void update() {

    move();
    shoot();
    hit();
  }


  // Enemy を描画する関数
  public void draw() {

    int r = (int) (sin((float)millis()/heartbeat_freq + heartbeat_phase)*10.0);
    int c = (int) (sin((float)millis()/heartbeat_freq + heartbeat_phase)*50.0); //±50
    int alpha = 255;

    // ヒット直後，1sec間は100ms毎に点滅を繰り返す
    if(isInvincible() && (millis() / 100) % 2 == 0){
      alpha = 0;
    }else{
      alpha = 255;
    }
    
    noStroke();
    /*難易度ごとに敵変更 & ダメージを受けてるならalpha値変更*/
     int difficulty = world.get_difficulty();
     switch(difficulty) {
      case 1:
        ghost(position, r, alpha);
        break;
      case 2:
        UFO(position, r, alpha);
        break;
      case 3:
        EyeMonster(position, r, alpha);
        break;
      default:
        break;
     }

    //circle(position.x,position.y,size+r);
   //弾を描画する処理を書く
    drawBullets();
  }


  /*EyeMonster*/
  void EyeMonster(PVector pos, int r, int alpha){
    fill(75, 0, 130, alpha);
    int Size = size+r;
    pushMatrix();
    circle(pos.x, pos.y, Size);
    fill(255, 255, 255, alpha);
    ellipse(pos.x, pos.y, Size, Size/2);
    fill(255, 0, 0, alpha);
    circle(pos.x, pos.y, Size/2);
    fill(0, 0, 0, alpha);
    circle(pos.x, pos.y, Size/6);
    popMatrix();
  }
  
  
  /*ghost*/
  void ghost(PVector pos, int r, int alpha){
    fill(200, 200, 200, alpha);
    int Size = size+r;
    pushMatrix();
    /*body*/
    circle(pos.x, pos.y, Size);
    /*tail*/
    triangle(pos.x, pos.y+Size/2, pos.x+Size/3, pos.y+2*Size/3, pos.x+Size/4, pos.y);
    /*head*/
    fill(255, 255, 255, alpha);
    triangle(pos.x-Size/4, pos.y-3*Size/8, pos.x, pos.y-2*Size/3, pos.x+Size/4, pos.y-3*Size/8);
    /*face*/
    //eye
    fill(255, 255, 0, alpha);
    circle(pos.x-Size/8, pos.y-Size/8, Size/8);
    circle(pos.x+Size/8, pos.y-Size/8, Size/8);
    //tongue
    fill(255, 0, 0, alpha);
    triangle(pos.x-Size/4, pos.y, pos.x, pos.y+Size/3, pos.x+Size/4, pos.y);
    /*hand*/
    stroke(2);
    line(pos.x-Size/4, pos.y+Size/8, pos.x-3*Size/8, pos.y+Size/4);
    line(pos.x-3*Size/8, pos.y+Size/4, pos.x-Size/4, pos.y+Size/4);
    line(pos.x+3*Size/8, pos.y+Size/8, pos.x+Size/4, pos.y+Size/4);
    line(pos.x+3*Size/8, pos.y+Size/4, pos.x+Size/4, pos.y+Size/4);
    noStroke();
    popMatrix();
  }
  
  /*UFO*/
  void UFO(PVector pos, int r, int alpha){
    fill(255, 255, 0, alpha);
    int Size = size+r;
    pushMatrix();
    /*bottom*/
    arc(pos.x-Size/4, pos.y+Size/16, Size/2, Size/2, 0, PI);
    arc(pos.x, pos.y+Size/8, Size/2, Size/2, 0, PI);
    arc(pos.x+Size/4, pos.y+Size/16, Size/2, Size/2, 0, PI);
    /*enban*/
    fill(138, 43, 226, alpha);
    ellipse(pos.x, pos.y-Size/16, 4*Size/3, Size/2);
    /*body*/
    fill(169, 169, 169, alpha);
    arc(pos.x, pos.y, Size, Size, PI, TWO_PI);
    /*window*/
    fill(135, 206, 250, alpha);
    circle(pos.x-Size/4, pos.y-3*Size/16, 3*Size/16);
    circle(pos.x, pos.y-3*Size/16, 3*Size/16);
    circle(pos.x+Size/4, pos.y-3*Size/16, 3*Size/16);
    popMatrix();
  }
  
  // Player の Bullet に当たると Enemy の hp を1削る．
  // 連続攻撃に対処するため，攻撃を受けた後は一定時間攻撃を受けない
  private void hit(){
    if(!isHitted()) return;
    if(!isInvincible()){
      lastHitTime_ms = millis();
      is_dead = (--hp == 0);
      divideSelf();
    }
  }
  
  // Enemy が無敵かどうか
  private Boolean isInvincible(){
    return (millis() - lastHitTime_ms) < INVINCIBLE_TERM_MS;
  }
  
  // Bullet に当たったかを判定する
  private Boolean isHitted(){
    for(Player player : world.getPlayers()) {
      ArrayList<Bullet> pBullets = player.getBullets();
      
      for(Bullet pBullet : pBullets){
        float dist = PVector.sub(pBullet.getPosition(), this.position).mag();
        // 衝突判定
        if (dist < size/2) {
          if(!isInvincible()) return true; //敵が無敵時間の時は自機の弾を消さないよう修正
          pBullets.remove(pBullet);
          return true;
        }
      }
    }
    return false;
  }
  

  // Enemy を2つに分裂する
  protected void divideSelf(){
    if(hp == 0) return;
    size /= 2;
    Enemy brother = new Enemy(new PVector(this.position.x, this.position.y), this.size, this.hp, lastHitTime_ms);
    world.getEnemies().add(brother);
  }

  public ArrayList<Bullet> getBullets() { return bullets; }
  
  public PVector getPosition() { return this.position; }
  
  public void keyPressed(int key) {}
  public void mousePressed() {}


  //自機方向を中心に30度角度をつけた三方向に射撃する関数．
  private void threeWayShoot(PVector playerPos){
    // 弾の数が上限を超えるとき、撃たない
    int ebul_numcurrent = world.get_ebul_numcurrent(); // 現在の画面内の敵弾の数
    int ebul_numlimit = world.get_ebul_numlimit(); // 敵弾の上限数
    if (ebul_numcurrent >= ebul_numlimit) return;
    world.set_ebul_numcurrent( ebul_numcurrent + 3 ); // 弾の数を更新


    PVector toPlayerVec = PVector.sub( playerPos, this.position);
    float deg = PI / 3; //これで30度角になる．

    for(int i=0 ; i<3 ; i++){
      float tmp_deg = -deg + deg * i;
      PVector tmp_Vec = toPlayerVec.copy().rotate(tmp_deg).normalize().mult(2.0);
      int damage = int(random(5,10));
      
      PVector bulletPos = new PVector();
      bulletPos = this.position.copy();
      bullets.add(new Bullet(bulletPos,tmp_Vec,damage,false));
    }
  }


  //threeWayshootのタイミング調整を行う関数．
  //ひたすらshoot内で呼べばタイミング通り打てる．
  protected void threeWayShooter_addtiming(int timing_ms){
      int time = millis() / timing_ms;

    if(time % 2 == 0 && !this.isShooted){
      for(Player player : world.getPlayers()) {
        threeWayShoot(player.position);

        //tmp++;
      }
      this.isShooted = true;

    }
    if(time % 2 == 1){
      this.isShooted = false;

    }

  }

  protected void drawBullets(){

      //for(int b_idx = 0; b_idx < bullets.size(); b_idx++) {
      for(int b_idx = bullets.size()-1; b_idx >= 0 ; b_idx--) { 
        Bullet b = bullets.get(b_idx);
        b.update(); 
        if(b.getPosition().x < 0 || b.getPosition().x > width
        || b.getPosition().y < 0 || b.getPosition().y > height) {
          bullets.remove(b_idx);
          world.set_ebul_numcurrent( world.get_ebul_numcurrent() - 1 );
        } else 
          b.draw();
    }
  }
}


class Boss extends Enemy{
  private boolean isShooted_Nway;
  private int numShoot_NWay;
  private int bulletSpeed_Nway;
  private int shootTiming_Nway;
  
  private int movespeed;

  public Boss(PVector pos){
    super(pos);
    
    movespeed = 2;
    isShooted_Nway = false;
    numShoot_NWay = 40;
    bulletSpeed_Nway =int(random(3,6));
   
     // 現在のゲームの難易度を取得
     // それに応じて弾を撃つ間隔を設定
     int difficulty = world.get_difficulty();
     switch(difficulty) {
      case 1:
        shootTiming_Nway = 500;
        break;
      case 2:
        shootTiming_Nway = 400;
        break;
      case 3:
        shootTiming_Nway = 300;
        break;
     }
       
    System.out.println("timing = "+shootingTiming_ms);
    super.size = 150;
    super.heartbeat_phase = random(2.0*PI);
    super.heartbeat_freq = 400.0;
    super.hp = 10;
  }
  
  public void move(){//ボスの動き
    position.y = size+(size-10)*sin(radians(millis())/10);
    position.x += movespeed;
    if(position.x > width || position.x < 0){
      movespeed *= -1;
    }
  }
  
  // Boss を分裂させない
  protected void divideSelf(){
  }

  public void shoot(){
    //super.shoot();
    threeWayShooter_addtiming(shootingTiming_ms);
    Nwayshooter_addtiming(shootTiming_Nway);

  }
  

  //敵を中心に360度で全方向に打つ関数．射撃する密度は numWayから設定可能．  
  private void NwayShoot(int numWay,int bulletSpeed){
    // 弾の数が上限を超えるとき、撃たない
    int bossbul_numcurrent = world.get_bossbul_numcurrent(); // 現在の画面内の敵弾の数
    int bossbul_numlimit = world.get_bossbul_numlimit(); // 敵弾の上限数
    if (bossbul_numcurrent >= bossbul_numlimit) return;
    world.set_bossbul_numcurrent( bossbul_numcurrent + numWay ); // 弾の数を更新

    PVector stdVec = new PVector(0,bulletSpeed);
    float deg = TWO_PI / numWay;

    for(int i=0; i<numWay; i++){
      PVector tmp_Vec = stdVec.copy().rotate(deg * i);
      int damage = int(random(5,10));
      PVector bulletPos = new PVector();
      bulletPos = this.position.copy();
      super.bullets.add(new Bullet(bulletPos,tmp_Vec,damage,false));

    }

  }


  @Override
  protected void drawBullets(){
      super.drawBullets();

      for(int b_idx = super.bullets.size()-1; b_idx >= 0 ; b_idx--) {
        Bullet b = super.bullets.get(b_idx);
        b.update(); 
        if(b.getPosition().x < 0 || b.getPosition().x > width
        || b.getPosition().y < 0 || b.getPosition().y > height) {
          super.bullets.remove(b_idx);
          world.set_bossbul_numcurrent( world.get_bossbul_numcurrent() - 1 );
        } else 
          b.draw();
    }
  }

  private void Nwayshooter_addtiming(int timing_ms){
     int time = millis() / timing_ms;

    if(time % 2 == 0 && !this.isShooted_Nway){
      NwayShoot(numShoot_NWay,bulletSpeed_Nway);
      this.isShooted_Nway = true;

    }
    
    if(time%2 == 1){
      this.isShooted_Nway = false;

    }
  }

}
