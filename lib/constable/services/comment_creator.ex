defmodule Constable.Services.CommentCreator do
  alias ConstableWeb.Api.CommentView
  alias Constable.Comment
  alias Constable.Repo
  alias Constable.Services.MentionFinder
  alias Constable.Subscription
  alias Constable.Emails
  alias Constable.Mailer

  def create(params) do
    changeset = Comment.create_changeset(params)

    case Repo.insert(changeset) do
      {:ok, comment} ->
        comment = comment |> Repo.preload([:user, announcement: :user])
        broadcast_html(comment)
        broadcast(comment)
        mentioned_users = email_mentioned_users(comment)
        email_subscribers(comment, mentioned_users)
        subscribe_comment_author(comment)
        {:ok, comment}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp subscribe_comment_author(comment) do
    subscribe_user(comment.announcement_id, comment.user_id)
    comment
  end

  defp email_subscribers(comment, mentioned_users) do
    users = find_subscribed_users(comment.announcement_id) -- mentioned_users
    |> Enum.reject(fn (user) -> user.id == comment.user_id end)

    Emails.new_comment(comment, users) |> Mailer.deliver_later
    comment
  end

  defp email_mentioned_users(comment) do
    users = MentionFinder.find_users(comment.body)

    Emails.new_comment_mention(comment, users) |> Mailer.deliver_later
    users
  end

  defp find_subscribed_users(announcement_id) do
    Repo.all(Subscription.for_announcement(announcement_id))
    |> Enum.map(fn (subscription) -> subscription.user end)
  end

  defp broadcast(comment) do
    ConstableWeb.Endpoint.broadcast!(
      "update",
      "comment:add",
      CommentView.render("show.json", %{comment: comment})
    )
  end

  defp broadcast_html(comment) do
    ConstableWeb.Endpoint.broadcast!(
      "live-html",
      "new-comment",
      %{
        comment: comment,
      }
    )
  end

  defp subscribe_user(announcement_id, comment_user_id) do
    params = %{
      user_id: comment_user_id,
      announcement_id: announcement_id
    }

    Repo.get_by(Subscription, params) || insert_subscription(params)
  end

  defp insert_subscription(params) do
    Subscription.changeset(params)|> Repo.insert!
  end
end
