#!/usr/bin/env python3
"""Update Apple App Store metadata (description, keywords, promo text, release notes) via App Store Connect API.

Usage:
    python3 scripts/update_appstore_metadata.py
"""
import base64
import json
import os
import subprocess
import sys
import urllib.request
import urllib.error

KEY_ID = os.environ.get("ASC_KEY_ID", "55A763B9XW")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "2e924c90-75cb-4ef0-a036-574926a7b628")
KEY_PATH = os.environ.get(
    "ASC_KEY_PATH",
    os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8")
)
ASC_APP_ID = os.environ.get("ASC_APP_ID", "6746752194")

# Apple App Store description rejects emojis in the description field. Clean plain text is required.
APPLE_DESCRIPTION = """Chores Star transforms everyday household chores into playful, confidence-building adventures for kids and peaceful harmony for parents.

Powered by our built-in AI Chore Coach, Chores Star doesn't just hand children a dry checklist — it motivates them, breaks tasks into bite-sized missions, and teaches the lifelong "why" behind taking care of their home and family. Less nagging, more high-fives!

MEET YOUR BUILT-IN AI CHORE COACH
Chores shouldn't feel like a punishment or a battle of wills. With intelligent mission guidance, every chore becomes a chance to learn and shine:
• Playful Motivation & Pep Talks: The AI coach gives high-energy encouragement and fun micro-challenges (race the 3-minute song, channel stealth ninja speed) so kids jump in excited to finish.
• Clear Step-by-Step Guidance: No more feeling overwhelmed by "clean your room." The AI breaks each chore into 3–4 practical, sequential steps a child can easily follow.
• Teaching the Lifelong "Why": Kids discover how their effort benefits everyone:
  - For You: Fosters personal pride, focus, independence, and calm in their own space.
  - For Your Family: Shows how teamwork lifts the household load and shows real care.
  - For Your Home: Reveals how small daily actions keep our living spaces cozy and welcoming.
• Superpower Life Skills: Every chore highlights a transferable real-world superpower, from attention to detail to steady consistency.
• Custom House Notes: Parents can add specific instructions (where supplies live, special house rules) and the AI coach seamlessly weaves them into the child's guide!

HOW CHORES STAR WORKS
1. Add Chores & Set Stars: Assign a star reward based on effort — quick tidy-ups earn a few stars, bigger projects earn more.
2. Kids Claim Missions: Children tap "I'll do it!" to grab chores from the board, or parents assign them directly.
3. Step-by-Step Execution: Kids open their AI Mission Guide to see their pep talk, checklist, and life-skill takeaway.
4. Photo Proof & Approval: Kids snap before & after photos to show off their hard work. Parents review and approve in seconds.
5. Star Rewards & Treats: Earned stars are exchanged in your family's custom Treats Store!

TREATS THAT FIT YOUR REAL FAMILY
Swap stars for real-life experiences and privileges you choose together:
• Family movie night pick
• Extra 30 minutes of gaming or screen time
• Special trip for ice cream or weekend outing
• Allowance or savings goal contributions

KEEPS KIDS ENGAGED & COMING BACK
• Daily Streaks: Celebrates daily consistency and builds positive momentum.
• Weekly Leaderboard: Friendly family standings where every child's effort is recognized.
• Levels & Badges: Watch kids level up as their responsibility grows.
• Today's Missions: A clear, clutter-free view of what's on today's plate so children can work independently.

DESIGNED FOR SAFETY & PRIVACY
• Frictionless Child Login: Kids join with a simple family invite code — no child email address or password required.
• Sign in with Apple or Google: Effortless, secure access for parents.
• Zero Ads, Zero Tracking: Your family's routines, notes, and photos stay strictly private.
• Fair by Design: Children cannot approve their own chores, keeping accountability honest and rewarding.

Give your children the gift of responsibility, confidence, and teamwork — while taking the stress out of household routines.

Download Chores Star today and turn daily chores into family superpowers!"""

PROMOTIONAL_TEXT = (
    "Meet your AI chore coach! Turn chores into playful missions with fun motivation, "
    "step-by-step guidance, and life-skill learning that brings your family closer."
)
KEYWORDS = "chores,chore chart,allowance,habits,kids,family,routine,ai coach,tasks,rewards,parenting,star chart"
WHATS_NEW = (
    "Meet your AI Chore Coach! Every chore now comes with playful motivation, "
    "clear step-by-step guidance, and real-life superpower lessons for kids. "
    "Plus, snap before-and-after photo proof directly in the task card!"
)


def get_token():
    cmd = f"""
    b64url() {{ openssl base64 -A | tr '+/' '-_' | tr -d '='; }}
    now=$(date +%s)
    exp=$((now + 1200))
    header=$(printf '{{"alg":"ES256","kid":"{KEY_ID}","typ":"JWT"}}' | b64url)
    payload=$(printf '{{"iss":"{ISSUER_ID}","iat":%d,"exp":%d,"aud":"appstoreconnect-v1"}}' "$now" "$exp" | b64url)
    signing_input="$header.$payload"
    der_sig=$(printf '%s' "$signing_input" | openssl dgst -sha256 -sign "{KEY_PATH}" -binary | openssl base64 -A)
    python3 - "$signing_input" "$der_sig" <<'INNER'
import base64, sys
signing_input, der_b64 = sys.argv[1], sys.argv[2]
der = base64.b64decode(der_b64)
def read_int(buf, i):
    n = buf[i + 1]
    val = int.from_bytes(buf[i + 2:i + 2 + n], "big")
    return val, i + 2 + n
i = 2 if der[1] < 0x80 else 2 + (der[1] & 0x7F)
r, i = read_int(der, i)
s, _ = read_int(der, i)
raw = r.to_bytes(32, "big") + s.to_bytes(32, "big")
sig = base64.urlsafe_b64encode(raw).rstrip(b"=").decode()
print(f"{{signing_input}}.{{sig}}")
INNER
    """
    return subprocess.check_output(cmd, shell=True, text=True).strip()


def api_request(method, path, token, payload=None):
    url = f"https://api.appstoreconnect.apple.com{path}"
    data = json.dumps(payload).encode("utf-8") if payload else None
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method=method,
    )
    with urllib.request.urlopen(req) as resp:
        if resp.status == 204:
            return None
        return json.load(resp)


def main():
    if not os.path.exists(KEY_PATH):
        sys.exit(f"Error: ASC key not found at {KEY_PATH}")

    token = get_token()

    # 1. Update promotional text on all versions where supported (promotionalText can be changed anytime!)
    versions_resp = api_request("GET", f"/v1/apps/{ASC_APP_ID}/appStoreVersions", token)
    for v in versions_resp.get("data", []):
        v_id = v["id"]
        v_str = v["attributes"]["versionString"]
        v_state = v["attributes"]["appStoreState"]
        locs_resp = api_request("GET", f"/v1/appStoreVersions/{v_id}/appStoreVersionLocalizations", token)
        for loc in locs_resp.get("data", []):
            loc_id = loc["id"]
            locale = loc["attributes"]["locale"]
            # If draft, update full metadata
            if v_state == "PREPARE_FOR_SUBMISSION":
                print(f"Updating full metadata on {v_str} ({locale})...")
                patch_data = {
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "id": loc_id,
                        "attributes": {
                            "description": APPLE_DESCRIPTION,
                            "keywords": KEYWORDS,
                            "promotionalText": PROMOTIONAL_TEXT,
                            "whatsNew": WHATS_NEW,
                        },
                    }
                }
                api_request("PATCH", f"/v1/appStoreVersionLocalizations/{loc_id}", token, patch_data)
                print(f"  ✓ {v_str} ({locale}) full metadata updated.")
            elif v_state == "READY_FOR_SALE":
                # Only promotionalText is editable on live versions without a new submission
                print(f"Updating promotionalText on live version {v_str} ({locale})...")
                patch_data = {
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "id": loc_id,
                        "attributes": {
                            "promotionalText": PROMOTIONAL_TEXT,
                        },
                    }
                }
                try:
                    api_request("PATCH", f"/v1/appStoreVersionLocalizations/{loc_id}", token, patch_data)
                    print(f"  ✓ {v_str} ({locale}) promotionalText updated.")
                except Exception as e:
                    print(f"  x Note for {v_str}: {e}")

    print("App Store Connect metadata sync complete!")


if __name__ == "__main__":
    main()
