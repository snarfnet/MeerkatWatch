#!/usr/bin/env python3
import base64
import os
import time
from pathlib import Path

import jwt
import requests


KEY_ID = os.environ.get("ASC_KEY_ID", "WDXGY9WX55")
ISSUER = os.environ.get("ASC_ISSUER_ID", "2be0734f-943a-4d61-9dc9-5d9045c46fec")
P8_PATH = Path(os.environ.get("ASC_P8_PATH", f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8")).expanduser()
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.meerkatwatch")
PROFILE_NAME = os.environ.get("PROFILE_NAME", "MeerkatWatch App Store")
REFRESH_PROFILE = os.environ.get("REFRESH_PROFILE", "").lower() in {"1", "true", "yes"}


def make_token():
    return jwt.encode(
        {"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"},
        P8_PATH.read_text(),
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


def api(method, path, payload=None):
    headers = {"Authorization": f"Bearer {make_token()}", "Content-Type": "application/json"}
    response = requests.request(method, f"https://api.appstoreconnect.apple.com/v1{path}", headers=headers, json=payload)
    print(method, path.split("?")[0][-60:], response.status_code)
    if response.status_code >= 400:
        print(response.text[:1000])
        response.raise_for_status()
    return response.json() if response.text else {}


def first_data(response, label):
    data = response.get("data")
    if not data:
        raise RuntimeError(f"No {label} found")
    if isinstance(data, list):
        return data[0]
    return data


bundle = first_data(api("GET", f"/bundleIds?filter[identifier]={BUNDLE_ID}&limit=1"), "bundle ID")
bundle_id = bundle["id"]

certs = api("GET", "/certificates?filter[certificateType]=IOS_DISTRIBUTION&limit=200").get("data", [])
if not certs:
    certs = api("GET", "/certificates?filter[certificateType]=DISTRIBUTION&limit=200").get("data", [])
if not certs:
    raise RuntimeError("No distribution certificates found in App Store Connect")

profiles = api("GET", f"/profiles?filter[name]={PROFILE_NAME}&limit=20").get("data", [])
active_profiles = [profile for profile in profiles if profile.get("attributes", {}).get("profileState") == "ACTIVE"]

if REFRESH_PROFILE:
    for profile in active_profiles:
        api("DELETE", f"/profiles/{profile['id']}")
    active_profiles = []

if active_profiles:
    profile = active_profiles[0]
else:
    profile = first_data(
        api(
            "POST",
            "/profiles",
            {
                "data": {
                    "type": "profiles",
                    "attributes": {
                        "name": PROFILE_NAME,
                        "profileType": "IOS_APP_STORE",
                    },
                    "relationships": {
                        "bundleId": {"data": {"type": "bundleIds", "id": bundle_id}},
                        "certificates": {
                            "data": [{"type": "certificates", "id": cert["id"]} for cert in certs],
                        },
                    },
                }
            },
        ),
        "created profile",
    )

content = profile["attributes"].get("profileContent")
if not content:
    profile = first_data(api("GET", f"/profiles?filter[name]={PROFILE_NAME}&limit=1"), "profile")
    content = profile["attributes"]["profileContent"]

profiles_dir = Path.home() / "Library" / "MobileDevice" / "Provisioning Profiles"
profiles_dir.mkdir(parents=True, exist_ok=True)
out = profiles_dir / "MeerkatWatch_App_Store.mobileprovision"
out.write_bytes(base64.b64decode(content))
print(f"PROFILE_PATH={out}")
print(f"PROFILE_NAME={PROFILE_NAME}")
