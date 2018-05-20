Code.require_file "../scaffold_helper.exs", __DIR__

defmodule CodeSampleIntegrationTest do
  use ExUnit.Case

  setup do
    CodeSample.Authentication.start_link

    # Build up "./test/resources/pp_doc.txt" in a platform agnostic way
    test_file = Path.join [".", "test", "resources", "pp_doc.txt"]
    current_token = CodeSample.Authentication.get_token

    # If there is an exists version of this file, we want to delete it
    # We'll create a new version to run our tests against after this block
    # It is unusual that this file will actually exist, as it *normally* gets cleaned up by the on_exit callback
    case ScaffoldHelper.get_file_id("pp_doc.txt", current_token) do
      nil ->
        nil
      file_id ->
        ScaffoldHelper.delete_file!(file_id, current_token)
    end

    # Uploads a fresh copy of our example file.  pp_file_id will be passed into each test via the context map
    pp_file_id = ScaffoldHelper.upload_file!(test_file, current_token)

    # After each test finishes, we'll delete the file
    on_exit fn ->
      ScaffoldHelper.delete_file!(pp_file_id, current_token)
    end

    # Metadata to be passed to the tests
    {:ok, file_id: pp_file_id}
  end

  test "A fresh file has no comments", context do
    assert CodeSample.get_comments!(context[:file_id], CodeSample.Authentication.get_token) == []
  end

  test "Getting comments from a non-existant file raises an exception", context do
    assert_raise RuntimeError, fn ->
      CodeSample.get_comments!("1234", CodeSample.Authentication.get_token)
    end
  end

  test "We can add a comment to a file", context do
    # Create comment and save response
    response = CodeSample.create_comment!("Test Comment!", context[:file_id], CodeSample.Authentication.get_token)
    # Save new comment's ID
    new_comment_id = Map.get(response, "id")
    # From response, parse message
    new_comment = Map.get(response, "message")
    # Compare parsed message to what it should be
    assert new_comment == "Test Comment!"
  end

  test "We can delete a comment from a file", context do
    # Create comment to be deleted
    response = CodeSample.create_comment!("Test Comment!", context[:file_id], CodeSample.Authentication.get_token)
    # Save created comment's ID from response
    new_comment_id = Map.get(response, "id")
    # Delete message and check that 204 was the recieved code (indicating successful deletion)
    assert CodeSample.delete_comment!(new_comment_id, CodeSample.Authentication.get_token) == 204
  end

  test "We can modify a comment on a file" context do
    # Create comment to be updated in the future
    response = CodeSample.create_comment!("Test Comment!", context[:file_id], CodeSample.Authentication.get_token)
    # Save the new comment's ID
    new_comment_id = Map.get(response, "id")
    # Update the previously created comment
    update_response = CodeSample.update_comment!("Updated Comment!", new_comment_id, CodeSample.Authentication.get_token)
    # Save updated comment's message
    updated_comment_message = Map.get(update_response, "message")
    # Compare updated comment's message to what it should be
    assert updated_comment_message = "Updated Comment!"
end
