# A simple space invader type game
# for DragonRuby by Akzidenz-Grotesk

def tick args
  # set up initial values
  defaults args
  # check the user input and handle it
  check_inputs args
  # perform calculations
  calc args
  # draw the results
  render args
end

# set up initial values
def defaults args

  # general defaults
  args.state.margin ||= 40
  args.state.game_state ||= "playing"

  # player defaults
  args.state.player_y ||= args.state.margin
  args.state.player_x ||= 100
  args.state.player_w ||= 80
  args.state.player_h ||= 80
  args.state.player_speed ||= 5

  # player bullet defaults
  args.state.player_bullet_x ||= -500
  args.state.player_bullet_y ||= -500
  args.state.player_bullet_w ||= 10
  args.state.player_bullet_h ||= 40
  args.state.player_bullet_speed ||= 10
  args.state.player_bullet_shooting ||= false

  # enemy defaults
  args.state.enemy_x ||= 40
  args.state.enemy_y ||= 600
  args.state.enemy_w ||= 80
  args.state.enemy_h ||= 80
  args.state.enemy_speed ||= 2
  args.state.enemy_dir ||= 1

  # enemy bullet defaults
  args.state.enemy_bullet_x ||= -500
  args.state.enemy_bullet_y ||= -500
  args.state.enemy_bullet_w ||= 10
  args.state.enemy_bullet_h ||= 40
  args.state.enemy_bullet_speed ||= 10
  args.state.enemy_bullet_shooting ||= false
end

# see if the user pressed any keys and react
def check_inputs args
  # if the game is over
  if args.state.game_state != "playing"
    # let the player press enter to restart
    if args.inputs.keyboard.key_down.enter
      # quick way to reset the whole game
      $gtk.reset
    end
    # stop processing this method and go back to the previous
    return
  end

  # player movement
  if args.inputs.left
    args.state.player_x -= args.state.player_speed
  end
  if args.inputs.right
    args.state.player_x += args.state.player_speed
  end

  # player shooting
  if args.inputs.keyboard.key_down.space
    shoot args
  end
end

# player shoots bullet
def shoot args
  # keep track of whether the bullet is being shot
  args.state.player_bullet_shooting = true
  # set the bullet's position to the player's center
  args.state.player_bullet_x = args.state.player_x + args.state.player_w / 2
  args.state.player_bullet_y = args.state.player_y
end

# perform calculations that need to be done every tick
def calc args
  #get out of this method if the game is over
  return if args.state.game_state != "playing"
  # move the player's bullet
  move_player_bullet args
  # move the enemy
  move_enemy args
  # randomly fire enemy bullet
  enemy_shoot args
  # move the enemy's bullet
  move_enemy_bullet args
end

# check to see if the enemy has been hit
def check_enemy_hit args
  # define a rectangle around the enemy
  enemy_hitbox = [
    args.state.enemy_x,
    args.state.enemy_y,
    args.state.enemy_w,
    args.state.enemy_h
  ]
  # define a rect around the player's bullet
  player_bullet_hitbox = [
    args.state.player_bullet_x,
    args.state.player_bullet_y,
    args.state.player_bullet_w,
    args.state.player_bullet_h
  ]
  
  # draw the hitbox rects
  args.outputs.debug << {
    x: enemy_hitbox.x,
    y: enemy_hitbox.y,
    w: enemy_hitbox.w,
    h: enemy_hitbox.h,
    r: 255, 
    g: 0,
    b: 0
  }.border

  args.outputs.debug << {
    x: player_bullet_hitbox.x,
    y: player_bullet_hitbox.y,
    w: player_bullet_hitbox.w,
    h: player_bullet_hitbox.h, 
    r: 255, 
    g: 0, 
    b: 0
  }.border

  # check to see if the rects overlap
  if enemy_hitbox.intersect_rect? player_bullet_hitbox
    # the enemy has been hit
    game_over args, "win"
  end
end

def check_player_hit args
  # define a rectangle around the player
  player_hitbox = [
    args.state.player_x,
    args.state.player_y,
    args.state.player_w,
    args.state.player_h
  ]
  # define a rect around the enemy's bullet
  enemy_bullet_hitbox = [
    args.state.enemy_bullet_x,
    args.state.enemy_bullet_y,
    args.state.enemy_bullet_w,
    args.state.enemy_bullet_h
  ]
  
  # draw a border around the hitbox rects
  args.outputs.debug << {
    x: player_hitbox.x,
    y: player_hitbox.y,
    w: player_hitbox.w,
    h: player_hitbox.h, 
    r: 255, 
    g: 0, 
    b: 0
  }.border

  args.outputs.debug << {
    x: enemy_bullet_hitbox.x,
    y: enemy_bullet_hitbox.y,
    w: enemy_bullet_hitbox.w,
    h: enemy_bullet_hitbox.h, 
    r: 255, 
    g: 0, 
    b: 0
  }.border

  # check to see if the rects overlap
  if player_hitbox.intersect_rect? enemy_bullet_hitbox
    # the player has been hit
    game_over args, "lose"
  end
end

# the enemy randomly fires bullets at the player
def enemy_shoot args
  # generate a random number from 0 to 99
  r = rand(100)
  # is the random number 0? that give a a 1 in 100 chance of shooting
  # is the enemy shooting? Only shoot if not already shooting.
  if r == 1 && args.state.enemy_bullet_shooting == false
    # set the enemy bullet position to the enemy position
    args.state.enemy_bullet_x = args.state.enemy_x + args.state.enemy_w / 2
    args.state.enemy_bullet_y = args.state.enemy_y
    # track state of enemy bullet
    args.state.enemy_bullet_shooting = true
  end
end

# update enemy position
def move_enemy args

  # define our right and left boundaries
  right = 1280 - args.state.enemy_w - args.state.margin
  left = args.state.margin

  # if enemy reaches the left or right boundary...
  if args.state.enemy_x < left || args.state.enemy_x > right
    # reverse the enemy's direction
    args.state.enemy_dir = -args.state.enemy_dir
  end

  # calculate the enemy's next x position
  args.state.enemy_x += args.state.enemy_speed * args.state.enemy_dir
end

# update the player bullet position
def move_player_bullet args
  # don't update the position if the bullet isn't in action
  if args.state.player_bullet_shooting
    # go see if the bullet hit the enemy
    check_enemy_hit args
    # update the bullet y position
    args.state.player_bullet_y += 10    
    # has the bullet gone off the top of the screen?
    if args.state.player_bullet_y > 720
      # don't bother updating it
      args.state.player_bullet_shooting = false
    end
  end
end

# update the enemy bullet position
def move_enemy_bullet args
  # don't update the position if the bullet isn't in action
  if args.state.enemy_bullet_shooting
    # go see if the bullet hit the player
    check_player_hit args
    # update the bullet y position
    args.state.enemy_bullet_y -= 10
    # has the bullet gone off the bottom of the screen?
    if args.state.enemy_bullet_y < 0 - args.state.enemy_bullet_h
      # don't bother updating it
      args.state.enemy_bullet_shooting = false
    end
  end
end

# the game is done, did you win?
def game_over args, win_or_lose
  # keep track of whether you won or lost
  args.state.game_state = win_or_lose
end

# draw the game to the screen
def render args
  # draw the player's bullet
  render_player_bullet args
  # draw the player
  render_player args
  # draw the enemy bullet
  render_enemy_bullet args
  # draw the enemy
  render_enemy args
  # draw game over
  render_game_over args
end

# draw the player bullet
def render_player_bullet args 
  args.outputs.sprites << {
    x: args.state.player_bullet_x,
    y: args.state.player_bullet_y,
    w: args.state.player_bullet_w,
    h: args.state.player_bullet_h,
    path: 'sprites/square/blue.png'
  }
end

# draw the enemy bullet
def render_enemy_bullet args 
  args.outputs.sprites << {
    x: args.state.enemy_bullet_x,
    y: args.state.enemy_bullet_y,
    w: args.state.enemy_bullet_w,
    h: args.state.enemy_bullet_h,
    path: 'sprites/square/orange.png'
  }
end

# draw the player
def render_player args
  args.outputs.sprites << {
    x: args.state.player_x,
    y: args.state.player_y,
    w: args.state.player_w, 
    h: args.state.player_h,
    path: 'sprites/circle/blue.png',
    angle: 90
  }
end

# draw the enemy
def render_enemy args
  args.outputs.sprites << {
    x: args.state.enemy_x,
    y: args.state.enemy_y,
    w: args.state.enemy_w,
    h: args.state.enemy_h,
    path: 'sprites/hexagon/orange.png'
  }
end

def render_game_over args
  return if args.state.game_state == "playing"
  args.outputs.solids << {
    x: 0, 
    y: 0, 
    w: 1280,
    h: 720
  }
  args.outputs.labels << {
    x: 1280/2, 
    y: 500, 
    text: "You #{args.state.game_state}!", 
    size_enum: 120, 
    alignment_enum: 1, 
    r: 255, 
    g: 255, 
    b: 255
  }
end

# just a helpful message
def debug args, msg
  args.outputs.debug << {
    x: 10, 
    y: 700, 
    text: msg
  }.label
end