import subprocess
from pathlib import Path

import tomllib

path = Path.home() / ".config/neru/theme.toml"

with path.open("rb") as f:
    themes = tomllib.load(f)["theme"]

for mode in ("light", "dark"):
    for key, color in themes[mode].items():
        subprocess.run(
            [
                "neru",
                "config",
                "set",
                "--no-reload",
                f"theme.{mode}.{key}",
                color,
            ],
            check=True,
        )

subprocess.run(["neru", "config", "reload"], check=True)
