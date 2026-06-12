#!/usr/bin/env python3
import base64
import hashlib
import os
import subprocess
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path

import jwt
import requests


KEY_ID = os.environ.get("ASC_KEY_ID", "WDXGY9WX55")
ISSUER = os.environ.get("ASC_ISSUER_ID", "2be0734f-943a-4d61-9dc9-5d9045c46fec")
P8_PATH = Path(os.environ.get("ASC_P8_PATH", f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8")).expanduser()
KEYCHAIN = os.environ.get("BUILD_KEYCHAIN", "build.keychain")
KEYCHAIN_PASSWORD = os.environ["KEYCHAIN_PASSWORD"]
WORK_DIR = Path("/tmp/meerkatwatch-signing")
KEY_PATH = WORK_DIR / "distribution.key"
CSR_PATH = WORK_DIR / "distribution.csr"
CERT_PATH = WORK_DIR / "distribution.cer"
INVALID_SERIALS = {
    "7F1B97135055A53774568AA929DBA0DB",
    "797262360B421323CA2A52F022C3F0BF",
}


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
    return response


def api_json(method, path, payload=None):
    response = api(method, path, payload)
    if response.status_code not in (200, 201, 204):
        raise RuntimeError(f"{method} {path} failed {response.status_code}: {response.text[:800]}")
    return response.json() if response.text else {}


def run(args):
    print("+", " ".join(str(arg) for arg in args), flush=True)
    subprocess.run(args, check=True)


def generate_csr():
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    run(["openssl", "genrsa", "-out", str(KEY_PATH), "2048"])
    run([
        "openssl",
        "req",
        "-new",
        "-key",
        str(KEY_PATH),
        "-out",
        str(CSR_PATH),
        "-subj",
        "/CN=MeerkatWatch CI Distribution/O=TokyoNasu/C=JP",
    ])


def parse_date(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def serial_from_content(content):
    if not content:
        return ""
    with tempfile.NamedTemporaryFile(suffix=".cer") as temp:
        temp.write(base64.b64decode(content))
        temp.flush()
        result = subprocess.run(
            ["openssl", "x509", "-inform", "DER", "-in", temp.name, "-noout", "-serial"],
            check=True,
            capture_output=True,
            text=True,
        )
    return result.stdout.strip().replace("serial=", "").replace(":", "").upper()


def distribution_certs():
    seen = set()
    certs = []
    for cert_type in ("DISTRIBUTION", "IOS_DISTRIBUTION"):
        for cert in api_json("GET", f"/certificates?filter[certificateType]={cert_type}&limit=200").get("data", []):
            if cert["id"] not in seen:
                seen.add(cert["id"])
                certs.append(cert)
    return certs


def delete_stale_or_oldest_certificate():
    now = datetime.now(timezone.utc)
    candidates = []
    for cert in distribution_certs():
        detail = api_json("GET", f"/certificates/{cert['id']}").get("data", cert)
        attrs = detail.get("attributes", {})
        serial = (attrs.get("serialNumber") or "").replace(":", "").upper()
        if not serial:
            serial = serial_from_content(attrs.get("certificateContent"))
        expires = parse_date(attrs.get("expirationDate"))
        name_text = " ".join(str(attrs.get(k) or "") for k in ("name", "displayName", "commonName")).lower()
        stale = serial in INVALID_SERIALS or "meerkatwatch ci" in name_text or (expires is not None and expires < now)
        print(f"Inspecting cert {cert['id']} serial={serial or 'none'} expires={attrs.get('expirationDate') or 'none'} stale={stale}")
        if stale:
            api("DELETE", f"/certificates/{cert['id']}")
            return True
        if expires is not None:
            candidates.append((expires, cert["id"]))
    if candidates:
        _, cert_id = sorted(candidates, key=lambda item: item[0])[0]
        api("DELETE", f"/certificates/{cert_id}")
        return True
    return False


def create_certificate():
    csr = CSR_PATH.read_text()
    payload = {
        "data": {
            "type": "certificates",
            "attributes": {
                "certificateType": "DISTRIBUTION",
                "csrContent": csr,
            },
        }
    }
    try:
        return api_json("POST", "/certificates", payload)["data"]
    except RuntimeError as error:
        text = str(error).lower()
        if not any(word in text for word in ("maximum", "limit", "reached", "already have")):
            raise
        if not delete_stale_or_oldest_certificate():
            raise
        return api_json("POST", "/certificates", payload)["data"]


def import_certificate(cert):
    content = cert.get("attributes", {}).get("certificateContent")
    if not content:
        raise RuntimeError("Created certificate did not include certificateContent")
    CERT_PATH.write_bytes(base64.b64decode(content))
    run(["security", "import", str(KEY_PATH), "-k", KEYCHAIN, "-T", "/usr/bin/codesign", "-T", "/usr/bin/security"])
    run(["security", "import", str(CERT_PATH), "-k", KEYCHAIN, "-T", "/usr/bin/codesign", "-T", "/usr/bin/security"])
    run(["security", "set-key-partition-list", "-S", "apple-tool:,apple:", "-s", "-k", KEYCHAIN_PASSWORD, KEYCHAIN])
    sha1 = hashlib.sha1(CERT_PATH.read_bytes()).hexdigest().upper()
    print(f"IOS_DISTRIBUTION_CERT_SHA1={sha1}")
    print(f"ASC_CERTIFICATE_ID={cert['id']}")


generate_csr()
certificate = create_certificate()
import_certificate(certificate)
