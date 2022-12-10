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

compute_knot_velocity :: (using knot: *Knot, graph: []Knot) {
    TARGET_DISTANCE :: 100;
    STIFFNESS :: 20;
    velocity = make_vector2(0);
    for neighbors {
        neighbor := *graph[it];
        len := length(position - neighbor.position);
        dir := ifx len > EPSILON then (position - neighbor.position)/len else make_vector2(1, 0);
        target := neighbor.position + dir*TARGET_DISTANCE;
        velocity += (target - position)*STIFFNESS;
    }

    for *other: graph {
        if other != knot && length(knot.position - other.position) <= KNOT_RADIUS*2 {
            len := length(knot.position - other.position);
            dir := ifx len > EPSILON then (knot.position - other.position)/len else make_vector2(1, 0);
            REPULSION :: 0.5;
            velocity += (knot.position - other.position)*REPULSION;
        }
    }
}

Knot :: struct {
    position: Vector2;
    velocity: Vector2;
    neighbors: [..]int;
}

main :: () {
    the_window := create_window(window_width, window_height, "Rope Simulation");
    Simp.set_render_target(the_window);
    quit := false;
    drag := -1;
    knots : [..]Knot;
    array_add(*knots, .{
        position = make_vector2(xx (window_width/2), xx (window_height/2))
    });
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
                    case .MOUSE_BUTTON_RIGHT; if !it.key_pressed {
                        for *knots {
                            if length(mouse_position() - it.position) <= KNOT_RADIUS {
                                new_knot : Knot;
                                new_knot.position = mouse_position();
                                array_add(*new_knot.neighbors, it_index);
                                array_add(*it.neighbors, knots.count);
                                array_add(*knots, new_knot);
                                break;
                            }
                        }
                    }

                    case .MOUSE_BUTTON_LEFT; if it.key_pressed {
                        for *knots {
                            if length(mouse_position() - it.position) <= KNOT_RADIUS {
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
            knots[drag].position = mouse_position();
        }

        for *knots {
            compute_knot_velocity(it, knots);
            if it_index != drag then it.position += it.velocity*current_dt;
        }

        for *knot: knots {
            for knot.neighbors {
                neighbor := *knots[it];
                immediate_thicc_line(knot.position, neighbor.position, 30, make_vector4(.5, .5, .5, 1));
            }
        }

        for *knot: knots {
            immediate_circle(knot.position, KNOT_RADIUS, COLOR_GREEN);
        }

        Simp.swap_buffers(the_window);

        sleep_milliseconds(10);
    }
}
