from moderngl import Program
from game_object import GameObject

class Scene:
    def __init__(self, program:Program):
        self.gameObjects = [
            GameObject((-2, 0, 0), (1, 1, 1), (0.8,0.2,0.1), 0, 0),
            GameObject((-2, 0,-3), (1, 1, 1), (1,   1,   1), 1, 0),
            GameObject((2, 0,  0), (1, 1, 1), (0.5,0.4,0.6), 0, 1),
            GameObject((6, 0,  0), (1, 1, 1), (0.5,0.4,0.6), 0, 1),
            GameObject((0, -1, 0), (0, 1, 0), (0.5,0.2,0.1), 0, 2),
        ]

        for j,i in enumerate(self.gameObjects):
            program[f"shapes[{j}].position"] = i.position
            program[f"shapes[{j}].size"] = i.size
            program[f"shapes[{j}].type"] = i.type
            program[f"shapes[{j}].material.color"] = i.color
            program[f"shapes[{j}].material.type"] = i.material