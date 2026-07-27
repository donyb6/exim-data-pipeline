import requests
import yaml
from pathlib import Path


def run():
    with open("config/columns.yaml", "r") as f:
        config = yaml.safe_load(f)

    url = config["source_url"]
    save_path = Path(config["raw_file_path"])
    save_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Downloading from {url} ...")
    response = requests.get(url)
    response.raise_for_status()

    with open(save_path, "wb") as f:
        f.write(response.content)

    print(f"Saved to {save_path} ({len(response.content):,} bytes)")


if __name__ == "__main__":
    run()