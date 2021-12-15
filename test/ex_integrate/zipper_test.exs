defmodule ExIntegrate.Core.ZipperTest do
  use ExUnit.Case, async: true

  alias ExIntegrate.Core.Zipper, as: Z

  test "initially, current item is nil" do
    zipper = Z.zip([1, 2, :foo])
    assert is_nil(Z.node(zipper))
  end

  describe "modifying current item" do
    test "on success, modifies the item" do
      zipper = [1, 2, 42] |> Z.zip() |> Z.right()
      updated_zipper = zipper |> Z.put_current(:bar)
      assert Z.node(updated_zipper) == :bar
    end
  end

  describe "moving to the right" do
    test "when there are items to the right, moves to the right" do
      zipper = [1, 2] |> Z.zip() |> Z.right()
      assert Z.node(zipper) == 1
    end

    test "raises when there aren't elements to the right" do
      zipper = [1] |> Z.zip()

      assert_raise Z.TraversalError, fn ->
        zipper |> Z.right() |> Z.right()
      end
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
  end
end
