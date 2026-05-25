import hashlib
import os
import time

import jwt
import requests

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER = os.environ["ASC_ISSUER_ID"]
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.miminenrei")
APP_NAME = os.environ.get("APP_NAME", "\u307f\u307f\u5e74\u9f62")
APP_SKU = os.environ.get("APP_SKU", "miminenrei")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"
REVIEW_CONTACT = {
    "contactFirstName": "Tokyo",
    "contactLastName": "Nasu",
    "contactEmail": "tokyonasu@yahoo.co.jp",
    "contactPhone": "+81 80-2368-9194",
}

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", "iphone67", 3),
    ("APP_IPHONE_65", "iphone65", 3),
    ("APP_IPHONE_55", "iphone55", 3),
]

META = {
    "ja": {
        "description": (
            "\u8033\u306e\u5e74\u9f62\u3092\u7c21\u5358\u30c1\u30a7\u30c3\u30af\u3002\n\n"
            "8,000Hz\u304b\u308918,000Hz\u307e\u3067\u30018\u6bb5\u968e\u306e\u9ad8\u5468\u6ce2\u97f3\u3092\u9806\u756a\u306b\u518d\u751f\u3002"
            "\u300c\u805e\u3053\u3048\u305f\u300d\u300c\u805e\u3053\u3048\u306a\u3044\u300d\u3092\u30bf\u30c3\u30d7\u3059\u308b\u3060\u3051\u3002\n\n"
            "\u7d50\u679c\u306f\u300c\u8033\u5e74\u9f62\u300d\u3068\u3057\u3066\u8868\u793a\u3002"
            "\u5404\u5468\u6ce2\u6570\u3054\u3068\u306e\u805e\u3053\u3048\u65b9\u3082\u78ba\u8a8d\u3067\u304d\u307e\u3059\u3002\n\n"
            "\u8033\u3092\u5b88\u308b\u30d2\u30f3\u30c8\u3082\u53ce\u9332\u3002"
            "\u30a4\u30e4\u30db\u30f3\u63a8\u5968\u30fb\u9759\u304b\u306a\u5834\u6240\u3067\u304a\u8a66\u3057\u304f\u3060\u3055\u3044\u3002"
        ),
        "keywords": "\u8033\u5e74\u9f62,\u8074\u529b,\u8033,\u30c6\u30b9\u30c8,\u9ad8\u5468\u6ce2,Hz,\u8074\u3053\u3048,\u30c1\u30a7\u30c3\u30af,\u5065\u5eb7,\u30b7\u30cb\u30a2",
        "whatsNew": "\u306f\u3058\u3081\u3066\u306e\u30ea\u30ea\u30fc\u30b9\u3067\u3059\u3002",
        "promotionalText": "\u3042\u306a\u305f\u306e\u8033\u306f\u4f55\u6b73\uff1f\u9ad8\u5468\u6ce2\u97f3\u3067\u8033\u5e74\u9f62\u3092\u30c1\u30a7\u30c3\u30af\u3002",
    },
    "en-US": {
        "description": (
            "Check your ear age in minutes.\n\n"
            "Play 8 high-frequency tones from 8,000 Hz to 18,000 Hz. "
            "Tap 'Heard' or 'Not heard' for each.\n\n"
            "Results show your estimated ear age and a breakdown by frequency. "
            "Tips for protecting your hearing included.\n\n"
            "Use headphones in a quiet place for best results."
        ),
        "keywords": "ear age,hearing,test,frequency,Hz,hearing test,health,senior,sound,check",
        "whatsNew": "Initial release.",
        "promotionalText": "How old are your ears? Check with high-frequency tones.",
    },
}

p8 = open(P8_PATH, encoding="utf-8").read()


def token():
    now = int(time.time())
    payload = {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, p8, algorithm="ES256", headers={"kid": KEY_ID})


def headers():
    return {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}


def api(method, path, **kwargs):
    for _ in range(6):
        response = requests.request(method, f"https://api.appstoreconnect.apple.com/v1{path}", headers=headers(), timeout=120, **kwargs)
        if response.status_code not in (401, 429, 500, 502, 503, 504):
            return response
        time.sleep(20)
    return response


def api_json(method, path, **kwargs):
    response = api(method, path, **kwargs)
    try:
        body = response.json()
    except Exception:
        body = {}
    return response, body


def list_all(path):
    rows, next_path = [], path
    while next_path:
        response, body = api_json("GET", next_path)
        if response.status_code != 200:
            raise RuntimeError(f"List failed {response.status_code}: {response.text[:300]}")
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def find_app_id():
    response, body = api_json("GET", f"/apps?filter[bundleId]={BUNDLE_ID}")
    data = body.get("data", [])
    if data:
        return data[0]["id"]
    raise RuntimeError(f"App not found for {BUNDLE_ID}. Create the app in App Store Connect first.")


def find_or_create_version(app_id):
    for version in list_all(f"/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=200"):
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            return version["id"], attrs.get("appStoreState")
    payload = {"data": {"type": "appStoreVersions", "attributes": {"platform": "IOS", "versionString": APP_VERSION}, "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}}
    response, body = api_json("POST", "/appStoreVersions", json=payload)
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Version create failed {response.status_code}: {response.text[:300]}")
    return body["data"]["id"], "PREPARE_FOR_SUBMISSION"


def wait_for_build(app_id):
    for i in range(90):
        response, body = api_json("GET", f"/builds?filter[app]={app_id}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1")
        if body.get("data"):
            return body["data"][0]["id"]
        print(f"Waiting for build... {i+1}/90")
        time.sleep(30)
    raise RuntimeError(f"Build {BUILD_NUMBER} did not finish processing")


def ensure_localizations(version_id):
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200")
    existing = {item["attributes"]["locale"]: item for item in localizations}
    for locale in META:
        if locale in existing:
            continue
        payload = {"data": {"type": "appStoreVersionLocalizations", "attributes": {"locale": locale}, "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}}}
        response, body = api_json("POST", "/appStoreVersionLocalizations", json=payload)
        if response.status_code in (200, 201):
            existing[locale] = body["data"]
    return list(existing.values())


def update_metadata(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        meta = META.get(locale, META["en-US"])
        payload = {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": meta}}
        response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json=payload)
        print(f"Metadata {locale}: {response.status_code}")


def update_review_detail(version_id):
    attrs = {**REVIEW_CONTACT, "demoAccountRequired": False, "demoAccountName": "", "demoAccountPassword": "", "notes": "Hearing age test app. Plays high-frequency tones and asks the user if they can hear each one. Use headphones for testing."}
    response, body = api_json("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if response.status_code == 200 and body.get("data"):
        detail_id = body["data"]["id"]
        api("PATCH", f"/appStoreReviewDetails/{detail_id}", json={"data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}})
        return
    api("POST", "/appStoreReviewDetails", json={"data": {"type": "appStoreReviewDetails", "attributes": attrs, "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}}})


def upload_screenshots(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        sets = list_all(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200")
        existing = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in sets}
        for display_type, prefix, count in SCREENSHOT_GROUPS:
            set_id = existing.get(display_type)
            if not set_id:
                payload = {"data": {"type": "appScreenshotSets", "attributes": {"screenshotDisplayType": display_type}, "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}}}}
                response, body = api_json("POST", "/appScreenshotSets", json=payload)
                if response.status_code not in (200, 201):
                    continue
                set_id = body["data"]["id"]
            for s in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
                api("DELETE", f"/appScreenshots/{s['id']}")
            for i in range(1, count + 1):
                upload_screenshot(set_id, f"{prefix}/{prefix}_{i:02d}.png")


def upload_screenshot(set_id, rel_path):
    path = os.path.join(SCREENSHOT_DIR, rel_path)
    if not os.path.exists(path):
        print(f"  Missing: {path}")
        return
    data = open(path, "rb").read()
    checksum = hashlib.md5(data).hexdigest()
    filename = os.path.basename(rel_path)
    payload = {"data": {"type": "appScreenshots", "attributes": {"fileName": filename, "fileSize": len(data)}, "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}}
    response, body = api_json("POST", "/appScreenshots", json=payload)
    if response.status_code not in (200, 201):
        return
    sid = body["data"]["id"]
    for op in body["data"]["attributes"]["uploadOperations"]:
        rh = {item["name"]: item["value"] for item in op["requestHeaders"]}
        requests.put(op["url"], headers=rh, data=data[op["offset"]:op["offset"]+op["length"]], timeout=120)
    api("PATCH", f"/appScreenshots/{sid}", json={"data": {"type": "appScreenshots", "id": sid, "attributes": {"uploaded": True, "sourceFileChecksum": checksum}}})
    print(f"  {rel_path}: ok")


def assign_build(version_id, build_id):
    api("PATCH", f"/builds/{build_id}", json={"data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}})
    api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json={"data": {"type": "builds", "id": build_id}})


def cancel_blocking_submissions(app_id):
    for state in ("UNRESOLVED_ISSUES", "READY_FOR_REVIEW"):
        response, body = api_json("GET", f"/apps/{app_id}/reviewSubmissions?filter[state]={state}&limit=200")
        if response.status_code != 200:
            continue
        for sub in body.get("data", []):
            api("PATCH", f"/reviewSubmissions/{sub['id']}", json={"data": {"type": "reviewSubmissions", "id": sub["id"], "attributes": {"canceled": True}}})
            time.sleep(30)


def submit_for_review(app_id, version_id):
    response, body = api_json("POST", "/reviewSubmissions", json={"data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"}, "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})
    if response.status_code != 201:
        raise RuntimeError(f"Review submission failed {response.status_code}: {response.text[:300]}")
    sid = body["data"]["id"]
    for attempt in range(20):
        response = api("POST", "/reviewSubmissionItems", json={"data": {"type": "reviewSubmissionItems", "relationships": {"reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sid}}, "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}}})
        if response.status_code == 201:
            break
        time.sleep(30)
    response, body = api_json("PATCH", f"/reviewSubmissions/{sid}", json={"data": {"type": "reviewSubmissions", "id": sid, "attributes": {"submitted": True}}})
    if response.status_code != 200:
        raise RuntimeError(f"Submit failed {response.status_code}: {response.text[:300]}")
    print(f"Submitted: {body['data']['attributes']['state']}")


def main():
    app_id = find_app_id()
    version_id, state = find_or_create_version(app_id)
    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"Already submitted: {state}")
        return
    build_id = wait_for_build(app_id)
    update_metadata(version_id)
    update_review_detail(version_id)
    upload_screenshots(version_id)
    print("Waiting for screenshot processing...")
    time.sleep(300)
    cancel_blocking_submissions(app_id)
    assign_build(version_id, build_id)
    submit_for_review(app_id, version_id)


if __name__ == "__main__":
    main()
