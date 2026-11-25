### Added

- `RiddlerLiveView.Journey`, the LiveComponent a host's LiveView embeds: given the host's name for a Journey and its `Riddler.Journey.Host` module, it draws the screen the host presents, hands the host each submit and back request built from the presented answer, draws the host's findings beside the questions they name, draws waiting and asks the host again after the answer's `retry_after_ms`, and draws done; an outcome the moves did not list, a back request the moves did not offer, a form from another screen and a screen with an element nothing draws are refused without calling the host.
- Every component that derives an `id` takes `id_prefix`, so two screens or two Journeys on one page carry no `id` twice.
- `RiddlerLiveView.Components.frame/1` takes `refusals`, a count of refused submits, so focus moves to the first finding again on every refusal.
- `RiddlerLiveView.Components.secret_question/1` names its input `riddler-password[` and the question's key and `]` unless the host passes a `name`, so Phoenix's default `:filter_parameters` keeps the value out of the line LiveView logs for each event.
