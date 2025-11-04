defmodule Fortymm.Accounts.UserTest do
  use Fortymm.DataCase, async: true

  alias Fortymm.Accounts.User

  import Fortymm.AccountsFixtures

  describe "username_changeset/2" do
    test "requires username" do
      changeset = User.username_changeset(%User{}, %{})
      assert "can't be blank" in errors_on(changeset).username
    end

    test "validates minimum length" do
      changeset = User.username_changeset(%User{}, %{username: "ab"})
      assert "should be at least 3 character(s)" in errors_on(changeset).username
    end

    test "validates maximum length" do
      changeset = User.username_changeset(%User{}, %{username: String.duplicate("a", 21)})
      assert "should be at most 20 character(s)" in errors_on(changeset).username
    end

    test "accepts valid username with lowercase letters and numbers" do
      changeset = User.username_changeset(%User{}, %{username: "user123"})
      assert changeset.valid?
    end

    test "accepts valid username with underscores" do
      changeset = User.username_changeset(%User{}, %{username: "user_name"})
      assert changeset.valid?
    end

    test "accepts valid username with periods" do
      changeset = User.username_changeset(%User{}, %{username: "user.name"})
      assert changeset.valid?
    end

    test "accepts username with uppercase letters" do
      changeset = User.username_changeset(%User{}, %{username: "UserName"})
      assert changeset.valid?
    end

    test "rejects username starting with underscore" do
      changeset = User.username_changeset(%User{}, %{username: "_username"})

      assert "must start with a letter or number" in errors_on(changeset).username
    end

    test "rejects username ending with underscore" do
      changeset = User.username_changeset(%User{}, %{username: "username_"})

      assert "must end with a letter or number" in errors_on(changeset).username
    end

    test "rejects username starting with period" do
      changeset = User.username_changeset(%User{}, %{username: ".username"})

      assert "must start with a letter or number" in errors_on(changeset).username
    end

    test "rejects username ending with period" do
      changeset = User.username_changeset(%User{}, %{username: "username."})

      assert "must end with a letter or number" in errors_on(changeset).username
    end

    test "rejects username with consecutive underscores" do
      changeset = User.username_changeset(%User{}, %{username: "user__name"})

      assert "cannot contain consecutive underscores or periods" in errors_on(changeset).username
    end

    test "rejects username with consecutive periods" do
      changeset = User.username_changeset(%User{}, %{username: "user..name"})

      assert "cannot contain consecutive underscores or periods" in errors_on(changeset).username
    end

    test "rejects username with special characters" do
      changeset = User.username_changeset(%User{}, %{username: "user@name"})

      assert "can only contain letters, numbers, underscores, and periods" in errors_on(changeset).username
    end

    test "rejects username with spaces" do
      changeset = User.username_changeset(%User{}, %{username: "user name"})

      assert "can only contain letters, numbers, underscores, and periods" in errors_on(changeset).username
    end

    test "validates uniqueness of username (case insensitive)" do
      user = user_fixture(%{username: "testuser"})
      assert user.username == "testuser"

      # Try to create another user with the same username
      {:error, changeset} =
        Fortymm.Accounts.register_user(%{
          email: unique_user_email(),
          username: "testuser"
        })

      assert "has already been taken" in errors_on(changeset).username
    end

    test "validates uniqueness of username with different casing" do
      user = user_fixture(%{username: "testuser"})
      assert user.username == "testuser"

      # Try to register with username that differs only in casing
      {:error, changeset} =
        Fortymm.Accounts.register_user(%{
          email: unique_user_email(),
          username: "testuser"
        })

      assert "has already been taken" in errors_on(changeset).username
    end

    test "validates uniqueness when existing username has mixed casing" do
      user = user_fixture(%{username: "testuser"})
      assert user.username == "testuser"

      # Try to register with same normalized username
      {:error, changeset} =
        Fortymm.Accounts.register_user(%{
          email: unique_user_email(),
          username: "testuser"
        })

      assert "has already been taken" in errors_on(changeset).username
    end

    test "requires username to change when updating" do
      user = user_fixture(%{username: "oldusername"})
      changeset = User.username_changeset(user, %{username: "oldusername"})
      assert "did not change" in errors_on(changeset).username
    end

    test "accepts username change when different" do
      user = user_fixture(%{username: "oldusername"})
      changeset = User.username_changeset(user, %{username: "newusername"})
      assert changeset.valid?
    end
  end

  describe "registration_changeset/2" do
    test "requires username for registration" do
      changeset = User.registration_changeset(%User{}, %{email: unique_user_email()})
      assert "can't be blank" in errors_on(changeset).username
    end

    test "validates username format during registration" do
      changeset =
        User.registration_changeset(%User{}, %{
          email: unique_user_email(),
          username: "_invalid"
        })

      assert "must start with a letter or number" in errors_on(changeset).username
    end

    test "rejects registration with invalid characters in username" do
      changeset =
        User.registration_changeset(%User{}, %{
          email: unique_user_email(),
          username: "user@name!"
        })

      assert "can only contain letters, numbers, underscores, and periods" in errors_on(changeset).username
    end

    test "rejects registration with consecutive separators in username" do
      changeset =
        User.registration_changeset(%User{}, %{
          email: unique_user_email(),
          username: "user__name"
        })

      assert "cannot contain consecutive underscores or periods" in errors_on(changeset).username
    end

    test "accepts valid registration with username" do
      changeset =
        User.registration_changeset(%User{}, %{
          email: unique_user_email(),
          username: "validusername"
        })

      assert changeset.valid?
    end

    test "validates case-insensitive uniqueness during registration" do
      user = user_fixture(%{username: "testuser"})
      assert user.username == "testuser"

      # Try to register with same normalized username
      {:error, changeset} =
        Fortymm.Accounts.register_user(%{
          email: unique_user_email(),
          username: "testuser"
        })

      assert "has already been taken" in errors_on(changeset).username
    end

    test "validates case-insensitive uniqueness when existing has mixed case" do
      user = user_fixture(%{username: "testuser"})
      assert user.username == "testuser"

      # Try to register with same normalized username
      {:error, changeset} =
        Fortymm.Accounts.register_user(%{
          email: unique_user_email(),
          username: "testuser"
        })

      assert "has already been taken" in errors_on(changeset).username
    end
  end
end
