### Added

- `RiddlerLiveView.Journey` asks `Riddler.Journey.Access.check/4` of the host's `access` module on mount, on every refresh, before every submit and before every back, and draws one refusal, carrying `data-riddler-refused` and the new `refused_text`, alike for a Journey the host does not have and one the actor may not see; a membership revoked after the mount refuses the next submit or back.
- `RiddlerLiveView.Journey` raises `ArgumentError` when it mounts without an `access` module, or with one that is not a loaded module exporting `member?/2`.
- A host callback or access module that raises, throws or exits, or a host answer outside `Riddler.Journey.Host`, no longer crashes the LiveView: the component draws the refusal on present and on the access check, keeps what is drawn on submit and back, and logs one line naming the callback and the kind of failure, never the event's parameters.
