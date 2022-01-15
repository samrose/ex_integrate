defmodule ExIntegrate.Core.Zipper do
  @moduledoc """
  A set of functions operating on zippers. For now, zippers are in two
  dimensions only.

  The internal structure of a zipper should be considered opaque and subject to
  change. To get or update the current item, traverse the zipper, or perform any
  other operation on the zipper, use the public functions exposed in this
  module.

  References:
    * [Wikipedia](https://en.wikipedia.org/wiki/Zipper_(data_structure))
    * [Gerard Huet's original paper](https://www.st.cs.uni-saarland.de/edu/seminare/2005/advanced-fp/docs/huet-zipper.pdf)
    * [Clojure stdlib](https://clojuredocs.org/clojure.zip/zipper)
    * [ElixirForum post](https://elixirforum.com/t/elixir-needs-a-fifo-type/5701/24)
  """

  @opaque t :: {[term], term | nil | :end, [term]}
  @opaque t(a_list) :: {[], nil, a_list}

  defmodule TraversalError do
    defexception [:message]

    @impl Exception
    def exception(value) do
      msg = "cannot traverse the zipper in this direction. #{inspect(value)}"
      %TraversalError{message: msg}
    end
  end

  @spec zip(val) :: t(val) when val: list
  def zip(list) when is_list(list) do
    {[], nil, list}
  end

  @spec node(t) :: term
  def node({_l, current, _r}),
    do: current

  @spec right(t) :: t
  def right({_, :end, []} = zipper),
    do: raise(TraversalError, zipper)

  def right({l, current, []}),
    do: right({l, current, [:end]})

  def right({[], nil, [head_r | tail_r]}),
    do: {[], head_r, tail_r}

  def right({l, old_current, [head_r | tail_r]}) do
    new_l = l ++ [old_current]
    {new_l, head_r, tail_r}
  end

  @spec put_current(t, term) :: t
  def put_current({l, _current_value, r}, new_value),
    do: {l, new_value, r}

  @spec rightmost(t) :: term
  def rightmost({_l, _current, r}),
    do: List.last(r)

  def left_items({l, _current, _r}),
    do: l

  def right_items({_l, _current, r}),
    do: r

  def to_list({[], nil, r}),
    do: r

  def to_list({l, current, r}),
    do: l ++ [current | r]

  @spec end?(t) :: boolean
  def end?(zipper) do
    case zipper do
      {_, :end, []} -> true
      _ -> false
    end
  end

  @spec zipper?(term) :: boolean
  def zipper?({l, _, r}) when is_list(l) and is_list(r), do: true
  def zipper?(_), do: false
end
