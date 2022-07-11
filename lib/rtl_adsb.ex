defmodule RtlAdsb do
  use Application



  def start(_type, _args) do
    children = [
      RtlAdsb.AdsbListener,
      RtlAdsb.CheckParity
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
    {:ok, _} = Registry.start_link(keys: :unique, name: Registry.Processes)
  end

end

defmodule RtlAdsb.AdsbListener do
  use GenServer
  require Logger

  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args \\ []) do
    path = "C:\\web_stuff\\rtl_adsb\\lib\\BIN\\rtl_sdr\\rtl_adsb.exe"
    port = Port.open({:spawn_executable, path}, [:binary])

    {:ok, %{message_string: "", acc: 0}}
  end

  def handle_info({port, {:data, text_line}}, state) do
    cond do
      state.acc === 0 ->
        if text_line === "*" do
          Logger.info("New record started")
          new_acc = state.acc + 1
          {:noreply, Map.put(state, :acc, new_acc)}
        else
          Logger.error("Bad record start")
          {:error, :bad_record_start}
        end
      state.acc > 0 && state.acc < 29 ->
        # Logger.info("Half-Byte #{state.acc}")
        new_acc = state.acc + 1
        new_message = state.message_string <> convert_to_bin(text_line)
        # GenServer.cast(:check_parity, )
        {:noreply, %{state | message_string: new_message, acc: new_acc}}
      state.acc === 29 ->
        if text_line === ";" do
          Logger.info("Record ended")
          Logger.info("#{state.message_string}")
          new_acc = state.acc + 1
          {:noreply, %{state | acc: new_acc}}
        else
          Logger.info("Error in message termination")
          {:noreply, state}
        end
      state.acc === 30 ->
        new_acc = state.acc + 1
        Logger.info("carriage return")
        {:noreply, %{state | acc: new_acc}}
      state.acc === 31 ->
        Logger.info("new line")
        {:noreply, %{state | message_string: "", acc: 0}}
    end
  end
  def convert_to_bin(single_hex_char) do
    cond do
      single_hex_char === "0" ->
        "0000"
      single_hex_char === "1" ->
        "0001"
      single_hex_char === "2" ->
        "0010"
      single_hex_char === "3" ->
        "0011"
      single_hex_char === "4" ->
        "0100"
      single_hex_char === "5" ->
        "0101"
      single_hex_char === "6" ->
        "0110"
      single_hex_char === "7" ->
        "0111"
      single_hex_char === "8" ->
        "1000"
      single_hex_char === "9" ->
        "1001"
      single_hex_char === "a" ->
        "1010"
      single_hex_char === "b" ->
        "1011"
      single_hex_char === "c" ->
        "1100"
      single_hex_char === "d" ->
        "1101"
      single_hex_char === "e" ->
        "1110"
      single_hex_char === "f" ->
        "1111"
    end
  end
end

# defmodule RtlAdsb.CheckParity do
#   use GenServer

#   def init(_args \\ []) do
#     {:ok, ""}
#   end

#   def start_link do
#     GenServer.start_link(__MODULE__, [], name: :check_parity)
#   end

#   def handle_cast({:check, message}, messages) do

#   end
# end
