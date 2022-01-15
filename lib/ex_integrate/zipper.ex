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

  defstruct l: [], current: nil, r: []

  @end_token :end

  @type t :: %__MODULE__{
          l: list,
          current: term,
          r: list
        }

  @type t(val) :: %__MODULE__{r: val}

  defmodule TraversalError do
    defexception [:message]

    @impl Exception
    def exception(value) do
      msg = "cannot traverse the zipper in this direction. #{inspect(value)}"
      %TraversalError{message: msg}
    end
  end

  defguard is_zipper(term) when is_struct(term, __MODULE__)

  @spec zip(val) :: t(val) when val: list
  def zip(list) when is_list(list), do: %__MODULE__{r: list}

  @spec node(t) :: term
  def node(%__MODULE__{} = zipper), do: zipper.current

  @spec right(t) :: t | no_return
  def right(%__MODULE__{current: @end_token, r: []} = zipper), do: raise(TraversalError, zipper)
  def right(%__MODULE__{r: []} = zipper), do: right(%{zipper | r: [@end_token]})

  def right(%__MODULE__{l: [], current: nil, r: [head_r | tail_r]}),
    do: %__MODULE__{current: head_r, r: tail_r}

  def right(%__MODULE__{} = zipper) do
    l = zipper.l ++ [zipper.current]
    [head_r | tail_r] = zipper.r
    %__MODULE__{l: l, current: head_r, r: tail_r}
  end

  @spec put_current(t, term) :: t
  def put_current(%__MODULE__{} = zipper, new_value),
    do: %{zipper | current: new_value}

  @spec rightmost(t) :: term
  def rightmost(%__MODULE__{} = zipper), do: zipper |> right_items() |> List.last()

  @spec left_items(t) :: list
  def left_items(%__MODULE__{} = zipper), do: zipper.l

  @spec right_items(t) :: list
  def right_items(%__MODULE__{} = zipper), do: zipper.r

  @spec to_list(t) :: list
  def to_list(%__MODULE__{l: [], current: nil, r: r}), do: r
  def to_list(%__MODULE__{} = zipper), do: Enum.concat([zipper.l, zipper.r, [zipper.current]])

  @spec end?(t) :: boolean
  def end?(%__MODULE__{} = zipper), do: zipper.current == @end_token

  @spec zipper?(term) :: boolean
  def zipper?(zipper) when is_zipper(zipper), do: true
  def zipper?(_), do: false
end
