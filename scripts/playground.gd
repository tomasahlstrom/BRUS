extends Node2D
## BRUS Technical Test 001: procedural forest, player movement and 2D lights.
## Controls: WASD/arrows, gamepad left stick, or touch/click a destination.

const WORLD_SIZE := Vector2(2200, 1500)
const PLAYER_SPEED := 170.0
const TREE_COUNT := 165

var player_pos := Vector2(260, 760)
var target_pos := Vector2.ZERO
var moving_to_target := false
var trees: Array[Dictionary] = []
var camera: Camera2D
var player_light: PointLight2D
var beacon_light: PointLight2D
var beacon_pos := Vector2(1810, 690)
var elapsed := 0.0
var status_label: Label

func _ready() -> void:
    _make_forest()
    camera = Camera2D.new()
    camera.position = player_pos
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 4.0
    add_child(camera)
    camera.make_current()

    var ambient := CanvasModulate.new()
    ambient.color = Color(0.32, 0.40, 0.49)
    add_child(ambient)

    player_light = _make_light(Color(0.82, 0.92, 1.0), 1.15, 2.4)
    player_light.position = player_pos
    add_child(player_light)

    beacon_light = _make_light(Color(1.0, 0.06, 0.045), 2.3, 3.5)
    beacon_light.position = beacon_pos
    add_child(beacon_light)

    var ui := CanvasLayer.new()
    add_child(ui)
    status_label = Label.new()
    status_label.position = Vector2(20, 18)
    status_label.add_theme_font_size_override("font_size", 18)
    status_label.text = "BRUS  /  TECHNICAL TEST 001"
    ui.add_child(status_label)
    var help := Label.new()
    help.position = Vector2(20, 48)
    help.add_theme_font_size_override("font_size", 14)
    help.text = "WASD / arrows / gamepad  •  tap to walk"
    ui.add_child(help)

func _make_forest() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 19041946
    for i in range(TREE_COUNT):
        var p := Vector2(rng.randf_range(50, WORLD_SIZE.x - 50), rng.randf_range(50, WORLD_SIZE.y - 50))
        # Keep the central service road clear.
        if absf(p.y - 760.0 + sin(p.x * 0.004) * 75.0) < 115.0:
            continue
        trees.append({"pos": p, "size": rng.randf_range(20.0, 43.0), "shade": rng.randf_range(0.0, 0.12)})

func _make_light(tint: Color, energy: float, scale_factor: float) -> PointLight2D:
    var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
    for y in range(128):
        for x in range(128):
            var d := Vector2(x - 63.5, y - 63.5).length() / 63.5
            var a := pow(maxf(0.0, 1.0 - d), 2.0)
            image.set_pixel(x, y, Color(1, 1, 1, a))
    var texture := ImageTexture.create_from_image(image)
    var light := PointLight2D.new()
    light.texture = texture
    light.color = tint
    light.energy = energy
    light.texture_scale = scale_factor
    return light

func _process(delta: float) -> void:
    elapsed += delta
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if direction.length_squared() > 0.001:
        moving_to_target = false
    elif moving_to_target:
        var diff := target_pos - player_pos
        if diff.length() < 7.0:
            moving_to_target = false
        else:
            direction = diff.normalized()
    player_pos += direction * PLAYER_SPEED * delta
    player_pos = player_pos.clamp(Vector2(24, 24), WORLD_SIZE - Vector2(24, 24))
    player_light.position = player_pos
    camera.position = player_pos
    # A brief red pulse every ~3.5 seconds.
    var pulse := fposmod(elapsed, 3.5)
    beacon_light.enabled = pulse < 0.35
    beacon_light.energy = 3.5 if pulse < 0.12 else 1.8
    status_label.text = "BRUS  /  TECHNICAL TEST 001   |   X: %d  Y: %d" % [int(player_pos.x), int(player_pos.y)]
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        target_pos = get_global_mouse_position()
        moving_to_target = true
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        target_pos = get_global_mouse_position()
        moving_to_target = true

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#101b21"))
    # Service road: broad dark strip with narrow highlights.
    var road := PackedVector2Array()
    for i in range(45):
        var x := float(i) * 50.0
        road.append(Vector2(x, 760.0 - sin(x * 0.004) * 75.0 - 68.0))
    for i in range(44, -1, -1):
        var x := float(i) * 50.0
        road.append(Vector2(x, 760.0 - sin(x * 0.004) * 75.0 + 68.0))
    draw_colored_polygon(road, Color("#28312e"))
    for tree in trees:
        var p: Vector2 = tree["pos"]
        var s: float = tree["size"]
        var shade: float = tree["shade"]
        draw_circle(p + Vector2(7, 12), s * 0.75, Color(0.015, 0.025, 0.035, 0.6))
        draw_circle(p, s, Color(0.055 + shade, 0.13 + shade, 0.13 + shade))
        draw_circle(p + Vector2(-s * 0.22, -s * 0.24), s * 0.55, Color(0.09 + shade, 0.20 + shade, 0.18 + shade))
    # Small radio building and mast beacon.
    draw_rect(Rect2(Vector2(1710, 575), Vector2(245, 195)), Color("#3b4648"))
    draw_rect(Rect2(Vector2(1740, 605), Vector2(185, 125)), Color("#232b31"))
    draw_rect(Rect2(Vector2(1800, 690), Vector2(42, 80)), Color("#10171d"))
    draw_line(beacon_pos, beacon_pos + Vector2(0, -240), Color("#6c777b"), 5.0)
    draw_circle(beacon_pos + Vector2(0, -240), 8.0, Color("#ff3b31") if beacon_light.enabled else Color("#60201e"))
    draw_circle(player_pos + Vector2(3, 5), 12.0, Color(0, 0, 0, 0.4))
    draw_circle(player_pos, 10.0, Color("#b4c5ba"))
    draw_circle(player_pos + Vector2(0, -4), 5.0, Color("#d8c9a3"))
    if moving_to_target:
        draw_arc(target_pos, 10, 0, TAU, 20, Color("#a6b5b2"), 1.5)
