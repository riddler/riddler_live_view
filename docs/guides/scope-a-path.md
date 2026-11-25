# Scope a Path to who may see it

This page shows how to start a Journey of a Path under a scope, and how the
scope decides who `RiddlerLiveView.Journey` shows it to. It uses two Paths:
patron registration, a Journey that belongs to one patron, and the
branch-library onboarding, a Journey that belongs to one branch.

It assumes the host and access modules of [Render a Journey in a
LiveView](render-a-journey.md).

## What a scope is

A Journey runs under a `Riddler.Journey.Scope`: one kind and one id, both
strings, such as `{"patron", "P-1001"}` or `{"branch", "B-12"}`. The host
chooses the scope when it starts the execution and keeps it on its own
execution record; nothing changes it afterwards. Riddler lists no kinds: any
string a host names is a kind.

A Path is the host's own record of a document and the kind of scope its
Journeys take. Riddler asks only that the host checks a scope against that
kind before it starts the execution, with `Riddler.Journey.Access.check_kind/2`.

## Start a Journey under the right scope

Write the Path's scope kind where the host looks up the Path, and check it in
the host's `start/2`, the first callback of `Riddler.Journey.Host`:

```elixir
defmodule Library.RegistrationHost do
  @behaviour Riddler.Journey.Host

  alias Riddler.Journey
  alias Riddler.Journey.Access

  # Each Path names the one scope kind its Journeys take.
  @path_kinds %{"patron_registration" => "patron", "branch_onboarding" => "branch"}

  @impl true
  def start(path, scope) do
    with {:ok, kind} <- Map.fetch(@path_kinds, path),
         :ok <- Access.check_kind(scope, kind),
         {:ok, journey} <- Library.Executions.create(path, scope),
         {:ok, execution} <- Library.Executions.fetch(journey),
         {:ok, answer} <-
           Journey.present(execution.document, execution.status, execution.root) do
      {:ok, journey, answer}
    else
      _refused -> {:error, :no_such_journey}
    end
  end

  # present/1, submit/2 and back/2 as in "Render a Journey in a LiveView".
end
```

`check_kind/2` answers `:ok` when the scope's kind equals the Path's kind byte
for byte, and `{:error, :wrong_scope_kind}` otherwise, so a branch's scope
cannot start a patron registration. `start/2` answers the same
`{:error, :no_such_journey}` for a Path the host does not have and for a
scope of the wrong kind.

The package never calls `start/2`: a host starts a Journey from its own code,
before it embeds the component. Ask the access module first, with the scope
the Journey is to be started under, so that no Journey starts for an actor who
does not belong to it:

```elixir
def start_registration(patron_id) do
  with {:ok, scope} <- Riddler.Journey.Scope.new("patron", patron_id),
       :ok <- Riddler.Journey.Access.check(Library.PatronAccess, patron_id, scope, :present),
       {:ok, journey, _answer} <-
         Library.RegistrationHost.start("patron_registration", scope) do
    {:ok, journey}
  end
end
```

Keep the `journey` it answers: it is the value you pass to the component.

## Say who belongs to a scope

The access module answers `member?/2`: whether an actor belongs to a scope.
Patron registration answers it from the patron's own id. The branch-library
onboarding belongs to a branch, so its access module answers from the staff
the host keeps for that branch:

```elixir
defmodule Library.BranchAccess do
  @behaviour Riddler.Journey.Access

  alias Riddler.Journey.Scope

  @impl true
  def member?(staff_id, %Scope{kind: "branch", id: branch_id}),
    do: Library.Staff.works_at?(staff_id, branch_id)

  def member?(_staff_id, _scope), do: false

  @impl true
  def scopes(staff_id), do: Library.Staff.branch_scopes(staff_id)

  # Optional: the operations a member may take. Without it every member may
  # present, submit and go back.
  @impl true
  def allowed?(staff_id, %Scope{id: branch_id}, :submit),
    do: Library.Staff.manages?(staff_id, branch_id)

  def allowed?(_staff_id, _scope, _operation), do: true
end
```

`scopes/1` answers exactly the scopes for which `member?/2` is `true`; the
package never calls it, and keeping the two in agreement is the host's.
`allowed?/3` is optional: `Riddler.Journey.Access.check/4` calls it only after
`member?/2` answered `true`, and a host that does not define it lets every
member take every operation.

## Embed it with the right modules

Each Path's Journey is embedded with the access module for its kind. The
branch onboarding page passes the staff member as the actor:

```heex
<.live_component
  module={RiddlerLiveView.Journey}
  id="onboarding"
  journey={@journey}
  host={Library.RegistrationHost}
  access={Library.BranchAccess}
  actor={@staff_id}
/>
```

The component asks `Riddler.Journey.Access.check/4` with the scope the host's
`present/1` answers: on mount, on every refresh and retry, before every submit
and before every back. A staff member who stops working at the branch while
the page is open is refused on the next press, and the component draws the one
refusal it draws for a Journey that does not exist. It does not say which of
the two it is, so a visitor learns nothing about which Journeys exist.

A change to the `journey`, `host`, `access` or `actor` assign asks the host
and the access module again, as on mount.

## See also

- `Riddler.Journey.Access`, `Riddler.Journey.Scope` and
  `Riddler.Journey.Host` for the three contracts, in riddler.
- `RiddlerLiveView.Journey`, "Who may see the Journey", for what the component
  asks and when.
- [Render a Journey in a LiveView](render-a-journey.md) for the component and
  the host's other callbacks.
