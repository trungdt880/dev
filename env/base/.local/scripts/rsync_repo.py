#!/usr/bin/env python

import importlib
import os
import sys
from typing import List, Optional

if sys.version_info[1] < 7:
    raise Exception("Must be using Python >= 3.7")

PYTHON_PATH = sys.executable


def import_neccessary_modules(modname: str) -> None:
    lookup = {"yaml": "pyyaml"}
    try:
        # If Module it is already installed, try to Import it
        importlib.import_module(modname)
    except ImportError:
        # Error if Module is not installed Yet,  the '\033[93m' is just code to print in certain colors
        print(f"\033[93mSince you don't have the Python Module [{modname}] installed!")
        print("Installing it using Python's pip command.\033[0m")
        if modname in lookup:
            modname = lookup[modname]
        if os.system(f"{PYTHON_PATH} -m pip --version") == 0:
            # No error from running PIP in the Command Window, therefor PIP.exe is in the %PATH%
            os.system(f"{PYTHON_PATH} -m pip install {modname}")
        else:
            print(f"\033[91mAbort!!!  pip not found.")
            print(
                f"You'll need to manually install the Module: {modname} in order for this program to work."
            )
            exit()


import subprocess
from pathlib import Path

import_neccessary_modules("pydantic")
import_neccessary_modules("yaml")
import_neccessary_modules("typer")
import_neccessary_modules("typing_extensions")

import typer
import yaml
from pydantic import (BaseModel, Field, ValidationError, field_validator,
                      validator)
from pydantic.functional_validators import AfterValidator
from typing_extensions import Annotated


def check_path_exists(path: str) -> str:
    p = Path(path)
    assert p.exists(), f"Path {path} does not exist."
    return path


def check_has_space(path: str) -> str:
    counter = path.count(" ")
    assert counter == 0, "Path has space in it, not supported for now"
    return path


def check_is_remote_path(path: str) -> str:
    counter = path.count(":")
    assert counter == 1, f"Remote dir ({path}) should have only one (:)"
    return path


SafePath = Annotated[
    str, AfterValidator(check_has_space), AfterValidator(check_path_exists)
]
RemotePath = Annotated[
    str, AfterValidator(check_has_space), AfterValidator(check_is_remote_path)
]

default_filters = [
    ".git",
    "__pycache__",
    ".ipynb_checkpoints",
    ".vscode",
    "logs",
    "wandb",
    "outputs",
    "weights",
    "notebooks",
    "*.o",
    "*.so",
    "*.flac",
    "*.mp4",
    "*.tar",
    "*.dcm",
    "*.mp3",
    "*.dicom",
    "*.xml",
    "*.swp",
    "*.pb",
    "*.tmp",
    "*.csv",
    "*.onnx",
    "*.zip",
    "*.parquet",
    "*.html",
    "*.feather",
    "*.pth",
    "*.wav",
    "*.pkl",
    "*.npy",
    "*.zip",
]

img_exts = [
    "*.jpeg",
    "*.jpg",
    "*.png",
]


class RsyncConfig(BaseModel):
    src_dir: SafePath
    target_dir: Optional[RemotePath] = Field(default=None)
    target_dirs: Optional[List[RemotePath]] = Field(default=None)
    rsync_cmd: str = "rsyncp"
    only_exts: List[str] = []
    enable_filter_by_path: bool = False
    filter_path: Path = Path("_rfilter.txt")
    filter_images: bool = True
    filter_tmp: bool = True
    filter_default: bool = True
    sync_all: bool = Field(False)

    @field_validator("target_dirs")
    def check_exclusive_fields(cls, v, info):
        if v is not None:
            assert len(v) > 0, "target_dirs should not be empty list"
            if info.data.get("target_dir") is not None:
                raise ValueError(
                    'Only one of "target_dir" or "target_dirs" should be provided.'
                )
            # Automatically set target_dir to the first element of target_dirs
            info.data["target_dir"] = v[0]
        elif info.data.get("target_dir") is None:
            raise ValueError('One of "target_dir" or "target_dirs" must be provided.')
        return v

    @property
    def exclude_str(self):
        result = ""
        if self.filter_default:
            for str in default_filters:
                result += f" --exclude={str}"
            if self.filter_images:
                for str in img_exts:
                    result += f" --exclude={str}"
            if self.filter_tmp:
                result += " --exclude=*tmp*"
        return result

    def get_include_exclude(self):
        exclude_from = ""
        if self.enable_filter_by_path and self.filter_path.exists():
            exclude_from = "--exclude-from=" + str(self.filter_path.resolve())
        else:
            if not self.filter_path.exists():
                print(
                    f"Filter path: {self.filter_path.resolve()} does not exists",
                    "sync everything",
                )
        exclude_str = f"{self.exclude_str} {exclude_from}"
        include_str = ""
        if self.only_exts:
            for ext in self.only_exts:
                assert ext.startswith("*"), f"Extension {ext} should start with *"
                include_str += f"--include={ext} "
            include_str += "--exclude=*"
        if self.sync_all:
            exclude_str = ""
            include_str = ""
        return exclude_str, include_str

    @property
    def upload_command(self):
        exclude_str, include_str = self.get_include_exclude()
        s = f"-aP --prune-empty-dirs {exclude_str} {include_str} {str(self.src_dir)} {str(self.target_dir)}"
        return s

    @property
    def upload_commands(self):
        exclude_str, include_str = self.get_include_exclude()
        all_s = []
        if self.target_dirs and len(self.target_dirs) > 0:
            for target_dir in self.target_dirs:
                s = f"-aP --prune-empty-dirs {exclude_str} {include_str} {str(self.src_dir)} {str(target_dir)}"
                all_s.append(s)
        else:
            s = f"-aP --prune-empty-dirs {exclude_str} {include_str} {str(self.src_dir)} {str(self.target_dir)}"
            all_s.append(s)
        return all_s

    @property
    def download_command(self):
        exclude_str, include_str = self.get_include_exclude()
        target_dir = str(self.target_dir)
        if not target_dir[-1].endswith("/"):
            target_dir += "/"
        s = f"-aP --prune-empty-dirs {exclude_str} {include_str} {target_dir} {str(self.src_dir)}"
        return s


app = typer.Typer()


@app.command()
def upload(
    config_path: Path = typer.Option("_rsync.yaml", help="Config path"),
    # rsync_cmd: str = typer.Option("rsyncp", help="Custom rsync path"),
):
    if not config_path.exists():
        print(f"Config path: {config_path.resolve()} does not exists, do nothing.")
        exit()
    with open(config_path, "r") as f:
        config = RsyncConfig.model_validate(yaml.load(f, Loader=yaml.SafeLoader))
    for suffix in config.upload_commands:
        command = f"{config.rsync_cmd} {suffix}"
        print(command)
        subprocess.run(["/bin/bash", "-i", "-c", command])


@app.command()
def download(
    config_path: Path = typer.Option("_rsync.yaml", help="Config path"),
):
    if not config_path.exists():
        print(f"Config path: {config_path.resolve()} does not exists, do nothing.")
        exit()
    with open(config_path, "r") as f:
        config = RsyncConfig.model_validate(yaml.load(f, Loader=yaml.SafeLoader))
    command = f"{config.rsync_cmd} {config.download_command}"
    print(command)
    subprocess.run(["/bin/bash", "-i", "-c", command])


if __name__ == "__main__":
    app()
