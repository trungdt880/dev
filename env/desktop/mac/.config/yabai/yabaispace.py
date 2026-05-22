#! /Users/termanteus/miniforge3/bin/python
import json
import subprocess
import sys
from typing import Dict, List

import numpy as np


def get_nth_space(index: int) -> int:
    spaces = get_non_native_spaces()

    if index - 1 >= len(spaces):
        return spaces[-1]["index"]

    return spaces[index - 1]["index"]


def get_next_space() -> int:
    return get_adjacent_space(False)


def get_previous_space() -> int:
    return get_adjacent_space(True)


def get_adjacent_space(prev: bool) -> int:
    spaces = get_non_native_spaces()
    focused_space_idx = np.argwhere([space["has-focus"] for space in spaces])[0][0]
    target_space_idx = (
        (focused_space_idx - 1) % len(spaces)
        if prev
        else (focused_space_idx + 1) % len(spaces)
    )
    return spaces[target_space_idx]["index"]


def get_non_native_spaces() -> List[Dict]:
    spaces = json.loads(
        subprocess.run(
            ["yabai", "-m", "query", "--spaces"], stdout=subprocess.PIPE
        ).stdout.decode("utf-8")
    )
    spaces = [space for space in spaces if not space["is-native-fullscreen"]]
    spaces = sorted(spaces, key=lambda x: (x["display"], x["index"]))
    spaces = [
        {
            k: v
            for k, v in space.items()
            if k in ["index", "label", "display", "has-focus"]
        }
        for space in spaces
    ]
    return spaces


def get_first_space_from_display(display_idx: int) -> int:
    spaces = get_non_native_spaces()
    firs_space = [space for space in spaces if space["display"] == display_idx][0]
    return firs_space["index"]


if __name__ == "__main__":
    func_name = sys.argv[1]
    if func_name in ["get_next_space", "get_previous_space"]:
        print(globals()[func_name]())
    else:
        print(globals()[func_name](int(sys.argv[2])))
