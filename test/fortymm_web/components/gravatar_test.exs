defmodule FortymmWeb.Components.GravatarTest do
  use FortymmWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  use FortymmWeb, :html
  alias FortymmWeb.Components.Gravatar

  describe "avatar/1" do
    test "renders gravatar with email" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar email="test@example.com" />
        """)

      # MD5 hash of "test@example.com"
      expected_hash = "55502f40dc8b7c769880b10874abc9d0"

      assert html =~ "https://www.gravatar.com/avatar/#{expected_hash}"
      assert html =~ "s=80"
      assert html =~ "d=identicon"
      assert html =~ ~s(alt="User avatar")
    end

    test "generates correct MD5 hash for email" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar email="user@domain.com" />
        """)

      # MD5 hash of "user@domain.com"
      expected_hash = "cd2bfcffe5fee4a1149d101994d0987f"

      assert html =~ expected_hash
    end

    test "trims whitespace from email" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar email="  test@example.com  " />
        """)

      # MD5 hash of "test@example.com" (trimmed)
      expected_hash = "55502f40dc8b7c769880b10874abc9d0"

      assert html =~ expected_hash
    end

    test "converts email to lowercase" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar email="Test@Example.COM" />
        """)

      # MD5 hash of "test@example.com" (lowercased)
      expected_hash = "55502f40dc8b7c769880b10874abc9d0"

      assert html =~ expected_hash
    end

    test "renders with custom size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar email="test@example.com" size={40} />
        """)

      assert html =~ "s=40"
    end

    test "renders with default size when not specified" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar email="test@example.com" />
        """)

      assert html =~ "s=80"
    end

    test "renders with custom CSS class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar email="test@example.com" class="rounded-full border-2" />
        """)

      assert html =~ ~s(class="rounded-full border-2")
    end

    test "renders without class attribute when not specified" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar email="test@example.com" />
        """)

      # Should render img tag but class should not be set or be empty
      refute html =~ ~r/class="[^"]+"/
    end

    test "renders with custom alt text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar email="test@example.com" alt="John Doe" />
        """)

      assert html =~ ~s(alt="John Doe")
    end

    test "renders with default alt text when not specified" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar email="test@example.com" />
        """)

      assert html =~ ~s(alt="User avatar")
    end

    test "renders with global attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar email="test@example.com" id="user-avatar" data-testid="avatar-image" />
        """)

      assert html =~ ~s(id="user-avatar")
      assert html =~ ~s(data-testid="avatar-image")
    end

    test "renders with multiple custom attributes combined" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar
          email="admin@example.com"
          size={64}
          class="w-16 h-16 rounded-full"
          alt="Administrator"
          data-role="admin"
        />
        """)

      expected_hash = "e64c7d89f26bd1972efa854d13d7dd61"

      assert html =~ expected_hash
      assert html =~ "s=64"
      assert html =~ ~s(class="w-16 h-16 rounded-full")
      assert html =~ ~s(alt="Administrator")
      assert html =~ ~s(data-role="admin")
    end

    test "renders img tag with correct structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Gravatar.avatar email="test@example.com" />
        """)

      assert html =~ ~r/<img[^>]+>/
      assert html =~ ~r/src="/
    end
  end
end
