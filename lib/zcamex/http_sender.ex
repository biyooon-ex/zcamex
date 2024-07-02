defmodule Zcamex.HTTPSender do
  @behaviour Zcamex.Sender

  @default_mec_backend "localhost"
  @default_cloud_backend "localhost"

  @impl true
  def send(destination, _znodes, _mtopics, payload) do
    url = get_url(destination)
    response = Req.post(url, json: Jason.encode!(payload))

    case response do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, "#{status} #{body}"}

      {:error, reason} ->
        {:error, Exception.message(reason)}
    end
  end

  defp get_url(:mec),
    do: "http://" <> System.get_env("MEC_BACKEND", @default_mec_backend) <> ":4444/echo"

  defp get_url(:cloud),
    do: "http://" <> System.get_env("CLOUD_BACKEND", @default_cloud_backend) <> ":4444/echo"
end
