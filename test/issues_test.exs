defmodule IssuesTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  doctest Issues

  import Issues.CLI, only: [parse_args: 1, sort_into_descending_order: 1]
  alias Issues.GithubIssues

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  test ":help returned by option parsing with -h and --help options" do
    assert parse_args(["-h", "anything"]) == :help
    assert parse_args(["--help", "anything"]) == :help
  end

  test "three values returned if three given" do
    assert parse_args(["user", "project", "99"]) == {"user", "project", 99}
  end

  test "count is defaulted if two values given" do
    assert parse_args(["user", "project"]) == {"user", "project", 4}
  end

  test "fetches github repo issues" do
    use_cassette "issues" do
      expected_response = [
        %{
          "number" => 10978,
          "created_at" => "2021-05-13T14:51:51Z",
          "title" =>
            "Beam files aren't built with rebar3 3.14.4 + Elixir 1.12.0-rc.1 + build_embedded: true"
        },
        %{
          "number" => 10977,
          "created_at" => "2021-05-13T08:57:06Z",
          "title" => "Better format Elixir exceptions in Erlang"
        },
        %{
          "number" => 10974,
          "created_at" => "2021-05-12T10:07:48Z",
          "title" =>
            "Failure in linked process during ExUnit on_exit doesn't change process exit code"
        }
      ]

      {:ok, issues} = GithubIssues.fetch("elixir-lang", "elixir")

      Enum.each(expected_response, fn r ->
        result =
          issues
          |> Enum.find(&(&1["number"] == r["number"]))

        assert r
               |> Map.to_list()
               |> Enum.all?(&(&1 in result)),
               "Issue ##{r["number"]} is not compatible with issue ##{result["number"]}"
      end)
    end
  end

  test "sort descending order the correct way" do
    result = sort_into_descending_order(fake_created_at_list(["c", "a", "b"]))
    issues = for issue <- result, do: Map.get(issue, "created_at")
    assert issues == ~w{ c b a }
  end

  defp fake_created_at_list(values) do
    for value <- values, do: %{"created_at" => value, "other_data" => "..."}
  end
end
