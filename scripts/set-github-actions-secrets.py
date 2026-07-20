#!/usr/bin/env python3
"""Set GitHub Actions secrets for the Sheldon Drive TestFlight workflow."""

from __future__ import annotations

import base64
import os
import sys
from pathlib import Path
from urllib.parse import urlparse

import requests
from nacl import encoding, public


REPO = os.environ.get("GITHUB_REPOSITORY", "oreo0727/SheldonDrive")
SIGNING_ENV = Path(os.environ.get("SIGNING_ENV", "private/apple-signing/github-secrets.env"))
API_ENV = Path(os.environ.get("API_ENV", "private/apple-signing/app-store-connect-api.env"))


def load_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise SystemExit(f"Invalid env line in {path}: {raw_line}")
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def github_token() -> str:
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        return token

    credentials = Path.home() / ".git-credentials"
    if credentials.exists():
        for line in credentials.read_text().splitlines():
            if "github.com" not in line:
                continue
            parsed = urlparse(line.strip())
            if parsed.password:
                return parsed.password

    raise SystemExit("Set GITHUB_TOKEN or configure ~/.git-credentials for github.com.")


def encrypt_secret(public_key: str, value: str) -> str:
    key = public.PublicKey(public_key.encode("utf-8"), encoding.Base64Encoder())
    sealed_box = public.SealedBox(key)
    encrypted = sealed_box.encrypt(value.encode("utf-8"))
    return base64.b64encode(encrypted).decode("utf-8")


def main() -> int:
    secrets = load_env_file(SIGNING_ENV)
    secrets.update(load_env_file(API_ENV))

    private_key_file = secrets.pop("APP_STORE_CONNECT_API_PRIVATE_KEY_FILE", "")
    if private_key_file:
        key_path = Path(private_key_file)
        if not key_path.exists():
            raise SystemExit(f"Missing App Store Connect private key file: {key_path}")
        secrets["APP_STORE_CONNECT_API_PRIVATE_KEY"] = key_path.read_text()

    required = [
        "APPLE_TEAM_ID",
        "APPLE_CERTIFICATE_P12_BASE64",
        "APPLE_CERTIFICATE_PASSWORD",
        "APPLE_KEYCHAIN_PASSWORD",
        "APPLE_PROVISIONING_PROFILE_BASE64",
        "APP_STORE_CONNECT_API_KEY_ID",
        "APP_STORE_CONNECT_API_ISSUER_ID",
        "APP_STORE_CONNECT_API_PRIVATE_KEY",
    ]
    missing = [name for name in required if not secrets.get(name)]
    if missing:
        print("Missing required secrets:", ", ".join(missing), file=sys.stderr)
        print(f"Signing env: {SIGNING_ENV}", file=sys.stderr)
        print(f"API env: {API_ENV}", file=sys.stderr)
        return 1

    token = github_token()
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    public_key_response = requests.get(
        f"https://api.github.com/repos/{REPO}/actions/secrets/public-key",
        headers=headers,
        timeout=20,
    )
    public_key_response.raise_for_status()
    key_data = public_key_response.json()

    for name in required:
        encrypted_value = encrypt_secret(key_data["key"], secrets[name])
        response = requests.put(
            f"https://api.github.com/repos/{REPO}/actions/secrets/{name}",
            headers=headers,
            json={"encrypted_value": encrypted_value, "key_id": key_data["key_id"]},
            timeout=20,
        )
        response.raise_for_status()
        print(f"Set secret: {name}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
