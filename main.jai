#import "Basic";
#import "Window_Creation";
#import "Input";
#import "Math";
#import "Random";
Simp :: #import "Simp";

WINDOW_FACTOR     :: 100;
WINDOW_WIDTH      :: 16*WINDOW_FACTOR;
WINDOW_HEIGHT     :: 9*WINDOW_FACTOR;
COLOR_RED         :: Vector4.{1, 0, 0, 1};
COLOR_GREEN       :: Vector4.{0, 1, 0, 1};
COLOR_BLUE        :: Vector4.{0, 0, 1, 1};
CIRCLE_RESOLUTION :: 30;
KNOT_RADIUS       :: 30;
EPSILON :: 0.000001;

window_width := WINDOW_WIDTH;
window_height := WINDOW_HEIGHT;

immediate_thicc_line :: (p0: Vector2, p1: Vector2, t: float, color: Vector4) {
    v1 := p1 - p0;
    v2 := make_vector2(-v1.y, v1.x);
    v2l := sqrt(v2.x*v2.x + v2.y*v2.y);
    if v2l > EPSILON {
        v2.x /= v2l;
        v2.y /= v2l;
        Simp.immediate_quad(p0 + v2*(t/2), p0 - v2*(t/2), p1 - v2*(t/2), p1 + v2*(t/2), color);
    }
}

immediate_circle :: (center: Vector2, radius: float, color: Vector4) {
    STEP_ANGLE :: 2*PI/CIRCLE_RESOLUTION;
    for 0..CIRCLE_RESOLUTION-1 {
        p0 := center;
        p1 := center + make_vector2(cos(STEP_ANGLE*it), sin(STEP_ANGLE*it))*radius;
        p2 := center + make_vector2(cos(STEP_ANGLE*(it + 1)), sin(STEP_ANGLE*(it + 1)))*radius;
        Simp.immediate_triangle(
            make_vector3(p0, 0), make_vector3(p1, 0), make_vector3(p2, 0),
            color, color, color);
    }
}
 
mouse_position :: () -> Vector2 {
    x, y, success := get_mouse_pointer_position();
    assert(success);
    return make_vector2(xx x, xx (window_height - y));
}

compute_knot_velocity :: (knot: Vector2, nbors: .. Vector2) -> Vector2 {
    TARGET_DISTANCE :: 100;
    STIFFNESS :: 20;
    result := make_vector2(0);
    for nbors {
        len := length(knot - it);
        dir := ifx len > EPSILON then (knot - it)/len else make_vector2(1, 0);
        target := it + dir*TARGET_DISTANCE;
        result += (target - knot)*STIFFNESS;
    }
    return result;
}

main :: () {
    the_window := create_window(window_width, window_height, "Rope Simulation");
    Simp.set_render_target(the_window);
    quit := false;
    drag := -1;
    ROPE_LENGTH :: 10;
    rope : [ROPE_LENGTH]Vector2;
    for *rope {
        it.x = random_get_zero_to_one()*window_width;
        it.y = random_get_zero_to_one()*window_height;
    }
    rope_velocity : [ROPE_LENGTH]Vector2;
    last_time := get_time();
    while !quit {
        now := get_time();
        delta : float64 = now - last_time;
        current_dt := cast(float) delta;
        last_time = now;

        update_window_events();
        for get_window_resizes() {
            Simp.update_window(it.window);
            window_width = it.width;
            window_height = it.height;
        }

        for events_this_frame {
            if it.type == {
                case .QUIT; quit = true;
                case .KEYBOARD; if it.key_code == {
                    case .MOUSE_BUTTON_LEFT; if it.key_pressed {
                        for *rope {
                            if length(mouse_position() - it) <= KNOT_RADIUS {
                                drag = it_index;
                                break;
                            }
                        }
                    } else {
                        drag = -1;
                    }
                }
            }
        }
        Simp.clear_render_target(.08, .08, .08, 1);
        
        Simp.set_shader_for_color();

        if drag >= 0 {
            rope[drag] = mouse_position();
        }

        if ROPE_LENGTH > 1 {
            rope_velocity[0] = compute_knot_velocity(rope[0], rope[1]);
            for 1..ROPE_LENGTH-2 {
                rope_velocity[it] = compute_knot_velocity(rope[it], rope[it-1], rope[it+1]);
            }
            rope_velocity[ROPE_LENGTH-1] = compute_knot_velocity(rope[ROPE_LENGTH-1], rope[ROPE_LENGTH-2]);
        }

        for 0..ROPE_LENGTH-1 {
            if it != drag {
                rope[it] += rope_velocity[it]*current_dt;
            }
        }

        for 0..ROPE_LENGTH-2 {
            immediate_thicc_line(rope[it], rope[it+1], 30, make_vector4(.5, .5, .5, 1));
        }

        for 0..ROPE_LENGTH-1 {
            immediate_circle(rope[it], KNOT_RADIUS, COLOR_GREEN);
        }

        Simp.swap_buffers(the_window);

        sleep_milliseconds(10);
    }
}
