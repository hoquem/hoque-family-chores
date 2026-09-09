#!/usr/bin/env python3
"""Update Google Play Store listing metadata via Google Play Android Developer API.

Usage:
    scripts/.play-venv/bin/python scripts/update_playstore_listing.py
"""
import os
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build

PACKAGE_NAME = os.environ.get("PLAY_PACKAGE_NAME", "com.hoque.familychores")
SERVICE_ACCOUNT_JSON = os.environ.get(
    "PLAY_SERVICE_ACCOUNT_JSON",
    os.path.expanduser("~/.playstore/service-account.json")
)
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

TITLE = "Chores Star"
SHORT_DESCRIPTION = "Turn chores into AI missions & treats that motivate kids and teach life skills."

FULL_DESCRIPTION = """Chores Star transforms everyday household chores into playful, confidence-building adventures for kids and peaceful harmony for parents.

Powered by our built-in AI Chore Coach, Chores Star doesn't just hand children a dry checklist — it motivates them, breaks tasks into bite-sized missions, and teaches the lifelong "why" behind taking care of their home and family. Less nagging, more high-fives!

🚀 MEET YOUR BUILT-IN AI CHORE COACH
Chores shouldn't feel like a punishment or a battle of wills. With intelligent mission guidance, every chore becomes a chance to learn and shine:
• Playful Motivation & Pep Talks: The AI coach gives high-energy encouragement and fun micro-challenges (race the 3-minute song, channel stealth ninja speed) so kids jump in excited to finish.
• Clear Step-by-Step Guidance: No more feeling overwhelmed by "clean your room." The AI breaks each chore into 3–4 practical, sequential steps a child can easily follow.
• Teaching the Lifelong "Why": Kids discover how their effort benefits everyone:
  - For You: Fosters personal pride, focus, independence, and calm in their own space.
  - For Your Family: Shows how teamwork lifts the household load and shows real care.
  - For Your Home: Reveals how small daily actions keep our living spaces cozy and welcoming.
• Superpower Life Skills: Every chore highlights a transferable real-world superpower, from attention to detail to steady consistency.
• Custom House Notes: Parents can add specific instructions (where supplies live, special house rules) and the AI coach seamlessly weaves them into the child's guide!

⭐ HOW CHORES STAR WORKS
1. Add Chores & Set Stars: Assign a star reward based on effort — quick tidy-ups earn a few stars, bigger projects earn more.
2. Kids Claim Missions: Children tap "I'll do it!" to grab chores from the board, or parents assign them directly.
3. Step-by-Step Execution: Kids open their AI Mission Guide to see their pep talk, checklist, and life-skill takeaway.
4. Photo Proof & Approval: Kids snap before & after photos to show off their hard work. Parents review and approve in seconds.
5. Star Rewards & Treats: Earned stars are exchanged in your family's custom Treats Store!

🎁 TREATS THAT FIT YOUR REAL FAMILY
Swap stars for real-life experiences and privileges you choose together:
• Family movie night pick
• Extra 30 minutes of gaming or screen time
• Special trip for ice cream or weekend outing
• Allowance or savings goal contributions

🔥 KEEPS KIDS ENGAGED & COMING BACK
• Daily Streaks: Celebrates daily consistency and builds positive momentum.
• Weekly Leaderboard: Friendly family standings where every child's effort is recognized.
• Levels & Badges: Watch kids level up as their responsibility grows.
• Today's Missions: A clear, clutter-free view of what's on today's plate so children can work independently.

🔒 DESIGNED FOR SAFETY & PRIVACY
• Frictionless Child Login: Kids join with a simple family invite code — no child email address or password required.
• Sign in with Apple or Google: Effortless, secure access for parents.
• Zero Ads, Zero Tracking: Your family's routines, notes, and photos stay strictly private.
• Fair by Design: Children cannot approve their own chores, keeping accountability honest and rewarding.

Give your children the gift of responsibility, confidence, and teamwork — while taking the stress out of household routines.

Download Chores Star today and turn daily chores into family superpowers!"""


def main():
    if not os.path.exists(SERVICE_ACCOUNT_JSON):
        sys.exit(f"Error: Service account not found at {SERVICE_ACCOUNT_JSON}")

    creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_JSON, scopes=SCOPES
    )
    service = build("androidpublisher", "v3", credentials=creds, cache_discovery=False)
    edit = service.edits().insert(packageName=PACKAGE_NAME, body={}).execute()
    edit_id = edit["id"]

    try:
        for lang in ["en-GB", "en-US"]:
            try:
                service.edits().listings().update(
                    packageName=PACKAGE_NAME,
                    editId=edit_id,
                    language=lang,
                    body={
                        "title": TITLE,
                        "shortDescription": SHORT_DESCRIPTION,
                        "fullDescription": FULL_DESCRIPTION,
                    },
                ).execute()
                print(f"Updated listing for {lang}")
            except Exception as e:
                print(f"Could not update listing for {lang}: {e}")

        service.edits().commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
        print("Successfully committed Play Store listing updates!")
    except Exception as e:
        service.edits().delete(packageName=PACKAGE_NAME, editId=edit_id).execute()
        sys.exit(f"Commit failed: {e}")


if __name__ == "__main__":
    main()
