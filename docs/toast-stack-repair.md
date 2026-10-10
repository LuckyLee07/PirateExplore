# Important notification readability

Natural first-time alchemy showed “钻石+1” covering the achievement text. The
ordinary toast path now has a measured vertical stack, with at most three
visible cards. Each uses the actual wrapped LabelTTF content size; cards fit
inside the central screen region with 12 logical pixels between them. The
alchemy receipt remains separate beside its control, with no economy changes.

Free slots fill in FIFO order rather than waiting for a serial display delay.
Short messages last about 1.8 seconds; longer text gets up to 3.4 seconds and
wraps within the viewport. A very tall single card scales to the available
height without truncating its text. The existing limited-message option only
coalesces an identical pending message of the same kind; it cannot drop a
different achievement, reward or error because the queue is busy.

Native ownership is local to a child of NotificationNode. No native pointer or
playing flag is kept globally. One delayed pump action belongs to that child,
not NotificationNode itself; exit cancels this driver and the card animations,
without cancelling unrelated notification business actions. Finished callbacks
have generation guards. Lifecycle callbacks do not remove native siblings.

Ordinary scene transitions leave Director's notification node running, as in
the original engine. On actual notification-layer exit, already-shown cards
retire without replay; unshown text remains FIFO. Same-layer reentry pumps it;
a replacement layer pumps it when its next notification arrives. No old scene
or native card is retained in that pending text queue.

`tools/tests/toast_stack_regression.lua` runs with the regular Lua test runner
and the existing headless Cocos executable. Native checks cover measured long
Chinese labels at both target aspect ratios, ten-message FIFO, scene/notification
lifecycle, delayed stale callbacks, actual retained-reference counts through
repeated early replacements, unrelated host actions, and production-only quiet
mode. The alchemy native suite still passes. These are real node/label/action
checks, not full GUI or device acceptance; the native GUI owner verifies the
visible first-alchemy achievement/reward pair separately.
