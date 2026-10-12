# Event rebind gesture lifetime

Independent review reproduced an inherited native input error in both 8ddf958 and the entry-scene expansion: begin touching battle3108, rebind the persistent entry to tavern3004, then release. The newly installed tavern callback ran even though the gesture belonged to the old battle.

The local EventLayer button wrappers now capture the owner generation only after an accepted BEGIN, reject END across a generation change, and clear the token on cancel/end. Cancellation resets paint and hold state. Shared SDButton, EventPageUI and production event/economy callbacks are unchanged.

The original real-GLView reproduction is included in the native scene-render runner, with fresh-tap recovery and hide/show-release checks. Existing scene-render gesture and exact dynamic-pixel tests remain required. Desktop and mobile verification are separate gates.
