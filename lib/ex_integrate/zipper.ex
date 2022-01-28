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

  @initial_position -1

  @enforce_keys [:l, :r, :current, :size]
  defstruct @enforce_keys ++ [position: @initial_position]

  @opaque t :: %__MODULE__{
            l: [term] | [],
            current: term,
            r: [term] | [],
            size: non_neg_integer,
            position: integer
          }

  @opaque t(val) :: %__MODULE__{
            r: [val] | [],
            l: [val] | [],
            current: val | nil,
            size: non_neg_integer,
            position: integer
          }

  defmodule TraversalError do
    defexception [:message]

    @impl Exception
    def exception(value) do
      msg = "cannot traverse the zipper in this direction. #{inspect(value)}"
      %TraversalError{message: msg}
    end
  end

  defguard is_zipper(term) when is_struct(term, __MODULE__)

  defguard is_at_start(zipper)
           when zipper.l == [] and
                  is_nil(zipper.current) and
                  zipper.position == @initial_position

  defguard is_at_end(zipper) when zipper.position == zipper.size

  defguard is_out_of_bounds(zipper)
           when is_zipper(zipper) and
                  (zipper.position >= zipper.size or zipper.position < @initial_position)

  @spec new(val) :: t(val) when val: list
  def new(list) when is_list(list) do
    struct!(__MODULE__,
      l: [],
      current: nil,
      r: list,
      size: length(list),
      position: @initial_position
    )
  end

  defdelegate zip(list), to: __MODULE__, as: :new

  @spec node(t) :: term
  def node(%__MODULE__{} = zipper), do: zipper.current

  @spec right(t) :: t | no_return
  def right(zipper) when is_out_of_bounds(zipper),
    do: raise(TraversalError, zipper)

  def right(zipper) when is_at_start(zipper) do
    zipper
    |> Map.put(:current, hd(zipper.r))
    |> Map.put(:r, tl(zipper.r))
    |> Map.update(:position, nil, &(&1 + 1))
  end

  def right(%__MODULE__{r: []} = zipper) do
    zipper
    |> Map.put(:l, zipper.l ++ [zipper.current])
    |> Map.update(:position, nil, &(&1 + 1))
  end

  def right(%__MODULE__{} = zipper) do
    zipper
    |> Map.put(:l, zipper.l ++ [zipper.current])
    |> Map.put(:current, hd(zipper.r))
    |> Map.put(:r, tl(zipper.r))
    |> Map.update(:position, nil, &(&1 + 1))
  end

  @spec replace_at(t, non_neg_integer, term) :: t
  def replace_at(%__MODULE__{size: size} = zipper, index, _)
      when index >= size,
      do: zipper

  def replace_at(zipper, 0, new_value) when is_at_start(zipper) do
    Map.update(zipper, :r, nil, fn r ->
      List.replace_at(r, 0, new_value)
    end)
  end

  def replace_at(%__MODULE__{position: position} = zipper, index, new_value)
      when index == position do
    Map.put(zipper, :current, new_value)
  end

  def replace_at(%__MODULE__{position: position} = zipper, index, new_value)
      when index < position do
    Map.update(zipper, :l, nil, fn l ->
      List.replace_at(l, index, new_value)
    end)
  end

  def replace_at(%__MODULE__{position: position} = zipper, index, new_value)
      when index > position do
    Map.update(zipper, :r, nil, fn r ->
      r_index = index - position - 1
      List.replace_at(r, r_index, new_value)
    end)
  end

  @spec put_current(t, term) :: t
  def put_current(%__MODULE__{} = zipper, new_value),
    do: replace_at(zipper, zipper.position, new_value)

  @spec rightmost(t) :: term
  def rightmost(%__MODULE__{} = zipper),
    do: zipper |> right_items() |> List.last()

  @spec left_items(t) :: list
  def left_items(%__MODULE__{} = zipper), do: zipper.l

  @spec right_items(t) :: list
  def right_items(%__MODULE__{} = zipper), do: zipper.r

  @spec to_list(t) :: list
  def to_list(zipper) when is_at_start(zipper), do: zipper.r

  def to_list(zipper) when is_at_start(zipper) or is_at_end(zipper),
    do: zipper.l ++ zipper.r

  def to_list(%__MODULE__{} = zipper),
    do: zipper.l ++ [zipper.current] ++ zipper.r

  @spec end?(t) :: boolean
  def end?(zipper) when is_at_end(zipper), do: true
  def end?(_), do: false

  @spec zipper?(term) :: boolean
  def zipper?(zipper) when is_zipper(zipper), do: true
  def zipper?(_), do: false
end
