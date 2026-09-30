import '../usecases/family/join_family_usecase.dart' show formatInviteCode;

/// App Store link tagged with the "invite" campaign, so installs from shared
/// invites show up under Campaigns in App Store Connect analytics.
/// ``pt`` is the Apple provider token for this developer account.
const String kInviteAppStoreUrl =
    'https://apps.apple.com/app/id6746752194?pt=127879651&ct=invite&mt=8';

/// Android families join the closed test first: until Play production launches
/// (TASK-493) the store listing is "Not Found" for anyone who is not an
/// opted-in tester. Joining the group grants access; the opt-in page then
/// enrols them. When production launches, replace both with the store listing.
const String kInviteTesterGroupUrl =
    'https://groups.google.com/g/chores-star-testers/about';
const String kInvitePlayOptInUrl =
    'https://play.google.com/apps/testing/com.hoque.familychores';

/// The text a family member shares to invite someone into their family.
///
/// Names the join controls as they appear in the app: the onboarding card
/// heading and button (family_onboarding_screen.dart) and the start of the kid
/// button on the sign-in screen (login_screen.dart). Change those labels and
/// this message together.
///
/// :param inviteCode: the family's invite code, as stored.
/// :returns: a plain-text message with the grouped code and install links.
String inviteMessage(String inviteCode) => '''
Join our family on Chores Star! Install the app, then enter our family code: ${formatInviteCode(inviteCode)}

Grown-ups: sign in, then under "Join a family" enter the code and tap "Join family".
Kids: tap "I'm a kid" on the sign-in screen.

iPhone and iPad: $kInviteAppStoreUrl
Android (early access): join $kInviteTesterGroupUrl then install from $kInvitePlayOptInUrl''';
