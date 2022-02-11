defmodule ExIntegrate.Core.ZipperTest do
  use ExUnit.Case, async: true

  alias ExIntegrate.Core.Zipper, as: Z

  describe "moving to the right" do
    test "initially, current item is nil" do
      zipper = Z.zip([1, 2, :foo])
      assert is_nil(Z.node(zipper))
    end

    test "when there are still items to the right, moves to the right" do
      zipper = [1, 2] |> Z.zip() |> Z.right()
      assert Z.node(zipper) == 1
    end

    test "end position is one past the rightmost item" do
      zipper = [1, 2] |> Z.zip() |> Z.right() |> Z.right() |> Z.right()
      assert Z.end?(zipper)
    end

    test "raises when trying to move past the end" do
      zipper = [1, 2] |> Z.zip()

      assert_raise Z.TraversalError, fn ->
        zipper |> Z.right() |> Z.right() |> Z.right() |> Z.right()
      end
    end
  end

  describe "updating an item" do
    setup :generate_random_item

    defp generate_random_item(_) do
      item = Enum.random([:bar, [[42], "foo"], %{baz: :bat}])
      [item: item]
    end

    test "returns updated zipper when zipper is at beginning", %{item: item} do
      zipper =
        [1, 2, 42]
        |> Z.zip()
        |> Z.replace_at(0, item)

      assert Z.to_list(zipper) == [item, 2, 42]
    end

    test "returns updated zipper when item is in focus", %{item: item} do
      zipper =
        [1, 2, 42]
        |> Z.zip()
        |> Z.right()
        |> Z.replace_at(0, item)

      assert Z.to_list(zipper) == [item, 2, 42]
    end

    test "returns updated zipper when item is left of focus", %{item: item} do
      zipper =
        [1, 2, 42]
        |> Z.zip()
        |> Z.right()
        |> Z.right()
        |> Z.replace_at(0, item)

      assert Z.to_list(zipper) == [item, 2, 42]
    end

    test "returns updated zipper when item is right of focus", %{item: item} do
      zipper =
        [1, 2, 42]
        |> Z.zip()
        |> Z.right()
        |> Z.right()
        |> Z.replace_at(2, item)

      assert Z.to_list(zipper) == [1, 2, item]
    end

    test "returns original zipper when index is out of bounds" do
      zipper = [1, 2, 42] |> Z.zip()
      assert zipper == Z.replace_at(zipper, 100, :not_updated)
    end
  end

  describe "updating current item" do
    test "on success, modifies the item" do
      zipper = [1, 2, 42] |> Z.zip() |> Z.right()
      new_item = Enum.random([:bar, [[42], "foo"], %{baz: :bat}])
      updated_zipper = Z.put_current(zipper, new_item)

      assert Z.node(updated_zipper) == new_item
    end
  end

  test "gets the rightmost item" do
    zipper = Z.zip([1, :foo, ["three"]])
    assert Z.rightmost(zipper) == ["three"]
  end

  test "gets the items left of the current one" do
    zipper = [1, :foo, ["three"]] |> Z.zip() |> Z.right() |> Z.right() |> Z.right()
    assert Z.left_items(zipper) == [1, :foo]
  end

  test "gets the items right of the current one" do
    zipper = ["something", [42, :blue], 56] |> Z.zip() |> Z.right() |> Z.right()
    assert Z.right_items(zipper) == [56]
  end

  test "converts to list" do
    original_list = [1..2, {"something", :foo, []}, {{:bar}}]

    zipper = Z.zip(original_list)
    assert Z.to_list(zipper) == original_list

    zipper = zipper |> Z.right() |> Z.right() |> Z.right()
    assert Z.to_list(zipper) == original_list
  end

  test "checks if the focus has reached the end" do
    zipper_at_end =
      ["something", [[42]]]
      |> Z.zip()
      |> Z.right()
      |> Z.right()
      |> Z.right()

    assert Z.end?(zipper_at_end)
  end

  describe "checking if the input is a zipper" do
    test "returns true for zippers" do
      zipper = Z.zip([1, 2, 3])
      assert Z.zipper?(zipper)
    end

    test "returns false for non-zippers" do
      non_zipper = Enum.random([["not", "a", "zipper"], Enum.random(0..1000), :foobar])
      refute Z.zipper?(non_zipper)
    end
  end
end
