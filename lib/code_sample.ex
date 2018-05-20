defmodule CodeSample do
  @moduledoc """
  This module provides convenience functions helpful in manipulating comments.

  Supported functions include creating, getting, updating, and deleting comments associated with a particular file.
  """
  @doc """
  Creates and places a comment to a specified comment.
  """ 
  @spec get_comments!(String.t, String.t) :: integer
  def get_comments!(file_id, token) do
    case HTTPoison.get! "https://api.box.com/2.0/files/#{file_id}/comments", %{Authorization: "Bearer #{token}"} do
      %{status_code: 200, body: body} -> # In the event of a response code of 200 (Successful GET)...
        body
        |> Poison.decode!
        |> Map.get("entries")
      %{status_code: code, body: body} -> # In the event of a non desired response...
        raise "Failed to get comments.  Received #{code}: #{body}" # Provide more info about what happened.
    end
  end

  @spec create_comment(String.t, String.t, String.t) :: {:ok , String.t} | {:auth_failure, String.t} | {:error, String.t}
  def create_comment(comment, file_id, token) do
    case HTTPoison.post!("https://api.box.com/2.0/comments", Poison.encode!(%{"item": %{"type": "file", "id": "#{file_id}"}, "message": "#{comment}"}), %{Authentication: "Bearer #{token}"}) do
      %{body: body, status_code: 201} -> # In the event of a response code of 201 (successful creation)...
        comment_id = body
                     |> Poison.decode! # Decode the incoming response
                     |> Map.get("id") # Grab the new comment's ID.
        {:ok, comment_id}
      %{status_code: 401} -> # In the event of a response code of 401 (Unauthorized)
        {:auth_failure, "Failed to create comment. Authorization token is invalid"}
      %{status_code: status_code, body: body} ->
        {:error, "Failed to post new comment '#{comment}' to file with id: #{file_id}, POST returned #{status_code}: #{Poison.decode!(body)}"}
    end 
  end

  @doc """
  create_comment! works exactly like create_comment but will raise exception in the vent of a comment creation error
  """

  def create_comment!(comment, file_id, token) do
    case delete_comment(comment, file_id, token) do
      {:ok, comment_id} ->
        comment_id
      {_, error} ->
        raise error
    end
  end

  @spec update_comment(String.t, String.t, String.t) :: {:ok , String.t} | {:auth_failure, String.t} | {:error, String.t}
  def update_comment(new_comment, comment_id, token) do
    case HTTPoison.put!("https://api.box.com/2.0/comments/#{comment_id}", Poison.encode!(%{"message": "#{new_comment}"}), %{Authentication: "Bearer #{token}"}) do
      %{body: body, status_code: 200} -> # In the event of a response code of 200 (Successful PUT)...
        body
        |> Poison.decode!
        |> Map.get("id")
        {:ok, comment_id}
      %{status_code: 401, body: body} -> # In the event of a response code of 401 (Unauthorized)
        {:auth_failure, "Failed to update comment. Authorization token is invalid. Body: #{body}"}
      %{status_code: status_code, body: body} ->
        {:error, "Failed to put updated comment #{comment_id}, PUT returned #{status_code}: #{Poison.decode!(body)}"}
    end
  end

  @doc """
  update_comment! works exactly like update_comment but will raise exception in the vent of an update error
  """

  def update_comment!(new_comment, file_id, token) do
    case delete_comment(new_comment, file_id, token) do
      {:ok, comment_id} ->
        comment_id
      {_, error} ->
        raise error
    end
  end

  @spec delete_comment(String.t, String.t) :: {:ok, String.t} | {:auth_failure, String.t} | {:error, String.t}
  def delete_comment(comment_id, token) do
    case HTTPoison.delete!("https://api.box.com/2.0/comments/#{comment_id}", Poison.encode!(%{Authentication: "Bearer #{token}"})) do
      %{status_code: 204} -> # 204 is the proper response for a successful deletion
        {:ok, "Successfully deleted comment with ID: #{comment_id}"}
      %{status_code: 401} ->
        {:auth_failure, "Failed to delete comment with ID: #{comment_id}. Authorization is invalid"}
      %{status_code: code, body: body} ->
        {:error, "Failed to delete comment with ID: #{comment_id}. DELETE recieved #{code}: #{Poison.decode!(body)}"}
    end
  end

  @doc """
  delete_comment! works exactly like delete_comment but will raise exception in the vent of a deletion error
  """

  def delete_comment!(comment_id, token) do
    case delete_comment(file_id, token) do
      {:ok, _} ->
        :ok
      {_, error} ->
        raise error
    end
  end
end
