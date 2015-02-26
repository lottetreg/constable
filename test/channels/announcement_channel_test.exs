defmodule AnnouncementChannelTest do
  use Constable.TestWithEcto, async: false
  import ChannelTestHelper
  alias Phoenix.Socket
  alias Constable.Repo
  alias Constable.AnnouncementChannel
  alias Constable.Serializers
  alias Constable.Queries

  test "announcements:index returns announcements with ids as the key" do
    user = Forge.saved_user(Repo)
    announcement = Forge.saved_announcement(Repo, user_id: user.id)
    |> Repo.preload([:comments, :user])
    announcement_id = to_string(announcement.id)

    socket_with_topic("announcements:index")
    |> handle_in_topic(AnnouncementChannel)

    announcements = %{
      announcements:
      Map.put(%{}, announcement_id, Serializers.to_json(announcement))
    }

    assert_socket_replied_with_payload("announcements:index", announcements)
  end

  test "announcements:index returns announcements with embedded comments" do
    user = Forge.saved_user(Repo)
    announcement = Forge.saved_announcement(Repo, user_id: user.id)
    Forge.saved_comment(Repo, announcement_id: announcement.id, user_id: user.id)
    announcement = announcement |> Repo.preload([:user, comments: :user])
    announcement_id = to_string(announcement.id)

    socket_with_topic("announcements:index")
    |> handle_in_topic(AnnouncementChannel)

    announcements = %{
      announcements:
      Map.put(%{}, announcement_id, Serializers.to_json(announcement))
    }
    assert_socket_replied_with_payload("announcements:index", announcements)
  end

  test "announcements:create returns an announcement" do
    user = Forge.saved_user(Repo)
    params = %{"title" => "Foo", "body" => "Bar"}
    Phoenix.PubSub.subscribe(Constable.PubSub, self, "announcements:create")

    socket_with_topic("announcements:create")
    |> Socket.assign(:current_user_id, user.id)
    |> handle_in_topic(AnnouncementChannel, params)

    announcement =
      Queries.Announcement.with_sorted_comments
      |> Repo.one
      |> Serializers.to_json
    assert_socket_broadcasted_with_payload("announcements:create", announcement)
  end

  defmodule FakeAnnouncementMailer do
    def created(announcement) do
      send self, {:new_announcement_email_sent, announcement}
    end
  end

  test "announcements:create sends a notification email to all users" do
    user = Forge.saved_user(Repo)
    params = %{"title" => "Foo", "body" => "Bar"}
    Pact.override(self, :announcement_mailer, FakeAnnouncementMailer)

    socket_with_topic("announcements:create")
    |> Socket.assign(:current_user_id, user.id)
    |> handle_in_topic(AnnouncementChannel, params)

    announcement = Queries.Announcement.with_sorted_comments |> Repo.one
    assert_received {:new_announcement_email_sent, ^announcement}
  end

  test "announcements:update returns an announcement" do
    user = Forge.saved_user(Repo)
    announcement = Forge.saved_announcement(Repo, user_id: user.id)
    params = %{"id" => announcement.id, "title" => "New!", "body" => "NEW!!!"}
    Phoenix.PubSub.subscribe(Constable.PubSub, self, "announcements:update")

    socket_with_topic("announcements:update")
    |> Socket.assign(:current_user_id, user.id)
    |> handle_in_topic(AnnouncementChannel, params)

    Queries.Announcement.with_sorted_comments
    |> Repo.one
    |> Serializers.to_json

    assert_received {:socket_broadcast, %{payload: payload}}
    assert payload.title == "New!"
    assert payload.body == "NEW!!!"
  end

  test "announcements:update doesn't update when user doesn't own it" do
    user = Forge.saved_user(Repo)
    other_user = Forge.saved_user(Repo)
    announcement = Forge.saved_announcement(Repo, user_id: other_user.id)
    params = %{"id" => announcement.id, "title" => "New!", "body" => "NEW!!!"}
    Phoenix.PubSub.subscribe(Constable.PubSub, self, "announcements:update")

    socket_with_topic("announcements:update")
    |> Socket.assign(:current_user_id, user.id)
    |> handle_in_topic(AnnouncementChannel, params)

    Queries.Announcement.with_sorted_comments
    |> Repo.one
    |> Serializers.to_json

    refute_received {:socket_broadcast, _payload }
  end
end
