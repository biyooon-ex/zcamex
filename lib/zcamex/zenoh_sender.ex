defmodule Zcamex.ZenohSender do
  @behaviour Zcamex.Sender

  @default_mec_backend "localhost"
  @default_cloud_backend "localhost"

  @ping_key "demo/zcam/ping"
  @pong_key "demo/zcam/pong"

  @impl true
  def send(destination, payload) do
    zrouter = get_zrouter(destination)

    config =
      %Zenohex.Config{
        connect: %Zenohex.Config.Connect{endpoints: [zrouter]},
        scouting: %Zenohex.Config.Scouting{delay: 200}
      }

    {:ok, session} = Zenohex.open(config)
    {:ok, publisher} = Zenohex.Session.declare_publisher(session, @ping_key)

    # Declare subscriber with created Zenoh session
    {:ok, subscriber} = Zenohex.Session.declare_subscriber(session, @pong_key)

    image = payload |> Map.get("image")
    Zenohex.Publisher.put(publisher, image)

    case Zenohex.Subscriber.recv_timeout(subscriber, 1_000_000) do
      {:ok, sample} -> {:ok, %{"image" => sample.value}}
      {:error, :timeout} -> {:error, "Zecho timeout"}
    end
  end

  defp get_zrouter(:mec),
    do: "tcp/" <> System.get_env("MEC_BACKEND", @default_mec_backend) <> ":7447"

  defp get_zrouter(:cloud),
    do: "tcp/" <> System.get_env("CLOUD_BACKEND", @default_cloud_backend) <> ":7447"
end
