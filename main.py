import pygame as pg
import moderngl as mgl
from pygame.locals import *
import numpy as np

from camera import Camera
from scene import Scene

class Engine:
    screen_size = (1920, 1080)

    def __init__(self):
        pg.init()

        self.screen = pg.display.set_mode(self.screen_size, DOUBLEBUF | OPENGL | FULLSCREEN, vsync=1)
        self.ctx = mgl.create_context() 

        self.clock = pg.time.Clock()
        self.delta_time = 0
        self.time = 0
        self.tick = 1

        pg.mouse.set_visible(False)

        self.is_running = True
        self.on_init()

    def on_init(self):
        self.prog = self.get_program()
        self.camera = Camera(pg.Vector3(0, 0, -5))

        self.prog['resolution'] = self.screen_size
        # texture = self.ctx.texture((2560, 1280), 4, pg.image.tobytes(pg.image.load('assets/bg.jpg').convert(), 'RGBA'))
        # texture.use(location=0)

        self.vao = self.ctx.simple_vertex_array(self.prog, self.ctx.buffer(np.array([[-1, -1], [1, -1], [-1, 1], [1, 1]], dtype=np.float32)), 'in_vert')

        self.scene = Scene(self.prog)

        self.texture = self.ctx.texture(self.screen_size, 4)

        # Створення FBO
        self.fbo = self.ctx.framebuffer(color_attachments=[self.texture])

    def get_program(self):
        with open(f'program/vertex.glsl') as file:
            vertex_shader = file.read()

        with open(f'program/fragment.glsl') as file:
            fragment_shader = file.read()

        return self.ctx.program(vertex_shader=vertex_shader, fragment_shader=fragment_shader)

    def handle_events(self):
        for event in pg.event.get():
            if event.type == QUIT or (event.type == KEYDOWN and event.key == K_ESCAPE):
                self.is_running = False

    def render(self):
        self.fbo.use()
        self.ctx.clear(0, 0, 0)
        self.vao.render(mgl.TRIANGLE_STRIP)

        self.ctx.screen.use()
        self.ctx.clear(0.0, 0.0, 0.0)
        self.texture.use()
        self.vao.render(mgl.TRIANGLE_STRIP)
        pg.display.flip()

    def update(self):
        self.prog['cam_pos'] = self.camera.position
        self.prog['cam_rot'] = self.camera.rotation

        self.prog['u_seed1'] = np.random.rand(2)
        self.prog['u_seed2'] = np.random.rand(2)

        self.prog['sample_part'] = 1

        self.camera.update()

    def run(self):
        while self.is_running:
            self.handle_events()
            self.update()
            self.render()
            self.clock.tick(60)
            self.tick += 1
        quit()

if __name__ == '__main__':
    engine = Engine()
    engine.run()