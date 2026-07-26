import requests
import yaml
from pathlib import Path

# Load settings from config file instead of hardcoding them here
with open("config/columns.yaml", "r") as f:
    config = yaml.safe_load(f)

url = config["source_url"]
save_path = Path(config["raw_file_path"])

# Make sure the folder exists before trying to save into it
save_path.parent.mkdir(parents=True, exist_ok=True)

print(f"Downloading from {url} ...")
response = requests.get(url)
response.raise_for_status()  # stops the script with a clear error if the download failed

with open(save_path, "wb") as f:
    f.write(response.content)

print(f"Saved to {save_path} ({len(response.content):,} bytes)")