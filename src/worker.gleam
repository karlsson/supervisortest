import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/io
import gleam/otp/actor.{type Started}
import gleam/string

pub const my_name = "worker"

type State {
  State(subject: Subject(WorkerMessage))
}

pub type WorkerMessage =
  #(Subject(String), String)

pub fn start_link(
  name: process.Name(WorkerMessage),
  subject: Subject(WorkerMessage),
) -> Result(process.Pid, a) {
  let selector1 =
    process.new_selector() |> process.selecting(subject, function.identity)

  let state = State(subject)
  let assert Ok(actor.Started(pid, _data)) =
    actor.initialised(state)
    |> actor.selecting(selector1)
    |> actor.returning(subject)
    |> actor.new()
    |> actor.on_message(loop)
    |> actor.start()

  let _ = process.register(pid, name)
  Ok(pid)
}

fn loop(
  i,
  msg,
) -> actor.Next(
  actor.Initialised(State, WorkerMessage, Subject(WorkerMessage)),
  b,
) {
  case msg {
    #(sender_subject, request) -> {
      case request {
        "die" -> {
          let assert True = False
          io.println("not reached")
        }
        _ -> {
          let reply =
            "Continuing with Worker "
            <> string.inspect(process.self())
            <> " "
            <> request
          process.send(sender_subject, reply)
          io.println(reply)
        }
      }
    }
  }

  actor.continue(i)
}
