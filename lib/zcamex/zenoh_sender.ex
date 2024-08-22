defmodule Zcamex.ZenohSender do
  @behaviour Zcamex.Sender

  @default_mec_backend "localhost"
  @default_cloud_backend "localhost"

  @prefix_ping_key "demo/zcam/ping/"
  @prefix_pong_key "demo/zcam/pong/"

  def create_zenoh_nodes(destination) do
    # Set endpoint
    zrouter = get_zrouter(destination)

    config =
      %Zenohex.Config{
        connect: %Zenohex.Config.Connect{endpoints: [zrouter]},
        scouting: %Zenohex.Config.Scouting{delay: 200}
      }

    # Open session and declare publisher
    {:ok, session} = Zenohex.open(config)
    ping_key = @prefix_ping_key <> "#{destination}"
    {:ok, publisher} = Zenohex.Session.declare_publisher(session, ping_key)

    # Declare subscriber with created Zenoh session
    pong_key = @prefix_pong_key <> "#{destination}"
    {:ok, subscriber} = Zenohex.Session.declare_subscriber(session, pong_key)

    %{:pub => publisher, :sub => subscriber}
  end

  @impl true
  def send(destination, znodes, payload) do
    publisher = znodes[destination] |> Map.get(:pub)
    image = payload |> Map.get("image")
    Zenohex.Publisher.put(publisher, image)

    subscriber = znodes[destination] |> Map.get(:sub)

    case subscribe(subscriber) do
      {:ok, image} -> {:ok, image}
      {:error, :timeout} -> {:error, "Zecho timeout"}
    end
  end

  defp subscribe(subscriber) do
    case Zenohex.Subscriber.recv_timeout(subscriber) do
      {:error, :timeout} ->
        subscribe(subscriber)

      {:ok, sample} ->
        {:ok, %{"image" => sample.value}}
    end
  end

  defp get_zrouter(:mec),
    do: "tcp/" <> System.get_env("MEC_BACKEND", @default_mec_backend) <> ":7447"

  defp get_zrouter(:cloud),
    do: "tcp/" <> System.get_env("CLOUD_BACKEND", @default_cloud_backend) <> ":7447"
end
