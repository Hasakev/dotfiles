# Lessons

## Don't explain away an unexplained symptom (2026-10-03)
Saw the DP-1 popout close instantly during testing and blamed "fullscreen Discord holding
focus" without proving it. The real cause was my own bar-height optimisation: the focus grab
armed while the layer surface was mid-resize, Hyprland cleared it, and every keybind-opened
panel (Super+D!) died instantly. User found it.
Rule: if a test shows odd behaviour, reproduce it in a clean state before attributing it to
the environment. After any change to window size/focus/grab logic, re-test open-via-keybind
on EVERY monitor, not just the one that worked before.

## Translucency under Hyprland is perceptually much stronger (2026-10-03)
Hyprland blends in linear light: a 94%-opaque dark panel over bright text still shows the
text at ~52/255 (measured). "Looks see-through" was real, not a screenshot artefact.
Rule: content panels/toasts/OSD are solid; reserve alpha for deliberate glass (islands),
and judge it by screenshot, not by the alpha number.

## Overlapping input handlers: declaration order is z-order (2026-10-03)
A base component's catch-all MouseArea declared after its `default property` content sits on
top and swallows clicks meant for inner controls (tray icons). Put catch-all handlers first,
and verify every interactive child gets input, not just the container.
