defmodule Extension.MapTest do
  use ExUnit.Case, async: true

  import Extension.Map

  describe "Extension.Map.safe_get" do
    test "safe_get/2 from nil returns nil" do
      assert safe_get(nil, :foo) == nil
      assert safe_get(nil, "bar") == nil
      assert safe_get(nil, nil) == nil
    end

    test "safe_get/2 from empty map returns nil" do
      assert safe_get(%{}, :foo) == nil
      assert safe_get(%{}, "bar") == nil
      assert safe_get(%{}, nil) == nil
    end

    test "safe_get/2 from map returns value" do
      assert safe_get(%{foo: 1}, :foo) == 1
      assert safe_get(%{"bar" => 2}, "bar") == 2
    end

    test "safe_get/2 get missing value returns nil" do
      assert safe_get(%{foo: 1}, "bar") == nil
      assert safe_get(%{foo: 1}, nil) == nil
    end

    test "safe_get/3 from nil with default returns nil" do
      assert safe_get(nil, :foo, 4) == nil
      assert safe_get(nil, "bar", 5) == nil
      assert safe_get(nil, nil, 6) == nil
    end

    test "safe_get/3 from empty map with default returns default" do
      assert safe_get(%{}, :foo, 4) == 4
      assert safe_get(%{}, "bar", 5) == 5
      assert safe_get(%{}, nil, 6) == 6
    end

    test "safe_get/3 from map with default returns value" do
      assert safe_get(%{foo: 1}, :foo, 4) == 1
      assert safe_get(%{"bar" => 2}, "bar", 5) == 2
      assert safe_get(%{foo: 1}, nil, 6) == 6
    end
  end
end
