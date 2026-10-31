"""Cancels downloads whose movie/series was removed from Radarr/Sonarr.

Removing a title in Radarr/Sonarr (or with Seerr's Manage > "Remove from
Radarr/Sonarr") leaves its torrent running in qBittorrent. Every run this
remembers which queued download belongs to which title; once that title is gone,
the torrent is removed from qBittorrent with its files and the title is cleared
in Seerr, so it can be requested again. Downloads it never saw attached to a
title (e.g. torrents added by hand) are left alone.
"""
import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request

INTERVAL = int(os.environ.get("INTERVAL", "60"))
STATE = "/data/state.json"

ARRS = [
    {"name": "radarr", "url": "http://radarr:7878", "conf": "/arr/radarr/config.xml",
     "item": "movie", "unknown": "includeUnknownMovieItems", "seerr": "movie"},
    {"name": "sonarr", "url": "http://sonarr:8989", "conf": "/arr/sonarr/config.xml",
     "item": "series", "unknown": "includeUnknownSeriesItems", "seerr": "tv"},
]
SEERR = "http://seerr:5055"
SEERR_CONF = "/arr/seerr/settings.json"


def log(*msg):
    print(time.strftime("%F %T"), *msg, flush=True)


def call(base, key, method, path, body=None, **params):
    url = base + path + ("?" + urllib.parse.urlencode(params) if params else "")
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data, method=method, headers={
        "X-Api-Key": key, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        raw = r.read()
    return json.loads(raw) if raw else None


def arr_key(arr):
    return re.search(r"<ApiKey>([^<]+)", open(arr["conf"]).read()).group(1)


def clear_seerr(kind, tmdb_id):
    if not tmdb_id:
        return
    key = json.load(open(SEERR_CONF))["main"]["apiKey"]
    try:
        info = call(SEERR, key, "GET", f"/api/v1/{kind}/{tmdb_id}").get("mediaInfo")
        if info:
            call(SEERR, key, "DELETE", f"/api/v1/media/{info['id']}")
            log(f"  cleared {kind} {tmdb_id} in Seerr")
    except urllib.error.HTTPError as e:
        log(f"  Seerr: {kind} {tmdb_id}: HTTP {e.code}")


def check(arr, seen):
    """seen: downloadId -> title it belonged to, kept between runs."""
    key = arr_key(arr)
    fk = arr["item"] + "Id"  # movieId / seriesId
    titles = {t["id"]: t for t in call(arr["url"], key, "GET", f"/api/v3/{arr['item']}")}
    records = call(arr["url"], key, "GET", "/api/v3/queue",
                   page=1, pageSize=1000, **{arr["unknown"]: "true"})["records"]

    queue = {}  # a season pack has one record per episode
    for rec in records:
        if rec.get("downloadId"):
            queue.setdefault(rec["downloadId"], []).append(rec)

    for dl, recs in queue.items():
        tid = next((r[fk] for r in recs if r.get(fk)), None)
        if tid in titles:
            t = titles[tid]
            seen[dl] = {"id": tid, "tmdbId": t.get("tmdbId"), "title": t["title"]}
        elif dl in seen and seen[dl]["id"] not in titles:
            t = seen.pop(dl)
            log(f"{arr['name']}: '{t['title']}' was removed, cancelling its download")
            call(arr["url"], key, "DELETE", "/api/v3/queue/bulk",
                 {"ids": [r["id"] for r in recs]},
                 removeFromClient="true", blocklist="false")
            clear_seerr(arr["seerr"], t["tmdbId"])

    for dl in list(seen):  # finished or removed some other way
        if dl not in queue:
            del seen[dl]


def main():
    try:
        state = json.load(open(STATE))
    except (OSError, ValueError):
        state = {}
    log(f"watching Radarr/Sonarr queues every {INTERVAL}s")
    while True:
        for arr in ARRS:
            try:
                check(arr, state.setdefault(arr["name"], {}))
            except Exception as e:  # service restarting etc., retry next run
                log(f"{arr['name']}: {e}")
        with open(STATE + ".tmp", "w") as f:
            json.dump(state, f)
        os.replace(STATE + ".tmp", STATE)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
