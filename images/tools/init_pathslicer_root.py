#!/usr/bin/env python3
# Copyright (C) 2022  The Software Heritage developers
# See the AUTHORS file at the top-level directory of this distribution
# License: GNU General Public License version 3, or any later version
# See top-level LICENSE file for more information

# very simple tool to ensure any pathslicer based objstorage found in the SWH
# config file do have its root directory created

import os
from swh.core.config import read as config_read


def ensure_pathslicer_root(cfg):
    if cfg.get("cls") == "pathslicing":
        root = cfg.get("root")
        if root:
            ensure_root(root)
    else:
        for k, v in cfg.items():
            if isinstance(v, dict):
                ensure_pathslicer_root(v)


def ensure_root(root):
    print(f"Create directorty {root}")
    try:
        os.makedirs(root, exist_ok=True)
    except PermissionError as exc:
        print(f"Failed to create directory: {exc}")


config_file = os.environ.get("SWH_CONFIG_FILENAME")
cfg = config_read(config_file)
ensure_pathslicer_root(cfg)
