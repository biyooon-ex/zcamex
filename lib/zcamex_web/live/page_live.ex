defmodule ZcamexWeb.PageLive do
  use ZcamexWeb, :live_view
  alias Zcamex.{HTTPSender}
  require Logger

  @protocol_options ["http"]
  @default_protocol "http"
  @default_fps "10"
  @default_image_quality "0.2"

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       protocol_options: @protocol_options,
       selected_protocol: @default_protocol,
       selected_fps: @default_fps,
       selected_image_quality: @default_image_quality,
       mec_error: nil,
       cloud_error: nil,
       form:
         to_form(%{
           "protocol" => @default_protocol,
           "fps" => @default_fps,
           "image_quality" => @default_image_quality
         })
     )}
  end

  def handle_event("form_changed", params, socket) do
    %{"protocol" => protocol, "fps" => fps, "image_quality" => image_quality} = params

    {:noreply,
     socket
     |> assign(
       selected_protocol: protocol,
       selected_fps: fps,
       selected_image_quality: image_quality,
       form: to_form(params)
     )
     |> push_event("update_webcam_settings", %{
       fps: fps,
       image_quality: image_quality
     })}
  end

  def handle_event("send_image", %{"image" => image}, socket) do
    %{selected_protocol: selected_protocol} = socket.assigns

    {:noreply,
     socket
     |> start_async(:send_to_mec, fn -> handle_send(selected_protocol, :mec, image) end)
     |> start_async(:send_to_cloud, fn -> handle_send(selected_protocol, :cloud, image) end)}
  end

  def handle_async(:send_to_mec, {:ok, {:ok, result}}, socket) do
    {:noreply,
     socket
     |> assign_error(:mec, nil)
     |> push_event("mec_returned", result)}
  end

  def handle_async(:send_to_mec, {:ok, {:error, message}}, socket) do
    {:noreply,
     socket
     |> assign_error(:mec, message)
     |> push_event("mec_returned", %{
       returned_image: nil,
       latency: nil
     })}
  end

  def handle_async(:send_to_mec, {:exit, {exception, _stacktrace}}, socket) do
    {:noreply,
     socket
     |> assign_error(:mec, Exception.message(exception))
     |> push_event("mec_returned", %{
       returned_image: nil,
       latency: nil
     })}
  end

  def handle_async(:send_to_cloud, {:ok, {:ok, result}}, socket) do
    {:noreply,
     socket
     |> assign_error(:cloud, nil)
     |> push_event("cloud_returned", result)}
  end

  def handle_async(:send_to_cloud, {:ok, {:error, message}}, socket) do
    {:noreply,
     socket
     |> assign_error(:cloud, message)
     |> push_event("cloud_returned", %{
       returned_image: nil,
       latency: nil
     })}
  end

  def handle_async(:send_to_cloud, {:exit, {exception, _stacktrace}}, socket) do
    {:noreply,
     socket
     |> assign_error(:cloud, Exception.message(exception))
     |> push_event("cloud_returned", %{
       returned_image: nil,
       latency: nil
     })}
  end

  defp handle_send(protocol, destination, image) do
    start_time = :os.system_time(:millisecond)
    payload = %{"image" => image}
    response = send(protocol, destination, payload)
    end_time = :os.system_time(:millisecond)
    latency = end_time - start_time
    handle_response(response, latency)
  end

  defp handle_response({:ok, %{"image" => image}}, latency) do
    {:ok, %{returned_image: image, latency: latency}}
  end

  defp handle_response({:error, message}, _latency) do
    {:error, message}
  end

  defp assign_error(socket, :mec, message), do: assign(socket, mec_error: message)
  defp assign_error(socket, :cloud, message), do: assign(socket, cloud_error: message)

  defp send("http", destination, payload), do: HTTPSender.send(destination, payload)
end
