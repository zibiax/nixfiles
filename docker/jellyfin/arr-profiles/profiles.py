"""Sets up the "Efficient 4K HDR" quality profile in Radarr and Sonarr.

Ranking: 2160p HDR > 1080p HDR > 1080p. Rejected: 2160p without HDR, Dolby
Vision without an HDR10 fallback, AV1 (no hardware decode on the RTX 2060),
upscales, BRRips and remuxes. Radarr rejects releases over 15 GB; Sonarr caps
2160p at 200 MB/min instead (about 9 GB for a 46 min episode), since a size
format would also reject season packs. Seerr requests use the profile by default.

Runs once at `docker compose up` and updates everything by name, so it can be
rerun any time. Edits made in the UI to these formats/profile get overwritten.
"""
import json
import re
import time
import urllib.error
import urllib.request

PROFILE = "Efficient 4K HDR"
REJECT = -10000

HDR = r"\b(HDR(10(\+|P(lus)?)?)?|PQ10|HLG)(?![a-z])"
HDR10P = r"\bHDR10(\+|P(lus)?)(?![a-z])"
DV = r"\b(DV|DoVi|Dolby[ ._-]?Vision)\b"
X265 = r"\b(x265|HEVC|h[ ._-]?265)\b"
AV1 = r"\bAV1\b"
BRRIP = r"\bBR[ ._-]?Rip\b"
UPSCALED = r"\b(Up(scaled?|rez)|AI[ ._-]?(Up(scaled?)?|Enhanced))\b"

ARRS = [
    {"name": "radarr", "url": "http://radarr:7878/api/v3", "conf": "/arr/radarr/config.xml",
     "max_2160": 200},  # the 15 GB format below is the real cap
    {"name": "sonarr", "url": "http://sonarr:8989/api/v3", "conf": "/arr/sonarr/config.xml",
     "max_2160": 200},  # MB/min
]
SEERR = "http://seerr:5055/api/v1"
SEERR_CONF = "/arr/seerr/settings.json"

QUALITIES = {
    "1080p": {"WEBDL-1080p", "WEBRip-1080p", "Bluray-1080p"},
    "2160p": {"WEBDL-2160p", "WEBRip-2160p", "Bluray-2160p"},
}


def log(*msg):
    print(time.strftime("%F %T"), *msg, flush=True)


def call(base, key, method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(base + path, data, method=method, headers={
        "X-Api-Key": key, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        raw = r.read()
        return json.loads(raw) if raw else None


def wait(base, key, path):
    for _ in range(60):
        try:
            return call(base, key, "GET", path)
        except (urllib.error.URLError, ConnectionError):
            time.sleep(5)
    raise SystemExit(f"{base} did not come up")


def title(name, pattern, negate=False):
    return {"name": name, "implementation": "ReleaseTitleSpecification", "negate": negate,
            "required": True, "fields": [{"name": "value", "value": pattern}]}


def is_2160p():
    return {"name": "2160p", "implementation": "ResolutionSpecification", "negate": False,
            "required": True, "fields": [{"name": "value", "value": 2160}]}


def formats(app):
    f = [
        ("HDR", 500, [title("HDR", HDR)]),
        ("HDR10+", 100, [title("HDR10+", HDR10P)]),
        ("DV with HDR10 fallback", 100, [title("DV", DV), title("HDR", HDR)]),
        ("DV without fallback", REJECT, [title("DV", DV), title("Not HDR", HDR, negate=True)]),
        # 4K only: at 1080p small x265 re-encodes would outrank proper encodes
        ("x265", 50, [title("x265", X265), is_2160p()]),
        ("AV1", REJECT, [title("AV1", AV1)]),
        ("Upscaled", REJECT, [title("Upscaled", UPSCALED)]),
        ("BRRip", REJECT, [title("BRRip", BRRIP)]),
        ("2160p without HDR", REJECT, [
            is_2160p(), title("Not HDR", HDR, negate=True), title("Not DV", DV, negate=True)]),
    ]
    if app == "radarr":
        f.append(("Over 15 GB", REJECT, [
            {"name": "Over 15 GB", "implementation": "SizeSpecification", "negate": False,
             "required": True, "fields": [{"name": "min", "value": 15}, {"name": "max", "value": 10000}]}]))
    return f


def upsert(api, path, existing, body):
    if existing:
        return api("PUT", f"{path}/{existing['id']}", {**body, "id": existing["id"]})
    return api("POST", path, body)


def quality_items(schema_items):
    """Ascending items with the 1080p and 2160p qualities each folded into one
    allowed group, so custom format scores (HDR) decide within a resolution."""
    flat = [q for it in schema_items for q in (it["items"] or [it])]
    out, done = [], set()
    for q in flat:
        group = next((g for g, names in QUALITIES.items() if q["quality"]["name"] in names), None)
        if group is None:
            out.append({"quality": q["quality"], "items": [], "allowed": False})
        elif group not in done:
            done.add(group)
            out.append({"id": 2000 + len(done) - 1, "name": group, "allowed": True,
                        "items": [{"quality": x["quality"], "items": [], "allowed": True}
                                  for x in flat if x["quality"]["name"] in QUALITIES[group]]})
    return out


def setup(arr):
    key = re.search(r"<ApiKey>(.*?)</ApiKey>", open(arr["conf"]).read()).group(1)
    api = lambda method, path, body=None: call(arr["url"], key, method, path, body)  # noqa: E731
    have = {c["name"]: c for c in wait(arr["url"], key, "/customformat")}
    scores = {}
    for name, score, specs in formats(arr["name"]):
        cf = upsert(api, "/customformat", have.get(name),
                    {"name": name, "includeCustomFormatWhenRenaming": False, "specifications": specs})
        scores[cf["id"]] = score

    schema = api("GET", "/qualityprofile/schema")
    items = quality_items(schema["items"])
    profile = {**{k: v for k, v in schema.items() if k not in ("items", "formatItems")},
               "name": PROFILE, "upgradeAllowed": True,
               "cutoff": next(i["id"] for i in items if i.get("name") == "2160p"),
               "minFormatScore": 0, "cutoffFormatScore": 500, "minUpgradeFormatScore": 1,
               "items": items,
               "formatItems": [{"format": c["id"], "name": c["name"], "score": scores.get(c["id"], 0)}
                               for c in api("GET", "/customformat")]}
    existing = next((p for p in api("GET", "/qualityprofile") if p["name"] == PROFILE), None)
    profile_id = upsert(api, "/qualityprofile", existing, profile)["id"]

    # MB per minute; the floor keeps out starved 4K encodes
    for d in api("GET", "/qualitydefinition"):
        if d["quality"]["name"] in QUALITIES["2160p"]:
            api("PUT", f"/qualitydefinition/{d['id']}", {
                **d, "minSize": max(d.get("minSize") or 0, 25), "maxSize": arr["max_2160"],
                "preferredSize": min(d.get("preferredSize") or 95, arr["max_2160"] - 5)})
    log(f"{arr['name']}: profile {PROFILE!r} (id {profile_id}) and {len(scores)} formats up to date")
    return profile_id


def set_seerr_default(profile_ids):
    key = json.load(open(SEERR_CONF))["main"]["apiKey"]
    for app, profile_id in profile_ids.items():
        for server in wait(SEERR, key, f"/settings/{app}"):
            if server["activeProfileId"] != profile_id:
                body = {k: v for k, v in server.items() if k != "id"}
                body.update(activeProfileId=profile_id, activeProfileName=PROFILE)
                call(SEERR, key, "PUT", f"/settings/{app}/{server['id']}", body)
                log(f"seerr: {server['name']} now requests with {PROFILE!r}")


if __name__ == "__main__":
    set_seerr_default({arr["name"]: setup(arr) for arr in ARRS})
