class World {
  public World() {
    players = new ArrayList<Player>();
    enemies = new ArrayList<Enemy>();

    //日本語表示対応
    PFont font = createFont("MS Gothic",50);
    textFont(font);

    minim = new Minim(getPApplet());
    bgm_start = minim.loadFile("Oceanic_life_free_bgm_ver.mp3");
    bgm_game = minim.loadFile("digitalworld.mp3");
    bgm_over = minim.loadFile("yokoku_cut.mp3");
    sound_pikin = minim.loadFile("button31.mp3");
    hardmord = minim.loadFile("hardmord.mp3");
    hardmord_game = minim.loadFile("hardmord_game.mp3");
    warning = minim.loadFile("Warning.mp3");


    init();
  }

  int score;                                 //スコア
  private ArrayList<Player> players;
  private ArrayList<Enemy> enemies;

  // 画面内の敵の弾の上限数
  private int ebul_numlimit = 100;
  // 今現在の画面内の敵の弾の数
  private int ebul_numcurrent = 0;
  // 画面内の敵の弾の上限数（ボスバージョン）
  private int bossbul_numlimit = 400;
  // 今現在の画面内の敵の弾の数（ボスバージョン）
  private int bossbul_numcurrent = 0;


  private Boss boss;
  private PVector player_p;  //player座標
  private PImage back; //プレイ画面の背景

  // 0: スタート画面，1: EasyModeのゲーム画面, 2:NormalModeのゲーム画面，3:HardModeのゲーム画面 , -1:ゲームオーバー画面, -2:Menu(操作方法)
  private int scene = 0;



  // -------- ステージ番号 ---------
  public final int MENU_NUM = -2; // メニュー画面
  public final int GAMEOVER_NUM = -1; // ゲームオーバー画面
  public final int START_NUM = 0; // スタート画面
  public final int EASY_NUM = 1; // EasyMode
  public final int NORMAL_NUM = 2; // NormalMode
  public final int HARD_NUM = 3; // HardMode




  // ゲーム難易度
  // 1:イージー, 2: ノーマル, 3: ハード
  private int difficulty;

  // 敵が何体倒されたらボスを出現させるか
  // イージーでは7, ノーマルでは10, ハードでは12
  private int e_beatlimit;

  // 敵が何フレームに1回生まれるか
  // イージーでは240, ノーマルでは120, ハードでは60
  private int e_born_intvl;
  // ---------------------------------


  // ボムの残り回数
  private int bomb_left = 5;
  public int get_bomb_left() { return this.bomb_left; }
  public void set_bomb_left(int bl) { this.bomb_left = bl; }


  private boolean boss_in = false; // true: boss出現

  ArrayList<Player> getPlayers() { return this.players; }

  ArrayList<Enemy> getEnemies() { return this.enemies; }

  // ebul_numlimitのゲッタ―
  public int get_ebul_numlimit() { return this.ebul_numlimit; }
  // ebul_numcurrentのゲッター
  public int get_ebul_numcurrent() { return this.ebul_numcurrent; }
  // ebul_numcurrentのセッター
  public void set_ebul_numcurrent(int argnum) { this.ebul_numcurrent = argnum; }
  // bossbul_numlimitのゲッタ―
  public int get_bossbul_numlimit() { return this.bossbul_numlimit; }
  // bossbul_numcurrentのゲッター
  public int get_bossbul_numcurrent() { return this.bossbul_numcurrent; }
  // bossbul_numcurrentのセッター
  public void set_bossbul_numcurrent(int argnum) { this.bossbul_numcurrent = argnum; }

  Minim minim;
  AudioPlayer bgm_start, bgm_game, bgm_over;
  AudioPlayer sound_pikin, hardmord, hardmord_game, warning;
  

  private int k_count = 0;  //kが押される度にカウントを増やす(裏モードであるHardを出現させるため)
  private int is_previousmenu = 0;  //メニューからスタート画面に遷移する際に，音楽がスムーズに流れるようにするため


  // 難易度のゲッタ―
  public int get_difficulty() {
    return this.difficulty;
  }

  void draw() {
    switch(scene) {             //画面遷移
      case START_NUM:   
        draw_start();
        break;

      case EASY_NUM:
      case NORMAL_NUM:
      case HARD_NUM:
        draw_game(scene);
        break;

      case GAMEOVER_NUM:
        draw_over();
        break;

      case MENU_NUM:
        draw_menu();
        break;
    }
  }

  void init() {
    scene = 0;
    back = loadImage("stars.jpg");
    back.resize(back.width+500, back.height+500);
    init_start();
  }

  /**************** スタート画面 *************************/
  private int textAlpha_start = 0;                     //文字エフェクトのための変数
  private boolean textAlphaIsAscending_start = true;   //文字エフェクトの繰り返し
  private int textAlpha_hard = 0;                      //文字エフェクトのための変数(難易度hard出現時)

  private int[] starsX_start, starsY_start;            //starの初期位置
  private int starsNum_start = 300;                    //starの数

  private boolean shootingStarOn_start = false;        //流れ星flag
  private int shootingStarX_start, shootingStarY_start;//流れ星の初期位置

  PImage titleImg_start, menu_start;                   //タイトルとメニューの画像挿入

  private void init_start() {
    // スタート画面での初期化
    textAlpha_start = 0;
    textAlphaIsAscending_start = true;

    //星作成
    starsX_start = new int[starsNum_start];
    starsY_start = new int[starsNum_start];
    for(int i=0; i<starsNum_start; i++){
      starsX_start[i] = (int)random(0, width);
      starsY_start[i] = (int)random(0, height);
    }

    shootingStarOn_start = false;

    titleImg_start = loadImage("title_2.png");
    menu_start = loadImage("menu.png");
    
    println(is_previousmenu);

    if(is_previousmenu == 0){   //音楽再生がスムーズになるように
      bgm_start.rewind();
      bgm_start.loop();
    }
  }

  private void draw_start() {
    // スタート画面での毎フレームの処理
    background(25, 25, 50);

    //星の輝き
    for(int i=0; i<starsNum_start; i++){
      int brightness = (int)random(100, 255);
      fill(brightness, brightness, 200);
      noStroke();
      rect(starsX_start[i], starsY_start[i], 1, 1);
    }

    //流れ星
    if(shootingStarOn_start){
      // 流れ星があるならそれを流れさせる，確率で消す
      shootingStarX_start -= 4;
      shootingStarY_start += 3;
      fill(200);
      noStroke();
      rect(shootingStarX_start, shootingStarY_start, 3, 3);

      if(random(0, 1) < 0.02f){
        shootingStarOn_start = false;
      }
      if(shootingStarX_start < 0 || shootingStarY_start > height){
        shootingStarOn_start = false;
      }
    }else{
      // 流れ星が無いなら確率で流れ星を発生させる
      if(random(0, 1) < 0.01f){
        shootingStarX_start = (int)random(100, width);
        shootingStarY_start = (int)random(0, height-100);
        shootingStarOn_start = true;
      }
    }

    image(titleImg_start, width/2-300, 70, 600, 320);
    image(menu_start, 40, 40, 30, 30); 

    //スタート画面上の文字
    textAlign(CENTER);
    fill(0, 255, 255, textAlpha_start);
    textSize(30);
    text("Select the level", width/2-150, 400, 300, 50);
    fill(255, 255, 255);
    text("Menu", 50, 40, 125, 100);
    
    fill(200);
    noStroke();
    rect(width/2-100-125, 440, 125, 50);
    rect(width/2-125/2, 440, 125, 50);
    if(k_count >= 10){
      fill(30, 30, 30, textAlpha_hard);
      rect(width/2+100, 440, 125, 50);
    }
    noFill();
    stroke(150);
    strokeWeight(4);
    rect(width/2-100-120, 445, 115, 40);
    rect(width/2-115/2, 445, 115, 40);
    if(k_count >= 10){
      fill(0, 0, 0, textAlpha_hard);
      rect(width/2+100+5, 445, 115, 40);
    }
    fill(50);
    textSize(30);
    textAlign(CENTER);
    text("Easy", width/2-100-125, 450, 125, 100);
    text("Normal", width/2-125/2, 450, 125, 100);
    if(k_count >= 10){
      fill(255, 0, 0, textAlpha_hard);
      text("Hard", width/2+100, 450, 125, 100);
    }

    if(textAlphaIsAscending_start){   //徐々にSlect the levelが出現するように
     textAlpha_start += 2;
     if(textAlpha_start > 255)
       textAlphaIsAscending_start = false;
    }else{
      textAlpha_start -= 2;
     if(textAlpha_start < 0)
       textAlphaIsAscending_start = true;
    }
    if(k_count >= 10){                 //裏モードが徐々に出現するように
      if(textAlpha_hard < 255){
      textAlpha_hard += 2;
      }
    }
  }
  
  /***************** メニュー画面*************************/
  
  
  private void draw_menu() {
    // スタート画面での毎フレームの処理
    background(25, 25, 50);

    for(int i=0; i<starsNum_start; i++){
      int brightness = (int)random(100, 255);
      fill(brightness, brightness, 200);
      noStroke();
      rect(starsX_start[i], starsY_start[i], 1, 1);
    }

    if(shootingStarOn_start){
      // 流れ星があるならそれを流れさせる，確率で消す
      shootingStarX_start -= 4;
      shootingStarY_start += 3;
      fill(200);
      noStroke();
      rect(shootingStarX_start, shootingStarY_start, 3, 3);

      if(random(0, 1) < 0.02f){
        shootingStarOn_start = false;
      }
      if(shootingStarX_start < 0 || shootingStarY_start > height){
        shootingStarOn_start = false;
      }
    }else{
      // 流れ星が無いなら確率で流れ星を発生させる
      if(random(0, 1) < 0.01f){
        shootingStarX_start = (int)random(100, width);
        shootingStarY_start = (int)random(0, height-100);
        shootingStarOn_start = true;
      }
    }
    
    noStroke();
    //for(int i = 0; i < 6; i++){
    for(int i = 0; i < 7; i++){
      fill(242, 224, 201);
      ellipse(100, 125 + 60*i, 50, 50);
      rect(100, 100 + 60*i, 400, 50);
      fill(242, 201, 161);
      ellipse(500, 125 + 60*i, 50, 50);
      rect(500, 100 + 60*i, 200, 50);
      ellipse(700, 125 + 60*i, 50, 50);
      if(i == 0){
        fill(110, 118, 175);
        text("Move forward", 100, 100 + 25/2 + 60*i, 200, 100); 
        fill(255, 255, 255);
        rect(600, 105 + 70*i, 40, 40); 
        fill(0, 0, 0);
        text("W", 520, 100 + 25/2 + 60*i, 200, 100);
      } else if(i == 1){
        fill(110, 118, 175);
        text("Move backward", 100, 100 + 25/2 + 60*i, 200, 100); 
        fill(255, 255, 255);
        rect(600, 105 + 60*i, 40, 40); 
        fill(0, 0, 0);
        text("S", 520, 100 + 25/2 + 60*i, 200, 100);
      } else if(i == 2){
        fill(110, 118, 175);
        text("Move left", 100, 100 + 25/2 + 60*i, 200, 100); 
        fill(255, 255, 255);
        rect(600, 105 + 60*i, 40, 40); 
        fill(0, 0, 0);
        text("A", 520, 100 + 25/2 + 60*i, 200, 100);
      } else if(i == 3){
        fill(110, 118, 175);
        text("Move right", 100, 100 + 25/2 + 60*i, 200, 100); 
        fill(255, 255, 255);
        rect(600, 105 + 60*i, 40, 40); 
        fill(0, 0, 0);
        text("D", 520, 100 + 25/2 + 60*i, 200, 100);
      } else if(i == 4){
        fill(110, 118, 175);
        text("Shoot bullets", 100, 100 + 25/2 + 60*i, 200, 100); 
        fill(255, 255, 255);
        rect(532, 105 + 60*i, 170, 40); 
        fill(0, 0, 0);
        text("Left mouse button", 520, 100 + 25/2 + 60*i, 200, 100);
      } else if(i == 5){
        fill(110, 118, 175);
        text("Bomb", 100, 100 + 25/2 + 60*i, 200, 100); 
        fill(255, 255, 255);
        rect(532, 105 + 60*i, 170, 40); 
        fill(0, 0, 0);
        text("Right mouse button", 520, 100 + 25/2 + 60*i, 200, 100);
      } else if(i == 6){
        fill(110, 118, 175);
        text("Exit game", 100, 100 + 25/2 + 60*i, 200, 100); 
        fill(255, 255, 255);
        rect(585, 105 + 60*i, 70, 40); 
        fill(0, 0, 0);
        text("Esc", 520, 100 + 25/2 + 60*i, 200, 100);
      }
    }
    
    fill(255, 255, 255, textAlpha_start);
    text("How to play SHOOTING GAME", 200, 30, 400, 50);
    
    fill(200);
    //rect(width/2 + 200, 495, 100, 40); 
    rect(width/2 + 200, 545, 100, 40); 
    noFill();
    stroke(150);
    strokeWeight(4);
    rect(width/2 + 205, 550, 90, 30);
    fill(0, 0, 0);
    text("Back", width/2 + 150, 550, 200, 100);
    
   
    
    if(textAlphaIsAscending_start){   
     textAlpha_start += 1;
    }
  }
  
  
  

  /***************** ゲーム画面 **************************/
  int lastHP_game = 0;                //残りHP
  boolean isGameOver_game = false;    //GameOverかどうか

  int beated;                         //倒した敵の数
  
  boolean textAlphaIsAscending_game = false; //HPエフェクト
  int textAlpha_game = 255;           //HPエフェクトのための変数   
  boolean last_HP_50 = true;          //残りHPが50あるかどうか                   
  
  private void init_game() {
    // 難易度設定
    difficulty = scene;
    
    // ゲーム画面での初期化
    players = new ArrayList<Player>();
    enemies = new ArrayList<Enemy>();
    Player p = new Player(new PVector(width/2.0, height * (3/4.0)));
    players.add(p);
    isGameOver_game = false;
    // 画面内の敵の弾の上限数
    ebul_numlimit = 100;
    // 今現在の画面内の敵の弾の数
    ebul_numcurrent = 0;
    // 画面内の敵の弾の上限数（ボスバージョン）
    bossbul_numlimit = 400;
    // 今現在の画面内の敵の弾の数（ボスバージョン）
    bossbul_numcurrent = 0;

    boss = new Boss(new PVector(random(width), random(height)));
    boss_in = false;

    // 難易度に応じて、敵の出現頻度やボスまで何体倒すかを設定
    switch(difficulty) {
      case EASY_NUM:
        bomb_left = 2;
        e_born_intvl = 240;
        e_beatlimit = 7;
        break;
      case NORMAL_NUM:
        bomb_left = 1;
        e_born_intvl = 120;
        e_beatlimit = 10;
        break;
      case HARD_NUM:
        bomb_left = 0;
        e_born_intvl = 60;
        e_beatlimit = 12;
        break;
      default:
        break;
    }

    //ハードモードのみBGM変更
    if(scene == HARD_NUM){
      hardmord_game.rewind();
      hardmord_game.loop();
    } else {
      bgm_game.rewind();
      bgm_game.loop();
    }

    for (Player player : players) {
      player_p = player.getPosition();
    }
  }

  // イージー、ノーマル、ハード、全てここで対応するよう変更
  private void draw_game(int difficulty) {

    // 現在の難易度をクラスフィールドに記録
    this.difficulty = difficulty;

    // ゲーム画面での毎フレームの処理
    image(back, -player_p.x, -player_p.y);
    // ゲーム画面での毎フレームの処理

    lastHP_game = 0;
    is_previousmenu = 0;  //音楽のバグ修正
    
    if(frameCount % e_born_intvl == 0 && !boss_in) {  //難易度変更できる箇所(Enemyの生成)
      Enemy e = new Enemy(new PVector(random(width), random(height)));
      enemies.add(e);
    }

    for(int e_idx = 0; e_idx < enemies.size(); e_idx++) {
      Enemy enemy = enemies.get(e_idx);
      enemy.update();
      if(enemy.isHitted()){     //Enemyに自分の弾丸が当たった時
        score+=10;              //score加算
      }
      if(enemy.is_dead){        //Enemyが死んだとき
        enemies.remove(e_idx);
        score+=500;             //score加算 
        beated++;               //倒した敵数を一つ増やす
      }
      else
        enemy.draw();
    }

    if(boss_in){                //bossがいるとき
      boss.update();
      if (boss.is_dead){ // Bossが倒されたらisGameOver_gameをtrueにする
        isGameOver_game = true;
        beated++;
      }else{
        boss.draw();
      }
    }else if(beated >= e_beatlimit){ // enemy撃破数でtrueに変更(ここが難易度変更することができる部分：何体敵を倒せば，ボスが出現するか)
      boss_in = true;
    }

    for(Player player : players) {
      player.update();
      player.draw();
      player_p = player.getPosition();

      drawHP(player);
      drawLife(player);
      drawScore();
      // ボムの残り回数を描く
      drawBombLeft();

      if(player.getHP()<=0){
        player.setHP(100);
        player.life--;
        fill(255);
        textSize(30);
        delay(500);
      }
      if(player.getLife()<=0){
        isGameOver_game = true;
      }

      lastHP_game += player.getHP();
    }

    if(isGameOver_game)
      changeSceneTo(GAMEOVER_NUM);
  }


 void drawHP(Player player){    //HP描画
      fill(200);
      rect(30,8,200,30);
      println("life = " + player.getLife() + "HP = " + player.getHP());
      if(player.getHP() <= 30){     //HP表示の変更,30を切ると赤点滅になる，そして警告音が鳴る
        if(last_HP_50){   //サウンド
          warning.rewind();
          warning.loop();
          last_HP_50 = false;
        }
        fill(255,0,0, textAlpha_game);
        if(textAlphaIsAscending_game){   
          textAlpha_game += 10;
          if(textAlpha_game > 255){
            textAlphaIsAscending_game = false;
          }
        }else{
          textAlpha_game -= 10;
          if(textAlpha_game < 0){
            textAlphaIsAscending_game = true;
          }
        }
      } else {
        warning.pause();
        fill(#ADFF2F);
        last_HP_50 = true;
      }
      rect(30,8,player.getHP()*2,30);
  }

 void drawLife(Player player){    //ライフ描画
       fill(255);
       textSize(30);
       text("LIFE:"+player.getLife(),100,70);
 }

 void drawScore(){                //スコア描画
    fill(255);
    textSize(30);
    text("SCORE:"+score,width/2.0,35);
  }


  // ボムの残り回数を描く
  public void drawBombLeft() {
    fill(255);
    textSize(30);
    text("BOMB_LEFT:"+bomb_left, 135, 100);
  }

  /************* ゲームオーバー画面 ***********************/
  int frameCount_over = 0;

  private void init_over() {
    // ゲームオーバー画面での初期化
    background(25, 25, 50);
    fill(255);
    rect(50, 50, width-100, height-100);
    frameCount_over = 0;

    bgm_over.rewind();
    bgm_over.loop();
  }

  private void draw_over() {
    // ゲームオーバー画面での毎フレームの処理

    stroke(0);
    strokeWeight(2);
    line(width/2-(frameCount_over%20)*5, 150, width/2+(frameCount_over%20)*5, 150);
    strokeWeight(1);

    fill(50);
    textAlign(CENTER);
    text("RESULT", 100, 100, width-200, 50);

    textAlign(LEFT);
    text("Score : ", 100, 200, width-200, 100);

    text("Beated : ", 100, 300, width-200, 100);

    if(frameCount_over > 40){ // スコアを時間差で表示
      textAlign(RIGHT);
      text(str(score), 100, 200, width-200, 100);
    }

    if(frameCount_over > 80){ // 残りHPを時間差で表示
      textAlign(RIGHT);
      text(str(beated), 100, 300, width-200, 100);
    }

    if(frameCount_over > 120){ // RetryボタンとExitボタンを時間差で表示
      fill(200);
      noStroke();
      rect(width/2-100-125, 440, 125, 50);
      rect(width/2+100, 440, 125, 50);
      noFill();
      stroke(150);
      strokeWeight(4);
      rect(width/2-100-120, 445, 115, 40);
      rect(width/2+100+5, 445, 115, 40);
      fill(50);
      textAlign(CENTER);
      text("Retry", width/2-100-125, 450, 125, 100);
      text("Exit", width/2+100, 450, 125, 100);
    }

    textAlign(LEFT);
    strokeWeight(1);
    frameCount_over ++;
  }

  /********************************************************/

  void changeSceneTo(int sceneNo){ // 引数sceneNoのシーンへ遷移
    // sceneNo は 0:スタート画面，1:EasyModeのゲーム画面， 2:NormalModeのゲーム画面，3:HardModeのゲーム画面, -1:ゲームオーバー画面, -2:Menu画面
    if(sceneNo == EASY_NUM){
      bgm_start.pause();
      bgm_over.pause();
      
      scene = EASY_NUM;
      init_game();
    }else if(sceneNo == GAMEOVER_NUM){
      bgm_game.pause();
      hardmord_game.pause();
      scene = GAMEOVER_NUM;
      init_over();
    }else if(sceneNo == START_NUM){
      bgm_over.pause();
      scene = START_NUM;
      init_start();
    }else if(sceneNo == NORMAL_NUM){
      bgm_start.pause();
      bgm_over.pause();
      
      scene = NORMAL_NUM;
      init_game();
    }else if(sceneNo == HARD_NUM){
      bgm_start.pause();
      bgm_over.pause();
      
      scene = HARD_NUM;
      init_game();
    }else if(sceneNo == MENU_NUM){
      scene = MENU_NUM;
    }
  }
  
  void keyPressed(int key) {
    if(scene == START_NUM){ // スタート画面
      if(key == 'k'){  //裏モード(Hard)の出現
        k_count++;
        if(k_count == 10){
          hardmord.rewind();
          hardmord.play();
        }
      }
    }


    if(scene == EASY_NUM){ // ゲーム画面
      if(key == 'a'){
        //isGameOver_game = true; // デバッグ用
      }
    }

    if(scene == GAMEOVER_NUM){ // ゲームオーバー画面
      if(key == ENTER){
        sound_pikin.rewind();
        sound_pikin.play();
        changeSceneTo(START_NUM);
      }
    }

    if(key == 'e') {
      Enemy e = new Enemy(new PVector(random(width), random(height)));
      enemies.add(e);
    }

    for(Player player : players) player.keyPressed(key);
    for(Enemy enemy : enemies) enemy.keyPressed(key);
  }
  
  void keyReleased(int key){
    for(Player player : players) player.keyReleased(key);
  }

  void mousePressed(){
    if(scene == START_NUM){  //ゲームスタート画面
      if(10 < mouseY && mouseY < 10 + 60){ //Menuボタン
        if(10 < mouseX && mouseX < 10 + 140){
          is_previousmenu = 0;
          changeSceneTo(MENU_NUM);
          sound_pikin.rewind();
          sound_pikin.play();
        }
      }
      if(450 < mouseY && mouseY < 450+100){
        if(width/2-100-125 < mouseX && mouseX < width/2-100){ // Easyボタン
          changeSceneTo(EASY_NUM);
          sound_pikin.rewind();
          sound_pikin.play();
        }
        if(width/2-125/2 < mouseX && mouseX < width/2+125/2){ // Normalボタン
          changeSceneTo(NORMAL_NUM);
          sound_pikin.rewind();
          sound_pikin.play();
        }
        if(k_count >= 10){  //裏モード
          if(width/2+100 < mouseX && mouseX < width/2+100+125){ // Hardボタン
            changeSceneTo(HARD_NUM);
            sound_pikin.rewind();
            sound_pikin.play();
          }
        }
      }
    }
    
    if(scene == MENU_NUM){  //メニュー画面 
      if(550 < mouseY && mouseY < 550 + 30){ //Backボタン
        if(width/2 + 205 < mouseX && mouseX < width/2 + 205 + 90){
          is_previousmenu = 1;
          changeSceneTo(START_NUM);
          sound_pikin.rewind();
          sound_pikin.play();
        }
      }
    }
    

    if(scene >= EASY_NUM) {
      for(Player player : players) player.mousePressed();
      for(Enemy enemy : enemies) enemy.keyPressed(key);
    }
    
    
    if(scene == GAMEOVER_NUM){ // ゲームオーバー画面
      if(450 < mouseY && mouseY < 450+100){
        if(width/2-100-125 < mouseX && mouseX < width/2-100){ // Retryボタン
          changeSceneTo(START_NUM);
          sound_pikin.rewind();
          sound_pikin.play();
          score = 0;
          boss_in = false;
          beated = 0;
        }
        if(width/2+100 < mouseX && mouseX < width/2+100+125){ // Exitボタン
          sound_pikin.rewind();
          sound_pikin.play();
          getPApplet().stop();
          exit();
        }
      }
    }
  }

  void stopMusic(){
    bgm_start.close();
    bgm_game.close();
    bgm_over.close();
    sound_pikin.close();
    hardmord.close();
    hardmord_game.close();
    warning.close();
    minim.stop();
  }
}
