defmodule Zcamex.HTTPSender do

  @behaviour Zcamex.Sender

  @default_mec_http_backend_url   "http://localhost:4444/echo"
  @default_cloud_http_backend_url "http://localhost:4444/echo"

  @impl true
  def send(destination, payload) do
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

  defp get_url(:mec), do: System.get_env("MEC_HTTP_BACKEND_URL", @default_mec_http_backend_url)
  defp get_url(:cloud), do: System.get_env("CLOUD_HTTP_BACKEND_URL", @default_cloud_http_backend_url)

end
